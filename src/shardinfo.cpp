//     shardinfo.cpp: Common U-tree (shard) methods and helpers for sharded BT models.

#include "shardinfo.h"
#include <algorithm>

using std::endl;

//--------------------------------------------------
//S equal width shards on [0,1]
void shardinfo::setequal(size_t S)
{
   this->S=S;
   cuts.resize(S-1);
   for(size_t s=0;s<(S-1);s++) cuts[s]=((double)(s+1))/((double)S);
   w.assign(S,1.0/((double)S));
   ns.assign(S,0);
}
//--------------------------------------------------
//shards defined by the interior cutpoints icuts
bool shardinfo::setcuts(const std::vector<double>& icuts)
{
   for(size_t s=0;s<icuts.size();s++) {
      if(icuts[s]<=0.0 || icuts[s]>=1.0) return false;
      if(s>0 && icuts[s]<=icuts[s-1]) return false;
   }
   S=icuts.size()+1;
   cuts=icuts;
   w.resize(S);
   for(size_t s=0;s<S;s++) {
      double a = (s==0) ? 0.0 : cuts[s-1];
      double b = (s==(S-1)) ? 1.0 : cuts[s];
      w[s]=b-a;
   }
   ns.assign(S,0);
   return true;
}
//--------------------------------------------------
//shard that u falls in
size_t shardinfo::shard(double u) const
{
   return (size_t)(std::upper_bound(cuts.begin(),cuts.end(),u)-cuts.begin());
}
//--------------------------------------------------
//write S, cuts, weights and shard sizes, one value per line
void shardinfo::write(std::ostream& os) const
{
   os << S << endl;
   for(size_t s=0;s<cuts.size();s++) os << std::scientific << cuts[s] << endl;
   for(size_t s=0;s<S;s++) os << std::scientific << w[s] << endl;
   for(size_t s=0;s<S;s++) os << ns[s] << endl;
}
//--------------------------------------------------
//read the format produced by write
void shardinfo::read(std::istream& is)
{
   is >> S;
   cuts.resize(S-1);
   w.resize(S);
   ns.resize(S);
   for(size_t s=0;s<cuts.size();s++) is >> cuts[s];
   for(size_t s=0;s<S;s++) is >> w[s];
   for(size_t s=0;s<S;s++) is >> ns[s];
}
//--------------------------------------------------
//shard s's mean function (sum of its mean trees) and sigma (product of its
//variance trees) at x, summed/multiplied in the same order as the models' setf
void shardtrees::eval(size_t s, double* x, xinfo& xi, double& f, double& sd)
{
   f=0.0;
   for(size_t j=0;j<mt[s].size();j++) f+=mt[s][j].bn(x,xi)->gettheta();
   sd=1.0;
   for(size_t j=0;j<vt[s].size();j++) sd*=vt[s][j].bn(x,xi)->gettheta();
}

#ifdef _OPENMPI
//--------------------------------------------------
//move each local observation to the data ranks of the shard its u falls in
void mpi_shard_exchange(MPI_Comm comm, shardinfo& shi, size_t T, size_t p,
                        std::vector<double>& x, std::vector<double>& u,
                        std::vector<std::vector<double>*>& cols)
{
   int rank,size;
   MPI_Comm_rank(comm,&rank);
   MPI_Comm_size(comm,&size);
   size_t n=u.size();
   size_t nc=cols.size();
   size_t rl=p+1+nc; //row length: x, u, cols

   // destination rank of each local observation
   std::vector<int> dest(n);
   std::vector<int> scounts(size,0), rcounts(size,0);
   std::vector<size_t> rr(shi.S,0); //round-robin counters per shard
   for(size_t i=0;i<n;i++) {
      size_t s=shi.shard(u[i]);
      dest[i]=(int)(s*(T+1)+1+(rr[s]+(size_t)rank)%T);
      rr[s]++;
      scounts[dest[i]]+=(int)rl;
   }
   MPI_Alltoall(scounts.data(),1,MPI_INT,rcounts.data(),1,MPI_INT,comm);

   std::vector<int> sdispls(size,0), rdispls(size,0);
   for(int i=1;i<size;i++) {
      sdispls[i]=sdispls[i-1]+scounts[i-1];
      rdispls[i]=rdispls[i-1]+rcounts[i-1];
   }

   // pack rows in destination order
   std::vector<double> sbuf(n*rl);
   std::vector<double> rbuf(rdispls[size-1]+rcounts[size-1]);
   std::vector<int> pos(sdispls);
   for(size_t i=0;i<n;i++) {
      double* row=&sbuf[pos[dest[i]]];
      for(size_t j=0;j<p;j++) row[j]=x[i*p+j];
      row[p]=u[i];
      for(size_t k=0;k<nc;k++) row[p+1+k]=(*cols[k])[i];
      pos[dest[i]]+=(int)rl;
   }

   MPI_Alltoallv(sbuf.data(),scounts.data(),sdispls.data(),MPI_DOUBLE,
                 rbuf.data(),rcounts.data(),rdispls.data(),MPI_DOUBLE,comm);

   // unpack the rows this rank now owns
   size_t nn=rbuf.size()/rl;
   x.resize(nn*p); u.resize(nn);
   for(size_t k=0;k<nc;k++) cols[k]->resize(nn);
   for(size_t i=0;i<nn;i++) {
      const double* row=&rbuf[i*rl];
      for(size_t j=0;j<p;j++) x[i*p+j]=row[j];
      u[i]=row[p];
      for(size_t k=0;k<nc;k++) (*cols[k])[i]=row[p+1+k];
   }
}
//--------------------------------------------------
//gather every shard's trees on every rank
void mpi_gather_shard_trees(MPI_Comm comm, shardinfo& shi, size_t T,
                            std::vector<tree*>& mtrees, std::vector<tree*>& vtrees,
                            shardtrees& st)
{
   int rank,size;
   MPI_Comm_rank(comm,&rank);
   MPI_Comm_size(comm,&size);
   size_t m=mtrees.size(), mh=vtrees.size(), nt=m+mh;
   bool sender=(((size_t)rank)%(T+1)==0);  //shard masters send their trees

   // pack the node count of each tree, the ids, variables and cutpoints of each
   // tree's nodes (as three blocks per tree) and the theta of each tree's nodes
   std::vector<int> nn, ibuf;
   std::vector<double> dbuf;
   if(sender) {
      nn.resize(nt);
      for(size_t j=0;j<nt;j++) {
         tree* t=(j<m) ? mtrees[j] : vtrees[j-m];
         int k=(int)t->treesize();
         nn[j]=k;
         size_t ib=ibuf.size(), db=dbuf.size();
         ibuf.resize(ib+3*k);
         dbuf.resize(db+k);
         t->treetovec(&ibuf[ib],&ibuf[ib+k],&ibuf[ib+2*k],&dbuf[db]);
      }
   }

   // gather the counts, then the trees
   int nnodes=(int)dbuf.size();
   std::vector<int> nodecounts(size);
   MPI_Allgather(&nnodes,1,MPI_INT,nodecounts.data(),1,MPI_INT,comm);
   std::vector<int> ncounts(size), ndispls(size,0), icounts(size), idispls(size,0), dcounts(size), ddispls(size,0);
   for(int r=0;r<size;r++) {
      ncounts[r]=(((size_t)r)%(T+1)==0) ? (int)nt : 0;
      icounts[r]=3*nodecounts[r];
      dcounts[r]=nodecounts[r];
      if(r>0) {
         ndispls[r]=ndispls[r-1]+ncounts[r-1];
         idispls[r]=idispls[r-1]+icounts[r-1];
         ddispls[r]=ddispls[r-1]+dcounts[r-1];
      }
   }
   std::vector<int> nnall(ndispls[size-1]+ncounts[size-1]);
   std::vector<int> iall(idispls[size-1]+icounts[size-1]);
   std::vector<double> dall(ddispls[size-1]+dcounts[size-1]);
   MPI_Allgatherv(nn.data(),(int)nn.size(),MPI_INT,nnall.data(),ncounts.data(),ndispls.data(),MPI_INT,comm);
   MPI_Allgatherv(ibuf.data(),(int)ibuf.size(),MPI_INT,iall.data(),icounts.data(),idispls.data(),MPI_INT,comm);
   MPI_Allgatherv(dbuf.data(),(int)dbuf.size(),MPI_DOUBLE,dall.data(),dcounts.data(),ddispls.data(),MPI_DOUBLE,comm);

   // unpack
   st.mt.assign(shi.S,std::vector<tree>(m));
   st.vt.assign(shi.S,std::vector<tree>(mh));
   for(size_t s=0;s<shi.S;s++) {
      int r=(int)(s*(T+1));
      int* ip=&iall[idispls[r]];
      double* dp=&dall[ddispls[r]];
      for(size_t j=0;j<nt;j++) {
         int k=nnall[ndispls[r]+j];
         tree& t=(j<m) ? st.mt[s][j] : st.vt[s][j-m];
         t.vectotree((size_t)k,ip,ip+k,ip+2*k,dp);
         ip+=3*k;
         dp+=k;
      }
   }
}
#endif

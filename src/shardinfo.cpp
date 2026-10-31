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
#endif

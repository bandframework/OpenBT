//     shardinfo.h: Common U-tree (shard) definition and helpers for sharded BT models.

#ifndef GUARD_shardinfo_h
#define GUARD_shardinfo_h

#include <iostream>
#include <vector>
#include <cstddef>

#ifdef _OPENMPI
#   include <mpi.h>
#endif

//--------------------------------------------------
// The common U-tree shared by all trees in a sharded ensemble.  Since U is
// univariate on [0,1], any such tree is a partition of [0,1] into S intervals,
// so it is stored as the S-1 sorted interior cutpoints.  Shard s is the interval
// [cuts[s-1],cuts[s]) (with 0 and 1 at the ends) and its weight w[s] is the
// interval width.  As in tree, u goes left of a cutpoint if u < cut.
class shardinfo {
public:
   shardinfo(): S(1),cuts(),w(1,1.0),ns(1,0) {}
   void setequal(size_t S);                          //S equal width shards
   bool setcuts(const std::vector<double>& icuts);   //false if icuts are not strictly increasing in (0,1)
   size_t shard(double u) const;                     //shard that u falls in
   void write(std::ostream& os) const;
   void read(std::istream& is);

   size_t S;                  //number of shards
   std::vector<double> cuts;  //S-1 interior cutpoints
   std::vector<double> w;     //S shard weights (widths)
   std::vector<size_t> ns;    //S shard sample sizes (informational)
};

#ifdef _OPENMPI
//--------------------------------------------------
// Move each local observation to the shard its u value falls in.  Shard s is
// owned by ranks s*(T+1),...,s*(T+1)+T of comm, where the first is the shard's
// master (which receives no data) and the remaining T are its data ranks.
// Observations are spread round-robin over a shard's data ranks.  On return x
// (row-major, n x p), u and each of the per-observation vectors in cols hold
// this rank's new rows.
void mpi_shard_exchange(MPI_Comm comm, shardinfo& shi, size_t T, size_t p,
                        std::vector<double>& x, std::vector<double>& u,
                        std::vector<std::vector<double>*>& cols);
#endif

#endif

//     crn.h: Random number generator class methods.

#include "crn.h"

//--------------------------------------------------
crn::crn():df(0),alpha(0.5),beta(0.5),gen(0),nor(0),uni(0),chi(0),gam(0)
{
   gen = new genD;
   nor = new norD;
   uni = new uniD;
   gam = new gamD;
   gen->seed(99);
}
crn::~crn()
{
   delete gen;
   delete nor;
   delete uni;
   if(chi) delete chi;
   if(gam) delete gam;
}
//--------------------------------------------------
void crn::set_df(int df)
{
   if(df>0) {
      if(chi) delete chi;
      chi = new chiD(df);
   }
}
void crn::set_gam(double alpha,double beta)
{
   if(gam) delete gam;
   this->alpha=alpha;
   this->beta=beta;
   gam = new gamD(alpha,1.0/beta); //c++ uses scale, so 1/beta.
}
void crn::set_seed(int seed)
{
   // delete gen;
   // gen = new genD(seed);
   gen->seed(seed);
}
std::default_random_engine crn::get_engine_state()
{
   return *gen;
}
void crn::set_engine_state(std::stringstream& state)
{
   state >> (*gen);
}


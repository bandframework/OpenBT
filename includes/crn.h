//     crn.h: Random number generator class definition.

#ifndef CRN_H
#define CRN_H

#include "rn.h"
#include <random> 
#include <sstream>

class crn: public rn
{
//typedefs
//   typedef std::default_random_engine genD;
   typedef std::minstd_rand0 genD; // pinned: mpi_resetrn assumes single-word streamed state
   typedef std::normal_distribution<double> norD;
   typedef std::uniform_real_distribution<double> uniD;
   typedef std::chi_squared_distribution<double> chiD;
   typedef std::gamma_distribution<double> gamD;
public:
//constructor
   crn();
//virtual
   virtual ~crn();
   virtual double normal() {return (*nor)(*gen);}
   virtual double uniform() {return (*uni)(*gen);}
   virtual double chi_square() {return (*chi)(*gen);}
   virtual double gamma() {return (*gam)(*gen);}
   virtual void set_df(int df);
//get,set
   int get_df()  {return df;}
   void set_seed(int seed);
   void set_gam(double alpha,double beta);
//   std::default_random_engine get_engine_state();
   std::minstd_rand0 get_engine_state();
   void set_engine_state(std::stringstream& state);
private:
   int df;
   double alpha,beta;
   genD* gen;
   norD* nor;
   uniD* uni;
   chiD* chi;
   gamD* gam;
};

#endif //CRN_H


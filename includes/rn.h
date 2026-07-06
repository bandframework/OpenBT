//     rn.h: Random number generator virtual class definition.

#ifndef GUARD_rn
#define GUARD_rn

//pure virtual base class for random numbers
class rn
{
public:
   virtual double normal() = 0; //standard normal
   virtual double uniform() = 0; //uniform(0,1)
   virtual double chi_square() = 0; //chi-square
   virtual double gamma() = 0; //gamma(a,b)
   virtual void set_df(int df) = 0; //set df for chi-square
   virtual void set_gam(double alpha,double beta)=0;
   virtual ~rn() {}
};

#endif

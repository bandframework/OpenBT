//     mbrt.h: Mean tree BT model class definition.

#ifndef GUARD_mbrt_h
#define GUARD_mbrt_h

#include "tree.h"
#include "treefuns.h"
#include "dinfo.h"
#include "brt.h"


class msinfo : public sinfo { //sufficient statistics (will depend on end node model)
public:
   msinfo():sinfo(),sumw(0.0),sumwy(0.0) {}
   msinfo(const msinfo& is):sinfo(is),sumw(is.sumw),sumwy(is.sumwy) {}
   virtual ~msinfo() {}  //need this so memory is properly freed in derived classes.
   double sumw;
   double sumwy;
   // compound addition operator needed when adding suff stats
   virtual sinfo& operator+=(const sinfo& rhs) {
      sinfo::operator+=(rhs);
      const msinfo& mrhs=static_cast<const msinfo&>(rhs);
      sumw+=mrhs.sumw;
      sumwy+=mrhs.sumwy;
      return *this;
   }
   // assignment operator for suff stats
   virtual sinfo& operator=(const sinfo& rhs)
   {
      if(&rhs != this) {
         sinfo::operator=(rhs);
         const msinfo& mrhs=static_cast<const msinfo&>(rhs);
         this->sumw = mrhs.sumw;
         this->sumwy = mrhs.sumwy;
      }
      return *this;
   }
   // addition opertor is defined in terms of compound addition
   const msinfo operator+(const msinfo& other) const {
      msinfo result = *this; //copy of myself.
      result += other;
      return result;
   }
};

class mbrt : public brt 
{
public:
   //--------------------
   //classes
   // tprior and mcmcinfo are same as in brt
   class cinfo { //parameters for end node model prior
   public:
      cinfo():tau(1.0),sigma(0) {}
      double tau;
      double* sigma;
   };
   //--------------------
   //constructors/destructors
   mbrt():brt() {}
   //--------------------
   //methods
   void draw(rn& gen);
   void draw_mpislave(rn& gen);
   void setci(double tau, double* sigma) { ci.tau=tau; ci.sigma=sigma; }
   virtual double drawnodetheta(sinfo& si, rn& gen);
   virtual double lm(sinfo& si);
   virtual void add_observation_to_suff(diterator& diter, sinfo& si);
   virtual sinfo* newsinfo() { return new msinfo; }
   virtual std::vector<sinfo*>& newsinfovec() { std::vector<sinfo*>* si= new std::vector<sinfo*>; return *si; }
   virtual std::vector<sinfo*>& newsinfovec(size_t dim) { std::vector<sinfo*>* si = new std::vector<sinfo*>; si->reserve(dim); for(size_t i=0;i<dim;i++) si->push_back(new msinfo); return *si; }
   virtual void local_mpi_reduce_allsuff(std::vector<sinfo*>& siv);
   virtual void local_mpi_sr_suffs(sinfo& sil, sinfo& sir);
   virtual void local_setr(diterator& diter);
   void pr();
   void cookdinfl(std::vector<double>& cdinfl, double* sigma); //Cook's distance
   void kldivinfl(std::vector<double>& klinfl, double* sigma); //KL-divergence based influence metric
   void cpoinfl(std::vector<double>& cpoinfl, double* sigma); //CPO^-1 based influence metric

   //--------------------
   //data
   //--------------------------------------------------
   //stuff that maybe should be protected
protected:
   //--------------------
   //model information
   cinfo ci; //conditioning info (e.g. other parameters and prior and end node models)
   //--------------------
   //data
   //--------------------
   //mcmc info
   //--------------------
   //methods
};


#endif

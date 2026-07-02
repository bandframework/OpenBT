//     tnorm.h: Truncated Normal helper functions for probit model.


// Draw from the truncated Normal distribution with left,right truncation points
// given by (lwr,upr).
// Based on https://people.sc.fsu.edu/~jburkardt/cpp_src/truncated_normal/truncated_normal.html
double gen_trunc_normal(double mu,double sig,double lwr, double upr,rn &gen);

// lwr is -Inf
double gen_left_trunc_normal(double mu,double sig,double upr,rn &gen);

// upr is +Inf
double gen_right_trunc_normal(double mu,double sig,double lwr,rn &gen);

// CDF of N(0,1) at x.
double normal_01_cdf(double x);

// inverse of N(0,1) CDF at p.
double normal_01_cdf_inv (double p);

// helper function
double r8_huge(void);

// helper function -- evaluate polynomial using Horner's method.
double r8poly_value_horner (int m,double c[],double x);
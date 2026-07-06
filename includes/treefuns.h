//     treefuns.h: BT tree class helper functions header.

#ifndef GUARD_treefuns_h
#define GUARD_treefuns_h

#include <iostream>
#include "tree.h"

//--------------------------------------------------
//make xinfo which has nc cutpoints uniform on [0,1] for each x variable.
// this is in brt: void makexinfo(size_t p, size_t n, double *x, xinfo& xi, size_t nc)
void makeUnifXinfo(size_t p,size_t nc,xinfo& xi);
//--------------------------------------------------
//write cutpoint information to screen
void prxi(xinfo& xi);
//--------------------------------------------------
//evaluate tree tr on grid xgrid, write to os
void grm(tree& tr, xinfo& xgrid, std::ostream& os);
//--------------------------------------------------
//fit tree at matrix of x, matrix is stacked columns x[i,j] is *(x+p*i+j)
void fit(tree& t, xinfo& xi, size_t p, size_t n, double *x,  double* fv);
//--------------------------------------------------
//does a (bottom) node have variables you can split on?
bool cansplit(tree::tree_p n, xinfo& xi);
//--------------------------------------------------
//find variables n can split on, put their indices in goodvars
void getgoodvars(tree::tree_p n, xinfo& xi,  std::vector<size_t>& goodvars);
//--------------------------------------------------
// Get the L,U values for a node in the tree *given* the tree
// structure both above and below that node.
void getLU(tree::tree_p node, xinfo& xi, int* L, int* U);
//--------------------------------------------------
// Get the L,U values for a node in the tree *given* the tree
// structure both above and below that node.
void getvarLU(tree::tree_p node, size_t var, xinfo& xi, int* L, int* U);

//--------------------------------------------------
// These ones support the rotate code, but could be generally useful too.
//--------------------------------------------------
// Does the tree split on variable v at cutpoint c?
bool hasvcsplit(tree::tree_p t, size_t v, size_t c);
//--------------------------------------------------
// Does the node split on variable v?
bool splitsonv(tree::tree_p t, size_t v);
//--------------------------------------------------
// Do both nodes split on variable v?
bool splitsonv(tree::tree_p nl, tree::tree_p nr, size_t v);
//--------------------------------------------------
// Is this a leaf node?
bool isleaf(tree::tree_p t);
//--------------------------------------------------
// Are these two nodes equal?
bool arenodesequal(tree::tree_p nl, tree::tree_p nr);
//--------------------------------------------------
// Are these two nodes leaf nodes?
bool arenodesleafs(tree::tree_p nl, tree::tree_p nr);
//--------------------------------------------------
// number of available cutpoints at node n for variable var
int getnumcuts(tree::tree_p n, xinfo& xi, size_t var);
//--------------------------------------------------
// Find number of variables internal tree node n can split on
void getinternalvars(tree::tree_p n, xinfo& xi,  std::vector<size_t>& goodvars);
//--------------------------------------------------
// End of rotate helper functions
//--------------------------------------------------

//--------------------------------------------------
// Vector Parameter/Model Mixing Functions
//--------------------------------------------------
//evaluate tree tr on grid xgrid, write to os
void grm_vec(tree& tr, xinfo& xgrid, std::ostream& os);

//fit tree at matrix of x, matrix is stacked columns x[i,j] is *(x+p*i+j) -- used for model mixing 
void mix(tree& t, xinfo& xi, size_t p, size_t n, double *x,  double* fv);


#endif

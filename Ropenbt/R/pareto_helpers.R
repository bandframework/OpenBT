##     pareto_helpers.R: R functions for manipulating output of OpenBT's mopareto() model.


# For cpf, find y_j at each y_i cutpoint for all i=1:d, where j = (not i). 
# This really only works for d=2. 
# 
# Args: cpf: (d)x(??) matrix CPF realization.
# 
# Returns: (dq)-tuple of y_j values, where j = (not i). 
GetIntersectVals = function(cpf, my.cuts, d=2)
{
  
  GetIntersectValsFori = function(i) {
    # Returns: q-tuple of y_j values, where j = (not i). 
    yi.vals = my.cuts[, i]
    not.i = ifelse(i == 1, 2, 1)
    sapply(yi.vals, function(yi) min(cpf[not.i, cpf[i, ] <= yi], na.rm = TRUE))
  }
  
  unlist(lapply(1:d, GetIntersectValsFori))
}



# Compute Modified Band data depth based UQ region
calcMBD = function(fit, d=2)
{
  if(class(fit)!="OpenBT_mopareto") stop("fit object not recognized, should be type OpenBT_mopareto.\n")

  cp.theta = lapply(fit, `[[`,"theta")
  nd = length(fit)

  ## 1. Create cuts
  n.cuts = 2^6  # also called q
  cp.theta.cbind = Reduce(cbind, cp.theta)
  my.cuts = sapply(1:d, function(i) seq(min(cp.theta.cbind[i, ]), 
  				   max(cp.theta.cbind[i, ]), length.out = n.cuts))  # (q x d) matrix
  
  ## 2. Create (dq)x(nd) matrix M
  mat.M = sapply(cp.theta, GetIntersectVals, my.cuts)
  
  ## 3. Create (2q)x(nd) matrix R
  mat.R.max = t(apply(mat.M, 1, rank, ties.method = "max"))  
  mat.R.min = t(apply(mat.M, 1, rank, ties.method = "min"))  
  
  ## 4. Create (unnormalized) T matrix 
  # If l (r) = # strictly to left (right) and m is multiplicity,  
  # then the correct unnormalized depth is (l+m)(r+m)-m^2. 
  # No ties implies mat.R.max equals mat.R.min. 
  mat.T = mat.R.max * (nd - mat.R.min + 1) - (mat.R.max - mat.R.min + 1)^2
  mat.T = mat.T / choose(nd, 2)
  
  ## 5. Compute modified depth of each Pareto front. 
  depth.mod = colMeans(mat.T, na.rm=TRUE)
  
  ## 6. Compute UQ region
  uq.cols = (rank(-depth.mod) <= (0.5 * nd))
  pf.uq.mbd = Reduce(cbind, lapply(which(uq.cols), function(i) cp.theta[[i]]))

  # 7. Compute PS
  cp.uq.a.cbind = Reduce(cbind, lapply(which(uq.cols), function(i) fit[[i]]$a))  # Use fit here
  cp.uq.b.cbind = Reduce(cbind, lapply(which(uq.cols), function(i) fit[[i]]$b))  # Use fit here
  
  return(list(depth.mbd=depth.mod,pf.uq.mbd=pf.uq.mbd,cp.uq.a=cp.uq.a.cbind,cp.uq.b=cp.uq.b.cbind))
}



# Compute Vorobev Random Sets based PF UQ region
calcRS = function(fit, d=2)
{
  if(class(fit)!="OpenBT_mopareto") stop("fit object not recognized, should be type OpenBT_mopareto.\n")

  cp.theta = lapply(fit, `[[`,"theta")
  nd = length(fit)

  # 2. if R is unknown then find the extremal values for the
  # objectives over the RNP sets realizations
  cp.theta.cbind = Reduce(cbind, cp.theta)
  
  ref.max = apply(cp.theta.cbind, 1, max)
  ref.min = apply(cp.theta.cbind, 1, min)
  ref.vol = Reduce(`*`, ref.max - ref.min)
  
  # 4. Determine the average volume of the attained sets
  FindVol = function(pt.set) {
    # Find hypervolume of pt.set wrt ref.pt.
    emoa::hypervolume_indicator(points = as.matrix(pt.set, nrow=d),
                                o = as.matrix(ref.max, nrow=d)) * -1
  }
  vols.cpfs = sapply(cp.theta, FindVol)
  avg.vol = mean(vols.cpfs)
  
  # 5. Find the value of the Vorob'ev threshold β∗ by dichotomy:
  WhichCPFsDomPt = function(z) {
    DoesCPFDomPt = function(cpt, z) {
      dom.by.dim = lapply(1:d, function(i) cpt[i, ] <= z[i])
      Reduce(`|`, Reduce(`&`, dom.by.dim))
    }
    sapply(cp.theta, DoesCPFDomPt, z=z)
  }
  
  pf.att = apply(cp.theta.cbind, 2, WhichCPFsDomPt)  # nd by n.pts matrix
  pf.att = colMeans(pf.att)  # n.pts-tuple
  
  # This region is defined by its nondominated point set.
  uq.cols = (0.25 <= pf.att) & (pf.att <= 0.75)
  pf.uq.rs = cp.theta.cbind[, uq.cols]
  
  # Compute UQ region for PS and its accuracy ##############################
  cp.a.cbind = Reduce(cbind, lapply(fit, `[[`, "a")) # Use fit here
  cp.b.cbind = Reduce(cbind, lapply(fit, `[[`, "b")) # Use fit here
  cp.uq.a.cbind = cp.a.cbind[, uq.cols]
  cp.uq.b.cbind = cp.b.cbind[, uq.cols]
   
  return(list(pf.uq=pf.uq.rs,cp.uq.a=cp.uq.a.cbind,cp.uq.b=cp.uq.b.cbind)) 
}

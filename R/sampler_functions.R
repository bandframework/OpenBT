#-----------------------------------------------------
# Samplers
#-----------------------------------------------------
# Gumbel sampling for categorical variables
rgumbel = function(n){
  u = runif(n,0,1)  
  rgum = -log(-log(u))
  return(rgum)
}

# Sample categorical variable with softmax pmf
rsoftmax = function(k,pvec,c=0,logprob = TRUE){
  # Draw gumbels 
  g = rgumbel(k)
  
  # define gamma
  if(logprob){
    # pvec = log unnormalized probability (already removes exp(..) with the log)
    gam = pvec + c
  }else{
    # pvec is unnormalized prob (usually includes the exponetial from the numerator) 
    gam = log(pvec) + c  
  }
  
  # Draw categories
  out = which.max(gam+g)
  return(out)
}

# Multivariate normal
rmvn = function(mvec, V){
  # Spectral decomposition to get V^1/2
  E = eigen(V)
  Ev = E$vectors
  Eval = E$values
  S = Ev%*%diag(sqrt(Eval))
  
  # Generate std normal
  N = nrow(V)
  z = rnorm(N, 0, 1)
  
  # Get the MVN random variable
  out = mvec + S%*%z
  return(out)
}


# Scaled Inverse Chi-squared
rscinvchi2 = function(n,v,lam){
  # Use inv-gamma identity (invg scale = gamma rate)
  out = 1/rgamma(n,shape=v/2,rate=v*lam/2)
  return(out)
}

# Scaled Inverse Chi-squared
rtscaled = function(n,df,mean,scale){
  # Use inv-gamma identity (invg scale = gamma rate)
  out = mean + sd*rt(n,df)
  return(out)
}

#-----------------------------------------------------
# Samplers Helpers in MCMC
#-----------------------------------------------------
# Log metropolis hastings
# nprop: proposal of c -> n
# cprop: proposal of n -> c
logmh = function(log_nden, log_nprop, ntheta, log_cprop, log_cden, ctheta){
  # Acceptance ratio
  a = log_nden - log_cden + log_cprop - log_nprop
  a = min(0,a)
  u = runif(0,1)
  
  # Accept/reject
  if(log(u)< a){
    accept = TRUE
    theta = ctheta
  }else{
    accept = FALSE
    theta = ntheta
  }
  out = list(theta = theta, accept = accept)
  return(out)
}

#-----------------------------------------------------
# Designs
#-----------------------------------------------------
# Grid 2-D Design Sampler 
# nc = number columns, nr = number rows, n = total points
# xmin, xmax = 2-d vector of min/max values for each dimension
grid_2d_design = function(n1,n2, xmin = c(-1,-1), xmax = c(1,1)){
  # Generate n uniform rvs
  n = n1*n2
  ux = runif(n,0,1)
  uy = runif(n,0,1)
  
  # Dimensions for each rectangle
  x1_len = (xmax[1] - xmin[1])/n1
  x2_len = (xmax[2] - xmin[2])/n2
  xgrid = expand.grid(1:n1,1:n2)
  
  # Get points
  x1 = ux*x1_len + x1_len*(xgrid[,1]-1) + xmin[1]
  x2 = uy*x2_len + x2_len*(xgrid[,2]-1) + xmin[2]
  
  # Join data
  xdata = cbind(x1,x2)
  return(xdata)
}

# Generate test grid around a given set of points
# d = length of square side, nbd = number of points in the neighborhood
grid_2d_testset = function(x_train, d = 1, nbd = 5){
  x_test = matrix(0, ncol = 2, nrow = nrow(x_train)*nbd)
  for(i in 1:nrow(x_train)){
    dx = d*runif(nbd,-0.5,0.5)
    dy = d*runif(nbd,-0.5,0.5)
    start = (i-1)*nbd + 1
    end = i*nbd
    x_test[start:end, ] = cbind(x_train[i,1]+dx,x_train[i,2]+dy)    
  }
  return(x_test)
}


# Max distance design over Prod [ad,bd] for d = 1,...,p 
# N = the discretized set of Prod [ad,bd]
# n = number of samples 
# m = number of samples to generate and test
# xgrid = list of unique points per dimension
max_distance_design = function(alist, blist, N, n, m, xgrid = NULL){
  # Generate points within [0,1]
  p = length(alist)
  if(is.null(xgrid)){
    xu = seq(0,1,length = N)
  }else{
    xu = list()
    for(j in 1:p){
      xu[[j]] = (xgrid[[j]]-alist[j])/(blist[j] - alist[j])      
    }
    
  }

  # Randomly sample new training set from xu
  for(i in 1:m){
    if(is.null(xgrid)){
      xset = matrix(sample(xu,size = n*p),byrow = TRUE, nrow = n, ncol = p)  
    }else{
      xset = matrix(0, ncol = p, nrow = n)
      for(j in 1:p){
        xset[,j] = sample(xu[[j]],size = n, replace = TRUE)  
      }
    }
    
    distx = matrix(0,nrow = n, ncol = n)
    # Get l2 distance
    for(j in 1:p){
      distx = distx + outer(xset[,j], xset[,j], "-")^2
    }
    if(i == 1){
      dmin = sqrt(min(distx[upper.tri(distx,diag=FALSE)]))
      xout = xset
    }else{
      dmin_temp = sqrt(min(distx[upper.tri(distx,diag=FALSE)]))
      if(dmin_temp<dmin){
        dmin = dmin_temp
        xout = xset
      }
    }
  }
  
  # Scale the inputs of the winning design
  if(is.null(xgrid)){
    for(j in 1:p){
      xout[,j] = xout[,j]*(blist[1] - alist[1]) + alist[1] 
    }
  }
    
  return(xout)
}


max_distance_design_unif_grid = function(Nlist, n, m){
  # Generate points within [0,1]
  p = length(Nlist)
  xg = list()
  for(i in 1:p){
    xg[[i]] = seq(1,Nlist[[i]], by = 1)/Nlist[[i]]
  }
  
  # Randomly sample new training set from xu
  for(i in 1:m){
    xexp = expand.grid(xg)
    xset = xexp[sample(1:nrow(xexp), size = n, replace = FALSE),]
    
    distx = matrix(0,nrow = n, ncol = n)
    # Get l2 distance
    for(j in 1:p){
      distx = distx + outer(xset[,j], xset[,j], "-")^2
    }
    if(i == 1){
      dmin = sqrt(max(distx))
      #dmin = sqrt(max(distx[upper.tri(distx,diag=FALSE)]))
      xout = xset
    }else{
      dmin_temp = sqrt(max(distx)) #sqrt(max(distx[upper.tri(distx,diag=FALSE)]))
      if(dmin_temp<dmin){
        dmin = dmin_temp
        xout = xset
      }
    }
    cat("Min-Max Progress: ",round(i/m, 4),"\r")
  }
  
  for(j in 1:p){
    xout[,j] = xout[,j]*Nlist[[j]]
  }
  
  return(xout)
}


# MOVE TO EXAMPLE FILE
# MALA Log Proposal
#mala_logprop = function(){}

# Test
# rgumbel(5)
# smax = 0
# nd = 50000
# pvec = c(0.1,0.2,0.3,0.2,0.2)
# for(i in 1:nd){
#   smax[i] = rsoftmax(5,pvec)
# }
# table(smax)/nd
# 
# 
# smax = 0
# pvec = exp(-c(4,2,1,2.3,0.4))
# const = sum(pvec)
# for(i in 1:nd){
#   smax[i] = rsoftmax(5,pvec,c = 0)
# }
# table(smax)/nd
# pvec/const


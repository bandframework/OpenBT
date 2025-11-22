#------------------------------------------------
# Feature weighted linear stacking
# Frequentist version of model mixing
#------------------------------------------------

library(glmnet)
#------------------------------------------------
fwls = function(y_train, f_train, g_list, lambda){
  # Control
  n = nrow(f_train)
  K = ncol(f_train)
  
  # Get wts basis
  wts = define_wts_basis(f_train, g_list)
  A = wts$gf_matrix
  Bvec = wts$Bvec
  B = sum(Bvec)
  
  # Get design matrix
  M = (t(A)%*%A + diag(lambda,B))
  
  # Get minimizer
  Minv = chol2inv(chol(M))
  beta = Minv%*%t(A)%*%y_train
  fitted_values = A%*%beta
  sigma2 = sum((fitted_values - y_train)^2)/(n-B)  
  beta_cov = sigma2*Minv%*%t(A)%*%A%*%Minv
 
  # Return objects
  out = list(beta = beta, beta_cov = beta_cov, lambda = lambda, sigma2 = sigma2,
            fitted_values = fitted_values, Bvec = Bvec)
  return(out)
}


define_wts_basis = function(f, g_list){
  # Control
  K = ncol(f)
  n = nrow(f)
  gf_matrix = matrix(0,nrow = n, ncol = 0)
  Bvec = c()
  
  # Rescale features in g_list by function predictions
  # Each component of g_list is a design matrix in terms of x (n X B_j)
  for(j in 1:K){
    Bvec[j] = ncol(g_list[[j]])
    gf_new = g_list[[j]]*f[,j] # pointwise mult
    colnames(gf_new) = paste0("gf",1:Bvec[j])
    gf_matrix = cbind(gf_matrix,gf_new)
  }
  out = list(gf_matrix = gf_matrix, Bvec = Bvec)
  return(out)
}


fwls_predict_mean = function(fit,f_test,gtest_list){
  # Control
  n = nrow(f_test)
  K = ncol(f_test)
  if(!("beta" %in% names(fit))){stop("Error, fit must be output of fwls(...)")}
  
  # Get wts basis and mean prediction
  wts = define_wts_basis(f_test, gtest_list)
  A = wts$gf_matrix
  beta = fit$beta
  wx_matrix = matrix(0, nrow = n, ncol = 0)
  bind = 0
  for(j in 1:K){
    b0 = bind + 1
    b1 = fit$Bvec[j] + bind
    bind = b1-b0 + 1 + bind
    
    betaj = fit$beta[b0:b1]
    w = gtest_list[[j]]%*%betaj
    wx_matrix = cbind(wx_matrix,w)
  }
  colnames(wx_matrix) = paste0("w",1:K)
  
  # Get mean prediction of f
  fx_values = rowSums(f_test*wx_matrix)
  
  out = list(fx = fx_values, wx = wx_matrix)
  return(out)
}


fwls_predict = function(fit,f_test,gtest_list,alpha = 0.05, return_cov = FALSE){
  # Control
  n = nrow(f_test)
  K = ncol(f_test)
  if(!("beta" %in% names(fit))){stop("Error, fit must be output of fwls(...)")}
  
  # Get wts basis
  wts = define_wts_basis(f_test, gtest_list)
  A = wts$gf_matrix
  beta = fit$beta
  fx_values = A%*%beta
  fx_cov = A%*%fit$beta_cov%*%t(A)
  
  # Get wts and uncertainty
  bind = 0
  wx_matrix = matrix(0, nrow = n, ncol = 0)
  wx_cov = list()
  for(j in 1:K){
    b0 = bind + 1
    b1 = fit$Bvec[j] + bind
    bind = b1-b0 + 1 + bind
    
    betaj = fit$beta[b0:b1]
    w = gtest_list[[j]]%*%betaj
    wx_matrix = cbind(wx_matrix,w)
    
    beta_covj = fit$beta_cov[b0:b1,b0:b1]
    wx_cov[[j]] = gtest_list[[j]]%*%beta_covj%*%t(gtest_list[[j]])
  }
  
  wx_matrix = as.matrix(wx_matrix)
  wx_cov = as.matrix(wx_cov)
  colnames(wx_matrix) = paste0("w",1:K)
  names(wx_cov) = paste0("w",1:K)
  
  # Get pointwise intervals
  z = qnorm(1-alpha/2)
  fx_lb = fx_values - z*diag(fx_cov)
  fx_ub = fx_values + z*diag(fx_cov)
  wx_lb = wx_ub = matrix(0,nrow = n, ncol = K)
  for(j in 1:K){
    wx_lb[,j] = wx_matrix[,j] - z*diag(wx_cov[[j]])
    wx_ub[,j] = wx_matrix[,j] + z*diag(wx_cov[[j]])
  }
  
  if(return_cov){
    out = list(fx = fx_values, wx = wx_matrix, fx_cov = fx_cov, wx_cov = wx_cov,
               fx_lb = fx_lb, fx_ub = fx_ub, wx_lb = wx_lb, wx_ub = wx_ub)
  }else{
    out = list(fx = fx_values, wx = wx_matrix,
               fx_lb = fx_lb, fx_ub = fx_ub, wx_lb = wx_lb, wx_ub = wx_ub)
  }
  return(out)
}


fwls_construct_basis = function(x,K,basis = "linear"){
  if(length(basis)==1){
    basis = rep(basis,K)  
  }
  g_list = list()
  for(j in 1:K){
    basisj = basis[j]
    if(basisj == "constant"){
      xt = data.frame(x^0)
    }else if(basisj == "linear"){
      xt = data.frame(x)
    }else if(basisj == "quad"){
      xt = data.frame(x,x^2)
    }else if(basisj == "cubic"){
      xt = data.frame(x,x^2,x^3)
    }else if(basisj == "sine"){
      xt = data.frame(sin(x))
    }else if(basisj == "cosine"){
      xt = data.frame(cos(x))
    }else{
      stop("add more optiions...")
    }
    g_list[[j]] = model.matrix(~as.matrix(xt))  
  }  
  return(g_list)
}

fwls_cv = function(y_train, f_train, g_list, lambda_seq){
    # Control
    n = nrow(f_train)
    K = ncol(f_train)
    
    # Get wts basis
    wts = define_wts_basis(f_train, g_list)
    A = wts$gf_matrix
    Bvec = wts$Bvec
    B = sum(Bvec)
    
    # Cross validation fit
    fitcv = cv.glmnet(A, y_train, alpha = 0, lambda = lambda_seq)
    lam0 = fitcv$lambda.1se

    out = fwls(y_train,f_train,g_list,lam0)    
    return(out)
}

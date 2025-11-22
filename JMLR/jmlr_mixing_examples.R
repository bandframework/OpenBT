#------------------------------------------------
# 2D Taylor Feature weighted linear stacking
# Frequentist version of model mixing
#------------------------------------------------
openbt_path = "/home/jcyannotty/OpenBT" # CHANGE PATH TO REPO LOCATION
setwd(paste0(openbt_path,"/src"))

# Load the R wrapper functions to the OpenBT library.
paste0(openbt_path,"/src/openbt.R")
paste0(openbt_path,"/src/openbt_mixing.R")
paste0(openbt_path,"/R/polynomials.R")
paste0(openbt_path,"/R/computer_expt_plots.R")
paste0(openbt_path,"/R/sampler_functions.R")
paste0(openbt_path,"/R/fwls.R")

library(plotly)
library(viridis)
library(latex2exp)

#-----------------------------------------------------
#-----------------------------------------------------
rmse_bart_bmm = c()
rmse_rpbart_bmm = c()
Nruns = 1
for(i in 1:Nruns){
  set.seed(1 + i) # 2 was the original fit
  n_train = 80 
  n_test = 25
  xoff = 0.10
  xmin = -pi
  xmax = pi
  s = 0.1

  # Generate data
  x_train = grid_2d_design(n1=10,n2=8, xmin = c(xmin,xmin), xmax = c(xmax,xmax))
  #x_train = grid_2d_design(n1=25,n2=20, xmin = c(xmin,xmin), xmax = c(xmax,xmax))
  xt_min = apply(x_train,2,min);  xt_max = apply(x_train,2,max); 
  x1_test = round(seq(xt_min[1]-0.1,xt_max[1]+0.1,length = n_test),4)
  x2_test = round(seq(xt_min[1]-0.1,xt_max[1]+0.1,length = n_test),4)
  x_test = expand.grid(x1_test,x2_test)

  # Generate True function
  f0_train = sin(x_train[,1]) + cos(x_train[,2])
  f0_test = sin(x_test[,1]) + cos(x_test[,2])

  set.seed(98 + i) # 99
  y_train = f0_train + rnorm(n_train,0,s)

  ks1 = 7
  kc1 = 10 #6
  ks2 = 13 #9
  kc2 = 6

  h1_sinexp = sapply(x_train[,1],function(x) sin_exp(k=ks1,x0=pi,x))
  h1_cosexp = sapply(x_train[,2],function(x) cos_exp(k=kc1,x0=pi,x))
  h1_train = h1_sinexp + h1_cosexp
  h1_test = sapply(x_test[,1],function(x) sin_exp(k=ks1,x0=pi,x)) + sapply(x_test[,2],function(x) cos_exp(k=kc1,x0=pi,x))

  h2_sinexp = sapply(x_train[,1],function(x) sin_exp(k=ks2,x0=-pi,x))
  h2_cosexp = sapply(x_train[,2],function(x) cos_exp(k=kc2,x0=-pi,x))
  h2_train = h2_sinexp + h2_cosexp
  h2_test = sapply(x_test[,1],function(x) sin_exp(k=ks2,x0=-pi,x)) + sapply(x_test[,2],function(x) cos_exp(k=kc2,x0=-pi,x))

  f_train = cbind(h1_train, h2_train)
  f_test = cbind(h1_test, h2_test)


  #-----------------------------------------------------
  # Model Training 
  #-----------------------------------------------------
  nu = 40
  rho = 1
  sig2_hat = max(apply(apply(f_train, 2, function(x) (x-y_train)^2),2,min))
  lam = rho*sig2_hat*(nu+2)/nu
  q0 = 4

  fit=openbt(x_train,y_train,f_train,pbd=c(1.0,0),ntree = 10,ntreeh=1,numcut=300,tc=2,model="mixbart",modelname="physics_model",
            ndpost = 10000, nskip = 2000, nadapt = 4000, adaptevery = 500, printevery = 500,
            power = 1.0, base = 0.95, minnumbot = 3, overallsd = sqrt(sig2_hat), k = 1.2, overallnu = nu,
            summarystats = FALSE, selectp = FALSE, rpath = TRUE, q = 4.0, rshp1 = 2, rshp2 = 10,
            stepwpert = 0.1, probchv = 0.1)


  #Get mixed mean function
  fitp=predict.openbt(fit,x.test = x_test, f.test = f_test,tc=4, q.lower = 0.025, q.upper = 0.975)

  rmse_rpbart_bmm[i] = sqrt(mean((fitp$mmean - f0_test)^2))
  
  fit_bart_bmm = openbt(x_train,y_train,f_train,pbd=c(1.0,0),ntree = 10,ntreeh=1,numcut=300,tc=2,model="mixbart",modelname="physics_model",
             ndpost = 10000, nskip = 2000, nadapt = 4000, adaptevery = 500, printevery = 500,
             power = 1.0, base = 0.95, minnumbot = 3, overallsd = sqrt(sig2_hat), k = 1.2, overallnu = nu,
             summarystats = FALSE, selectp = FALSE, rpath = FALSE, q = 4.0, rshp1 = 2, rshp2 = 10,
             stepwpert = 0.1, probchv = 0.1)
  
  
  #Get mixed mean function
  fitp_bart_bmm = predict.openbt(fit_bart_bmm,x.test = x_test, 
                                 f.test = f_test,tc=4, 
                                 q.lower = 0.025, q.upper = 0.975)
  rmse_bart_bmm[i] = sqrt(mean((fitp$mmean - f0_test)^2))
  
    # Save the first fit
  if(i == 1)
  {    
    fit_data_rpbart_bmm = list(
      pred_mean = fitp$mmean,
      pred_ub = fitp$m.upper,
      pred_lb = fitp$m.lower
    )

    fit_data_bart_bmm = list(
      pred_mean = fitp_bart_bmm$mmean,
      pred_ub = fitp_bart_bmm$m.upper,
      pred_lb = fitp_bart_bmm$m.lower    
    )
    ms = list(
        x_train = x_train,
        f_train = f_train,
        y_train = y_train,
        x_test = x_test,
        f_test = f_test,
        f0_test = f0_test
    )
  }
}

#------------------------------------------------
# Fit the model - Linear bases
#------------------------------------------------
basis = c("linear","linear")
K = ncol(ms$f_train)
g_train = fwls_construct_basis(ms$x_train, K, basis)
g_test = fwls_construct_basis(ms$x_test, K, basis)

fit_fwls_lin = fwls_cv(ms$y_train, ms$f_train, g_train, lambda = seq(0.1,20,by = 0.1))
fitp_fwls_lin = fwls_predict(fit_fwls_lin,ms$f_test,g_test)


#------------------------------------------------
# Fit the model - Cubic bases
#------------------------------------------------
basis = c("cubic","cubic")
K = ncol(ms$f_train)
g_train = fwls_construct_basis(ms$x_train, K, basis)
g_test = fwls_construct_basis(ms$x_test, K, basis)

fit_fwls_cube = fwls_cv(ms$y_train, ms$f_train, g_train, lambda = seq(0.1,20,by = 0.1))
fitp_fwls_cube = fwls_predict(fit_fwls_cube,ms$f_test,g_test)


scmin = -2.8; scmax = 2.15
scmid  = mean(c(scmax,scmin))
scbrk1 = mean(c(scmid,scmin))
scbrk2 = mean(c(scmid,scmax))

fwls_lin_trunc = ifelse(fitp_fwls_lin$fx > scmax, scmax, fitp_fwls_lin$fx)
fwls_lin_trunc = ifelse(fwls_lin_trunc < scmin, scmin, fwls_lin_trunc)

fwls_cube_trunc = ifelse(fitp_fwls_cube$fx > scmax, scmax, fitp_fwls_cube$fx)
fwls_cube_trunc = ifelse(fwls_cube_trunc < scmin, scmin, fwls_cube_trunc)

pdagger = plot_mean2d_viridis(ms$x_test,ms$f0_test,xcols = c(1,2),viridis_opt = "turbo",
                              title="True System", scale_limits = c(scmin,scmax))
p1 = plot_mean2d_viridis(ms$x_test,fit_data_rpbart_bmm$pred_mean,xcols = c(1,2),viridis_opt = "turbo",
                         title="RPBART-BMM", scale_limits = c(scmin,scmax))
p2 = plot_mean2d_viridis(ms$x_test,fit_data_bart_bmm$pred_mean,xcols = c(1,2),viridis_opt = "turbo",
                         title="BART-BMM", scale_limits = c(scmin,scmax))
p3 = plot_mean2d_viridis(ms$x_test,fwls_lin_trunc,xcols = c(1,2),viridis_opt = "turbo",
                         title="FWLS-Linear", scale_limits = c(scmin,scmax))
p4 = plot_mean2d_viridis(ms$x_test,fwls_cube_trunc,xcols = c(1,2),viridis_opt = "turbo",
                         title="FWLS-Cubic", scale_limits = c(scmin,scmax))


p_leg = g_legend(p1+theme(legend.position = "bottom", legend.key.size = unit(0.65,'cm'),
                          legend.key.width = unit(2.2,'cm'), legend.title = element_blank())+
                   labs(fill=TeX("$f_\\dagger(x)$"))) 

pdagger = pdagger + labs(x = bquote(x[1]), y = bquote(x[2]))
pdagger = pdagger + theme(plot.title = element_text(size = 16), axis.title = element_text(size = 17),
                          axis.text = element_text(size = 16)) 
pdagger = pdagger + theme(plot.title = element_text(size = 13)) + 
  scale_fill_viridis(breaks = c(scmin,scbrk1,scmid,scbrk2,scmax),
                     labels = c(paste0("< ",scmin),paste(scbrk1),paste(scmid)
                                ,paste(scbrk2),paste0("> ",scmax)),
                     limits = c(scmin,scmax), option = "turbo")
p_leg = g_legend(pdagger+theme(legend.position = "bottom", legend.key.size = unit(0.8,'cm'),
                               legend.key.width = unit(2.4,'cm'), legend.title = element_text(size=16),
                               legend.text = element_text(size = 14))+
                   labs(fill="f(x)\n  ")) 


p1 = p1 + labs(x = bquote(x[1]), y = bquote(x[2]))
p1 = p1 + theme(plot.title = element_text(size = 16), axis.title = element_text(size = 17),
                axis.text = element_text(size = 16)) 

p2 = p2 + labs(x = bquote(x[1]), y = bquote(x[2]))
p2 = p2 + theme(plot.title = element_text(size = 16), axis.title = element_text(size = 17),
                axis.text = element_text(size = 16)) 

p3 = p3 + labs(x = bquote(x[1]), y = bquote(x[2]))
p3 = p3 + theme(plot.title = element_text(size = 16), axis.title = element_text(size = 17),
                axis.text = element_text(size = 16)) 

p4 = p4 + labs(x = bquote(x[1]), y = bquote(x[2]))
p4 = p4 + theme(plot.title = element_text(size = 16), axis.title = element_text(size = 17),
                axis.text = element_text(size = 16)) 


grid.arrange(arrangeGrob(pdagger+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title.x = element_blank()),
                         p1+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title = element_blank()),
                         p2+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title = element_blank()),
                         p3+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title.x = element_blank()),
                         p4+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title = element_blank()),
                         #p5+theme(legend.position = "none", legend.key.size = unit(1.0,'cm'), axis.title = element_blank()),
                         bottom = textGrob(TeX("$x_1$"), gp=gpar(fontsize=14)),
                         nrow = 2), nrow=2, heights = c(10,1),p_leg)


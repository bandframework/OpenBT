##     openbt.R: R script wrapper functions for OpenBT.


# Load/Install required packages
required <- c("zip","data.table","Hmisc")
tbi <- required[!(required %in% installed.packages()[,"Package"])]
if(length(tbi)) {
   cat("***Installing OpenBT package dependencies***\n")
   install.packages(tbi,repos="https://cloud.r-project.org",quiet=TRUE)
}
library(zip,quietly=TRUE,warn.conflicts=FALSE)
library(data.table,quietly=TRUE,warn.conflicts=FALSE)
library(Hmisc,quietly=TRUE,warn.conflicts=FALSE) #for weighted mean/var/quantile used in repredict.*()
# library(foreach,quietly=TRUE,warn.conflicts=FALSE) #only used in repredict.openbt() method to speedup R-based reweighting calculations
# library(doMC,quietly=TRUE,warn.conflicts=FALSE) #only used in repredict.openbt() method to speedup R-based reweighting calculations


openbt = function(
x.train,
y.train,
f.train = matrix(1,nrow = length(y.train), ncol = 2),
ntree=NULL,
ntreeh=NULL,
ndpost=1000, nskip=100,
k=NULL,
power=2.0, base=.95,
tc=2,
sigmav=rep(1,length(y.train)),
f.sd.train = NULL, # rename
wts.prior.info = NULL, # keep/rename
fmean=mean(y.train),
overallsd = NULL,
overallnu= NULL,
chv = cor(x.train,method="spearman"),
pbd=.7,
pb=.5,
stepwpert=.1,
probchv=.1,
minnumbot=5,
printevery=100,
numcut=100,
xicuts=NULL,
nadapt=1000,
adaptevery=100,
summarystats=FALSE,
truncateds=NULL,
model=NULL,
modelname="model"
)
{
#--------------------------------------------------
# model type definitions
modeltype=0 # undefined
MODEL_BT=1
MODEL_BINOMIAL=2
MODEL_POISSON=3
MODEL_BART=4
MODEL_HBART=5
MODEL_PROBIT=6
MODEL_MODIFIEDPROBIT=7
MODEL_MERCK_TRUNCATED=8
MODEL_MIXBART=9
if(is.null(model))
{ 
   cat("Model type not specified.\n")
   cat("Available options are:\n")
   cat("model='bt'\n")
   cat("model='binomial'\n")
   cat("model='poisson'\n")
   cat("model='bart'\n")
   cat("model='hbart'\n")
   cat("model='probit'\n")
   cat("model='modifiedprobit'\n")
   cat("model='merck_truncated'\n")
   cat("model='mixbart'\n")

   stop("missing model type.\n")
}
if(model=="bart")
{
   modeltype=MODEL_BART
   if(is.null(ntree)) ntree=200
   if(is.null(ntreeh)) ntreeh=1
   if(is.null(k)) k=2
   if(is.null(overallsd)) overallsd=sd(y.train)
   if(is.null(overallnu)) overallnu=10
   pbd=c(pbd,0.0)
}
if(model=="hbart")
{
   modeltype=MODEL_HBART
   if(is.null(ntree)) ntree=200
   if(is.null(ntreeh)) ntreeh=40
   if(is.null(k)) k=5
   if(is.null(overallsd)) overallsd=sd(y.train)
   if(is.null(overallnu)) overallnu=10
}

if(model=="probit")
{
   modeltype=MODEL_PROBIT
   if(is.null(ntree)) ntree=200
   if(is.null(ntreeh)) ntreeh=1
   if(is.null(k)) k=1
   if(is.null(overallsd)) overallsd=1
   if(is.null(overallnu)) overallnu=-1
   if(length(pbd)==1) pbd=c(pbd,0.0)
}
if(model=="modified-probit") 
{
   modeltype=MODEL_MODIFIEDPROBIT
   if(is.null(ntree)) ntree=200
   if(is.null(ntreeh)) ntreeh=40
   if(is.null(k)) k=1
   if(is.null(overallsd)) overallsd=1
   if(is.null(overallnu)) overallnu=-1
}
if(model=="merck_truncated")
{
   modeltype=MODEL_MERCK_TRUNCATED
   if(is.null(ntree)) ntree=200
   if(is.null(ntreeh)) ntreeh=1
   if(is.null(k)) k=2
   if(is.null(overallsd)) overallsd=sd(y.train)
   if(is.null(overallnu)) overallnu=10
   if(is.null(truncateds)) {
      miny=min(y.train)[1]
      truncateds=(y.train==miny)
   }
}
if(model=="mixbart")
{
  modeltype=MODEL_MIXBART
  if(is.null(ntree)) ntree=20
  if(is.null(ntreeh)) ntreeh=1
  if(is.null(k)) k=1
  if(is.null(overallsd)) overallsd=sd(y.train)
  if(is.null(overallnu)) overallnu=10
  pbd=c(pbd,0.0)
}
#--------------------------------------------------
nd = ndpost
burn = nskip
m = ntree
mh = ntreeh
#--------------------------------------------------
#data
if(!is.matrix(x.train)){x.train = matrix(x.train, ncol = 1)}
n = length(y.train)
p = ncol(x.train)
#np = nrow(x.test)
x = t(x.train)
#xp = t(x.test)
if(modeltype==MODEL_BART || modeltype==MODEL_HBART || modeltype==MODEL_MERCK_TRUNCATED)
{
   y.train=y.train-fmean
   fmean.out=paste(0.0)
}
if(modeltype==MODEL_PROBIT || modeltype==MODEL_MODIFIEDPROBIT)
{
   fmean.out=paste(qnorm(fmean))
   uniqy=sort(unique(y.train))
   if(length(uniqy)>2) stop("Invalid y.train: Probit requires dichotomous response coded 0/1")
   if(uniqy[1]!=0 || uniqy[2]!=1) stop("Invalid y.train: Probit requires dichotomous response coded 0/1")
}

#Set mix discrepancy to FALSE if we use a different model
nsprior = FALSE
wtsprior = FALSE
if(modeltype==MODEL_MIXBART)
{
  #Center the response
  fmean.out=paste(0.0) 
  
  #Check to see if any discrepancy data has been passed into the function -- if so, we will use the discrepancy model mixing
  if(!is.null(f.sd.train)){
    nsprior = TRUE    
  }
  if(!is.null(wts.prior.info)){
    wtsprior = TRUE
    if(ncol(wts.prior.info) != 2 | nrow(wts.prior.info)!=ncol(f.train)) stop("Invalid wts.prior.info: Required dimensions of num.models x 2")
  }
}
#--------------------------------------------------
#cutpoints
if(!is.null(xicuts)) # use xicuts
{
   xi=xicuts
}
else # default to equal numcut per dimension
{
   xi=vector("list",p)
   minx=floor(apply(x,1,min))
   maxx=ceiling(apply(x,1,max))
   for(i in 1:p)
   {
      xinc=(maxx[i]-minx[i])/(numcut+1)
      xi[[i]]=(1:numcut)*xinc+minx[i]
   }
}

if(is.null(xicuts) & modeltype==MODEL_MIXBART){
  xi=vector("list",p)
  minx_temp=apply(x,1,min)
  maxx_temp=apply(x,1,max)
  
  maxx = round(maxx_temp,1) + ifelse((round(maxx_temp,1)-maxx_temp)>0,0,0.1)
  minx = round(minx_temp,1) - ifelse((minx_temp - round(minx_temp,1))>0,0,0.1)
  for(i in 1:p)
  {
    xinc=(maxx[i]-minx[i])/(numcut+1)
    xi[[i]]=(1:numcut)*xinc+minx[i]
  }
}
#--------------------------------------------------
if(modeltype==MODEL_BART || modeltype==MODEL_HBART || modeltype==MODEL_MERCK_TRUNCATED || modeltype==MODEL_MIXBART)
{
   rgy = range(y.train)
}
if(modeltype==MODEL_PROBIT || modeltype==MODEL_MODIFIEDPROBIT)
{
   rgy = c(-2,2)
}

if(modeltype==MODEL_MIXBART){
  tau =  (1)/(2*sqrt(m)*k)
  beta0 = 1/(2*m)
  overallsd = sqrt((overallnu+2)*overallsd^2/overallnu)
}else{
  tau =  (rgy[2]-rgy[1])/(2*sqrt(m)*k)
  beta0=0
}

if(modeltype==MODEL_MIXBART & nsprior){
  #tau = 1/(sqrt(m)*k)
  #tau = 1/(2*sqrt(m)*k)
  tau = 1/(2*(m)*k)
  beta0 = 1/m
}  

#--------------------------------------------------
overalllambda = overallsd^2
#--------------------------------------------------
powerh=power
baseh=base
if(length(power)>1) {
   powerh=power[2]
   power=power[1]
}
if(length(base)>1) {
   baseh=base[2]
   base=base[1]
}
#--------------------------------------------------
pbdh=pbd
pbh=pb
if(length(pbd)>1) {
   pbdh=pbdh[2]
   pbd=pbd[1]
}
if(length(pb)>1) {
   pbh=pb[2]
   pb=pb[1]
}
#--------------------------------------------------
if(modeltype==MODEL_BART)
{
   cat("Model: Bayesian Additive Regression Trees model (BART)\n")
}
#--------------------------------------------------
if(modeltype==MODEL_HBART)
{
   cat("Model: Heteroscedastic Bayesian Additive Regression Trees model (HBART)\n")
}
#--------------------------------------------------
if(modeltype==MODEL_PROBIT)
{
   cat("Model: Dichotomous outcome model: Albert & Chib Probit (fixed)\n")
#   overallnu=-1
   if(ntreeh>1)
    stop("method probit requires ntreeh=1")
   if(pbdh>0.0)
    stop("method probit requires pbd[2]=0.0")
}
#--------------------------------------------------
if(modeltype==MODEL_MODIFIEDPROBIT)
{
   cat("Model: Dichotomous outcome model: Modified Albert & Chib Probit\n")
}
#--------------------------------------------------
if(modeltype==MODEL_MERCK_TRUNCATED)
{
   cat("Model: Truncated BART model\n")
}
#--------------------------------------------------
if(modeltype==MODEL_MIXBART)
{
  cat("Model: Model Mixing with Bayesian Additive Regression Trees\n")
}
#--------------------------------------------------
stepwperth=stepwpert
if(length(stepwpert)>1) {
   stepwperth=stepwpert[2]
   stepwpert=stepwpert[1]
}
#--------------------------------------------------
probchvh=probchv
if(length(probchv)>1) {
   probchvh=probchv[2]
   probchv=probchv[1]
}
#--------------------------------------------------
minnumboth=minnumbot
if(length(minnumbot)>1) {
   minnumboth=minnumbot[2]
   minnumbot=minnumbot[1]
}

#--------------------------------------------------
#write out config file
xroot="x"
yroot="y"
sroot="s"
chgvroot="chgv"
froot="f"
fsdroot="fsd"
wproot="wpr"
xiroot="xi"
folder=tempdir(check=TRUE)
if(!dir.exists(folder)) dir.create(folder)
tmpsubfolder=tempfile(tmpdir="")
tmpsubfolder=substr(tmpsubfolder,5,nchar(tmpsubfolder))
tmpsubfolder=paste("openbt",tmpsubfolder,sep="")
folder=paste(folder,"/",tmpsubfolder,sep="")
if(!dir.exists(folder)) dir.create(folder)
fout=file(paste(folder,"/config",sep=""),"w")
writeLines(c(paste(modeltype),xroot,yroot,fmean.out,paste(m),paste(mh),paste(nd),paste(burn),
            paste(nadapt),paste(adaptevery),paste(tau),paste(beta0),paste(overalllambda),
            paste(overallnu),paste(base),paste(power),paste(baseh),paste(powerh),
            paste(tc),paste(sroot),paste(chgvroot),paste(froot),paste(fsdroot),paste(nsprior),paste(wproot),paste(wtsprior), 
            paste(pbd),paste(pb),paste(pbdh),paste(pbh),paste(stepwpert),paste(stepwperth),
            paste(probchv),paste(probchvh),paste(minnumbot),paste(minnumboth),
            paste(printevery),paste(xiroot),paste(modelname),paste(summarystats)),fout)
close(fout)
# folder=paste(".",modelname,"/",sep="")
# system(paste("rm -rf ",folder,sep=""))
# system(paste("mkdir ",folder,sep=""))
# system(paste("cp config ",folder,"config",sep=""))


#--------------------------------------------------
#write out data subsets
nslv=tc-1
ylist=split(y.train,(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(ylist[[i]],file=paste(folder,"/",yroot,i,sep=""))
xlist=split(as.data.frame(x.train),(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(t(xlist[[i]]),file=paste(folder,"/",xroot,i,sep=""))
slist=split(sigmav,(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(slist[[i]],file=paste(folder,"/",sroot,i,sep=""))
chv[is.na(chv)]=0 # if a var as 0 levels it will have a cor of NA so we'll just set those to 0.
write(chv,file=paste(folder,"/",chgvroot,sep=""))
for(i in 1:p) write(xi[[i]],file=paste(folder,"/",xiroot,i,sep=""))
rm(chv)

#Write the function output if using model mixing
if(modeltype == MODEL_MIXBART){
  flist=split(as.data.frame(f.train),(seq(n)-1) %/% (n/nslv))
  for(i in 1:nslv) write(t(flist[[i]]),file=paste(folder,"/",froot,i,sep=""))
  
  if(nsprior){
    # -- delete these two lines
    #fdmlist=split(as.data.frame(f.discrep.mean),(seq(n)-1) %/% (n/nslv))
    #for(i in 1:nslv) write(t(fdmlist[[i]]),file=paste(folder,"/",fdmroot,i,sep=""))
    
    fdslist=split(as.data.frame(f.sd.train),(seq(n)-1) %/% (n/nslv))
    for(i in 1:nslv) write(t(fdslist[[i]]),file=paste(folder,"/",fsdroot,i,sep=""))
  }
  
  if(wtsprior){
    write(wts.prior.info,file=paste(folder,"/",wproot,sep=""))
  }
}

if(modeltype==MODEL_MERCK_TRUNCATED)
{
   tlist=split(truncateds,(seq(n)-1) %/% (n/nslv))
   for(i in 1:nslv) {
      truncs=which(tlist[[i]]==TRUE)-1 #-1 for correct indexing in c/c++
      ftrun=file(paste(folder,"/","truncs",i,sep=""),"w")
      write(truncs,ftrun)
      close(ftrun)
   }
}
#--------------------------------------------------
#run program
cmdopt=100 #default to serial/OpenMP
runlocal=FALSE
cmd="openbtcli --conf"
if(Sys.which("openbtcli")[[1]]=="") # not installed in a global location, so assume current directory
   runlocal=TRUE

if(runlocal && Sys.which("./openbtcli")[[1]]=="") # not installed globally, not installed locally.
   stop("OpenBT library installation is missing.  \n")

if(runlocal) cmd="./openbtcli --conf"

cmdopt=system(cmd)

if(cmdopt==101) # MPI
{
   cmd=paste("mpirun -np ",tc," openbtcli ",folder,sep="")
}

if(cmdopt==100)  # serial/OpenMP
{ 
   if(runlocal)
      cmd=paste("./openbtcli ",folder,sep="")
   else
      cmd=paste("openbtcli ",folder,sep="")
}
#
#cat(cmd)
system(cmd)
#system(paste("rm -f ",folder,"/config",sep=""))
#system(paste("mv ",folder,"fit ",folder,modelname,".fit",sep=""))

res=list()

# Read in the influence metrics.
res$influence=NULL
for(i in 1:nslv)
   res$influence=rbind(res$influence,as.matrix(read.table(paste(folder,"/",modelname,".influence",i,sep=""))))

colnames(res$influence)=c("MeanCookD", "MaxCookD", "KLDiv", "CPOinv")
res$modeltype=modeltype
res$model=model
res$xroot=xroot; res$yroot=yroot;res$m=m; res$mh=mh; res$nd=nd; res$burn=burn
res$nadapt=nadapt; res$adaptevery=adaptevery; res$tau=tau;res$beta0=beta0;res$overalllambda=overalllambda
res$overallnu=overallnu; res$k=k; res$base=base; res$power=power; res$baseh=baseh; res$powerh=powerh
res$tc=tc; res$sroot=sroot; res$chgvroot=chgvroot;res$froot=froot;res$fsdroot=fsdroot; 
res$nsprior = nsprior; res$pbd=pbd; res$pb=pb
res$pbdh=pbdh; res$pbh=pbh; res$stepwpert=stepwpert; res$stepwperth=stepwperth
res$probchv=probchv; res$probchvh=probchvh; res$minnumbot=minnumbot; res$minnumboth=minnumboth
res$printevery=printevery; res$xiroot=xiroot; res$minx=minx; res$maxx=maxx;
res$summarystats=summarystats; res$modelname=modelname
class(xi)="OpenBT_cutinfo"
res$xicuts=xi
res$fmean=fmean
res$folder=folder
class(res)="OpenBT_posterior"

return(res)
}




#--------------------------------------------------
#Get Predictions
#--------------------------------------------------


predict.openbt = function(
object=NULL,
x.test=NULL,
f.test=matrix(1,nrow = 1, ncol = 2),
# f.discrep.mean = NULL, # delete
# f.sd.test = NULL, # delete
tc=2,
fmean=fit$fmean,
q.lower=0.025,
q.upper=0.975, ...
)
{

fit=object

# model type definitions
MODEL_BT=1
MODEL_BINOMIAL=2
MODEL_POISSON=3
MODEL_BART=4
MODEL_HBART=5
MODEL_PROBIT=6
MODEL_MODIFIEDPROBIT=7
MODEL_MERCK_TRUNCATED=8
MODEL_MIXBART=9

#--------------------------------------------------
# params
if(is.null(fit)) stop("No fitted model specified!\n")
if(is.null(x.test)) stop("No prediction points specified!\n")

nslv=tc
x.test=as.matrix(x.test)
p=ncol(x.test)
n=nrow(x.test)
k=2 #Default number of models for model mixing
xproot="xp"
fproot="fp"
#fpdmroot="fpdm"
#fpdsroot="fpds"

if(fit$modeltype==MODEL_MIXBART){
  if(is.null(f.test)){stop("No function output specified for model mixing!\n")}
  k=ncol(f.test) #Number of models
  #if(fit$nsprior){stop("No function discrepancy mean and/or standard deviation was provided, but model was trained with functional discrepancy.") } 
}

if(fit$modeltype==MODEL_BART || fit$modeltype==MODEL_HBART || fit$modeltype==MODEL_MERCK_TRUNCATED)
{
   fmean.out=paste(fmean)
}
if(fit$modeltype==MODEL_PROBIT || fit$modeltype==MODEL_MODIFIEDPROBIT)
{
   fmean.out=paste(qnorm(fmean))
}
if(fit$modeltype==MODEL_MIXBART){
  fmean.out=paste(0.0)
}

#--------------------------------------------------
#write out config file
fout=file(paste(fit$folder,"/config.pred",sep=""),"w")
writeLines(c(fit$modelname,fit$modeltype,fit$xiroot,xproot,fproot,
            paste(fit$nd),paste(fit$m),
            paste(fit$mh),paste(p),paste(k),paste(tc),
            fmean.out), fout)
close(fout)

#--------------------------------------------------
#write out data subsets
#folder=paste(".",fit$modelname,"/",sep="")
xlist=split(as.data.frame(x.test),(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(t(xlist[[i]]),file=paste(fit$folder,"/",xproot,i-1,sep=""))
for(i in 1:p) write(fit$xicuts[[i]],file=paste(fit$folder,"/",fit$xiroot,i,sep=""))

if(fit$modeltype==MODEL_MIXBART){
  #for(i in 1:k) write(f.test[,i],file=paste(fit$folder,"/",fproot,i,sep=""))
  flist=split(as.data.frame(f.test),(seq(n)-1) %/% (n/nslv))
  for(i in 1:nslv) write(t(flist[[i]]),file=paste(fit$folder,"/",fproot,i-1,sep=""))
  
  if(fit$nsprior){
    #fdmlist=split(as.data.frame(f.discrep.mean),(seq(n)-1) %/% (n/nslv))
    #for(i in 1:nslv) write(t(fdmlist[[i]]),file=paste(fit$folder,"/",fpdmroot,i-1,sep=""))
    
    #fdslist=split(as.data.frame(f.sd.train),(seq(n)-1) %/% (n/nslv))
    #for(i in 1:nslv) write(t(fdslist[[i]]),file=paste(fit$folder,"/",fpdsroot,i-1,sep=""))
  }
}

#--------------------------------------------------
#run prediction program
cmdopt=100 #default to serial/OpenMP
runlocal=FALSE
cmd="openbtcli --conf"
if(Sys.which("openbtcli")[[1]]=="") # not installed in a global location, so assume current directory
   runlocal=TRUE

if(runlocal) cmd="./openbtcli --conf"

cmdopt=system(cmd)

if(cmdopt==101) # MPI
{
   cmd=paste("mpirun -np ",tc," openbtpred ",fit$folder,sep="")
}

if(cmdopt==100)  # serial/OpenMP
{ 
   if(runlocal)
      cmd=paste("./openbtpred ",fit$folder,sep="")
   else
      cmd=paste("openbtpred ",fit$folder,sep="")
}

#cmd=paste("mpirun -np ",tc," openbtpred",sep="")
#cat(cmd)
system(cmd)
system(paste("rm -f ",fit$folder,"/config.pred",sep=""))


#--------------------------------------------------
#format and return
res=list()

# Old, original code for reading in the posterior predictive draws.
# res$mdraws=read.table(paste(fit$folder,"/",fit$modelname,".mdraws",0,sep=""))
# res$sdraws=read.table(paste(fit$folder,"/",fit$modelname,".sdraws",0,sep=""))
# for(i in 2:nslv)
# {
#    res$mdraws=cbind(res$mdraws,read.table(paste(fit$folder,"/",fit$modelname,".mdraws",i-1,sep="")))
#    res$sdraws=cbind(res$sdraws,read.table(paste(fit$folder,"/",fit$modelname,".sdraws",i-1,sep="")))
# }
# res$mdraws=as.matrix(res$mdraws)
# res$sdraws=as.matrix(res$sdraws)

# Faster using data.table's fread than the built-in read.table.
# However, it does strangely introduce some small rounding error on the order of 8.9e-16.
fnames=list.files(fit$folder,pattern=paste(fit$modelname,".mdraws*",sep=""),full.names=TRUE)
res$mdraws=as.matrix(do.call(cbind,sapply(fnames,data.table::fread)))
fnames=list.files(fit$folder,pattern=paste(fit$modelname,".sdraws*",sep=""),full.names=TRUE)
res$sdraws=as.matrix(do.call(cbind,sapply(fnames,data.table::fread)))

system(paste("rm -f ",fit$folder,"/",fit$modelname,".mdraws*",sep=""))
system(paste("rm -f ",fit$folder,"/",fit$modelname,".sdraws*",sep=""))

#Get Results for models that are not model mixing
if(fit$modeltype!=MODEL_MIXBART){
  res$mmean=apply(res$mdraws,2,mean)
  res$smean=apply(res$sdraws,2,mean)
  res$msd=apply(res$mdraws,2,sd)
  res$ssd=apply(res$sdraws,2,sd)
  res$m.5=apply(res$mdraws,2,quantile,0.5)
  res$m.lower=apply(res$mdraws,2,quantile,q.lower)
  res$m.upper=apply(res$mdraws,2,quantile,q.upper)
  res$s.5=apply(res$sdraws,2,quantile,0.5)
  res$s.lower=apply(res$sdraws,2,quantile,q.lower)
  res$s.upper=apply(res$sdraws,2,quantile,q.upper)
  res$pdraws=NULL
  res$pmean=NULL
  res$psd=NULL
  res$p.5=NULL
  res$p.lower=NULL
  res$p.upper=NULL
}

#Get probabilities for the probit models
if(fit$modeltype==MODEL_PROBIT || fit$modeltype==MODEL_MODIFIEDPROBIT)
{
   res$pdraws=read.table(paste(fit$folder,"/",fit$modelname,".pdraws",0,sep=""))
   for(i in 2:nslv)
   {
      res$pdraws=cbind(res$pdraws,read.table(paste(fit$folder,"/",fit$modelname,".pdraws",i-1,sep="")))
   }

   system(paste("rm -f ",fit$folder,"/",fit$modelname,".pdraws*",sep=""))

   res$pdraws=as.matrix(res$pdraws)
   res$pmean=apply(res$pdraws,2,mean)
   res$psd=apply(res$pdraws,2,sd)
   res$p.5=apply(res$pdraws,2,quantile,0.5)
   res$p.lower=apply(res$pdraws,2,quantile,q.lower)
   res$p.upper=apply(res$pdraws,2,quantile,q.upper)
}

#Get model mixing results -- using only a constant variance -- change later to match with HBART
if(fit$modeltype==MODEL_MIXBART){
  res$mmean=apply(res$mdraws,2,mean)
  res$msd=apply(res$mdraws,2,sd)
  res$m.5=apply(res$mdraws,2,quantile,0.5)
  res$m.lower=apply(res$mdraws,2,quantile,q.lower)
  res$m.upper=apply(res$mdraws,2,quantile,q.upper)
  res$smean=apply(res$sdraws,2,mean)
  res$ssd=apply(res$sdraws,2,sd)
  res$s.5=apply(res$sdraws,2,quantile,0.5)
  res$s.lower=apply(res$sdraws,2,quantile,q.lower)
  res$s.upper=apply(res$sdraws,2,quantile,q.lower)
  res$pdraws=NULL
  res$pmean=NULL
  res$psd=NULL
  res$p.5=NULL
  res$p.lower=NULL
  res$p.upper=NULL  
}

res$q.lower=q.lower
res$q.upper=q.upper
res$x.test=x.test
res$modeltype=fit$modeltype

class(res)="OpenBT_predict"

return(res)
}


#--------------------------------------------------
#Get Variable activity 
#--------------------------------------------------

vartivity.openbt = function(
fit=NULL,
q.lower=0.025,
q.upper=0.975
)
{

#--------------------------------------------------
# params
if(is.null(fit)) stop("No fitted model specified!\n")
p=length(fit$xicuts)
m=fit$m
mh=fit$mh
nd=fit$nd
modelname=fit$modelname


#--------------------------------------------------
#write out config file
fout=file(paste(fit$folder,"/config.vartivity",sep=""),"w")
writeLines(c(fit$modelname,
            paste(nd),paste(m),
            paste(mh),paste(p)) ,fout)
close(fout)


#--------------------------------------------------
#run vartivity program  -- it's not actually parallel so no call to mpirun.
runlocal=FALSE
if(Sys.which("openbtcli")[[1]]=="") # not installed in a global locaiton, so assume current directory
   runlocal=TRUE

if(runlocal)
   cmd=paste("./openbtvartivity ",fit$folder,sep="")
else
   cmd=paste("openbtvartivity ",fit$folder,sep="")

#cmd=paste("./openbtvartivity",sep="")
system(cmd)
system(paste("rm -f ",fit$folder,"/config.vartivity",sep=""))


#--------------------------------------------------
#read in result
res=list()
res$vdraws=read.table(paste(fit$folder,"/",fit$modelname,".vdraws",sep=""))
res$vdrawsh=read.table(paste(fit$folder,"/",fit$modelname,".vdrawsh",sep=""))
res$vdraws=as.matrix(res$vdraws)
res$vdrawsh=as.matrix(res$vdrawsh)

# normalize counts
colnorm=apply(res$vdraws,1,sum)
ix=which(colnorm>0)
res$vdraws[ix,]=res$vdraws[ix,]/colnorm[ix]
colnorm=apply(res$vdrawsh,1,sum)
ix=which(colnorm>0)
res$vdrawsh[ix,]=res$vdrawsh[ix,]/colnorm[ix]

res$mvdraws=apply(res$vdraws,2,mean)
res$mvdrawsh=apply(res$vdrawsh,2,mean)
res$vdraws.sd=apply(res$vdraws,2,sd)
res$vdrawsh.sd=apply(res$vdrawsh,2,sd)
res$vdraws.5=apply(res$vdraws,2,quantile,0.5)
res$vdrawsh.5=apply(res$vdrawsh,2,quantile,0.5)
res$vdraws.lower=apply(res$vdraws,2,quantile,q.lower)
res$vdraws.upper=apply(res$vdraws,2,quantile,q.upper)
res$vdrawsh.lower=apply(res$vdrawsh,2,quantile,q.lower)
res$vdrawsh.upper=apply(res$vdrawsh,2,quantile,q.upper)
res$q.lower=q.lower
res$q.upper=q.upper
res$modeltype=fit$modeltype

class(res)="OpenBT_vartivity"

return(res)
}

#--------------------------------------------------
#Sobol function
#--------------------------------------------------

sobol.openbt = function(
fit=NULL,
q.lower=0.025,
q.upper=0.975,
tc=2
)
{

#--------------------------------------------------
# params
if(is.null(fit)) stop("No fitted model specified!\n")
p=length(fit$xicuts)
m=fit$m
mh=fit$mh
nd=fit$nd
modelname=fit$modelname


#--------------------------------------------------
#write out config file
fout=file(paste(fit$folder,"/config.sobol",sep=""),"w")
writeLines(c(fit$modelname,fit$xiroot,
            paste(nd),paste(m),
            paste(mh),paste(p),paste(fit$minx),
            paste(fit$maxx),paste(tc)) ,fout)
close(fout)


#--------------------------------------------------
#run Sobol program
cmdopt=100 #default to serial/OpenMP
runlocal=FALSE
cmd="openbtcli --conf"
if(Sys.which("openbtcli")[[1]]=="") # not installed in a global locaiton, so assume current directory
   runlocal=TRUE

if(runlocal) cmd="./openbtcli --conf"

cmdopt=system(cmd)

if(cmdopt==101) # MPI
{
   cmd=paste("mpirun -np ",tc," openbtsobol ",fit$folder,sep="")
}

if(cmdopt==100)  # serial/OpenMP
{ 
   if(runlocal)
      cmd=paste("./openbtsobol ",fit$folder,sep="")
   else
      cmd=paste("openbtsobol ",fit$folder,sep="")
}

system(cmd)
system(paste("rm -f ",fit$folder,"/config.sobol",sep=""))


#--------------------------------------------------
#read in result
res=list()
draws=read.table(paste(fit$folder,"/",fit$modelname,".sobol",0,sep=""))
for(i in 2:tc)
    draws=rbind(draws,read.table(paste(fit$folder,"/",fit$modelname,".sobol",i-1,sep="")))
draws=as.matrix(draws)

drawsh=read.table(paste(fit$folder,"/",fit$modelname,".shapley",0,sep=""))
for(i in 2:tc)
    drawsh=rbind(drawsh,read.table(paste(fit$folder,"/",fit$modelname,".shapley",i-1,sep="")))
drawsh=as.matrix(drawsh)

labs=gsub("\\s+",",",apply(combn(1:p,2),2,function(zz) Reduce(paste,zz)))
res$vidraws=draws[,1:p]
res$vijdraws=draws[,(p+1):(p+p*(p-1)/2)]
res$tvidraws=draws[,(ncol(draws)-p):(ncol(draws)-1)]
res$vdraws=draws[,ncol(draws)]
res$sidraws=res$vidraws/res$vdraws
res$sijdraws=res$vijdraws/res$vdraws
res$tsidraws=res$tvidraws/res$vdraws
res$vidraws=as.matrix(res$vidraws)
colnames(res$vidraws)=paste("V",1:p,sep="")
res$vijdraws=as.matrix(res$vijdraws)
colnames(res$vijdraws)=paste("V",labs,sep="")
res$tvidraws=as.matrix(res$tvidraws)
colnames(res$tvidraws)=paste("TV",1:p,sep="")
res$vdraws=as.matrix(res$vdraws)
colnames(res$vdraws)="V"
res$sidraws=as.matrix(res$sidraws)
colnames(res$sidraws)=paste("S",1:p,sep="")
res$sijdraws=as.matrix(res$sijdraws)
colnames(res$sijdraws)=paste("S",labs,sep="")
res$tsidraws=as.matrix(res$tsidraws)
colnames(res$tsidraws)=paste("TS",1:p,sep="")
rm(draws)
res$shdraws=as.matrix(drawsh)
res$shdraws=res$shdraws/as.vector(res$vdraws)
colnames(res$shdraws)=paste("Sh",1:p,sep="")
rm(drawsh)

# summaries
res$msi=apply(res$sidraws,2,mean)
res$msi.sd=apply(res$sidraws,2,sd)
res$si.5=apply(res$sidraws,2,quantile,0.5)
res$si.lower=apply(res$sidraws,2,quantile,q.lower)
res$si.upper=apply(res$sidraws,2,quantile,q.upper)
names(res$msi)=paste("S",1:p,sep="")
names(res$msi.sd)=paste("S",1:p,sep="")
names(res$si.5)=paste("S",1:p,sep="")
names(res$si.lower)=paste("S",1:p,sep="")
names(res$si.upper)=paste("S",1:p,sep="")

res$msij=apply(res$sijdraws,2,mean)
res$sij.sd=apply(res$sijdraws,2,sd)
res$sij.5=apply(res$sijdraws,2,quantile,0.5)
res$sij.lower=apply(res$sijdraws,2,quantile,q.lower)
res$sij.upper=apply(res$sijdraws,2,quantile,q.upper)
names(res$msij)=paste("S",labs,sep="")
names(res$sij.sd)=paste("S",labs,sep="")
names(res$sij.5)=paste("S",labs,sep="")
names(res$sij.lower)=paste("S",labs,sep="")
names(res$sij.upper)=paste("S",labs,sep="")

res$mtsi=apply(res$tsidraws,2,mean)
res$tsi.sd=apply(res$tsidraws,2,sd)
res$tsi.5=apply(res$tsidraws,2,quantile,0.5)
res$tsi.lower=apply(res$tsidraws,2,quantile,q.lower)
res$tsi.upper=apply(res$tsidraws,2,quantile,q.upper)
names(res$mtsi)=paste("TS",1:p,sep="")
names(res$tsi.sd)=paste("TS",1:p,sep="")
names(res$tsi.5)=paste("TS",1:p,sep="")
names(res$tsi.lower)=paste("TS",1:p,sep="")
names(res$tsi.upper)=paste("TS",1:p,sep="")

res$mshi=apply(res$shdraws,2,mean)
res$mshi.sd=apply(res$shdraws,2,sd)
# res$shi.5=apply(res$shdraws,2,quantile,0.5)
# res$shi.lower=apply(res$shdraws,2,quantile,q.lower)
# res$shi.upper=apply(res$shdraws,2,quantile,q.upper)
names(res$mshi)=paste("Sh",1:p,sep="")
names(res$mshi.sd)=paste("Sh",1:p,sep="")
# names(res$shi.5)=paste("Sh",1:p,sep="")
# names(res$shi.lower)=paste("Sh",1:p,sep="")
# names(res$shi.upper)=paste("Sh",1:p,sep="")


res$q.lower=q.lower
res$q.upper=q.upper
res$modeltype=fit$modeltype

class(res)="OpenBT_sobol"

return(res)
}

#--------------------------------------------------
#Pareto function
#--------------------------------------------------
# Pareto Front Multiobjective Optimization using 2 fitted BART models
mopareto.openbt = function(
fit1=NULL,
fit2=NULL,
fit3=NULL,
q.lower=0.025,
q.upper=0.975,
tc=2
)
{

#--------------------------------------------------
# params
if(is.null(fit1) || is.null(fit2)) stop("No fitted models specified!\n")
#if(fit1$xicuts != fit2$xicuts) stop("Models not compatible\n")
if(fit1$nd != fit2$nd) stop("Models have different number of posterior samples\n")
p=length(fit1$xicuts)
d=2+(!is.null(fit3))
print(paste0("d=",d))
m1=fit1$m
m2=fit2$m
mh1=fit1$mh
mh2=fit2$mh
m3=0
mh3=0
if(!is.null(fit3)) {
   if(fit3$nd != fit2$nd) stop("Models have different number of posterior samples\n")
   m3=fit3$m
   mh3=fit3$mh
}
# if(is.null(fit3)) {
#    fit3=list()
#    fit3$modelname="null"
#    fit3$folder="null"
#    fit3$fmean=0.0
# }

nd=fit1$nd
modelname=fit1$modelname


#--------------------------------------------------
#write out config file
fout=file(paste(fit1$folder,"/config.mopareto",sep=""),"w")
if(!is.null(fit3)) {
writeLines(c(fit1$modelname,fit2$modelname,fit3$modelname,fit1$xiroot,
            fit2$folder,fit3$folder,
            paste(nd),paste(m1),
            paste(mh1),paste(m2),paste(mh2),
            paste(m3),paste(mh3),
            paste(p),paste(fit1$minx),
            paste(fit1$maxx),paste(fit1$fmean),paste(fit2$fmean),
            paste(fit3$fmean),paste(tc)) ,fout)
}
if(is.null(fit3)) {
writeLines(c(fit1$modelname,fit2$modelname,paste("null"),fit1$xiroot,
            fit2$folder,paste("null"),
            paste(nd),paste(m1),
            paste(mh1),paste(m2),paste(mh2),
            paste(m3),paste(mh3),
            paste(p),paste(fit1$minx),
            paste(fit1$maxx),paste(fit1$fmean),paste(fit2$fmean),
            paste(0.0),paste(tc)) ,fout)  
}
close(fout)


#--------------------------------------------------
#run Pareto Front program
cmdopt=100 #default to serial/OpenMP
runlocal=FALSE
cmd="openbtcli --conf"
if(Sys.which("openbtcli")[[1]]=="") # not installed in a global locaiton, so assume current directory
   runlocal=TRUE

if(runlocal) cmd="./openbtcli --conf"

cmdopt=system(cmd)

if(cmdopt==101) # MPI
{
   cmd=paste("mpirun -np ",tc," openbtmopareto ",fit1$folder,sep="")
}

if(cmdopt==100)  # serial/OpenMP
{ 
   if(runlocal)
      cmd=paste("./openbtmopareto ",fit1$folder,sep="")
   else
      cmd=paste("openbtmopareto ",fit1$folder,sep="")
}

system(cmd)
system(paste("rm -f ",fit1$folder,"/config.mopareto",sep=""))


#--------------------------------------------------
#read in result
res=list()
ii=1
u=0  # to modify temp indexing if fit3 exists
for(i in 1:tc) 
{
   con=file(paste(fit1$folder,"/",fit1$modelname,".mopareto",i-1,sep=""))
   open(con)
   s=readLines(con,1)
   while(length(s)>0) {
      temp=as.numeric(unlist(strsplit(s," ")))
      k=as.integer(temp[1])
      theta=matrix(0,ncol=k,nrow=d)
      theta[1,]=temp[2:(2+k-1)]
      theta[2,]=temp[(2+k):(2+2*k-1)]
      if(!is.null(fit3)) { 
         theta[3,]=temp[(2+2*k):(2+3*k-1)] 
         u=k
      }
      a=matrix(0,nrow=p,ncol=k)
      for(i in 1:p) a[i,]=temp[(2+(2+i-1)*k):(2+(2+i)*k-1)+u]
      b=matrix(0,nrow=p,ncol=k)
      for(i in 1:p) b[i,]=temp[(2+(2+p+i-1)*k):(2+(2+p+i)*k-1)+u]
      entry=list()
      entry[["theta"]]=theta
      entry[["a"]]=a
      entry[["b"]]=b
      res[[ii]]=entry
      ii=ii+1
      s=readLines(con,1)
   }
   close(con)
}


class(res)="OpenBT_mopareto"

return(res)
}



# Reweight predictions using output of influence.openbt().
# For method IS_GLOBAL: infl (influence obect) and pred (prediction object to be reweighted)
#                       Also, idx may be specified to apply weights only to a subset of observations.
# For method IS_LOCAL_*: pass infl (influence object), xpred (training x's from fit) and fit (fitted OpenBT object)
repredict.openbt<-function(pred=NULL,infl=NULL,fit=NULL,tc=2)
{
   if(is.null(pred)) stop("Model prediction object required.\n")
   if(is.null(infl)) stop("Model influence object required.\n")
   if(infl$method=="is_global" && class(pred)!="OpenBT_predict") stop("Model prediction object not recognized.\n")
   if(class(infl)!="OpenBT_influence") stop("Model influence object not recognized.\n")
   if(class(pred)!="OpenBT_predict") stop("Model pred object not recognized.\n")
   if(infl$method!="is_global" && infl$method!="is_local_int" && infl$method!="is_local_uint" && infl$method!="is_local_union" && infl$method!="is_local_l1" && infl$method!="is_local_l2") stop("Cannot reweight predictions with influence method ",infl$method,".\n")

   dropid=infl$infl.obs
   ninfl=length(dropid)
   res=list()
   cat("Applying weights\n")

   if(infl$method=="is_global")
   {
      res$mdraws=pred$mdraws
      res$wmat=apply(infl$w,1,prod)
      #re-weight and return the predictions
      # for(k in 1:ninfl)
         # for(i in 1:fit$nd) {
         #    # res$mdraws[i,]=res$mdraws[i,]*infl$w[i,k]
         #    res$mdraws[i,]=res$mdraws[i,]*res$wmat[i]
         # }

      # wbar=apply(infl$w,2,mean)#mean(infl$w)
      wbar=mean(res$wmat)#mean(infl$w)
      # res$mdraws=res$mdraws/wbar
      # res$wmat=infl$w
      res$wbar=wbar
      res$mmean=rep(0,nrow(pred$x.test))
      res$msd=rep(0,nrow(pred$x.test))
      res$m.5=rep(0,nrow(pred$x.test))
      res$m.lower=rep(0,nrow(pred$x.test))
      res$m.upper=rep(0,nrow(pred$x.test))
      for(i in 1:nrow(pred$x.test)) {
         res$mmean[i]=wtd.mean(res$mdraws[,i],res$wmat,normwt=TRUE)
         res$msd[i]=sqrt(wtd.var(res$mdraws[,i],res$wmat,normwt=TRUE))
         res$m.5[i]=wtd.quantile(res$mdraws[,i],res$wmat,probs=c(0.5),normwt=TRUE)
         res$m.lower[i]=wtd.quantile(res$mdraws[,i],res$wmat,probs=c(pred$q.lower),normwt=TRUE)
         res$m.upper[i]=wtd.quantile(res$mdraws[,i],res$wmat,probs=c(pred$q.upper),normwt=TRUE)

      }
   }

   if(infl$method=="is_local_int" || infl$method=="is_local_uint" || infl$method=="is_local_union" || infl$method=="is_local_l1")
   {

      if(is.null(fit)) stop("Method is_local_* requires fitted OpenBT_posterior in object fit\n")
      if(length(fit$xicuts)!=ncol(pred$x.test)) stop("xpred's are not same dimension as trained model\n")

      in_rect<-function(xin,a,b,p)
      {
         for(i in 1:length(xin)) {
            if(xin[i]<a[i] || xin[i]>b[i]) {
               return(FALSE)
            }
         }
         return(TRUE)
      }

      # get predictions
      p=length(fit$xicuts)
      res$mdraws=pred$mdraws

      # now for each posterior draw, identify all predictions in the hyperrectangle of influence
     # parallel::mcaffinity(1:tc)
     # cl=makeCluster(tc)
     # registerDoParallel(cl)
      # mcoptions = list(preschedule=TRUE,cores=tc)
      # wmat=foreach(j=1:nrow(pred$x.test),.combine=cbind,.options.multicore=mcoptions) %dopar% {
      #    tempwvec=matrix(1,nrow=fit$nd,ncol=1)
      #    for(i in 1:fit$nd) {
      #       for(k in 1:ninfl) {
      #          if(in_rect(pred$x.test[j,],infl$hyperrects[[k]]$a[i,],infl$hyperrects[[k]]$b[i,],p)) {
      #             tempwvec[i,1]=tempwvec[i,1]*infl$w[i,k,drop=FALSE]
      #          }
      #       }
      #    }
      #    tempwvec
      # }
      # wmat=as.matrix(wmat) # our final weight matrix, should be fit$nd rows x nrow(pred$x.test) columns
     # stopCluster(cl)

      # Original serial version of the above parallel R code:
      wmat=matrix(1,nrow=fit$nd,ncol=nrow(pred$x.test)) # our final weight matrix

      for(i in 1:fit$nd) {
         for(j in 1:nrow(pred$x.test)) { 
            for(k in 1:ninfl) {
               if(in_rect(pred$x.test[j,],infl$hyperrects[[k]]$a[i,],infl$hyperrects[[k]]$b[i,],p)) {
                  # if(wmat[i,j]==1) 
                     # wmat[i,j]=infl$w[i,k,drop=FALSE]
                  # else 
                  wmat[i,j]=wmat[i,j]*infl$w[i,k,drop=FALSE]
               }
            }
         }
      }


      wbar=apply(wmat,2,mean)
      # res$mdraws=res$mdraws*wmat
      # res$mdraws=t(t(res$mdraws)/wbar)
      res$wmat=wmat
      res$wbar=wbar
      res$mmean=rep(0,nrow(pred$x.test))
      res$msd=rep(0,nrow(pred$x.test))
      res$m.5=rep(0,nrow(pred$x.test))
      res$m.lower=rep(0,nrow(pred$x.test))
      res$m.upper=rep(0,nrow(pred$x.test))
      for(i in 1:nrow(pred$x.test)) {
         res$mmean[i]=wtd.mean(res$mdraws[,i],res$wmat[,i],normwt=TRUE)
         res$msd[i]=sqrt(wtd.var(res$mdraws[,i],res$wmat[,i],normwt=TRUE))
         res$m.5[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(0.5),normwt=TRUE)
         res$m.lower[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(pred$q.lower),normwt=TRUE)
         res$m.upper[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(pred$q.upper),normwt=TRUE)

      }

   }

   if(infl$method=="is_local_l2")
   {
      if(is.null(fit)) stop("Method is_local_* requires fitted OpenBT_posterior in object fit\n")

      res$mdraws=pred$mdraws
      wmat=matrix(1/fit$nd,nrow=fit$nd,ncol=nrow(pred$x.test))

      for(j in 1:ninfl) {
         dvec=rep(0,nrow(pred$x.test))
         for(k in 1:nrow(pred$x.test)) 
            dvec[k]=dist(rbind(pred$x.test[k,],infl$x.infl[dropid[[j]],]))
         idx=which(dvec<0.2)
         for(i in 1:fit$nd)
            for(k in idx)
               if(wmat[i,k]==1/fit$nd) wmat[i,k]=infl$w[i,j,drop=FALSE]
               else wmat[i,k]=wmat[i,k]*infl$w[i,j,drop=FALSE]
      }

      wbar=apply(wmat,2,mean)
      # res$mdraws=res$mdraws*wmat
      # res$mdraws=t(t(res$mdraws)/wbar)
      res$wmat=wmat
      res$wbar=wbar
      res$mmean=rep(0,nrow(pred$x.test))
      res$msd=rep(0,nrow(pred$x.test))
      res$m.5=rep(0,nrow(pred$x.test))
      res$m.lower=rep(0,nrow(pred$x.test))
      res$m.upper=rep(0,nrow(pred$x.test))
      for(i in 1:nrow(pred$x.test)) {
         res$mmean[i]=wtd.mean(res$mdraws[,i],res$wmat[,i],normwt=TRUE)
         res$msd[i]=sqrt(wtd.var(res$mdraws[,i],res$wmat[,i],normwt=TRUE))
         res$m.5[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(0.5),normwt=TRUE)
         res$m.lower[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(pred$q.lower),normwt=TRUE)
         res$m.upper[i]=wtd.quantile(res$mdraws[,i],res$wmat[,i],probs=c(pred$q.upper),normwt=TRUE)

      }
   }



   res$sdraws=pred$sdraws
   # res$mmean=apply(res$mdraws,2,mean)
   res$smean=pred$smean
   # res$msd=apply(res$mdraws,2,sd)
   res$ssd=pred$ssd
   # res$m.5=apply(res$mdraws,2,quantile,0.5)
   # res$m.lower=apply(res$mdraws,2,quantile,pred$q.lower)
   # res$m.upper=apply(res$mdraws,2,quantile,pred$q.upper)
   res$s.5=pred$s.5
   res$s.lower=pred$s.lower
   res$s.upper=pred$s.upper
   res$pdraws=pred$pdraws
   res$pmean=pred$pmean
   res$psd=pred$psd
   res$p.5=pred$p.5
   res$p.lower=pred$p.lower
   res$p.upper=pred$p.upper
   res$q.lower=pred$q.lower
   res$q.upper=pred$q.upper
   res$modeltype=pred$modeltype

   class(res)="OpenBT_predict"
   return(res)
}


# Calculate various metrics of influence for a regression tree model.
influence.openbt<-function(x.infl,y.infl,fit=NULL,infl.obs=NULL,dvec=NULL,tc=2,method="is_local_int")
{
   if(is.null(fit)) stop("Model fit object required.\n")
   if(class(fit)!="OpenBT_posterior") stop("Model fit object not recognized.\n")
   if(is.null(infl.obs)) stop("No hold-out drop id specified for reweighting (infl.obs=NULL).\n")
   if(min(infl.obs)<1) stop("Invalid drop id infl.obs=",infl.obs,".\n")
   if(max(infl.obs)>nrow(x.infl)) stop("Invalid drop id infl.obs=",infl.obs,".\n")
   if(method=="is_local_l1" && is.null(dvec)) stop("Invalid dvec for method is_local_l1.\n")

   nd=fit$nd
   # np=nrow(x.infl)
   ninfl=length(infl.obs)
   w=matrix(0,nrow=nd,ncol=ninfl)
   wsum=rep(1,ninfl)

   if(ninfl==0){
      stop("Argument infl.obs has no influential observations\n")
   }


   pp=predict.openbt(object=fit,x.test=x.infl,tc=tc)

   if(method=="is_global") {
      # w is an nd by np matrix where the j_th column contains the weights for each
      # nd posterior samples if (x_j,y_j) were removed from the dataset.
      for(kk in 1:ninfl)
         for(i in 1:nd) w[i,kk]=(2*pi)^(1/2)*pp$sdraws[i,infl.obs[kk]]*exp(1/(2*pp$sdraws[i,infl.obs[kk]]^2)*(y.infl[infl.obs[kk]]-pp$mdraws[i,infl.obs[kk]])^2)
#      w=apply(w,1,prod) # iid BART likelihood => we just combine the different terms productwise.
#      wsum=sum(w)
   } 
   # end IS_GLOBAL

   if(method=="is_local_int" || method=="is_local_union" || method=="is_local_uint" || method=="is_local_l1")
   {
      p=length(fit$xicuts)
      m=fit$m
      mh=fit$mh
      nd=fit$nd
      modelname=fit$modelname
      hrects.int=list()
      hrects.uint=list()
      hrects.union=list()
      hrects.l1=list()
#      w=matrix(0,nrow=nd,ncol=ninfl)
#      wsum=rep(1,ninfl)

      for(kk in 1:ninfl) {
         xd=x.infl[infl.obs[kk],]
         if(!is.vector(xd)) stop("xd is not a px1 vector in x.infl.\n")

         #--------------------------------------------------
         #write out config file
         fout=file(paste(fit$folder,"/config.influence",sep=""),"w")
         writeLines(c(fit$modelname,fit$xiroot,
                     paste(nd),paste(m),
                     paste(mh),paste(p),paste(xd),paste(fit$minx),
                     paste(fit$maxx),paste(tc)) ,fout)
         close(fout)


         #--------------------------------------------------
         #run influential hyperrectangle program
         cmdopt=100 #default to serial/OpenMP
         runlocal=FALSE
         cmd="openbtcli --conf"
         if(Sys.which("openbtcli")[[1]]=="") # not installed in a global locaiton, so assume current directory
            runlocal=TRUE

         if(runlocal) cmd="./openbtcli --conf"

         cmdopt=system(cmd)

         if(cmdopt==101) # MPI
         {
            cmd=paste("mpirun -np ",tc," openbtinfl ",fit$folder,sep="")
         }

         if(cmdopt==100)  # serial/OpenMP
         { 
            if(runlocal)
               cmd=paste("./openbtinfl ",fit$folder,sep="")
            else
               cmd=paste("openbtinfl ",fit$folder,sep="")
         }

         system(cmd)
         system(paste("rm -f ",fit$folder,"/config.influence",sep=""))

         #--------------------------------------------------
         #read in result
         ii=1
         a=matrix(0,nrow=nd,ncol=p)
         b=matrix(0,nrow=nd,ncol=p)
         au=matrix(0,nrow=nd,ncol=p)
         bu=matrix(0,nrow=nd,ncol=p)
         for(i in 1:tc) 
         {
            con=file(paste(fit$folder,"/",fit$modelname,".influence",i-1,sep=""))
            open(con)
            s=readLines(con,1)
            while(length(s)>0) {
               temp=as.numeric(unlist(strsplit(s," ")))
               a[ii,]=temp[1:p]
               b[ii,]=temp[(p+1):(2*p)]
               au[ii,]=temp[(2*p+1):(3*p)]
               bu[ii,]=temp[(3*p+1):(4*p)]
               ii=ii+1
               s=readLines(con,1)
            }
            close(con)
         }

         system(paste("rm -f ",fit$folder,"/",fit$modelname,".influence*",sep=""))

         hrects.int[[kk]]=list()
         hrects.uint[[kk]]=list()
         hrects.union[[kk]]=list()
         hrects.l1[[kk]]=list()
         hrects.int[[kk]][["a"]]=a
         hrects.int[[kk]][["b"]]=b
         hrects.uint[[kk]][["a"]]=matrix(apply(a,2,min),nrow=nd,ncol=p,byrow=TRUE)
         hrects.uint[[kk]][["b"]]=matrix(apply(b,2,max),nrow=nd,ncol=p,byrow=TRUE)
         hrects.union[[kk]][["a"]]=au
         hrects.union[[kk]][["b"]]=bu
         hrects.l1[[kk]][["a"]]=matrix(xd-dvec,nrow=nd,ncol=p,byrow=TRUE)
         hrects.l1[[kk]][["b"]]=matrix(xd+dvec,nrow=nd,ncol=p,byrow=TRUE)

         # w is an nd by 1 matrix where containing the weights for each
         # nd posterior samples if (x[infl.obs,],y[infl.obs]) were removed from the dataset,
         # where the weight would be applied to any predictions in the corresponding hyperrect
         # for this draw.  Otherwise, the weight is just 1, giving usual posterior average -- this
         # is handled in the reweight() function.
         for(i in 1:nd) w[i,kk]=(2*pi)^(1/2)*pp$sdraws[i,infl.obs[kk]]*exp(1/(2*pp$sdraws[i,infl.obs[kk]]^2)*(y.infl[infl.obs[kk]]-pp$mdraws[i,infl.obs[kk]])^2)
#         wsum[kk]=sum(w[,kk])
#         w[,kk]=w[,kk]/sum(w[,kk])

         # Perhaps a simple indicator of which observation has a lot of influence:
         # infl.max=apply(w,2,max)
         # infl.mean=apply(w,2,mean)
         # infl.ids=infl.obs
      } 
      # end for kk in 1:length(infl.obs) loop
   } 
   #end is_local_*
   for(i in 1:ninfl) wsum[i]=sum(w[,i])

   res=list()
   res$nd=nd
   # res$np=np
   res$x.infl=x.infl
   res$y.infl=y.infl
   res$w=w
   res$wsum=wsum
   # res$infl.max=infl.max
   # res$infl.mean=infl.mean
   res$infl.obs=infl.obs
   res$hyperrects=NULL
   if(method=="is_local_int") {
      res$hyperrects=hrects.int
   }
   if(method=="is_local_uint") {
      res$hyperrects=hrects.uint
   }
   if(method=="is_local_union") {
      res$hyperrects=hrects.union   
   }
   if(method=="is_local_l1") {
      res$hyperrects=hrects.l1   
   }
   res$method=method

   class(res)="OpenBT_influence"

   return(res)
}


summary.OpenBT_influence<-function(infl)
{
   cat("No summary method for object.\n")
}

print.OpenBT_influence<-function(infl)
{
   cat("OpenBT Influence\n")
   cat("metric: ",infl$method,"\n")
   cat(infl$nd, " posterior samples.\n")
   cat(infl$np, " observations.\n")

   if(infl$method=="is_global") {
      idx=sort(infl$infl,decreasing=TRUE,index.return=TRUE)$ix
      cat("\nTop 5 maximum weights: ", infl$infl[idx][1:5],"\n")
      cat("\nTop 5 influential observations by weights: \n")
      for(i in 1:5) {
         cat("Input ",idx[i]," max.influence=",infl$infl[idx[i]],
            " y=",infl$y.infl[idx[i]], " x=",infl$x.infl[idx[i],][1],"\n")
      }

      tab=sort(table(infl$infl.ids),decreasing=TRUE)
      cat("\nTop 5 influential observations by frequency: \n")
      print(tab[1:5])
   }
}

plot.OpenBT_influence<-function(infl)
{
   tab.ids=table(infl$infl.ids)

   if(infl$method=="is_global") {
      par(mfrow=c(1,2))
      plot(1:infl$np,infl$infl,xlab="Observation Index",ylab="max.influence",type="h",lwd=2)
      title(paste("metric: ",infl$method,sep=""))
      plot(tab.ids,xlab="Observation Index",ylab="Frequency")
      title(paste("metric: ",infl$method,sep=""))
   }

   if(infl$method=="is_local_int" || infl$method=="is_local_union")
   {
      # plot hyperrectangles
      plot(0,0,xlim=c(0,1),ylim=c(0,1),type="n",xlab="x1",ylab="x2")
      for(i in 1:nrow(infl$hyperrects$a)) rect(infl$hyperrects$a[i,1],infl$hyperrects$a[i,2],infl$hyperrects$b[i,1],infl$hyperrects$b[i,2],col=gray(0.5,alpha=0.1),border=NA)
   }
}



# Computer Model Calibration a BART emulator and BART discrepancy.
calibrate.openbt<-function(xc,yc,xf,yf,xdims=NULL,caldims=NULL,
                           calprior="normal",calpriora=NULL,calpriorb=NULL,
                           ntreec=NULL,ntreef=NULL,ndpost=1000,
                           nskip=100,kc=NULL,kf=NULL,power=2,base=0.95,tc=2,
                           sigmac=rep(1,length(yc)),sigmaf=rep(1,length(yf)),
                           fmeanc=0.0,fmeanf=0.0,overallsdc=NULL,
                           overallnuc=NULL,overallsdf=NULL,overallnuf=NULL,
                           chv=cor(xc,method="spearman"),pbd=0.7,pb=0.5,
                           stepwpert=0.1,probchv=0.1,minnumbot=5,printevery=100,
                           numcut=100,xicuts=NULL,nadapt=1000,adaptevery=100,
                           model="bart",modelname="model",summarystats=FALSE)
{
   if(is.null(xdims)) stop("xdims must be specified.\n")
   if(is.null(caldims)) stop("caldims must be specified.\n")
   numx=length(xdims)
   numcal=length(caldims)
   if(ncol(xc)!=numx+numcal) stop("xc not compatible with xdims+caldims.\n")
   if(ncol(xf)!=numx) stop("xf not compatible with xdims.\n")
   if(is.null(calprior)) stop("Invalid calibration parameter prior type specified.\n")
   if(is.null(calpriora)) stop("Invalid calibration parameter prior: calpriora.\n")
   if(is.null(calpriorb)) stop("Invalid calibration parameter prior: calpriorb.\n")

   if(length(calprior)==1) calprior=rep(calprior,numcal)
   if(length(calpriora)==1) calpriora=rep(calpriora,numcal)
   if(length(calpriorb)==1) calpriorb=rep(calpriorb,numcal)

   if(length(calprior)!=numcal || length(calpriora)!=numcal || length(calpriorb)!=numcal)
      stop("Invalid calibration parameter prior: does not match number of calibration parameters.\n")

   calpriortype=rep(NULL,numcal)
   for(i in 1:numcal) {
      if(calprior[i]=="normal") calpriortype[i]=1
      if(calprior[i]=="uniform") calpriortype[i]=0
      if(is.null(calpriortype[i])) stop("Invalid calibration parameter prior type specified.\n")
      if(calpriortype[i]==1 && calpriorb[i]<=0) stop("Invalid variance specified in calibration parameter prior.\n")
   }

   ntreehc=NULL
   ntreehf=NULL
   #--------------------------------------------------
   # model type definitions
   modeltype=rep(0,2) # undefined
   MODEL_BT=1
   MODEL_BINOMIAL=2
   MODEL_POISSON=3
   MODEL_BART=4
   MODEL_HBART=5
   MODEL_PROBIT=6
   MODEL_MODIFIEDPROBIT=7
   MODEL_MERCK_TRUNCATED=8


   if(length(model)==1) model=rep(model,2)
   if( (model[1]!="bart" && model[1]!="hbart") || (model[2]!="bart" && model[2]!="hbart") )
   { 
      cat("Model type not specified.\n")
      cat("Available options are:\n")
      cat("model='bart'\n")
      cat("model='hbart'\n")

      stop("missing model type.\n")
   }
   if(model[1]=="bart")
   {
      modeltype[1]=MODEL_BART
      if(is.null(ntreec)) ntreec=200
      if(is.null(ntreehc)) ntreehc=1
      if(is.null(kc)) kc=2
      if(is.null(overallsdc)) overallsdc=sd(yc)
      if(is.null(overallnuc)) overallnuc=10
      pbdc=c(pbd[1],0.0)
   }
   if(model[1]=="hbart")
   {
      modeltype=MODEL_HBART
      if(is.null(ntreec)) ntreec=200
      if(is.null(ntreehc)) ntreehc=40
      if(is.null(kc)) kc=5
      if(is.null(overallsdc)) overallsdc=sd(yc)
      if(is.null(overallnuc)) overallnuc=10
      pbdc=pbd
   }
   if(model[2]=="bart")
   {
      modeltype[2]=MODEL_BART
      if(is.null(ntreef)) ntreef=200
      if(is.null(ntreehf)) ntreehf=1
      if(is.null(kf)) kf=2
      if(is.null(overallsdf)) overallsdf=sd(yf)
      if(is.null(overallnuf)) overallnuf=10
      pbdf=c(pbd[1],0.0)
   }
   if(model[2]=="hbart")
   {
      modeltype[2]=MODEL_HBART
      if(is.null(ntreef)) ntreef=200
      if(is.null(ntreehf)) ntreehf=40
      if(is.null(kf)) kf=5
      if(is.null(overallsdf)) overallsdf=sd(yf)
      if(is.null(overallnuf)) overallnuf=10
      pbdf=pbd
   }


   #--------------------------------------------------
   nd = ndpost
   burn = nskip
   mc = ntreec
   mhc = ntreehc
   mf = ntreef
   mhf = ntreehf
   #--------------------------------------------------
   # simulator data
   nc = length(yc)
   p = ncol(xc)
   pdelta = ncol(xf)
   xpred = matrix(NA,nrow=nf,ncol=p)
   for(i in 1:numcal) {
      if(calpriortype[i])
         xpred[,caldims[i]]=calpriora[i]
      else
         xpred[,caldims[i]]=calpriora[i]+(calpriorb[i]-calpriora[i])/2.0
   }
   for(i in 1:pdelta) {
      xpred[,xdims[i]]=xf[,i]
   }
#   xpred = t(xpred)
#   xc = t(xc)
   nf = length(yf)
#   xf = t(xf)
   # if(modeltype==MODEL_BART || modeltype==MODEL_HBART)
   # {
   yc=yc-fmeanc
   yf=yf-fmeanf
   fmeanc.out=paste(fmeanc)
   fmeanf.out=paste(fmeanf)
   # }
   # if(modeltype==MODEL_PROBIT || modeltype==MODEL_MODIFIEDPROBIT)
   # {
   #    fmean.out=paste(qnorm(fmean))
   #    uniqy=sort(unique(y.train))
   #    if(length(uniqy)>2) stop("Invalid y.train: Probit requires dichotomous response coded 0/1")
   #    if(uniqy[1]!=0 || uniqy[2]!=1) stop("Invalid y.train: Probit requires dichotomous response coded 0/1")
   # }
   #--------------------------------------------------
   #cutpoints
   if(!is.null(xicuts)) # use xicuts
   {
      xic=xicuts
   }
   else # default to equal numcut per dimension
   {
      xic=vector("list",p)
      minxc=floor(apply(xc,2,min))
      maxxc=ceiling(apply(xc,2,max))
      for(i in 1:p)
      {
         xinc=(maxxc[i]-minxc[i])/(numcut+1)
         xic[[i]]=(1:numcut)*xinc+minxc[i]
      }
   }
   xif=vector("list",numx)
   for(i in 1:numx)
      xif[[i]]=xic[[xdims[i]]]

   #--------------------------------------------------
   if(modeltype[1]==MODEL_BART || modeltype[1]==MODEL_HBART)
   {
      rgc = range(yc)
   }
   if(modeltype[2]==MODEL_BART || modeltype[2]==MODEL_HBART)
   {
      rgf = range(yf)
   }
   # if(modeltype==MODEL_PROBIT || modeltype==MODEL_MODIFIEDPROBIT)
   # {
   #    rgy = c(-2,2)
   # }
   tauc =  (rgc[2]-rgc[1])/(2*sqrt(mc)*kc)
   tauf =  (rgf[2]-rgf[1])/(2*sqrt(mf)*kf)

   #--------------------------------------------------
   overalllambdac = overallsdc^2
   overalllambdaf = overallsdf^2
   #--------------------------------------------------
   powerh=power
   baseh=base
   if(length(power)>1) {
      powerh=power[2]
      power=power[1]
   }
   if(length(base)>1) {
      baseh=base[2]
      base=base[1]
   }
   #--------------------------------------------------
   pbdch=pbdc
   pbdfh=pbdf
   pbh=pb
   if(length(pbdc)>1) {
      pbdch=pbdc[2]
      pbdc=pbdc[1]
   }
   if(length(pbdf)>1) {
      pbdfh=pbdf[2]
      pbdf=pbdf[1]
   }
   if(length(pb)>1) {
      pbh=pb[2]
      pb=pb[1]
   }
   cat("Model: Bayesian Regression Tree based Computer Model Calibration\n")
   #--------------------------------------------------
   if(modeltype[1]==MODEL_BART)
   {
      cat("\tEmulator: BART\n")
   }
   #--------------------------------------------------
   if(modeltype[1]==MODEL_HBART)
   {
      cat("\tEmulator: Heteroscedastic BART\n")
   }
   #--------------------------------------------------
   if(modeltype[2]==MODEL_BART)
   {
      cat("\tDiscrepancy: BART\n")
   }
   #--------------------------------------------------
   if(modeltype[2]==MODEL_HBART)
   {
      cat("\tDiscrepancy: Heteroscedastic BART\n")
   }

   #--------------------------------------------------
   stepwperth=stepwpert
   if(length(stepwpert)>1) {
      stepwperth=stepwpert[2]
      stepwpert=stepwpert[1]
   }
   #--------------------------------------------------
   probchvh=probchv
   if(length(probchv)>1) {
      probchvh=probchv[2]
      probchv=probchv[1]
   }
   #--------------------------------------------------
   minnumboth=minnumbot
   if(length(minnumbot)>1) {
      minnumboth=minnumbot[2]
      minnumbot=minnumbot[1]
   }

   #--------------------------------------------------
   #write out config file
   xcroot="xc"
   ycroot="yc"
   scroot="sc"
   chgvcroot="chgvc"
   xicroot="xic"
   xfroot="xf"
   yfroot="yf"
   sfroot="sf"
   xproot="xpred"
   chgvfroot="chgvf"
   xifroot="xif"
   folder=tempdir(check=TRUE)
   if(!dir.exists(folder)) dir.create(folder)
   tmpsubfolder=tempfile(tmpdir="")
   tmpsubfolder=substr(tmpsubfolder,5,nchar(tmpsubfolder))
   tmpsubfolder=paste("openbt",tmpsubfolder,sep="")
   folder=paste(folder,"/",tmpsubfolder,sep="")
   if(!dir.exists(folder)) dir.create(folder)
   fout=file(paste(folder,"/config.calibrate",sep=""),"w")
   writeLines(c(paste(modeltype),xcroot,ycroot,xfroot,yfroot,xproot,fmeanc.out,fmeanf.out,
               paste(mc),paste(mhc),paste(mf),paste(mhf),paste(nd),paste(burn),
               paste(nadapt),paste(adaptevery),paste(tauc),paste(overalllambdac),
               paste(overallnuc),paste(tauf),paste(overalllambdaf),paste(overallnuf),
               paste(base),paste(power),paste(baseh),paste(powerh),
               paste(tc),paste(scroot),paste(sfroot),paste(chgvcroot),paste(chgvfroot),
               paste(pb),paste(pbdc),paste(pbdch),
               paste(pbdf),paste(pbdfh),paste(stepwpert),paste(stepwperth),
               paste(probchv),paste(probchvh),paste(minnumbot),paste(minnumboth),
               paste(printevery),paste(xicroot),paste(xifroot),paste(modelname),
               paste(as.integer(summarystats)),paste(numcal),paste(caldims-1),paste(calpriortype),
               paste(calpriora),paste(calpriorb)),fout)
   close(fout)


   #--------------------------------------------------
   #write out data subsets
   nslv=tc-1
   # yc data
   yclist=split(yc,(seq(nc)-1) %/% (nc/nslv))
   for(i in 1:nslv) write(yclist[[i]],file=paste(folder,"/",ycroot,i,sep=""))
   xclist=split(as.data.frame(xc),(seq(nc)-1) %/% (nc/nslv))
   for(i in 1:nslv) write(t(xclist[[i]]),file=paste(folder,"/",xcroot,i,sep=""))
#stop("done")

   sclist=split(sigmac,(seq(nc)-1) %/% (nc/nslv))
   for(i in 1:nslv) write(sclist[[i]],file=paste(folder,"/",scroot,i,sep=""))
   chv[is.na(chv)]=0 # if a var has 0 levels it will have a cor of NA so we'll just set those to 0.
   write(chv,file=paste(folder,"/",chgvcroot,sep=""))
   for(i in 1:p) write(xic[[i]],file=paste(folder,"/",xicroot,i,sep=""))
   # yf data
   yflist=split(yf,(seq(nf)-1) %/% (nf/nslv))
   for(i in 1:nslv) write(yflist[[i]],file=paste(folder,"/",yfroot,i,sep=""))
   xflist=split(as.data.frame(xf),(seq(nf)-1) %/% (nf/nslv))
   for(i in 1:nslv) write(t(xflist[[i]]),file=paste(folder,"/",xfroot,i,sep=""))
   sflist=split(sigmaf,(seq(nf)-1) %/% (nf/nslv))
   for(i in 1:nslv) write(sflist[[i]],file=paste(folder,"/",sfroot,i,sep=""))
   write(chv[xdims,xdims],file=paste(folder,"/",chgvfroot,sep=""))
   for(i in 1:pdelta) write(xif[[i]],file=paste(folder,"/",xifroot,i,sep=""))
   rm(chv)
   # xpred
   xplist=split(as.data.frame(xpred),(seq(nf)-1) %/% (nf/nslv))
   for(i in 1:nslv) write(t(xplist[[i]]),file=paste(folder,"/",xproot,i,sep=""))

   #--------------------------------------------------
   #run program
   cmdopt=100 #default to serial/OpenMP
   runlocal=FALSE
   cmd="openbtcalibrate --conf"
   if(Sys.which("openbtcalibrate")[[1]]=="") # not installed in a global locaiton, so assume current directory
      runlocal=TRUE

   if(runlocal) cmd="./openbtcalibrate --conf"

   cmdopt=system(cmd)

   if(cmdopt==101) # MPI
   {
      cmd=paste("mpirun -np ",tc," openbtcalibrate ",folder,sep="")
   }

   if(cmdopt==100)  # serial/OpenMP
   { 
      if(runlocal)
         cmd=paste("./openbtcalibrate ",folder,sep="")
      else
         cmd=paste("openbtcalibrate ",folder,sep="")
   }
   #
   system(cmd)
   system(paste("rm -f ",folder,"/config.calibrate",sep=""))


   #--------------------------------------------------
   # load in the theta posterior draws
   thetas=scan(paste(folder,"/model.eta.theta.fit",sep=""),quiet=TRUE)
   thetas=matrix(thetas,ncol=numcal,byrow=T)


   res=list()
   res$modeltype=modeltype
   res$model=model
   res$xcroot=xcroot; res$ycroot=ycroot; 
   #res$xfroot=xfroot; res$yfroot=yfroot; 
   res$xproot=xproot;
   res$mc=mc; res$mhc=mhc; 
   #res$mf=mf; res$mhf=mhf; 
   res$p=p; 
   #res$pdelta=pdelta;
   res$nd=nd; res$burn=burn; res$nadapt=nadapt; res$adaptevery=adaptevery; res$tauc=tauc; res$overalllambdac=overalllambdac
   res$overallnuc=overallnuc; 
   #res$tauf=tauf; res$overalllambdaf=overalllambdaf; res$overallnuf=overallnuf; 
   res$base=base; res$power=power; res$baseh=baseh; res$powerh=powerh
   res$k=numx+numcal;
   res$tc=tc; res$scroot=scroot; 
   #res$sfroot=sfroot; 
   res$chgvcroot=chgvcroot;
   #res$chgvfroot=chgvfroot; 
   res$pb=pb; res$pbdc=pbdc; res$pbdch=pbdch; 
   #res$pbdf=pbdf; res$pbdfh=pbdfh;
   res$stepwpert=stepwpert; res$stepwperth=stepwperth;
   res$probchv=probchv; res$probchvh=probchvh; res$minnumbot=minnumbot; res$minnumboth=minnumboth
   res$printevery=printevery; res$xicroot=xicroot; 
   #res$xifroot=xifroot; 
   res$minxc=minxc; res$maxxc=maxxc;
   res$xdims=xdims; res$numcal=numcal; res$caldims=caldims; res$calpriortype=calpriortype; res$calpriora=calpriora;
   res$calpriorb=calpriorb; res$summarystats=summarystats; res$modelname=paste(modelname,".eta",sep="")
   class(xic)="OpenBT_cutinfo"
   class(xif)="OpenBT_cutinfo"
   res$xiccuts=xic
#   res$xifcuts=xif
   res$fmeanc=fmeanc.out;
#   res$fmeanf=fmeanf.out;
   res$theta=thetas
   res$folder=folder

   res$delta$modeltype=modeltype[2]
   res$delta$model=model
   res$delta$xroot=xfroot
   res$delta$yroot=yfroot
   res$delta$xproot=xproot
   res$delta$k=numx
   res$delta$m=mf
   res$delta$mh=mhf
   res$delta$p=pdelta
   res$delta$nd=nd
   res$delta$burn=burn
   res$delta$nadapt=nadapt
   res$delta$adaptevery=adaptevery
   res$delta$tau=tauf
   res$delta$overalllambda=overalllambdaf
   res$delta$overallnu=overallnuf
   res$delta$base=base
   res$delta$power=power
   res$delta$baseh=baseh
   res$delta$powerh=powerh
   res$delta$chgvroot=chgvfroot
   res$delta$pb=pb
   res$delta$pbd=pbdf
   res$delta$pbdh=pbdfh
   res$delta$stepwpert=stepwpert
   res$delta$stepwperth=stepwperth
   res$delta$probchv=probchv
   res$delta$probchvh=probchvh
   res$delta$minnumbot=minnumbot
   res$delta$minnumboth=minnumboth
   res$delta$printevery=printevery
   res$delta$xiroot=xifroot
   res$delta$summarystats=summarystats
   res$delta$modelname=paste(modelname,".delta",sep="")
   res$delta$xicuts=xif
   res$delta$fmean=fmeanf.out
   res$delta$folder=folder
   class(res$delta)="OpenBT_posterior"


   class(res)="OpenBT_calibrate_posterior"

   return(res)
}


emulate.openbt = function(
fit=NULL,
x.test=NULL,
tc=2,
fmeanc=fit$fmeanc,
fmeanf=fit$delta$fmean,
q.lower=0.025,
q.upper=0.975
)
{

   # model type definitions
   MODEL_BT=1
   MODEL_BINOMIAL=2
   MODEL_POISSON=3
   MODEL_BART=4
   MODEL_HBART=5
   MODEL_PROBIT=6
   MODEL_MODIFIEDPROBIT=7
   MODEL_MERCK_TRUNCATED=8

   #--------------------------------------------------
   # params
   if(is.null(fit)) stop("No fitted model specified!\n")
   if(is.null(x.test)) stop("No emulation points specified!\n")
   if(class(fit)!="OpenBT_calibrate_posterior") stop("Invalid object passed to emulate.openbt()\n")

   xdims=fit$xdims
   caldims=fit$caldims
   nslv=tc
   x.test=as.matrix(x.test)
   pdelta=ncol(x.test)
   if(pdelta!=fit$delta$p) stop("x.test has incorrect dimensions.\n")
   n=nrow(x.test)
   p=fit$p
   x.eta.test=matrix(0,nrow=n,ncol=p)
   x.eta.test[,xdims]=x.test

   # Get discrepancy posterior first
   cat("Drawing from discrepancy posterior...\n")
   fit.delta=predict.openbt(fit$delta,x.test=x.test,tc=tc,fmean=fmeanf)

   # Get eta posterior next
   cat("Drawing from emulator posterior...\n")
   xeroot="xe"
   xdroot="xd"

   if( (fit$modeltype[1]==MODEL_BART || fit$modeltype[1]==MODEL_HBART) && (fit$modeltype[2]==MODEL_BART || fit$modeltype[2]==MODEL_HBART) )
   {
      fmeanc.out=paste(fmeanc)
      fmeanf.out=paste(fmeanf)
   }
   else stop("Invalid model passed to emulate.openbt()\n")
   # if(fit$modeltype==MODEL_PROBIT || fit$modeltype==MODEL_MODIFIEDPROBIT)
   # {
   #    fmean.out=paste(qnorm(fmean))
   # }


   #--------------------------------------------------
   #write out config file
   fout=file(paste(fit$folder,"/config.emulate",sep=""),"w")
   writeLines(c(paste(fit$modelname),paste(fit$modeltype),fit$xicroot,
               xeroot,paste(fit$nd),paste(fit$mc),
               paste(fit$mhc),paste(p),paste(pdelta),
               paste(fit$numcal),paste(caldims-1),paste(tc),
               fmeanc.out), fout)
   close(fout)



   #--------------------------------------------------
   #write out data subsets
   #folder=paste(".",fit$modelname,"/",sep="")
   xelist=split(as.data.frame(x.eta.test),(seq(n)-1) %/% (n/nslv))
   for(i in 1:nslv) write(t(xelist[[i]]),file=paste(fit$folder,"/",xeroot,i-1,sep=""))
   xdlist=split(as.data.frame(x.test),(seq(n)-1) %/% (n/nslv))
   for(i in 1:nslv) write(t(xdlist[[i]]),file=paste(fit$folder,"/",xdroot,i-1,sep=""))
   for(i in 1:p) write(fit$xiccuts[[i]],file=paste(fit$folder,"/",fit$xicroot,i,sep=""))
   for(i in 1:pdelta) write(fit$xifcuts[[i]],file=paste(fit$folder,"/",fit$xifroot,i,sep=""))


   #--------------------------------------------------
   #run prediction program
   cmdopt=100 #default to serial/OpenMP
   runlocal=FALSE
   cmd="openbtcli --conf"
   if(Sys.which("openbtcli")[[1]]=="") # not installed in a global location, so assume current directory
      runlocal=TRUE

   if(runlocal) cmd="./openbtcli --conf"

   cmdopt=system(cmd)

   if(cmdopt==101) # MPI
   {
      cmd=paste("mpirun -np ",tc," openbtemulate ",fit$folder,sep="")
   }

   if(cmdopt==100)  # serial/OpenMP
   { 
      if(runlocal)
         cmd=paste("./openbtemulate ",fit$folder,sep="")
      else
         cmd=paste("openbtemulate ",fit$folder,sep="")
   }

   #cmd=paste("mpirun -np ",tc," openbtpred",sep="")
   #cat(cmd)
   system(cmd)
   system(paste("rm -f ",fit$folder,"/config.emulate",sep=""))


#--------------------------------------------------
#format and return
res=list()


# Read in eta posterior
fnames=list.files(fit$folder,pattern=paste(fit$modelname,".mdraws*",sep=""),full.names=TRUE)
res$mdraws=as.matrix(do.call(cbind,sapply(fnames,data.table::fread)))
fnames=list.files(fit$folder,pattern=paste(fit$modelname,".sdraws*",sep=""),full.names=TRUE)
res$sdraws=as.matrix(do.call(cbind,sapply(fnames,data.table::fread)))

system(paste("rm -f ",fit$folder,"/",fit$modelname,".mdraws*",sep=""))
system(paste("rm -f ",fit$folder,"/",fit$modelname,".sdraws*",sep=""))

res$mmean=apply(res$mdraws,2,mean)
res$smean=apply(res$sdraws,2,mean)
res$msd=apply(res$mdraws,2,sd)
res$ssd=apply(res$sdraws,2,sd)
res$m.5=apply(res$mdraws,2,quantile,0.5)
res$m.lower=apply(res$mdraws,2,quantile,q.lower)
res$m.upper=apply(res$mdraws,2,quantile,q.upper)
res$s.5=apply(res$sdraws,2,quantile,0.5)
res$s.lower=apply(res$sdraws,2,quantile,q.lower)
res$s.upper=apply(res$sdraws,2,quantile,q.upper)
res$pdraws=NULL
res$pmean=NULL
res$psd=NULL
res$p.5=NULL
res$p.lower=NULL
res$p.upper=NULL
res$zdraws=res$mdraws+fit.delta$mdraws
res$zmean=apply(res$zdraws,2,mean)
res$zsd=apply(res$zdraws,2,sd)
res$z.5=apply(res$zdraws,2,quantile,0.5)
res$z.lower=apply(res$zdraws,2,quantile,q.lower)
res$z.upper=apply(res$zdraws,2,quantile,q.upper)

if(fit$modeltype==MODEL_PROBIT || fit$modeltype==MODEL_MODIFIEDPROBIT)
{
   res$pdraws=read.table(paste(fit$folder,"/",fit$modelname,".pdraws",0,sep=""))
   for(i in 2:nslv)
   {
      res$pdraws=cbind(res$pdraws,read.table(paste(fit$folder,"/",fit$modelname,".pdraws",i-1,sep="")))
   }

   system(paste("rm -f ",fit$folder,"/",fit$modelname,".pdraws*",sep=""))

   res$pdraws=as.matrix(res$pdraws)
   res$pmean=apply(res$pdraws,2,mean)
   res$psd=apply(res$pdraws,2,sd)
   res$p.5=apply(res$pdraws,2,quantile,0.5)
   res$p.lower=apply(res$pdraws,2,quantile,q.lower)
   res$p.upper=apply(res$pdraws,2,quantile,q.upper)
}

res$q.lower=q.lower
res$q.upper=q.upper
res$modeltype=fit$modeltype

res$delta=fit.delta

class(res)="OpenBT_emulate"

return(res)
}



# Scan the trees in the posterior to extract tree properties
# Returns the mean trees as a list of lists in object mt
# and the variance trees as a list of lists in object st.
# The format is mt[[i]][[j]] is the jth posterior tree from the ith posterior
# sum-of-trees (ensemble) sample.
# The tree is encoded in 4 vectors - the node ids, the node variables,
# the node cutpoints and the node thetas.
openbt.scanpost<-function(post)
{
   fp=file(paste(post$folder,"/",post$modelname,".fit",sep=""),open="r")
   if(scan(fp,what=integer(),nmax=1,quiet=TRUE) != post$nd) stop("Error scanning posterior\n")
   if(scan(fp,what=integer(),nmax=1,quiet=TRUE) != post$m) stop("Error scanning posterior\n")
   if(scan(fp,what=integer(),nmax=1,quiet=TRUE) != post$mh) stop("Error scanning posterior\n")
   if(scan(fp,what=integer(),nmax=1,quiet=TRUE) != post$nd*post$m) stop("Error scanning posterior\n")

   # scan mean trees
   numnodes=scan(fp,what=integer(),nmax=post$nd*post$m,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   ids=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   vars=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   cuts=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   thetas=scan(fp,what=double(),nmax=lenvec,quiet=TRUE)

   # scan var trees
   if(scan(fp,what=integer(),nmax=1,quiet=TRUE) != post$nd*post$mh) stop("Error scanning posterior\n")
   snumnodes=scan(fp,what=integer(),nmax=post$nd*post$mh,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   sids=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   svars=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   scuts=scan(fp,what=integer(),nmax=lenvec,quiet=TRUE)
   lenvec=scan(fp,what=integer(),nmax=1,quiet=TRUE)
   sthetas=scan(fp,what=double(),nmax=lenvec,quiet=TRUE)

   close(fp)

   # Now rearrange things into lists of lists so its easier to manipulate
   mt=list()
   ndx=2
   cs.numnodes=c(0,cumsum(numnodes))
   for(i in 1:post$nd) {
      ens=list()
      for(j in 1:post$m)
      {
         tree=list(id=ids[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  var=vars[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  cut=cuts[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  theta=thetas[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]])
         ens[[j]]=tree
         ndx=ndx+1
      }
      mt[[i]]=ens
   }


   st=list()
   ndx=2
   cs.numnodes=c(0,cumsum(snumnodes))
   for(i in 1:post$nd) {
      ens=list()
      for(j in 1:post$mh)
      {
         tree=list(id=sids[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  var=svars[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  cut=scuts[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]],
                  theta=sthetas[(cs.numnodes[ndx-1]+1):cs.numnodes[ndx]])
         ens[[j]]=tree
         ndx=ndx+1
      }
      st[[i]]=ens
   }

   return(list(mt=mt,st=st))
}



# Save a posterior tree fit from the tmp working directory
# into a local zip file given by [file].zip
# If not file option specified, uses [model name].zip as the file.
openbt.save<-function(post,fname=NULL)
{
   if(class(post)!="OpenBT_posterior") stop("Invalid object.\n")

   if(is.null(fname)) fname=post$modelname
   if(substr(fname,nchar(fname)-3,nchar(fname))!=".obt") fname=paste(fname,".obt",sep="")

   save(post,file=paste(post$folder,"/post.RData",sep=""))

   zipr(fname,paste(post$folder,"/",list.files(post$folder),sep=""))
   cat("Saved posterior to ",fname,"\n")
}


# Load a posterior tree fit from a zip file into a tmp working directory.
openbt.load<-function(fname)
{
   if(substr(fname,nchar(fname)-3,nchar(fname))!=".obt") fname=paste(fname,".obt",sep="")

   folder=tempdir(check=TRUE)
   if(!dir.exists(folder)) dir.create(folder)
   tmpsubfolder=tempfile(tmpdir="")
   tmpsubfolder=substr(tmpsubfolder,5,nchar(tmpsubfolder))
   tmpsubfolder=paste("openbt",tmpsubfolder,sep="")
   folder=paste(folder,"/",tmpsubfolder,sep="")
   if(!dir.exists(folder)) dir.create(folder)

   unzip(fname,exdir=folder)
   post=loadRData(paste(folder,"/post.RData",sep=""))
   post$folder=folder

   return(post)
}


# This is so lame. Seriously.
loadRData <- function(fname)
{
    load(fname)
    get(ls()[ls() != "fname"])
}


print.OpenBT_posterior<-function(x, ...)
{
   post = x
   MODEL_BT=1
   MODEL_BINOMIAL=2
   MODEL_POISSON=3
   MODEL_BART=4
   MODEL_HBART=5
   MODEL_PROBIT=6
   MODEL_MODIFIEDPROBIT=7
   MODEL_MERCK_TRUNCATED=8

   cat("OpenBT Posterior\n")
   cat("Model type: ")
   if(post$modeltype==MODEL_BART)
   {
      cat("Bayesian Additive Regression Trees model (BART)\n")
      cat("k=",post$k,"\n")
      cat("tau=",post$tau,"\n")
      cat("lambda=",post$overalllambda,"\n")
      cat("nu=",post$overallnu,"\n")
   }
   if(post$modeltype==MODEL_HBART)
   {
      cat("Heteroscedastic Bayesian Additive Regression Trees model (HBART)\n")
   }
   if(post$modeltype==MODEL_PROBIT)
   {
      cat("Dichotomous outcome model: Albert & Chib Probit (fixed)\n")
   }
   if(post$modeltype==MODEL_MODIFIEDPROBIT)
   {
      cat("Dichotomous outcome model: Modified Albert & Chib Probit\n")
   }
   if(post$modeltype==MODEL_MERCK_TRUNCATED)
   {
      cat("Truncated BART model\n")
   }

   cat("ntree=", post$m, " \n",sep="")
   cat("ntreeh=",post$mh," \n",sep="")
   cat(post$nd," posterior draws.\n")
   summary(post$xicuts)
}

summary.OpenBT_posterior<-function(object, ...)
{
   post = object
   cat("No summary method for object.\n")
}

print.OpenBT_predict<-function(x, ...)
{
   pred = x
   MODEL_BT=1
   MODEL_BINOMIAL=2
   MODEL_POISSON=3
   MODEL_BART=4
   MODEL_HBART=5
   MODEL_PROBIT=6
   MODEL_MODIFIEDPROBIT=7
   MODEL_MERCK_TRUNCATED=8

   cat("OpenBT Prediction\n")
   cat(ncol(pred$mdraws), " prediction locations.\n")
   cat(nrow(pred$mdraws), " realizations.\n")
   if(pred$modeltype==MODEL_PROBIT || pred$modeltype==MODEL_MODIFIEDPROBIT)
   {
      cat("Probability quantiles: ",pred$q.lower,",",pred$q.upper,"\n")
   }
   cat("Mean quantiles: ",pred$q.lower,",",pred$q.upper,"\n")
   cat("Variance quantiles: ",pred$q.lower,",",pred$q.upper,"\n\n")
}

summary.OpenBT_predict<-function(object, ...)
{
   pred = object
   cat("No summary method for object.\n")
}

print.OpenBT_sobol<-function(x, ...)
{
   sobol = x
   cat("OpenBT Sobol Indices\n")
   cat(ncol(sobol$vidraws), " variables.\n")
   cat(nrow(sobol$vidraws), " realizations.\n")
}

summary.OpenBT_sobol<-function(object, ...)
{
   sobol = object
   cat("Summary of Posterior Sobol Sensitivity Indices\n")

   cat("Expected Sobol Indices (Mean)\n")
   print(sobol$msi)
   print(sobol$mtsi)
   print(sobol$msij)

   cat("\nStd. Dev. of Sobol Indices (Mean)\n")
   print(sobol$msi.sd)
   print(sobol$tsi.sd)
   print(sobol$sij.sd)
}

plot.OpenBT_sobol<-function(x, ...)
{
   sobol = x
   par(mfrow=c(3,1))
   boxplot(sobol$sidraws,ylab="Sobol Sensitivity",main="First Order Sobol Indices",xlab="Variables")
   boxplot(sobol$sijdraws,ylab="Sobol Sensitivity",main="Two-way Sobol Indices",xlab="Variables")
   boxplot(sobol$tsidraws,ylab="Sobol Sensitivity",main="Total Sobol Indices",xlab="Variables")
}

print.OpenBT_vartivity<-function(x, ...)
{
   vartivity = x
   cat("OpenBT Variable Activity\n")
   cat(ncol(vartivity$vdraws), " variables.\n")
   cat(nrow(vartivity$vdraws), " realizations.\n")
}

summary.OpenBT_vartivity<-function(object, ...)
{
   vartivity = object
   cat("Summary of Posterior Variable Activity\n")

   p=length(vartivity$mvdraws)
   if(p<11)
   {
      cat("Expected Variable Activity (Mean)\n")
      mean.vartivity=vartivity$mvdraws
      ix=sort(mean.vartivity,index.return=TRUE,decreasing=TRUE)$ix
      mean.vartivity=round(mean.vartivity[ix],2)
      names(mean.vartivity)=ix
      print(mean.vartivity)
      cat("Expected Variable Activity (Variance)\n")
      sd.vartivity=vartivity$mvdrawsh
      ix=sort(sd.vartivity,index.return=TRUE,decreasing=TRUE)$ix
      sd.vartivity=round(sd.vartivity[ix],2)
      names(sd.vartivity)=ix
      print(sd.vartivity)
   }
   else
   {
      cat("Expected Variable Activity (Mean)\n")
      mean.vartivity=vartivity$mvdraws
      ix=sort(mean.vartivity,index.return=TRUE,decreasing=TRUE)$ix
      mean.vartivity=round(mean.vartivity[ix],2)
      rest=sum(mean.vartivity[11:p])
      mean.vartivity=mean.vartivity[1:11]
      mean.vartivity[11]=rest
      names(mean.vartivity)=c(ix[1:10],"...")
      print(mean.vartivity)
      cat("Expected Variable Activity (Variance)\n")
      sd.vartivity=vartivity$mvdrawsh
      ix=sort(sd.vartivity,index.return=TRUE,decreasing=TRUE)$ix
      sd.vartivity=round(sd.vartivity[ix],2)
      rest=sum(sd.vartivity[11:p])
      sd.vartivity=sd.vartivity[1:11]
      sd.vartivity[11]=rest
      names(sd.vartivity)=c(ix[1:10],"...")
      print(sd.vartivity)
   }
}

plot.OpenBT_vartivity<-function(x, ...)
{
   vartivity = x
   par(mfrow=c(1,2))
   yrange=c(0,max(max(vartivity$vdraws),max(vartivity$vdrawsh)))
   boxplot(vartivity$vdraws,ylab="% node splits",main="Mean Trees",xlab="Variables",ylim=yrange)
   boxplot(vartivity$vdrawsh,ylab="% node splits",main="Variance Trees",xlab="Variables",ylim=yrange)
}

summary.OpenBT_cutinfo<-function(object, ...)
{
   xi = object
   p=length(xi)
   cat("Number of variables: ",p,"\n")
   cat("Number of cutpoints per variable\n")
   for(i in 1:p)
   {
      cat("Variable ",i,": ",length(xi[[i]])," cutpoints\n")
   }
}

print.OpenBT_cutinfo<-function(x, ...)
{
   xi = x
   summary.OpenBT_cutinfo(xi)
}

# Takes the n x p design matrix and a scalar or vector of number of cutpoints 
# per variable, returns a BARTcutinfo object with variables/cutpoints initalized.
makecuts.openbt<-function(x,numcuts)
{
   p=ncol(x)
   if(length(numcuts)==1)
   {
      numcuts=rep(numcuts,p)
   }
   else if(ncol(x) != length(numcuts))
   {
      cat("Number of variables does not equal length of numcuts vector!\n")
      return(0)
   }

   xi=vector("list",p)
   minx=apply(x,2,min)
   maxx=apply(x,2,max)
   for(i in 1:p)
   {
      xinc=(maxx[i]-minx[i])/(numcuts[i]+1)
      xi[[i]]=(1:numcuts[i])*xinc+minx[i]
   }

   class(xi)="OpenBT_cutinfo"
   return(xi)
}

# Takes an existing OpenBT_cutinfo object xi and the particular variable to update, id,
# and the vector of cutpoints to manually assign to that variable, updates and returns
# the modified OpenBT_cutinfo object.
setvarcuts.openbt<-function(xi,id,cutvec)
{
   p=length(xi)
   if(id>p || id<1)
   {
      cat("Invalid variable specified\n")
      return(0)
   }
   xi[[id]]=cutvec
   return(xi)
}


#--------------------------------------------------
#Get model mixing weights
#--------------------------------------------------
mixingwts.openbt = function(
  fit=NULL,
  x.test=NULL,
  tc=2,
  numwts=NULL,
  q.lower=0.025,
  q.upper=0.975
)  
{
  # model type definitions
  MODEL_BT=1
  MODEL_BINOMIAL=2
  MODEL_POISSON=3
  MODEL_BART=4
  MODEL_HBART=5
  MODEL_PROBIT=6
  MODEL_MODIFIEDPROBIT=7
  MODEL_MERCK_TRUNCATED=8
  MODEL_MIXBART=9
  
  model_types = c("mixbart", "mix_emulate")
  #--------------------------------------------------
  # params
  if(is.null(fit)) stop("No fitted model specified!\n")
  if(is.null(x.test)) stop("No prediction points specified!\n")
  if(is.null(numwts)){stop("Missing number of model weights parameter numwts.\n")}
  if(!(fit$model %in% model_types)){stop("Wrong model type! This function is for mixbart.\n")}
  #if(fit$modeltype!=MODEL_MIXBART){stop("Wrong model type! This function is for mixbart.\n")}
  
  nslv=tc
  x.test=as.matrix(x.test)
  p=ncol(x.test)
  n=nrow(x.test)
  xwroot="xw"
  fitroot=".fit"
  if(fit$model == "mixbart"){m = fit$m; mh = fit$mh}else{m = fit$mix_model_args$ntree; mh = fit$mix_model_args$ntreeh}
  if(fit$model != "mixbart"){fitroot = ".fitmix"}
  #--------------------------------------------------
  #write out config file
  fout=file(paste(fit$folder,"/config.mxwts",sep=""),"w")
  writeLines(c(fit$modelname,fit$modeltype,fit$xiroot,xwroot,
               fitroot,paste(fit$nd),paste(m),
               paste(mh),paste(p),paste(numwts),paste(tc)), fout)
  close(fout)
 
  #--------------------------------------------------
  #write out data subsets
  #folder=paste(".",fit$modelname,"/",sep="")
  xlist=split(as.data.frame(x.test),(seq(n)-1) %/% (n/nslv))
  for(i in 1:nslv) write(t(xlist[[i]]),file=paste(fit$folder,"/",xwroot,i-1,sep=""))
  for(i in 1:p) write(fit$xicuts[[i]],file=paste(fit$folder,"/",fit$xiroot,i,sep=""))
  
  #--------------------------------------------------
  #run prediction program
  cmdopt=100 #default to serial/OpenMP
  runlocal=FALSE
  cmd="openbtcli --conf"
  if(Sys.which("openbtcli")[[1]]=="") # not installed in a global location, so assume current directory
    runlocal=TRUE
  
  if(runlocal) cmd="./openbtcli --conf"
  
  cmdopt=system(cmd)
  
  if(cmdopt==101) # MPI
  {
    cmd=paste("mpirun -np ",tc," openbtmixingwts ",fit$folder,sep="")
  }
  
  if(cmdopt==100)  # serial/OpenMP
  { 
    if(runlocal)
      cmd=paste("./openbtmixingwts ",fit$folder,sep="")
    else
      cmd=paste("openbtmixingwts ",fit$folder,sep="")
  }
  
  system(cmd)
  system(paste("rm -f ",fit$folder,"/config.mxwts",sep=""))
  
  
  #--------------------------------------------------
  #format and return
  res=list()
  wt_list = list()
  mean_matrix = sd_matrix = ub_matrix = lb_matrix = med_matrix = matrix(0, nrow = n, ncol = numwts)
  
  #Get the file names for the model weights 
  #--file name for model weight j using processor p is ".wjdrawsp"
  for(j in 1:numwts){
    #Get the files for weight j
    tagname = paste0(".w", j,"draws*")
    fnames=list.files(fit$folder,pattern=paste(fit$modelname,tagname,sep=""),full.names=TRUE)
    
    #Bind the posteriors for weight j across all x points -- npost X n data 
    wt_list[[j]] = do.call(cbind,sapply(fnames,data.table::fread))
    
    #Now populate the summary stat matrices -- n X k matrices
    mean_matrix[,j] = apply(wt_list[[j]], 2, mean)
    sd_matrix[,j] = apply(wt_list[[j]], 2, sd)
    med_matrix[,j] = apply(wt_list[[j]], 2, quantile,0.5)
    lb_matrix[,j] = apply(wt_list[[j]], 2, quantile,q.lower)
    ub_matrix[,j] = apply(wt_list[[j]], 2, quantile,q.upper)
  }
  
  #Save the list of posterior draws -- each list element is an npost X n dataframe 
  res$wdraws = wt_list 
  
  #Get model mixing results
  res$wmean=mean_matrix
  res$wsd=sd_matrix
  res$w.5=med_matrix
  res$w.lower=lb_matrix
  res$w.upper=ub_matrix

  res$q.lower=q.lower
  res$q.upper=q.upper
  res$modeltype=fit$modeltype
  
  class(res)="OpenBT_mixingwts"
  return(res)  
}


#----------------------------------------------
# Model mixing and emulation interface
#----------------------------------------------
openbt.mix_emulate = function(
mix_model_data = list(y_train = NULL, x_train = NULL),
emu_model_data = list('model1'=list(z_train = NULL, x_train = NULL),'model2'=list(z_train = NULL, x_train = NULL)),
mix_model_args = list('ntree'=10,'ntreeh'=1,'k'=2,'overallnu'=10,'overallsd'=NA,'power'=2.0,'base'=0.95,'powerh'=NA,'baseh'=NA),
emu_model_args = matrix(c(100,1,2,10,NA,2.0,0.95,NA,NA), nrow = 2, ncol = 9,byrow = TRUE, 
                        dimnames = list(paste0('model',1:2),c('ntree','ntreeh','k','overallnu','overallsd','power','base','powerh','baseh'))),
discrep_model_args = list('k' = 10, 'beta0' = NA),
ndpost=1000, nskip=100,nadapt=1000,adaptevery=100,
pbd=.7,
pb=.5,
stepwpert=.1,
probchv=.1,
minnumbot=5,
tc=2,
printevery=100,
numcut=100,
xicuts=NULL,
sigmav_list=NULL,
chv_list = NULL,
summarystats = FALSE,
model=NULL,
modelname="model"
#sigmav=rep(1,length(y.train)),
#chv = cor(x.train,method="spearman"),
)
{
#--------------------------------------------------
# model type definitions and check default arguments
modeltype=0
MODEL_MIX_EMULATE=1 #Full problem 
MODEL_MIX_ORTHOGONAL=2 # Full problem with orthogonal discrepancy

modeltype_list = c('mix_emulate','mix_orthogonal')

if(is.null(model)){
  stop(cat("Enter a model type. Valid types include:\n", paste(modeltype_list,collapse = ', ')))
} 

if(!(model %in% modeltype_list)){
  stop(cat("Invalid model type. Valid types include:\n", paste(modeltype_list,collapse = ', ')))
}
  
if(model == 'mix_emulate'){
  modeltype = MODEL_MIX_EMULATE
  if(is.null(mix_model_args$overallsd)) ntreeh=1
}
  
#--------------------------------------------------
# Define terms
nd = ndpost
burn = nskip
nummodels = length(emu_model_data)

#--------------------------------------------------
# Process the data 
# Model mixing data
if(is.null(mix_model_data$x_train) || is.null(mix_model_data$y_train)){
  stop('Invalid model mixing inputs. Either x_train or y_train is NULL.')
} 

# Cast x_train data to matrix 
if(!is.matrix(mix_model_data$x_train)){
  mix_model_data$x_train = matrix(is.null(mix_model_data$x_train), ncol = 1) 
}

# Define terms 
n = nrow(mix_model_data$x_train)
p = ncol(mix_model_data$x_train)
ymean = mean(mix_model_data$y_train)

# Emulation data
nc_vec = 0
pc_vec = 0
for(l in 1:nummodels){
  
  if(is.null(emu_model_data[[l]]$x_train) || is.null(emu_model_data[[l]]$z_train)){
    stop(paste0('Invalid emulation inputs. Either x_train or y_train is NULL in model ', l,'.'))
  } 
  
  # Cast the x_train data to matrix
  if(!is.matrix(mix_model_data$x_train)){
    emu_model_data[[l]]$x_train = matrix(is.null(emu_model_data[[l]]$x_train), ncol = 1) 
  }
  
  # Define terms
  nc_vec[l] = nrow(emu_model_data[[l]]$x_train)
  pc_vec[l] = ncol(emu_model_data[[l]]$x_train)
  
} 

# Get means of the model runs and mean center the data
zmean_vec = 0
for(l in 1:nummodels){
  zmean_vec[l] = mean(emu_model_data[[l]]$z_train)
  emu_model_data[[l]]$z_train = emu_model_data[[l]]$z_train - zmean_vec[l]
}

#--------------------------------------------------
# cutpoints
# get joint input matrix 
col_list1 = colnames(mix_model_data$x_train)
col_list2 = unique(unlist(lapply(emu_model_data, function(x) colnames(x$x_train))))

if(sum(sort(col_list1) != sort(col_list2))>0){
  stop(cat("The input variables in model mixing differ from the input variables in emulation.", 
           "\nModel Mixing Inputs: \n", col_list1, 
           "\nAll Emulation Inputs: \n", col_list2))
}

# Create a master list of inputs -- includes all from field obs and computer models
x_matrix = mix_model_data$x_train
xc_col_list = list()
for(l in 1:nummodels){
  # get matrix and Fill columns that are not present with NA
  x_new = matrix(0, nrow = nc_vec[l], ncol = p, dimnames = list(NULL, col_list1))
  xc_cols = 0
  ind = 1
  for(j in 1:length(col_list1)){
    cname = col_list1[j]
    if(cname %in% colnames(emu_model_data[[l]]$x_train)){
      # Add the corresponding data to the x_matrix
      x_new[,cname] = emu_model_data[[l]]$x_train[,cname]
      # Keep track of which columns are in the inputs for the lth computer model
      xc_cols[ind] = j 
      ind = ind + 1
    }else{
      # If the predictor is not in the input space of lth computer model, then just use NA in the x_matrix 
      x_new[,cname] = rep(NA, nc_vec[l])
    }
  }
  xc_col_list = append(xc_col_list, list(xc_cols))
  x_matrix = rbind(x_matrix, x_new)  
}
names(xc_col_list) = paste0('model',1:nummodels)

# Use x_matrix to create cutpoints
if(!is.null(xicuts)){
  xi=xicuts
}else{
  xi=vector("list",p)
  minx_temp=apply(t(x_matrix),1,function(x) min(x, na.rm = TRUE))
  maxx_temp=apply(t(x_matrix),1,function(x) max(x, na.rm = TRUE))
  
  maxx = round(maxx_temp,1) + ifelse((round(maxx_temp,1)-maxx_temp)>0,0,0.1)
  minx = round(minx_temp,1) - ifelse((minx_temp - round(minx_temp,1))>0,0,0.1)
  for(i in 1:p){
    xinc=(maxx[i]-minx[i])/(numcut+1)
    xi[[i]]=(1:numcut)*xinc+minx[i]
  }
}

#------------------------------------------------
# Priors
#------------------------------------------------
# Model Mixing
# -- Terminal node parameters
rgy = range(mix_model_data$y_train)
m = mix_model_args$ntree
k = mix_model_args$k

tau_disc = (rgy[2]-rgy[1])/(2*sqrt(m)*discrep_model_args$k)
tau_wts =  (1)/(2*sqrt(m)*k)
beta_wts = 1/(2*m)
if(is.na(discrep_model_args$beta0)){
  beta_disc = mean(mix_model_data$y_train)/m
}else{
  beta_disc = discrep_model_args$beta0/m
}

# -- Error variance
if(is.na(mix_model_args$overallsd)){
  mix_model_args$overallsd = sd(mix_model_data$y_train)
}
overalllambda_mix = mix_model_args$overallsd^2
overallnu_mix = mix_model_args$overallnu

# -- Tree prior (mean and variance trees)
power_mix = mix_model_args$power
base_mix = mix_model_args$base
powerh_mix = mix_model_args$powerh
baseh_mix = mix_model_args$baseh

if(is.na(powerh_mix)){
  powerh_mix=power_mix
}
if(is.na(baseh_mix)){
  baseh_mix=base_mix
}

# Emulation with BART
tau_emu = 0
base_emu = baseh_emu = 0
power_emu = powerh_emu = 0
overalllambda_emu = overallnu_emu = 0
for(l in 1:nummodels){
  # -- Terminal node parameters
  m = emu_model_args[l,'ntree']
  k = emu_model_args[l,'k']
  rgz = range(emu_model_data[[l]]$z_train)
  tau_emu[l] = (rgz[2]-rgz[1])/(2*sqrt(m)*k)
  
  # -- Error variance
  if(is.na(emu_model_args[l,'overallsd'])){
    emu_model_args[l,'overallsd'] = sd(emu_model_data[[l]]$z_train)
  }
  overalllambda_emu[l] = emu_model_args[l,'overallsd']^2
  overallnu_emu[l] = emu_model_args[l,'overallnu']
  
  # -- Tree prior (mean and variance trees)
  power_emu[l] = emu_model_args[l,'power']
  base_emu[l] = emu_model_args[l,'base']
  powerh_emu[l] = emu_model_args[l,'powerh']
  baseh_emu[l] = emu_model_args[l,'baseh']
  
  if(is.na(powerh_emu[l])) {
    powerh_emu[l] = power_emu[l]
  }
  if(is.na(baseh_emu[l])) {
    baseh_emu[l]=base_emu[l]
  }
}

#--------------------------------------------------
# Birth and death probability
pbdh=pbd
pbh=pb
if(length(pbd)>1) {
  pbdh=pbd[2]
  pbd=pbd[1]
}
if(length(pb)>1) {
  pbh=pb[2]
  pb=pb[1]
}


#--------------------------------------------------
# Process other arguments
#--------------------------------------------------
stepwperth=stepwpert
if(length(stepwpert)>1) {
  stepwperth=stepwpert[2]
  stepwpert=stepwpert[1]
}

probchvh=probchv
if(length(probchv)>1) {
  probchvh=probchv[2]
  probchv=probchv[1]
}

minnumboth=minnumbot
if(length(minnumbot)>1) {
  minnumboth=minnumbot[2]
  minnumbot=minnumbot[1]
}

# Set default argument for the sigmavs
if(is.null(sigmav_list)){
  for(l in 0:nummodels){
    sigmav_n = ifelse(l == 0, n, nc_vec[l]+n)
    sigmav_list[[l+1]] = rep(1,sigmav_n)
  }
}else{
  if(!is.list(sigmav_list)){
    stop("Invalid data type: sigmav_list must be a list object with length K+1.")
  }
  for(l in 0:nummodels){
    sigmav_n = ifelse(l == 0, n, nc_vec[l]+n)
    if(length(sigmav_list[[l+1]]) != sigmav_n){
      stop(cat("Invalid sigmav_list entry at item",l+1,"\n Length of sigmav_list[[l]] is incorrect. Required lengths are listed below: \n",
               "\t Mixing (l=1): ", n, " (number of field obs) \n",
               "\t Emulation (l>1): ", n + nc_vec[l+1], " (number of field obs + number of model runs))"))  
    }
    
  }
}

# Set the default argument for the chvs
if(is.null(chv_list)){
  for(l in 0:nummodels){
    if(l == 0){
      chv_data = mix_model_data$x_train   
    }else{
      xmixtemp = mix_model_data$x_train[,unlist(xc_col_list[l])]
      if(length(unlist(xc_col_list[l])) == 1){xmixtemp = matrix(xmixtemp,ncol = 1)}
      chv_data = rbind(emu_model_data[[l]]$x_train, xmixtemp)  
    }
    chv_list[[l+1]] = cor(chv_data,method="spearman")
  }  
}else{
  if(!is.list(chv_list)){
    stop("Invalid data type: chv_list must be a list object with length K+1.")
  }
  for(l in 0:nummodels){
    chv_p = ifelse(l == 0, p, pc_vec[l])
    if(chv_list[[l+1]] != chv_p){
      stop(paste0("Invalid chv_list entry at item k = ",l+1,". Number of rows & columns in chv_list[[k]] must match",
          " the number of columns in the design matrix for emulator k-1. If k = 1, then the number of rows & columns in", 
          " chv_list[[1]] must match the number of columns in the design matrix for the field observations."))  
    }
  }
}

#--------------------------------------------------
# Print statements
#--------------------------------------------------
if(modeltype==MODEL_MIX_EMULATE){
  cat("Model: KOH Bayesian Additive Model Mixing Trees\n")
}
if(modeltype==MODEL_MIX_ORTHOGONAL){
  cat("Model: Orthogonal Bayesian Additive Model Mixing Trees\n")
}

#--------------------------------------------------
#write out config file
#--------------------------------------------------
# Field data roots
yroots="yf"
xroots=c("xf",paste0("xc",1:nummodels))
zroots=paste0("zc",1:nummodels)
sroots=c("sf",paste0("sc",1:nummodels))
chgvroots=c("chgvf",paste0("chgvc",1:nummodels))
idroots="id"

# cut points root
xiroot="xi"

# Design column numbers for computer models
xc_design_cols = 0
h = 1
# Format -- number of cols for model 1, col numbers for model 1,...,number of cols for model K, col numbers for model K 
for(l in 1:nummodels){
  xc_design_cols[h] = paste(pc_vec[l])
  xc_design_cols[(h+1):(h+pc_vec[l])] = paste(xc_col_list[[l]])
  h = h+pc_vec[l] + 1
}

# Flatten the model arguments
m_vec = paste(c(mix_model_args$ntree, emu_model_args[,'ntree']))
mh_vec = paste(c(mix_model_args$ntreeh, emu_model_args[,'ntreeh']))
tau_vec = paste(c(tau_disc, tau_wts, tau_emu)) #Two mixing parameters, K emu parameters
beta_vec = paste(c(beta_disc, beta_wts)) #Only mixing parameters
base_vec = paste(c(base_mix, base_emu))
baseh_vec = paste(c(baseh_mix, baseh_emu))
power_vec = paste(c(power_mix, power_emu))
powerh_vec = paste(c(powerh_mix, powerh_emu))
lambda_vec = paste(c(overalllambda_mix, overalllambda_emu))
nu_vec = paste(c(overallnu_mix, overallnu_emu))
means_vec = c(ymean,zmean_vec)

# Bind all of the K+1 dimensional vectors together into one matrix
# Then flatten by row -- this makes things easier when reading in the data in c++
# This way, we read in all data for mixing, then read in the data for each emulator one at a time
info_matrix = data.frame(xroots, yzroots = c(yroots,zroots),sroots,chgvroots,means = paste(means_vec),
                         m_vec, mh_vec, base_vec, baseh_vec, power_vec, powerh_vec, lambda_vec, nu_vec)

info_vec = unlist(as.vector(t(info_matrix)))
  
# Creating temp directory and config file
folder=tempdir(check=TRUE)
if(!dir.exists(folder)) dir.create(folder)
tmpsubfolder=tempfile(tmpdir="")
tmpsubfolder=substr(tmpsubfolder,5,nchar(tmpsubfolder))
tmpsubfolder=paste("openbt",tmpsubfolder,sep="")
folder=paste(folder,"/",tmpsubfolder,sep="")
if(!dir.exists(folder)) dir.create(folder)
fout=file(paste(folder,"/config",sep=""),"w")

# Write lines to the config file fout
# writeLines(c(paste(modeltype),paste(nummodels),
#              xroots,yroot,zroots,sroots,chgvroots,paste(zmean_vec),xc_design_cols,
#              paste(nd),paste(burn),paste(nadapt),paste(adaptevery),
#              m_vec,mh_vec,tau_vec,beta_vec,lambda_vec,nu_vec,base_vec,power_vec,baseh_vec,powerh_vec, 
#              paste(pbd),paste(pb),paste(pbdh),paste(pbh),paste(stepwpert),paste(stepwperth),
#              paste(probchv),paste(probchvh),paste(minnumbot),paste(minnumboth),
#              paste(printevery),paste(xiroot),paste(tc),paste(modelname),paste(summarystats)),fout)

writeLines(c(paste(modeltype),paste(nummodels),info_vec,xc_design_cols,
             paste(nd),paste(burn),paste(nadapt),paste(adaptevery),
             tau_vec,beta_vec,
             paste(pbd),paste(pb),paste(pbdh),paste(pbh),paste(stepwpert),paste(stepwperth),
             paste(probchv),paste(probchvh),paste(minnumbot),paste(minnumboth),
             paste(printevery),paste(xiroot),paste(tc),paste(modelname),paste(summarystats)),fout)
close(fout)

#--------------------------------------------------
#write out data subsets
#--------------------------------------------------
nslv=tc-1
# Model Mixing data
ylist=split(mix_model_data$y_train,(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(ylist[[i]],file=paste(folder,"/",yroots,i,sep=""))

xlist=split(as.data.frame(mix_model_data$x_train),(seq(n)-1) %/% (n/nslv))
for(i in 1:nslv) write(t(xlist[[i]]),file=paste(folder,"/",xroots[1],i,sep=""))

# Emulation Data
#idlist = vector(mode='list', length = nslv)
for(l in 1:nummodels){
  zlist=split(emu_model_data[[l]]$z_train,(seq(nc_vec[l])-1) %/% (nc_vec[l]/nslv))
  for(i in 1:nslv) write(zlist[[i]],file=paste(folder,"/",zroots[l],i,sep=""))
  
  xlist=split(as.data.frame(emu_model_data[[l]]$x_train),(seq(nc_vec[l])-1) %/% (nc_vec[l]/nslv))
  for(i in 1:nslv) write(t(xlist[[i]]),file=paste(folder,"/",xroots[l+1],i,sep=""))  
}

# Write the ids per mpi
#for(i in 1:nslv) write(t(idlist[[i]]),file=paste(folder,"/",idroots,i,sep=""))

# Variance and rotation data
for(l in 0:nummodels){
  ntemp = ifelse(l==0, n, nc_vec[l]+n)
  slist=split(sigmav_list[[l+1]],(seq(ntemp)-1) %/% (ntemp/nslv))
  for(i in 1:nslv) write(slist[[i]],file=paste(folder,"/",sroots[l+1],i,sep=""))
  
  chv_list[[l+1]][is.na(chv_list[[l+1]])]=0 # if a var as 0 levels it will have a cor of NA so we'll just set those to 0.
  write(chv_list[[l+1]],file=paste(folder,"/",chgvroots[l+1],sep=""))
}

# Cutpoints
for(i in 1:p) write(xi[[i]],file=paste(folder,"/",xiroot,i,sep=""))
rm(chv_list)

#--------------------------------------------------
#run program
#--------------------------------------------------
cmdopt=100 #default to serial/OpenMP
runlocal=FALSE
cmd="openbtmixing --conf"
if(Sys.which("openbtmixing")[[1]]=="") # not installed in a global location, so assume current directory
  runlocal=TRUE

if(runlocal) cmd="./openbtmixing --conf"

cmdopt=system(cmd)

if(cmdopt==101) # MPI
{
  cmd=paste("mpirun -np ",tc," openbtmixing ",folder,sep="")
}

if(cmdopt==100)  # serial/OpenMP
{ 
  if(runlocal)
    cmd=paste("./openbtmixing ",folder,sep="")
  else
    cmd=paste("openbtmixing ",folder,sep="")
}

system(cmd)
#system(paste("rm -f ",folder,"/config",sep=""))

# Collect results
res=list()
res$modeltype=modeltype; res$model=model
res$xroot=xroots; res$yroot=yroots; res$zroots=zroots;res$sroot=sroots; res$chgvroot=chgvroots; res$xc_col_list=xc_col_list
res$means = means_vec; res$nummodels = nummodels;
res$nd=nd; res$burn=burn; res$nadapt=nadapt; res$adaptevery=adaptevery; 
res$mix_model_args = mix_model_args; res$emu_model_args = emu_model_args;
res$pbd=pbd; res$pb=pb; res$pbdh=pbdh; res$pbh=pbh; res$stepwpert=stepwpert; res$stepwperth=stepwperth
res$probchv=probchv; res$probchvh=probchvh; res$minnumbot=minnumbot; res$minnumboth=minnumboth
res$printevery=printevery; res$xiroot=xiroot; res$minx=minx; res$maxx=maxx;
res$summarystats=summarystats; res$tc=tc; res$modelname=modelname
class(xi)="OpenBT_cutinfo"
res$xicuts=xi
res$folder=folder
class(res)="OpenBT_posterior"

#res$k=k_vec; res$m=m_vec; res$mh=mh_vec;res$tau=tau_vec; res$beta_vec=beta_vec; res$overalllambda=lambda_vec; res$overallnu=nu_vec; 
#res$base=base_vec; res$power=power_vec; res$baseh=baseh_vec; res$powerh=powerh_vec 

return(res)

}

# Predict function for mixing and emulation
openbt.predict_mix_emulate = function(fit=NULL, x_test=NULL,tc=2,q.lower=0.025,q.upper=0.975){
  # model type definitions
  MODEL_MIX_EMULATE=1 #Full problem 
  MODEL_MIX_ORTHOGONAL=2 # Full problem with orthogonal discrepancy
  
  #--------------------------------------------------
  # Define objects
  if(is.null(fit)) stop("No fitted model specified!\n")
  if(is.null(x_test)) stop("No prediction points specified for !\n")
  nslv=tc
  means_vec=fit$means
  p=ncol(x_test)
  n=nrow(x_test)
  nummodels = fit$nummodels
  xproot = 'xp'
  
  x_test=as.matrix(x_test)
  x_col_list = fit$xc_col_list
  
  #--------------------------------------------------
  # Flatten any vector arguments that need to be passed to pred
  # Design column numbers for computer models -- flattens the x_col_list
  xc_design_cols = 0
  h = 1
  # Format -- number of cols for model 1, col numbers for model 1,...,number of cols for model K, col numbers for model K 
  for(l in 1:nummodels){
    pc = length(x_col_list[[l]])
    xc_design_cols[h] = paste(pc)
    xc_design_cols[(h+1):(h+pc)] = paste(fit$xc_col_list[[l]])
    h = h + pc + 1
  }
  
  # Flatten the m and mh vectors
  mvec = fit$mix_model_args$ntree
  mvec[2:(nummodels+1)] = fit$emu_model_args[,'ntree']
  mhvec = fit$mix_model_args$ntreeh
  mhvec[2:(nummodels+1)] = fit$emu_model_args[,'ntreeh']
  
  # Create an info matrix and vector of arguments that are required for the individual models
  info_matrix = data.frame(means = paste(means_vec),mvec, mhvec)
  info_vec = unlist(as.vector(t(info_matrix)))
  
  #--------------------------------------------------
  #write out config file
  fout=file(paste(fit$folder,"/config.pred",sep=""),"w")
  writeLines(c(fit$modelname,fit$modeltype,fit$xiroot,xproot,
               paste(fit$nd),paste(nummodels),paste(p),paste(tc),
               info_vec,xc_design_cols), fout)
  close(fout)
  
  #--------------------------------------------------
  #write out data subsets
  #folder=paste(".",fit$modelname,"/",sep="")
  xlist=split(as.data.frame(x_test),(seq(n)-1) %/% (n/nslv))
  for(i in 1:nslv) write(t(xlist[[i]]),file=paste(fit$folder,"/",xproot,i-1,sep=""))
  for(i in 1:p) write(fit$xicuts[[i]],file=paste(fit$folder,"/",fit$xiroot,i,sep=""))
  
  #--------------------------------------------------
  #run prediction program
  cmdopt=100 #default to serial/OpenMP
  runlocal=FALSE
  cmd="openbtcli --conf"
  if(Sys.which("openbtcli")[[1]]=="") # not installed in a global location, so assume current directory
    runlocal=TRUE
  
  if(runlocal) cmd="./openbtcli --conf"
  
  cmdopt=system(cmd)
  
  if(cmdopt==101) # MPI
  {
    cmd=paste("mpirun -np ",tc," openbtmixingpred ",fit$folder,sep="")
  }
  
  if(cmdopt==100)  # serial/OpenMP
  { 
    if(runlocal)
      cmd=paste("./openbtmixingpred ",fit$folder,sep="")
    else
      cmd=paste("openbtmixingpred ",fit$folder,sep="")
  }
  
  #cmd=paste("mpirun -np ",tc," openbtpred",sep="")
  #cat(cmd)
  system(cmd)
  system(paste("rm -f ",fit$folder,"/config.pred",sep=""))
  
  #--------------------------------------------------
  #format and return
  res_model=vector(mode = 'list', length = nummodels+2)
  names(res_model) = c("mixmodel", paste0("emulator",1:nummodels),"Information")
  res = vector(mode = 'list', length = 2)
  names(res) = c('mdraws', 'sdraws')
  
  fnames=list.files(fit$folder,pattern=paste(fit$modelname,".mdraws*",sep=""),full.names=TRUE)
  res$mdraws=do.call(cbind,sapply(fnames,data.table::fread))
  fnames=list.files(fit$folder,pattern=paste(fit$modelname,".sdraws*",sep=""),full.names=TRUE)
  res$sdraws=do.call(cbind,sapply(fnames,data.table::fread))
  
  #Separate results into mixing vs emulation
  for(i in 0:nummodels){
    # Initialize the list elements
    res_model[[i+1]] = vector(mode = 'list', length = 12)
    names(res_model[[i+1]]) = paste0(rep(c("m","s"),6),
                                    rep(c('draws','mean','sd','.5','.lower','.upper'),each = 2))
    ind = seq(i*fit$nd+1, (i+1)*fit$nd, 1)

    # Summarize the data for the selected model
    res_model[[i+1]]$mdraws = res$mdraws[ind,]
    res_model[[i+1]]$sdraws = res$sdraws[ind,]
    res_model[[i+1]]$mmean=apply(res_model[[i+1]]$mdraws,2,mean)
    res_model[[i+1]]$smean=apply(res_model[[i+1]]$sdraws,2,mean)
    res_model[[i+1]]$msd=apply(res_model[[i+1]]$mdraws,2,sd)
    res_model[[i+1]]$ssd=apply(res_model[[i+1]]$sdraws,2,sd)
    res_model[[i+1]]$m.5=apply(res_model[[i+1]]$mdraws,2,quantile,0.5)
    res_model[[i+1]]$s.5=apply(res_model[[i+1]]$sdraws,2,quantile,0.5)
    res_model[[i+1]]$m.lower=apply(res_model[[i+1]]$mdraws,2,quantile,q.lower)
    res_model[[i+1]]$s.lower=apply(res_model[[i+1]]$sdraws,2,quantile,q.lower)
    res_model[[i+1]]$m.upper=apply(res_model[[i+1]]$mdraws,2,quantile,q.upper)
    res_model[[i+1]]$s.upper=apply(res_model[[i+1]]$sdraws,2,quantile,q.upper)
  }
  
  res_model[[nummodels+2]] = list(q.lower=q.lower,q.upper=q.upper,modeltype=fit$modeltype)
  rm(res)
  class(res_model)="OpenBT_predict"
  
  return(res_model)
}

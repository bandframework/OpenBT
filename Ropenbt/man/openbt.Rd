\name{openbt}
\alias{openbt}
%\docType{package}
\title{Interface to Bayesian Regression Tree models in OpenBT.}
\description{
  The function \code{openbt()} is the main function for fitting Bayesian Regression Tree models that are provided in the OpenBT project.  
}
\usage{
openbt(x.train, y.train, f.train = matrix(1, nrow=length(y.train), ncol = 2), ntree=NULL,
     ntreeh=NULL, ndpost=1000, nskip=100, k=NULL, power=2.0, base=.95, tc=2, 
     sigmav=rep(1,length(y.train)), f.sd.train = NULL, wts.prior.info = NULL,
     fmean=mean(y.train), overallsd = NULL, overallnu=NULL, 
     chv = cor(x.train,method="spearman"), pbd=.7, pb=.5, stepwpert=.1, probchv=.1,
     minnumbot=5, printevery=100, numcut=100, xicuts=NULL, nadapt=1000, adaptevery=100,
     summarystats=FALSE,truncateds=NULL,model=NULL,modelname="model")
}
\arguments{
  \item{x.train}{nxp matrix of predictor variables for the training data.}
  \item{y.train}{nx1 vector of the observed response for the training data.}
  \item{f.train}{For eventual model mixing support.}
  \item{ntree}{Number of trees used for the mean model.}
  \item{ntreeh}{Number of trees used for the variance model.}
  \item{ndpost}{Number of iterations to run the MCMC algorithm after burn-in.}
  \item{nskip}{Number of MCMC iterations treated as burn-in and discarded.}
  \item{k}{Prior hyperparameter for the mean model.}
  \item{power}{Power parameter in the tree depth penalizing prior.}
  \item{base}{Base parameter in the tree depth penalizing prior.}
  \item{tc}{Number of OpenMP threads to use.}
  \item{sigmav}{Initialization of square-root of variance parameter.}
  \item{f.sd.train}{For eventual model mixing support.}
  \item{wts.prior.info}{For eventual model mixing support.}
  \item{fmean}{Overall mean of the data for pre-centering the data before running the model.}
  \item{overallsd}{A rudimentary estimate of the process standard deviation. Used in calibrating the variance prior.}
  \item{overallnu}{Shape parameter for the variance prior.}
  \item{chv}{Predictor correlation matrix used as a pre-conditioner for MCMC change-of-variable proposals.}
  \item{pbd}{Probability of performing a birth/death proposal, otherwise perform a rotate proopsal.}
  \item{pb}{Probability of performing a birth proposal given that we choose to perform a birth/death proposal.}
  \item{stepwpert}{Initial width of proposal distribution for peturbing cutpoints.}
  \item{probchv}{Probability of performing a change-of-variable proposal.  Otherwise, only do a perturb proposal}.
  \item{minnumbot}{Minimum number of observations required in bottom (terminal) nodes.}
  \item{printevery}{Outputs MCMC algorithm status every printevery iterations.}
  \item{numcut}{Number of cutpoints to use for each predictor variable.}
  \item{xicuts}{More detailed construction of cutpoints can be specified using makecuts() and passed as an argument here.}
  \item{nadapt}{Number of MCMC iterations allowed for adaptive MCMC. These are also discarded.}
  \item{adaptevery}{Adapt MCMC proposal distributions every adaptevery iterations until the algorithm has run for nadapt iterations.}
  \item{summarystats}{Return detailed summary statistics about the fitting procedure.}
  \item{truncateds}{For using the truncated Gaussian model contributed by Dai Feng.}
  \item{model}{Specifies the model type.  Options include 'bt','binomial','poisson','bart','hbart','probit','modifiedprobit' and 'merck_truncated'.}
  \item{modelname}{A user-specified string that names their model, such as myExampleModel.}
}
\details{
  \code{openbt()} is the main model fitting function for continuous and dichotomous response data.  
  The most common models to fit are a homoscedastic single-tree model, a homoscedastic BART model and a heteroscedastic BART model.

  For a BART model, set \code{pbd=c(0.7,0.0)} and \code{ntreeh=1}.  This forces a scalar (homoscedastic) variance term.

  For a single-tree model, set \code{pbd=(0.7,0.0)}, \code{ntreeh=1} and \code{ntree=1}. This forces the mean component to be modeled using only one tree.

  Examples are available on the OpenBT wiki page.
}
\value{
  \item{res}{Fitted model object of S3 class OpenBT_posterior.}
}
\references{
  Chipman, Hugh A., George, Edward I., and McCulloch, Robert E. (2010)
  BART: Bayesian additive regression trees. 
  \emph{The Annals of Applied Statistics}, \bold{4}, 266--298.
}
\author{
Matthew T. Pratola <mpratola@iu.edu> [aut, cre, cph]
Maintainer: Matthew T. Pratola <mpratola@iu.edu>
}
\seealso{
\code{\link{predict.openbt}}
}
\examples{
\dontrun{
  remotes::install_bitbucket("mpratola/openbt/Ropenbt")
  library(Ropenbt)

  # Test Branin function, rescaled
  braninsc <- function(xx)
  {  
    x1 <- xx[1]
    x2 <- xx[2]

    x1bar <- 15*x1 - 5
    x2bar <- 15 * x2

    term1 <- x2bar - 5.1*x1bar^2/(4*pi^2) + 5*x1bar/pi - 6
    term2 <- (10 - 10/(8*pi)) * cos(x1bar)

    y <- (term1^2 + term2 - 44.81) / 51.95
    return(y)
  }

  # Simulate branin data for testing
  set.seed(99)
  n=500
  p=2
  x = matrix(runif(n*p),ncol=p)
  y=rep(0,n)
  for(i in 1:n) y[i] = braninsc(x[i,])

  # Fit BART model
  fit=openbt(x,y,tc=4,model="bart",modelname="branin")
  summary(fit)
}
}
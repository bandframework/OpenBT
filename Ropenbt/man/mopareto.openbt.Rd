\name{mopareto.openbt}
\alias{mopareto.openbt}
%\docType{package}
\title{Pareto Front Multiobjective Optimization for OpenBT regression models.}
\description{
  The function \code{mopareto.openbt()} calculates the Pareto front and set for 2 fitted Bayesian tree models.  Supports continuous response BART or single tree models.
}
\usage{
\method{mopareto}{openbt}(
fit1,
fit2,
fit3,
q.lower=0.025,
q.upper=0.975,
tc=2)
}
\arguments{
  \item{fit1}{First object of type \code{OpenBT_posterior} from a previous call to \code{openbt()}}
  \item{fit2}{Second object of type \code{OpenBT_posterior} from a previous call to \code{openbt()}}
  \item{fit3}{Optionally, a third object of type \code{OpenBT_posterior} from a previous call to \code{openbt()}}
  \item{q.lower}{Lower quantile to return.}
  \item{q.upper}{Upper quantile to return.}
  \item{tc}{Number of cores to use for parallel computing.}
}
\details{
  \code{mopareto.openbt()} calculates the Pareto front and set for a pair (optionally, a 3-tuple) of Bayesian regression tree models that have been fit by \code{openbt()}.  

  Returns an object of type \code{OpenBT_mopareto} which is a length ndpost list with each list entry consisting of the following matrices:
}
\value{
  \item{theta}{Posterior realization of the predicted values along the Pareto front. Stored in a 2-row matrix whose number of columns corresponds to the number of hyperrectangles on the Pareto front.}
  \item{a}{Posterior realization of the lower-left corner of a hyperrectangle on the Pareto front.  Stored in a p-row matrix whose number of columns corresponds to the number of hyperrectangles on the Pareto front.}
  \item{b}{Posterior realization of the upper-right corner of a hyperrectangle on the Pareto front.  Stored in a p-row matrix whose number of columns corresponds to the number of hyperrectangles on the Pareto front.}
}
\references{
  Horiguchi, Akira, Santner, Thomas J., Sun, Ying, and Pratola, Matthew T. (2022)
  Using BART to perform Pareto optimization and quantify its uncertainties.
  \emph{Technometrics}, vol.64, 564--574.
}
\author{
Matthew T. Pratola <mpratola@iu.edu> [aut, cre, cph]
Maintainer: Matthew T. Pratola <mpratola@iu.edu>
}
\seealso{
\code{\link{openbt}}
\code{\link{calcMBD}}
\code{\link{calcRS}}
}
\examples{
\dontrun{
  # Example of MO optimization
  fit.a=openbt(x,y,pbd=c(0.7,0.0),ntreeh=1,numcut=20,tc=6,model="bart",modelname="branin-a")
  fit.b=openbt(x,y,pbd=c(0.7,0.0),ntreeh=1,numcut=20,tc=6,model="bart",modelname="branin-b")

  pf=mopareto.openbt(fit.a,fit.b,tc=6)  # quite slow, use many cores to speed it up

  # plot front
  par(mfrow=c(1,2))
  plot(0,0,xlim=c(-2,2),ylim=c(-2,2),type="n",xlab="y1",ylab="y2")
  for(vhr in pf) points(t(vhr$theta),pch=20)

  # plot set
  plot(0,0,xlim=c(0,1),ylim=c(0,1),type="n",xlab="x1",ylab="x2")
  for(vhr in pf) rect(vhr$a[1, ], vhr$a[2, ], vhr$b[1, ], vhr$b[2, ], col=gray(0.5,alpha=0.1), border=NA)

  # More examples found in pareto_example.R
}
}

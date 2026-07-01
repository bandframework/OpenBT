\name{calcRS}
\alias{calcRS}
%\docType{package}
\title{Construct UQ regions for Pareto Front/Set using random sets approach.}
\description{
  The function \code{calcRS()} takes \code{OpenBT_mopareto} object and calculates UQ regions for the estimated Pareto Front and Pareto Set using the random sets approach.
}
\usage{
calcRS(fit,d=2)
}
\arguments{
  \item{fit}{An \code{OpenBT_mopareto} object.}
  \item{d}{The number of responses being considered in the Pareto front/set.  Currently only d=2 responses is supported.}
}
\details{
  \code{calcRS()} calculates the random sets based UQ region for the Pareto front and set calculated using two OpenBT models.  
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
\code{\link{mopareto.openbt}}
}
\examples{
# For example usage, see readthedocs.
}
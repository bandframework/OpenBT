\name{makecuts.openbt}
\alias{makecuts.openbt}
%\docType{package}
\title{Make a variable cuts object to be used in OpenBT regression models.}
\description{
  The function \code{makecuts.openbt()} takes an n by p design matrix and a scalar or vector number of cutpoints per variable, and returns an object of type \code{OpenBT_cutinfo} with the cutpoint information.
}
\usage{
\method{makecuts}{openbt}(x,numcuts)
}
\arguments{
  \item{x}{An n by p design matrix.}
  \item{numcuts}{Can be a scalar (same number of cutpoints for each variable) or vector describing the number of cutpoints per variable.}
}
\details{
  \code{makecuts.openbt()} creates a cutpoint object for an OpenBT model.  

  Returns an object of type \code{OpenBT_cutinfo} which is a length p list, each having a vector describing the cutpoint locations.
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
\code{\link{openbt}}
}
\examples{
# For example usage, see readthedocs.
}
\name{setvarcuts.openbt}
\alias{setvarcuts.openbt}
%\docType{package}
\title{Modify an existing \code{OpenBT_cutinfo} cutpoint object.}
\description{
  The function \code{servarcuts.openbt()} can modify an existing cutpoint object.
}
\usage{
\method{setvarcuts}{openbt}(
xi,
id,
cutvec)
}
\arguments{
  \item{xi}{Object of type \code{OpenBT_cutinfo} created from a previous call to \code{makecuts()}}
  \item{id}{The variable to modify.}
  \item{cutvec}{The new cutpoint vector for variable \code{id}.}
}
\details{
  \code{setvarcuts.openbt()} allows one to modify an existing cutpoint object by replacing the cutpoints for variable \code{id} with a new cutpoint vector given by \code{cutvec}. 

  Returns an object of type \code{OpenBT_cutinfo}.
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

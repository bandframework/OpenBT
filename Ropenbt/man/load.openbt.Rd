\name{openbt.load}
\alias{openbt.load}
%\docType{package}
\title{Load a previously saved OpenBT model.}
\description{
  The function \code{openbt.load()} loads an OpenBT model previously saved using \code{openbt.save()}.
}
\usage{
\method{openbt}{load}(
fname)
}
\arguments{
  \item{fname}{Filename of the OpenBT model to load from disk storage.}
}
\details{
  \code{openbt.load()} loads an OpenBT model that was previously saved using \code{openbt.save()}.

  Returns an object of type \code{OpenBT_posterior}.
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
\dontrun{
  # Load fitted model to a new object.
  fit2=openbt.load("test")
}
}
\name{openbt.save}
\alias{openbt.save}
%\docType{package}
\title{Save a fitted OpenBT model to disk.}
\description{
  The function \code{openbt.save()} will save an OpenBT model to disk.
}
\usage{
\method{openbt}{save}(
post,fname=NULL)
}
\arguments{
  \item{post}{An object of type \code{OpenBT_posterior} to save to disk storage.}
  \item{fname}{The filename to store the saved result.}
}
\details{
  \code{openbt.save()} will save an OpenBT model that was previously fitted using \code{openbt()}.  The data is stored in compressed format and the extension \code{.obt} is automatically appended to the filename \code{fname}.
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
  # Save fitted model as test.obt in the working directory
  openbt.save(fit,"test")
}
}
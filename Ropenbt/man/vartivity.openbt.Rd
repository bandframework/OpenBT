\name{vartivity.openbt}
\alias{vartivity.openbt}
%\docType{package}
\title{Classical variable activity metric for OpenBT regression models.}
\description{
  The function \code{vartivity.openbt()} calculates the classical variable activity metric for Bayesian tree models that is based on counting the number of internal nodes that split on each variable in a dataset.
}
\usage{
\method{vartivity}{openbt}(
fit=NULL,
q.lower=0.025,
q.upper=0.975)
}
\arguments{
  \item{fit}{Object of type \code{OpenBT_posterior} from a previous call to \code{openbt()}}
  \item{q.lower}{Lower quantile to return.}
  \item{q.upper}{Upper quantile to return.}
}
\details{
  \code{vartivity.openbt()} calculates the classical variable activity metric for a Bayesian regression tree model that has been fit by \code{openbt()}.  

  Returns an object of type \code{OpenBT_vartivity} with the following entries.
}
\value{
  \item{vdraws}{Posterior realizations of the split proportions for each variable in the mean model, stored in an \code{ndpost x npred} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{vdrawsh}{Posterior realizations of the split proportions for each variable in the variance model, stored in an \code{ndpost x npred} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.  When a constant variance model is used, this will be zero.}
  \item{mvdraws}{Posterior mean of the split proportions for the mean model.}
  \item{mvdrawsh}{Posterior mean of the split proportions for the variance model.}
  \item{vdraws.sd}{Posterior standard deviation of the split proportions for the mean model.}
  \item{vdrawsh.sd}{Posterior standard deviation of the split proportions for the variance model.}
  \item{vdraws.5}{Posterior median of the split proportions for the mean model.}
  \item{vdrawsh.5}{Posterior median of the split proportions for the mean model.}
  \item{vdraws.lower}{Posterior \code{q.lower} quantile of the split proportions for the mean model.}
  \item{vdraws.upper}{Posterior \code{q.upper} quantile of the split proportions for the mean model.}
  \item{vdrawsh.lower}{Posterior \code{q.lower} quantile of the split proportions for the variance model.}
  \item{vdrawsh.upper}{Posterior \code{q.upper} quantile of the split proportions for the variance model.}
  \item{q.lower}{The lower quantile used.}
  \item{q.upper}{The upper quantile used.}
  \item{modeltype}{The type of model fitted by \code{openbt()}.}
}
\references{
  Chipman, Hugh A., George, Edward I., and McCulloch, Robert E. (2010)
  BART: Bayesian additive regression trees. 
  \emph{The Annals of Applied Statistics}, \bold{4}, 266--298.

  Horiguchi, Akira, Pratola, Matthew T. and Santner, Thomas J. (2020)
  Assessing Variable Activity for Bayesian Regression Trees.
  \emph{Reliability Engineering and System Safety}, \bold{207}, 107391.
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
  # Calculate variable activity information
  fitv=vartivity.openbt(fit2)

  # Plot variable activity
  plot(fitv)
}
}
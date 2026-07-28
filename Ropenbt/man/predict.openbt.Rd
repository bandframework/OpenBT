\name{predict.openbt}
\alias{predict.openbt}
%\docType{package}
\title{Drawing Posterior Predictive Realizations for OpenBT regression models.}
\description{
  The function \code{predict.openbt()} is the main function for drawing posterior predictive realizations at new inputs using a fitted model stored in an \code{OpenBT_posterior} object returned from \code{openbt()}.
}
\usage{
\method{predict}{openbt}(
object=NULL,
x.test=NULL,
f.test=matrix(1, nrow = 1, ncol = 2),
tc=2,
fmean=fit$fmean,
q.lower=0.025,
q.upper=0.975, ...)
}
\arguments{
  \item{object}{Object of type \code{OpenBT_posterior} from a previous call to \code{openbt()}}
  \item{x.test}{New input settings in the form of an \code{npred x p} matrix at which to construct predictions.  Defaults to the training inputs.}
  \item{f.test}{For eventual model mixing support.}
  \item{tc}{Number of CPU cores to use for parallel computing.}
  \item{fmean}{Mean-centering vector for the training data.  Defaults to the value used by \code{openbt()} when fitting the model.  Usually should be left to the default.}
  \item{q.lower}{Lower quantile to return.}
  \item{q.upper}{Upper quantile to return.}
  \item{...}{Additional arguments for S3 compatibility (currently unused).}
}
\details{
  \code{predict.openbt()} is the main function for calculating posterior predictions and uncertainties once a model has been fit by \code{openbt()}.  

  Returns an object of type \code{OpenBT_predict} with the following entries.
}
\value{
  \item{mdraws}{Posterior realizations of the mean function, \eqn{f({\bf x})}{f(x)} stored in an \code{ndpost x npred} matrix,
    where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{sdraws}{Posterior realizations of the standard deviation function, \eqn{s({\bf x})}{s(x)} stored in an \code{ndpost x npred} matrix,
    where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{mmean}{Posterior predictive mean of \eqn{f({\bf x})}{f(x)}.}
  \item{smean}{Posterior predictive mean of the standard deviation, \eqn{s({\bf x})}{s(x)}.}
  \item{msd}{Posterior standard deviation of the mean, \eqn{f({\bf x})}{f(x)}.}
  \item{ssd}{Posterior standard deviation of the standard deviation, \eqn{s({\bf x})}{s(x)}.}
  \item{m.5}{Posterior median of the mean function realizations, \eqn{f({\bf x})}{f(x)}.}
  \item{m.lower}{Posterior \code{q.lower} quantile of the mean function realizations.}
  \item{m.upper}{Posterior \code{q.upper} quantile of the mean function realizations.}
  \item{s.5}{Posterior median of the standard deviation function realizations, \eqn{s({\bf x})}{s(x)}.}
  \item{s.lower}{Posterior \code{q.lower} quantile of the standard deviation function realizations.}
  \item{s.upper}{Posterior \code{q.upper} quantile of the standard deviation function realizations.}
  \item{q.lower}{Lower quantile used in constructing the above.}
  \item{q.upper}{Upper quantile used in constructing the above.}
  \item{pdraws}{Posterior realizations of the probabilities from a probit model.}
  \item{pmean}{Posterior predictive mean of the probabilities from a probit model.}
  \item{psd}{Posterior standard deviation of the probit model fitted probabilities.}
  \item{p.5}{Posterior median of the probit model fitted probabilities.}
  \item{p.lower}{Posterior \code{q.lower} quantile of the probit model fitted probabilities.}
  \item{p.upper}{Posterior \code{q.upper} quantile of the probit model fitted probabilities.}
  \item{q.lower}{The lower quantile used.}
  \item{q.upper}{The upper quantile used.}
  \item{modeltype}{The type of model fitted.}
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
  # Calculate in-sample predictions
  fitp=predict.openbt(fit,x,tc=4)

  # Make a simple plot
  plot(y,fitp$mmean,xlab="observed",ylab="fitted")
  abline(0,1)
}
}

\name{sobol.openbt}
\alias{sobol.openbt}
%\docType{package}
\title{Sobol Sensitivity Indices for OpenBT regression models.}
\description{
  The function \code{sobol.openbt()} calculates the Sobol' sensitivity metric for Bayesian tree models.  Supports continuous response BART or single tree models.
}
\usage{
\method{sobol}{openbt}(
fit=NULL,
q.lower=0.025,
q.upper=0.975,
tc=2)
}
\arguments{
  \item{fit}{Object of type \code{OpenBT_posterior} from a previous call to \code{openbt()} with model type 'bart' or 'hbart'.}
  \item{q.lower}{Lower quantile to return.}
  \item{q.upper}{Upper quantile to return.}
  \item{tc}{Number of cores to use in parallel computing.}
}
\details{
  \code{sobol.openbt()} calculates the Sobol' sensitivity indices for a continuous response Bayesian regression tree model that has been fit by \code{openbt()}. These are exact (closed-form) calculations, and are much faster and more accurate than Monte-Carlo approximation methods. 

  Returns an object of type \code{OpenBT_sobol} with the following entries.
}
\value{
  \item{vidraws}{Posterior realizations of the 1-way Sobol' variability, stored in an \code{ndpost x p} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{vijdraws}{Posterior realizations of the 2-way Sobol' variability, stored in an \code{ndpost x p*(p-1)/2} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{tvidraws}{Posterior realizations of the total single effect Sobol' variability, stored in a matrix with ndpost rows, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{vdraws}{Posterior realizations of total variability, stored in a matrix with ndpost rows.}
  \item{sidraws}{Posterior realizations of the 1-way Sobol' sensitivities, stored in an \code{ndpost x p} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{sijdraws}{Posterior realizations of the 2-way Sobol' sensitivities, stored in an \code{ndpost x p*(p-1)/2} matrix, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{tsidraws}{Posterior realizations of the total single effect Sobol' sensitivities, stored in a matrix with ndpost rows, where ndpost is the number of kept MCMC draws in the \code{openbt} run.}
  \item{msi}{Posterior mean of the 1-way Sobol' sensitivities.}
  \item{msi.sd}{Posterior s.d. of the 1-way Sobol' sensitivities.}
  \item{si.5}{Posterior median of the 1-way Sobol' sensitivities.}
  \item{si.lower}{Posterior q.lower quantile of the 1-way Sobol' sensitivities.}
  \item{si.upper}{Posterior q.upper quantile of the 1-way Sobol' sensitivities.}
  \item{msij}{Posterior mean of the 2-way Sobol' sensitivities.}
  \item{sij.sd}{Posterior s.d. of the 2-way Sobol' sensitivities.}
  \item{sij.5}{Posterior median of the 2-way Sobol' sensitivities.}
  \item{sij.lower}{Posterior q.lower quantile of the 2-way Sobol' sensitivities.}
  \item{sij.upper}{Posterior q.upper quantile of the 2-way Sobol' sensitivities.}
  \item{mtsi}{Posterior mean of the total effect Sobol' sensitivities.}
  \item{tsi.sd}{Posterior s.d. of the total effect Sobol' sensitivities.}
  \item{tsi.5}{Posterior median of the total effect Sobol' sensitivities.}
  \item{tsi.lower}{Posterior q.lower quantile of the total effect Sobol' sensitivities.}
  \item{tsi.upper}{Posterior q.upper quantile of the total effect Sobol' sensitivities.}
  \item{q.lower}{The lower quantile used.}
  \item{q.upper}{The upper quantile used.}
  \item{modeltype}{The type of model fitted by \code{openbt()}.}
}
\references{
  Horiguchi, Akira, Pratola, Matthew T. and Santner, Thomas J. (2020)
  Assessing Variable Activity for Bayesian Regression Trees.
  \emph{Reliability Engineering and System Safety}, \bold{207}, 107391.

  Horiguchi, Akira and Pratola, Matthew T. (2025) Estimating Shapley Effects in Big-Data Emulation and Regression Settings using Bayesian Additive Regression Trees. \emph{arXiv preprint}, \bold{arXiv:2304.03809}, 1--32.
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
  # Calculate Sobol indices
  fits=sobol.openbt(fit2)
  fits$msi
  fits$mtsi
  fits$msij
}
}

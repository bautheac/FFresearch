#' Fama/French research factors
#'
#' @description Fama/French research factors historical data. The time series dates back to 1926 with data for the momentum factor.
#'
#' @format A data.table with variables:
#' \itemize{
#'   \item{Region}{Geographical market considered for factor construction.}
#'   \item{Frequency}{Factor return frequency (day, month, year).}
#'   \item{Period}{Period over which factor returns are calculated.}
#'   \item{Mkt-Rf}{Market return minus risk free rate.}
#'   \item{Rf}{Risk free rate of return.}
#'   \item{Mkt}{Market return.}
#'   \item{SMB}{Small minus big factor return.}
#'   \item{HML}{High minus low factor return.}
#'   \item{RMW}{Robust minus weak factor return.}
#'   \item{CMA}{Conservative minus aggressive factor return.}
#'   \item{Mom}{Momentum factor return.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
"fffactors"

#' Fama/French research factors
#'
#'
#' @format A data frame with variables:
#' \describe{
#' \item{Region}{Geographical market considered for factor construction.}
#' \item{Date}{Observation date.}
#' \item{Mkt-RF}{Market return minus risk free rate.}
#' \item{SMB}{Small minus big factor return.}
#' \item{HML}{High minus low factor return.}
#' \item{RMW}{Robust minus weak factor return.}
#' \item{CMA}{Conservative minus aggressive factor return.}
#' \item{RF}{Risk free rate of return.}
#' \item{Mkt}{Market return.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#' @examples
#' if (require("dplyr")) {
#'   data(fffactors)
#'   fffactors %>% filter(Region == "US")
#' }
#'
"fffactors"
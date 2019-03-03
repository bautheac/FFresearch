#' Fama/French variable breakpoints
#'
#' @description Variable breakpoints time series. The variable breakpoints are
#'   used to construct the Fama/French portfolios and factors.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{variable: Fama/French variable name. See the "\link{variables}" dataset in this
#'   package as well as \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/variable_definitions.html}
#'   for details.}
#'   \item{frequency: variable observation frequency.}
#'   \item{percentile: percentile breakpoint. "# negative" and "# positive" count the number of negative and
#'   positive occurences for a given period repectively.}
#'   \item{period: observation period.}
#'   \item{value: corresponding variable breakpoint value.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"breakpoints"



#' Fama/French research factors
#'
#' @description Return and level (risk free rate) time series for the Fama/French
#'   asset pricing factors.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction.}
#'   \item{frequency: factor return frequency (day, month, year).}
#'   \item{period: period over which factor returns are calculated or risk free rate level is observed.}
#'   \item{factor: Fama/French factor}
#'   \item{value: corresponding return (factors) or level (risk free rate) observation.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"factors"


#' Fama/French univariate sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   single variable sorts.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction.}
#'   \item{frequency: field observation frequency.}
#'   \item{sort variable: sort variable used for portfolio construction.}
#'   \item{diviend: Y (included) or N (excluded).}
#'   \item{weights: portoflio weighting method.}
#'   \item{portfolio: corresponding portoflio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_univariate"


#' Fama/French bivariate sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   sorting on two variables.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction.}
#'   \item{frequency: field observation frequency.}
#'   \item{sort variable 1: first sort variable used for portfolio construction.}
#'   \item{sort variable 2: second sort variable used for portfolio construction.}
#'   \item{diviend: Y (included) or N (excluded).}
#'   \item{weights: portoflio weighting method.}
#'   \item{portfolio: corresponding portoflio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_bivariate"



#' Fama/French three-way sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   sorting on three variables.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction.}
#'   \item{frequency: field observation frequency.}
#'   \item{sort variable 1: first sort variable used for portfolio construction.}
#'   \item{sort variable 2: second sort variable used for portfolio construction.}
#'   \item{sort variable 3: third sort variable used for portfolio construction.}
#'   \item{diviend: Y (included) or N (excluded).}
#'   \item{weights: portoflio weighting method.}
#'   \item{portfolio: corresponding portoflio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_trivariate"




#' Fama/French industry portfolios
#'
#' @description Return time series for Fama/French industry portfolios.
#'
#' @format A \linkS4class{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction.}
#'   \item{frequency: field observation frequency.}
#'   \item{diviend: Y (included) or N (excluded).}
#'   \item{weights: portoflio weighting method.}
#'   \item{portfolio: corresponding portoflio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_industries"



#' Fama/French variables
#'
#' @description Helper dataset. Provides details on Fama/French variables,
#'   including contruction methods.
#'
#' @format A \link[tibble]{tibble} with variables:
#' \itemize{
#'   \item{name: variable name.}
#'   \item{symbol: symbol used to refer to a given variable in the various datasets
#'   contained in the package.}
#'   \item{description: variable descriptive elements including contruction methods.
#'   See\url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/variable_definitions.html}
#'   for more details.}
#' }
#'
#' @source \url{http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom tibble tibble
#'
"variables"

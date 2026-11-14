#' Fama/French variable breakpoints
#'
#' @description Variable breakpoints time series. The variable breakpoints are
#'   used to construct the Fama/French portfolios and factors. Coverage starts
#'   in 1971: monthly breakpoints run from 197101 to 202609 and annual
#'   breakpoints from 1971 to 2026. Dividend/price breakpoints are observed in
#'   June only (197106 to 202606). The 1971 start is a maintainer decision
#'   (2026-11-14, spec #3 follow-up): R's lazyload database cannot serialise
#'   objects larger than 2^31 - 1 bytes, which the full-history bivariate
#'   exceeded; `factors` and `variables` keep their full history.
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{variable: Fama/French variable name. See the "\link{variables}" dataset in this
#'   package as well as \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/variable_definitions.html}
#'   for details. The "pior returns" label (prior returns) is kept as committed
#'   for compatibility.}
#'   \item{frequency: variable observation frequency (month, year).}
#'   \item{percentile: percentile breakpoint. "# negative" and "# positive" count the number of negative and
#'   positive occurrences for a given period respectively.}
#'   \item{period: observation period.}
#'   \item{value: corresponding variable breakpoint value.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"breakpoints"



#' Fama/French research factors
#'
#' @description Return and level (risk free rate) time series for the Fama/French
#'   asset pricing factors. Daily and monthly series run through September 2026
#'   and annual series through 2025. US history starts in 1926 (daily 19260126,
#'   monthly 192602) and 1927 (annual); regional history starts in July 1990
#'   (daily 19900702, monthly 199007) and 1991 (annual).
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction
#'   (US, developed, developed (ex US), Europe, JP, Asia-Pacific (ex JP), North America).}
#'   \item{frequency: factor return frequency (day, month, year).}
#'   \item{period: period over which factor returns are calculated or risk free rate level is observed.}
#'   \item{factor: Fama/French factor}
#'   \item{value: corresponding return (factors) or level (risk free rate) observation.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"factors"


#' Fama/French univariate sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   single variable sorts (US only). Daily and monthly series run through
#'   September 2026; annual series through 2025 or 2026 depending on the sort
#'   variable. Coverage starts in 1971 for every sort variable (daily
#'   19710104, monthly 197101, annual 1971). Daily observations are
#'   available for the size, book/market, momentum and reversal sorts only.
#'   The 1971 start is a maintainer decision (2026-11-14, spec #3 follow-up):
#'   R's lazyload database cannot serialise objects larger than 2^31 - 1
#'   bytes, which the full-history bivariate exceeded; `factors` and
#'   `variables` keep their full history.
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction (US).}
#'   \item{frequency: field observation frequency (day, month, year).}
#'   \item{sort variable: sort variable used for portfolio construction.}
#'   \item{dividend: Y (included) or N (excluded). N is only available for monthly
#'   and annual observations of the size, book/market, operating profitability,
#'   investment, earnings/price, cash flow/price and dividend/price sorts.}
#'   \item{weights: portfolio weighting method.}
#'   \item{portfolio: corresponding portfolio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_univariate"


#' Fama/French bivariate sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   sorting on two variables. Coverage starts in 1971 for the US sorts
#'   (daily 19710104, monthly 197101, annual 1971); regional series start in
#'   July 1990 (daily 19900702, monthly 199007) and 1991 (annual). Daily and
#'   monthly series run through September 2026; annual series through 2026
#'   (US) or 2025 (regions). The 1971 start is a maintainer decision
#'   (2026-11-14, spec #3 follow-up): R's lazyload database cannot serialise
#'   objects larger than 2^31 - 1 bytes. The full-history bivariate (34.8M
#'   rows) serialised to 2,363,328,315 bytes and failed standard installation
#'   on every platform; starting in 1971 keeps it under the limit. `factors`
#'   and `variables` keep their full history.
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction
#'   (US, developed, developed (ex US), Europe, JP, Asia-Pacific (ex JP), North America).}
#'   \item{frequency: field observation frequency (day, month, year).}
#'   \item{sort variable 1: first sort variable used for portfolio construction.}
#'   \item{sort variable 2: second sort variable used for portfolio construction.}
#'   \item{dividend: Y (included) or N (excluded).}
#'   \item{weights: portfolio weighting method.}
#'   \item{portfolio: corresponding portfolio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_bivariate"




#' Fama/French three-way sorts
#'
#' @description Return time series for Fama/French portfolios formed on
#'   sorting on three variables. Monthly and annual frequencies only. US series
#'   run from 197101 to 202609 (monthly) and 1971 to 2025 (annual); regional
#'   series from 199007 to 202609 (monthly) and 1991 to 2025 (annual). The
#'   1971 start is a maintainer decision (2026-11-14, spec #3 follow-up): R's
#'   lazyload database cannot serialise objects larger than 2^31 - 1 bytes,
#'   which the full-history bivariate exceeded; `factors` and `variables`
#'   keep their full history.
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction
#'   (US, developed, developed (ex US), Europe, JP, Asia-Pacific (ex JP), North America).}
#'   \item{frequency: field observation frequency (month, year).}
#'   \item{sort variable 1: first sort variable used for portfolio construction.}
#'   \item{sort variable 2: second sort variable used for portfolio construction.}
#'   \item{sort variable 3: third sort variable used for portfolio construction.}
#'   \item{dividend: Y (included) or N (excluded). US sorts ship both; regional
#'   sorts are dividend-included (Y) only.}
#'   \item{weights: portfolio weighting method.}
#'   \item{portfolio: corresponding portfolio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_trivariate"




#' Fama/French industry portfolios
#'
#' @description Return time series for Fama/French industry portfolios (US only).
#'   Daily and monthly series run from 1971 (daily 19710104, monthly 197101)
#'   through September 2026; annual series from 1971 through 2026. Portfolios
#'   span the union of the 5, 10, 12, 17, 30, 38, 48 and 49 industry
#'   classifications. The 1971 start is a maintainer decision (2026-11-14,
#'   spec #3 follow-up): R's lazyload database cannot serialise objects larger
#'   than 2^31 - 1 bytes, which the full-history bivariate exceeded;
#'   `factors` and `variables` keep their full history.
#'
#' @format A \link[data.table:data.table-class]{data.table} with variables:
#' \itemize{
#'   \item{region: geographical market considered for factor construction (US).}
#'   \item{frequency: field observation frequency (day, month, year).}
#'   \item{dividend: Y (included) or N (excluded).}
#'   \item{weights: portfolio weighting method.}
#'   \item{portfolio: corresponding portfolio.}
#'   \item{field: variable observed for given portfolio.}
#'   \item{period: observation period.}
#'   \item{value: corresponding field value.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom data.table data.table
#'
"portfolios_industries"



#' Fama/French variables
#'
#' @description Helper dataset. Provides details on Fama/French variables,
#'   including construction methods. The 48 rows cover every variable, factor
#'   and field used across the package's datasets, so any name appearing in the
#'   other datasets can be looked up here.
#'
#' @format A \link[tibble]{tibble} with variables:
#' \itemize{
#'   \item{name: variable name.}
#'   \item{symbol: symbol used to refer to a given variable in the various datasets
#'   contained in the package. Derived fields (the "value weight average of ..."
#'   and "equal weight average of ..." rows) have no symbol (NA).}
#'   \item{description: variable descriptive elements including construction methods.
#'   See \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/variable_definitions.html}
#'   for more details.}
#' }
#'
#' @source \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @importFrom tibble tibble
#'
"variables"

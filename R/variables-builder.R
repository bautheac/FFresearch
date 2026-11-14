# Variables dataset -------------------------------------------------------------------

#' Build the `variables` dataset
#'
#' Concrete `DatasetBuilder`: collects the field names the other datasets use
#' from `inventories` (one row per dataset, column and name), checks every
#' name has a definition and returns the name, symbol and description table.
#' Unlike the other builders it reads no library file: its inputs are the
#' other datasets' field inventories, injected for tests and read from the
#' shipped datasets by default.
#'
#' @noRd
VariablesBuilder <- R6::R6Class(
  "VariablesBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(inventories = variables_inventories()) {
      super$initialize("variables")
      private$inventories <- inventories
    }
  ),
  private = list(
    inventories = NULL,
    read_tables = function() {
      inventories <- private$inventories
      if (!is.data.frame(inventories) ||
          !identical(names(inventories), c("dataset", "column", "name")) ||
          !is.character(inventories$name) || anyNA(inventories$name)) {
        stop("`inventories` must be a data frame with character columns dataset, column and name.",
             call. = FALSE)
      }
      inventories
    },
    assemble = function(tables) {
      definitions <- variables_definitions()
      missing <- setdiff(unique(tables$name), definitions$name)
      if (length(missing) > 0L) {
        stop("`variables` has no definition for: ", paste(missing, collapse = ", "), ".",
             call. = FALSE)
      }
      tibble::as_tibble(definitions)
    }
  )
)

#' Create the variables builder
#'
#' `VariablesBuilderFactory$create()` wires a `VariablesBuilder` to the field
#' inventories of the shipped datasets, or to any other inventory table given
#' as `inventories`.
#'
#' @noRd
VariablesBuilderFactory <- R6::R6Class(
  "VariablesBuilderFactory",
  public = list(
    create = function(inventories = variables_inventories()) {
      VariablesBuilder$new(inventories)
    }
  )
)

# Field inventories of the shipped datasets: one row per dataset, column and
# name used. Loads one dataset at a time and collects it before the next: the
# bivariate dataset alone is about 2 GB. Requires the package to be installed
# with the rebuilt datasets.
variables_inventories <- function() {
  columns <- list(
    portfolios_univariate = c("sort variable", "field"),
    portfolios_bivariate = c("sort variable 1", "sort variable 2", "field"),
    portfolios_trivariate = c("sort variable 1", "sort variable 2", "sort variable 3", "field"),
    portfolios_industries = "field",
    breakpoints = "variable",
    factors = "factor")
  rows <- lapply(names(columns), function(dataset) {
    gc()
    env <- new.env()
    utils::data(list = dataset, package = "FFresearch", envir = env)
    x <- get(dataset, envir = env)
    used <- lapply(columns[[dataset]], function(column) {
      values <- x[[column]]
      if (is.factor(values)) levels(values) else unique(values)
    })
    rm(x, env); gc()
    data.table::data.table(
      dataset = dataset,
      column = rep(columns[[dataset]], lengths(used)),
      name = unlist(used, use.names = FALSE))
  })
  data.table::rbindlist(rows)
}

# The name -> symbol -> description mapping. The first 23 rows are the
# committed `variables` table, kept verbatim (including the committed
# "univariate market beta" and "book value" names); the rows after them define
# the names the rebuilt datasets added. Derived "value/equal weight average
# of ..." fields have no symbol. Row order is the shipped order.
variables_definitions <- function() {
  rows <- list(
    list(name = "market capitalization", symbol = "ME",
         description = "Market equity (size) is price times shares outstanding. Price is from CRSP, shares outstanding are from Compustat (if available) or CRSP."),
    list(name = "book value", symbol = "BE",
         description = "Book equity is constructed from Compustat data or collected from the Moody\u2019s Industrial, Financial, and Utilities manuals. BE is the book value of stockholders\u2019 equity, plus balance sheet deferred taxes and investment tax credit (if available), minus the book value of preferred stock. Depending on availability, we use the redemption, liquidation, or par value (in that order) to estimate the book value of preferred stock. Stockholders\u2019 equity is the value reported by Moody\u2019s or Compustat, if it is available. If not, we measure stockholders\u2019 equity as the book value of common equity plus the par value of preferred stock, or the book value of assets minus total liabilities (in that order). See Davis, Fama, and French, 2000, \u201cCharacteristics, Covariances, and Average Returns: 1929-1997,\u201d Journal of Finance, for more details."),
    list(name = "book/market", symbol = "ME/BE",
         description = "The book-to-market ratio used to form portfolios in June of year t is book equity for the fiscal year ending in calendar year t-1, divided by market equity at the end of December of t-1."),
    list(name = "operating profitability", symbol = "OP",
         description = "The operating profitability ratio used to form portfolios in June of year t is annual revenues minus cost of goods sold, interest expense, and selling, general, and administrative expenses divided by book equity for the last fiscal year end in t-1."),
    list(name = "investment", symbol = "INV",
         description = "The investment ratio used to form portfolios in June of year t is the change in total assets from the fiscal year ending in year t-2 to the fiscal year ending in t-1, divided by t-2 total assets."),
    list(name = "earnings/price", symbol = "E/P",
         description = "Earnings is total earnings before extraordinary items, from Compustat. The earnings/price ratio used to form portfolios in June of year t is earnings for the fiscal year ending in calendar year t-1, divided by market equity at the end of December of t-1."),
    list(name = "cash flow/price", symbol = "CF/P",
         description = "Cashflow is total earnings before extraordinary items, plus equity\u2019s share of depreciation, plus deferred taxes (if available), from Compustat. Equity\u2019s share is defined as market equity divided by assets minus book equity plus market equity. The cashflow/price ratio used to form portfolios in June of year t is the cashflow for the fiscal year ending in calendar year t-1, divided by market equity at the end of December of t-1."),
    list(name = "dividend/price", symbol = "D/P",
         description = "The dividend yield used to form portfolios in June of year t is the total dividends paid from July of t-1 to June of t per dollar of equity in June of t. The dividend yield is computed using the with and without dividend returns from CRSP, as described in Fama and French, 1988, \u201cDividend yields and expected stock returns,\u201d Journal of Financial Economics 25."),
    list(name = "accruals", symbol = "ACCR",
         description = "AC for June of year t is the change in operating working capital per split-adjusted share from the fiscal yearend t-2 to t-1 divided by book equity per share in t-1."),
    list(name = "univariate market beta", symbol = "BETA",
         description = "\u03b2 for June of year t is estimated using the preceding five years (two minimum) of past monthly returns."),
    list(name = "net share issues", symbol = "NI",
         description = "NI for June of year t is the change in the natural log of split-adjusted shares outstanding from the fiscal yearend in t-2 to the fiscal yearend in t-1."),
    list(name = "variance", symbol = "VAR",
         description = "Variance of daily returns (Var) using NYSE breakpoints. Var is estimated using 60 days (minimum 20) of lagged returns."),
    list(name = "residual variance", symbol = "RESVAR",
         description = "Variance of the residuals from the FF three-factor model (RVar) using NYSE breakpoints. RVar is estimated using 60 days (minimum 20) of lagged returns."),
    list(name = "short term reversal", symbol = "ST_Rev",
         description = "ST_Rev is the average return on the two low prior return portfolios minus the average return on the two high prior return portfolios: ST_Rev = 1/2 (Small Low + Big Low)  - 1/2(Small High + Big High)."),
    list(name = "long term reversal", symbol = "LT_Rev",
         description = "LT_Rev is the average return on the two low prior return portfolios minus the average return on the two high prior return portfolios:  LT_Rev = 1/2 (Small Low + Big Low) - 1/2(Small High + Big High)."),
    list(name = "value weight average of BE/ME", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * BE(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1; BE(Fiscal Year t-1): adjusted for net stock issuance to Dec t-1."),
    list(name = "value weight average of BE_FYt-1/ME_June t", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * BE(Fiscal Year t-1) / ME(Jun t)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1; BE(Fiscal Year t-1): adjusted for net stock issuance to June t."),
    list(name = "value weight average of OP", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * OP(fiscal year t-1) / BE(fiscal year t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of investment (rate of growth of assets)", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * Log(ASSET(t-1) / ASSET(t-2) / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Net Share Issues", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * NI / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Accruals", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * AC/B / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Prior Beta", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * BETA / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Past Return Variance", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * VAR / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "CMA", symbol = "CMA",
         description = "Conservative minus aggressive: the average return on the two conservative investment portfolios minus the average return on the two aggressive investment portfolios."),
    list(name = "HML", symbol = "HML",
         description = "High minus low: the average return on the two high book-to-market portfolios minus the average return on the two low book-to-market portfolios."),
    list(name = "LT_Rev", symbol = "LT_Rev",
         description = "LT_Rev is the average return on the two low prior return portfolios minus the average return on the two high prior return portfolios:  LT_Rev = 1/2 (Small Low + Big Low) - 1/2(Small High + Big High)."),
    list(name = "Mom", symbol = "Mom",
         description = "Momentum: the average return on the two high prior return portfolios minus the average return on the two low prior return portfolios: Mom = 1/2 (Small High + Big High) - 1/2(Small Low + Big Low)."),
    list(name = "RMW", symbol = "RMW",
         description = "Robust minus weak: the average return on the two robust operating profitability portfolios minus the average return on the two weak operating profitability portfolios."),
    list(name = "SMB", symbol = "SMB",
         description = "Small minus big: the average return on the three small portfolios minus the average return on the three big portfolios."),
    list(name = "ST_Rev", symbol = "ST_Rev",
         description = "ST_Rev is the average return on the two low prior return portfolios minus the average return on the two high prior return portfolios: ST_Rev = 1/2 (Small Low + Big Low)  - 1/2(Small High + Big High)."),
    list(name = "WML", symbol = "WML",
         description = "Winners minus losers: the momentum factor outside the US, the average return on the two high prior return portfolios minus the average return on the two low prior return portfolios."),
    list(name = "equal weight average of Prior Returns", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as the equal weight average of Prior Return. Prior Return: the lagged return measure used for the sort."),
    list(name = "market", symbol = NA_character_,
         description = "Market return: the value-weighted return on all NYSE, AMEX and NASDAQ stocks (CRSP), including dividends; computed as the market excess return plus the risk free rate."),
    list(name = "market beta", symbol = "BETA",
         description = "\u03b2 for June of year t is estimated using the preceding five years (two minimum) of past monthly returns."),
    list(name = "momentum", symbol = "Mom",
         description = "Prior 2-12 month returns: the cumulative return from month t-12 to month t-2, used to form momentum portfolios."),
    list(name = "pior returns", symbol = NA_character_,
         description = "Prior 2-12 month returns used to form momentum portfolios, with NYSE breakpoints. The 'pior returns' spelling is kept from the committed dataset for compatibility."),
    list(name = "return", symbol = NA_character_,
         description = "Portfolio return over the observation period, in percent, weighted and including dividends as indicated by the weights and dividend columns."),
    list(name = "risk free rate", symbol = "RF",
         description = "Risk free rate: the one-month US Treasury bill rate, from CRSP."),
    list(name = "size", symbol = "ME",
         description = "Market equity (size) is price times shares outstanding. Price is from CRSP, shares outstanding are from Compustat (if available) or CRSP."),
    list(name = "value weight average of ACCR", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * AC/B / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of CF/ME", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * CF(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of CF/P", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * CF(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of D/P", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * D/P] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1; D/P: dividends paid from July of t-1 to June of t per dollar of equity in June of t."),
    list(name = "value weight average of E/ME", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * E(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of E/P", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * E(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of NI", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * NI / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Natural Log of INV", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * Log(ASSET(t-1) / ASSET(t-2))] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1."),
    list(name = "value weight average of Prior Returns", symbol = NA_character_,
         description = "For portfolios formed in June of year t, calculated for June of t to June of t+1 as: Sum[ME(Mth) * Prior Return] / Sum[ME(Mth)]. Mth: a month from June of t to June of t+1; Prior Return: the lagged return measure used for the sort."))
  data.table::rbindlist(rows)
}

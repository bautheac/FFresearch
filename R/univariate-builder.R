# Univariate dataset ------------------------------------------------------------------

# One row per library file: region, sort variable, dividend and the weightings
# the file provides. Every univariate file carries both value- and
# equal-weighted returns, so `weights` is a list column. Base and daily files
# include dividends (Y); `_Wout_Div` files exclude them (N).
univariate_sources <- function() {
  sorts <- c(
    "Portfolios_Formed_on_ME" = "market capitalization",
    "Portfolios_Formed_on_BE-ME" = "book/market",
    "Portfolios_Formed_on_OP" = "operating profitability",
    "Portfolios_Formed_on_INV" = "investment",
    "Portfolios_Formed_on_E-P" = "earnings/price",
    "Portfolios_Formed_on_CF-P" = "cash flow/price",
    "Portfolios_Formed_on_D-P" = "dividend/price",
    "10_Portfolios_Prior_12_2" = "momentum",
    "10_Portfolios_Prior_1_0" = "short term reversal",
    "10_Portfolios_Prior_60_13" = "long term reversal",
    "Portfolios_Formed_on_AC" = "accruals",
    "Portfolios_Formed_on_BETA" = "market beta",
    "Portfolios_Formed_on_NI" = "net share issues",
    "Portfolios_Formed_on_VAR" = "variance",
    "Portfolios_Formed_on_RESVAR" = "residual variance")
  ex_dividend <- c("Portfolios_Formed_on_ME", "Portfolios_Formed_on_BE-ME",
                   "Portfolios_Formed_on_OP", "Portfolios_Formed_on_INV",
                   "Portfolios_Formed_on_E-P", "Portfolios_Formed_on_CF-P",
                   "Portfolios_Formed_on_D-P")
  daily <- c("Portfolios_Formed_on_ME", "Portfolios_Formed_on_BE-ME",
             "Portfolios_Formed_on_OP", "Portfolios_Formed_on_INV",
             "10_Portfolios_Prior_12_2", "10_Portfolios_Prior_1_0",
             "10_Portfolios_Prior_60_13")
  rows <- function(files, dividend) {
    base <- sub("_(Wout_Div|Daily)$", "", files)
    data.table::data.table(
      file = files, region = "US", `sort variable` = unname(sorts[base]),
      dividend = dividend, weights = rep(list(c("value", "equal")), length(files)))
  }
  data.table::rbindlist(list(
    rows(names(sorts), "Y"),
    rows(paste0(ex_dividend, "_Wout_Div"), "N"),
    rows(paste0(daily, "_Daily"), "Y")))
}

#' Build the `portfolios_univariate` dataset
#'
#' Concrete `DatasetBuilder`: reads every single-sort portfolio file listed in
#' `sources` through a `LinesSource`, parses it with a `PortfolioParser`, tags
#' the region, sort variable and dividend labels from the mapping, keeps the
#' fields and coverage the dataset ships, harmonises portfolio labels and
#' returns one long table ordered by the dataset key.
#'
#' @noRd
UnivariateBuilder <- R6::R6Class(
  "UnivariateBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = PortfolioParser$new(), sources = univariate_sources()) {
      super$initialize("portfolios_univariate")
      private$source <- source
      private$parser <- parser
      private$sources <- sources
    }
  ),
  private = list(
    source = NULL,
    parser = NULL,
    sources = NULL,
    read_tables = function() {
      tables <- lapply(seq_len(nrow(private$sources)), function(i) {
        lines <- private$source$read_lines(private$sources$file[[i]])
        table <- private$parser$parse(lines)
        table[, `:=`(region = private$sources$region[[i]],
                     `sort variable` = private$sources$`sort variable`[[i]],
                     dividend = private$sources$dividend[[i]])]
      })
      data.table::rbindlist(tables)
    },
    assemble = function(tables) {
      tables <- private$keep_fields(tables)
      tables <- private$keep_coverage(tables)
      private$rename_portfolios(tables)
      private$order_columns(tables)
    },
    keep_fields = function(tables) {
      tables[field %in% univariate_fields()]
    },
    keep_coverage = function(tables) {
      # The library also files daily OP and INV sorts, but the dataset ships
      # daily returns for the size, book/market and prior-return sorts only.
      tables[!(frequency == "day" & !`sort variable` %in% univariate_daily_sorts())]
    },
    rename_portfolios = function(tables) {
      # The library names deciles "2-Dec"..."9-Dec" in the ME, BE-ME, E-P,
      # CF-P and D-P files, the non-positive portfolio "<= 0" (NI: "< 0");
      # the dataset ships "Dec 2"..."Dec 9", "Negative" and "X .0".
      tables[, portfolio := sub("^([2-9])-Dec$", "Dec \\1", portfolio)]
      tables[portfolio == "<= 0", portfolio := "Negative"]
      tables[portfolio == "< 0", portfolio := "X .0"]
      invisible(tables)
    },
    order_columns = function(tables) {
      ordered <- tables[, .(region = factor(region, "US"),
                            frequency = factor(frequency, c("day", "month", "year")),
                            `sort variable` = factor(`sort variable`, univariate_sorts()),
                            dividend = factor(dividend, c("Y", "N")),
                            weights = factor(weights, c("value", "equal")),
                            portfolio,
                            field = factor(field, univariate_fields()),
                            period, value)]
      data.table::setorder(ordered, region, frequency, `sort variable`, dividend,
                           weights, portfolio, field, period)
      ordered[]
    }
  )
)

#' Create the univariate builder
#'
#' `UnivariateBuilderFactory$create()` wires a `UnivariateBuilder` to the live
#' library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`.
#'
#' @noRd
UnivariateBuilderFactory <- R6::R6Class(
  "UnivariateBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new()) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      UnivariateBuilder$new(source)
    }
  )
)

# Sort-variable levels in the mapping's order; field levels in the shipped
# order. Derived fields keep the library's section names (E/ME and CF/ME here,
# not the E/P and CF/P of the bivariate sorts).
univariate_sorts <- function() {
  unique(univariate_sources()$`sort variable`)
}

univariate_daily_sorts <- function() {
  c("market capitalization", "book/market", "momentum",
    "short term reversal", "long term reversal")
}

univariate_fields <- function() {
  c("return",
    "value weight average of BE/ME",
    "value weight average of OP",
    "value weight average of Natural Log of INV",
    "value weight average of E/ME",
    "value weight average of CF/ME",
    "value weight average of Prior Returns",
    "value weight average of ACCR",
    "value weight average of Prior Beta",
    "value weight average of NI",
    "value weight average of Past Return Variance")
}

# Factors dataset -------------------------------------------------------------------

#' Build the `factors` dataset
#'
#' Concrete `DatasetBuilder`: reads every factor file listed in `sources`
#' through a `LinesSource`, parses it with a `FrenchParser`, derives the
#' market return (excess return plus risk free rate), harmonises factor
#' names and returns one long table ordered by region, frequency, factor and
#' period.
#'
#' @noRd
FactorsBuilder <- R6::R6Class(
  "FactorsBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = FrenchParser$new(), sources = factors_sources()) {
      super$initialize("factors")
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
        table[, region := private$sources$region[[i]]]
      })
      data.table::rbindlist(tables)
    },
    assemble = function(tables) {
      factors <- private$add_market(tables)
      private$rename_factors(factors)
      private$order_columns(factors)
    },
    add_market = function(factors) {
      risk_free <- factors[factor == "RF", .(region, frequency, period, rf = value)]
      market <- merge(factors[factor == "Mkt-RF"], risk_free, by = c("region", "frequency", "period"))
      market[, `:=`(factor = "market", value = value + rf)][, rf := NULL]
      data.table::rbindlist(list(factors[factor != "Mkt-RF"], market), use.names = TRUE)
    },
    rename_factors = function(factors) {
      factors[factor == "RF", factor := "risk free rate"]
      factors[factor == "ST_REV", factor := "ST_Rev"]
      factors[factor == "LT_REV", factor := "LT_Rev"]
      invisible(factors)
    },
    order_columns = function(factors) {
      ordered <- factors[, .(region = factor(region, factors_regions()),
                             frequency = factor(frequency, c("month", "day", "year")),
                             factor, period, value)]
      data.table::setorder(ordered, region, frequency, factor, period)
      ordered[]
    }
  )
)

#' Create the factors builder
#'
#' `FactorsBuilderFactory$create()` wires a `FactorsBuilder` to the live
#' library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`.
#'
#' @noRd
FactorsBuilderFactory <- R6::R6Class(
  "FactorsBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new()) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      FactorsBuilder$new(source)
    }
  )
)

# Region vocabulary, following the library's current names. The committed
# datasets' `global` / `global (ex US)` labels become `developed` /
# `developed (ex US)` (spec #3, story 8).
factors_regions <- function() {
  c("US", "developed", "developed (ex US)", "Europe", "JP", "Asia-Pacific (ex JP)", "North America")
}

# One row per library file: region, file stem.
factors_sources <- function() {
  us <- data.table::data.table(region = "US", file = c(
    "F-F_Research_Data_5_Factors_2x3", "F-F_Research_Data_5_Factors_2x3_daily",
    "F-F_Momentum_Factor", "F-F_Momentum_Factor_daily",
    "F-F_ST_Reversal_Factor", "F-F_ST_Reversal_Factor_daily",
    "F-F_LT_Reversal_Factor", "F-F_LT_Reversal_Factor_daily"))
  regional <- list(
    list("developed", "Developed_5_Factors", "Developed_Mom_Factor"),
    list("developed (ex US)", "Developed_ex_US_5_Factors", "Developed_ex_US_Mom_Factor"),
    list("Europe", "Europe_5_Factors", "Europe_Mom_Factor"),
    list("JP", "Japan_5_Factors", "Japan_Mom_Factor"),
    list("Asia-Pacific (ex JP)", "Asia_Pacific_ex_Japan_5_Factors", "Asia_Pacific_ex_Japan_MOM_Factor"),
    list("North America", "North_America_5_Factors", "North_America_Mom_Factor"))
  rest <- data.table::rbindlist(lapply(regional, function(x) data.table::data.table(
    region = x[[1L]], file = c(x[[2L]], paste0(x[[2L]], "_Daily"), x[[3L]], paste0(x[[3L]], "_Daily")))))
  data.table::rbindlist(list(us, rest))
}

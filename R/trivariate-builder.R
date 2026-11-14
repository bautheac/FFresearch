# Trivariate dataset ------------------------------------------------------------------

# One row per library file: region, the three sort variables, dividend and the
# weightings the file provides. Every trivariate file carries both value- and
# equal-weighted returns, so `weights` is a list column. US base files include
# dividends (Y); `_Wout_Div` files exclude them (N). The library has no regional
# ex-dividend trivariate files, so every regional sort includes dividends (Y).
trivariate_sources <- function() {
  sorts <- list(
    list(us = "32_Portfolios_ME_BEME_OP_2x4x4", regional = "32_Portfolios_ME_BE-ME_OP_2x4x4",
         `sort variable 2` = "book/market", `sort variable 3` = "operating profitability"),
    list(us = "32_Portfolios_ME_BEME_INV_2x4x4", regional = "32_Portfolios_ME_BE-ME_INV(TA)_2x4x4",
         `sort variable 2` = "book/market", `sort variable 3` = "investment"),
    list(us = "32_Portfolios_ME_OP_INV_2x4x4", regional = "32_Portfolios_ME_INV(TA)_OP_2x4x4",
         `sort variable 2` = "operating profitability", `sort variable 3` = "investment"))
  regions <- c(
    "Developed_" = "developed",
    "Developed_ex_US_" = "developed (ex US)",
    "Europe_" = "Europe",
    "Japan_" = "JP",
    "Asia_Pacific_ex_Japan_" = "Asia-Pacific (ex JP)",
    "North_America_" = "North America")
  rows <- function(files, region, sort, dividend) {
    data.table::data.table(
      file = files, region = region, `sort variable 1` = "market capitalization",
      `sort variable 2` = sort$`sort variable 2`, `sort variable 3` = sort$`sort variable 3`,
      dividend = dividend, weights = rep(list(c("value", "equal")), length(files)))
  }
  us <- data.table::rbindlist(lapply(sorts, function(sort) {
    rows(c(sort$us, paste0(sort$us, "_Wout_Div")), "US", sort, c("Y", "N"))
  }))
  regional <- data.table::rbindlist(lapply(names(regions), function(prefix) {
    data.table::rbindlist(lapply(sorts, function(sort) {
      rows(paste0(prefix, sort$regional), regions[[prefix]], sort, "Y")
    }))
  }))
  data.table::rbindlist(list(us, regional))
}

#' Build the `portfolios_trivariate` dataset
#'
#' Concrete `DatasetBuilder`: reads every triple-sort file listed in `sources`
#' through a `LinesSource`, parses it with a `PortfolioParser`, keeps the
#' documented fields (returns and the US value-weight averages), joins the
#' last two tokens of each portfolio header with a dot and returns one long
#' table ordered by the dataset key.
#'
#' @noRd
TrivariateBuilder <- R6::R6Class(
  "TrivariateBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = PortfolioParser$new(), sources = trivariate_sources()) {
      super$initialize("portfolios_trivariate")
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
                     `sort variable 1` = private$sources$`sort variable 1`[[i]],
                     `sort variable 2` = private$sources$`sort variable 2`[[i]],
                     `sort variable 3` = private$sources$`sort variable 3`[[i]],
                     dividend = private$sources$dividend[[i]])]
      })
      data.table::rbindlist(tables)
    },
    assemble = function(tables) {
      portfolios <- private$select_fields(tables)
      private$join_labels(portfolios)
      ordered <- private$order_columns(portfolios)
      key <- c("region", "frequency", "sort variable 1", "sort variable 2", "sort variable 3",
               "dividend", "weights", "portfolio", "field", "period")
      if (anyDuplicated(ordered, by = key) > 0L) {
        stop("Duplicate `portfolios_trivariate` observations for the dataset key.", call. = FALSE)
      }
      ordered
    },
    select_fields = function(tables) {
      # Firm counts and sizes carry no documented field; regional files have
      # no derived value-weight averages.
      tables[field %in% trivariate_fields()]
    },
    join_labels = function(portfolios) {
      # Library headers are space-separated triples ("ME1 BM1 OP2"); the
      # dataset joins the last two tokens with a dot ("ME1 BM1.OP2").
      portfolios[, portfolio := sub(" ([^ ]*)$", ".\\1", portfolio)]
      invisible(portfolios)
    },
    order_columns = function(portfolios) {
      ordered <- portfolios[, .(
        region = factor(region, factors_regions()),
        frequency = factor(frequency, c("month", "year")),
        `sort variable 1` = factor(`sort variable 1`, "market capitalization"),
        `sort variable 2` = factor(`sort variable 2`, c("book/market", "operating profitability")),
        `sort variable 3` = factor(`sort variable 3`, c("operating profitability", "investment")),
        dividend = factor(dividend, c("Y", "N")),
        weights = factor(weights, c("value", "equal")),
        portfolio,
        field = factor(field, trivariate_fields()),
        period, value)]
      data.table::setorder(ordered, region, frequency, `sort variable 1`, `sort variable 2`,
                           `sort variable 3`, dividend, weights, portfolio, field, period)
      ordered[]
    }
  )
)

#' Create the trivariate builder
#'
#' `TrivariateBuilderFactory$create()` wires a `TrivariateBuilder` to the live
#' library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`.
#'
#' @noRd
TrivariateBuilderFactory <- R6::R6Class(
  "TrivariateBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new()) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      TrivariateBuilder$new(source)
    }
  )
)

# The documented fields, in committed level order. The four value-weight
# averages appear only in the US files, monthly and value-weighted.
trivariate_fields <- function() {
  c("return", "value weight average of BE/ME", "value weight average of BE_FYt-1/ME_June t",
    "value weight average of OP", "value weight average of investment (rate of growth of assets)")
}
# Bivariate dataset -------------------------------------------------------------------

# Region vocabulary, following the library's current names. The committed
# dataset's `global` / `global (ex US)` labels become `developed` /
# `developed (ex US)` (spec #3, story 8).
bivariate_regions <- function() {
  c("US", "developed", "developed (ex US)", "Europe", "JP", "Asia-Pacific (ex JP)", "North America")
}

# Field vocabulary of the committed dataset. The parser also tags firm counts,
# average sizes and sums of book equity; those sections are not shipped.
bivariate_fields <- function() {
  c("return",
    "value weight average of BE/ME",
    "value weight average of BE_FYt-1/ME_June t",
    "value weight average of OP",
    "value weight average of investment (rate of growth of assets)",
    "equal weight average of Prior Returns",
    "value weight average of Prior Returns",
    "value weight average of E/P",
    "value weight average of CF/P",
    "value weight average of D/P",
    "value weight average of Net Share Issues",
    "value weight average of Accruals",
    "value weight average of Prior Beta",
    "value weight average of Past Return Variance")
}

# Factor levels of every labelled column, in the committed order.
bivariate_levels <- function() {
  list(region = bivariate_regions(),
       frequency = c("day", "month", "year"),
       `sort variable 1` = c("market capitalization", "book/market", "operating profitability"),
       `sort variable 2` = c("book/market", "operating profitability", "investment", "momentum",
                             "earnings/price", "cash flow/price", "dividend/price",
                             "short term reversal", "long term reversal", "accruals",
                             "market beta", "net share issues", "variance", "residual variance"),
       dividend = c("Y", "N"),
       weights = c("value", "equal"),
       field = bivariate_fields())
}

bivariate_key <- function() {
  c("region", "frequency", "sort variable 1", "sort variable 2", "dividend",
    "weights", "portfolio", "field", "period")
}

# One row per library file: region, both sort variables, dividend and the
# weightings the file provides. Every bivariate file carries both value- and
# equal-weighted returns, so `weights` is a list column. Base and daily files
# include dividends (Y); `_Wout_Div` files exclude them (N). The US size x
# book/market sort uses the 10x10 file, not the 6/25 ones; the regions use the
# 25 variants. Regional momentum daily stems skip 20 trading days over 250.
bivariate_sources <- function() {
  us_rows <- list(
    list("100_Portfolios_10x10", "market capitalization", "book/market", "Y"),
    list("100_Portfolios_10x10_Wout_Div", "market capitalization", "book/market", "N"),
    list("100_Portfolios_10x10_Daily", "market capitalization", "book/market", "Y"),
    list("100_Portfolios_ME_OP_10x10", "market capitalization", "operating profitability", "Y"),
    list("100_Portfolios_10x10_ME_OP_Wout_Div", "market capitalization", "operating profitability", "N"),
    list("100_Portfolios_ME_OP_10x10_daily", "market capitalization", "operating profitability", "Y"),
    list("100_Portfolios_ME_INV_10x10", "market capitalization", "investment", "Y"),
    list("100_Portfolios_10x10_ME_INV_Wout_Div", "market capitalization", "investment", "N"),
    list("100_Portfolios_ME_INV_10x10_daily", "market capitalization", "investment", "Y"),
    list("25_Portfolios_ME_Prior_12_2", "market capitalization", "momentum", "Y"),
    list("25_Portfolios_ME_Prior_12_2_Daily", "market capitalization", "momentum", "Y"),
    list("25_Portfolios_ME_Prior_1_0", "market capitalization", "short term reversal", "Y"),
    list("25_Portfolios_ME_Prior_1_0_Daily", "market capitalization", "short term reversal", "Y"),
    list("25_Portfolios_ME_Prior_60_13", "market capitalization", "long term reversal", "Y"),
    list("25_Portfolios_ME_Prior_60_13_Daily", "market capitalization", "long term reversal", "Y"),
    list("6_Portfolios_ME_EP_2x3", "market capitalization", "earnings/price", "Y"),
    list("6_Portfolios_ME_EP_2x3_Wout_Div", "market capitalization", "earnings/price", "N"),
    list("6_Portfolios_ME_CFP_2x3", "market capitalization", "cash flow/price", "Y"),
    list("6_Portfolios_ME_CFP_2x3_Wout_Div", "market capitalization", "cash flow/price", "N"),
    list("6_Portfolios_ME_DP_2x3", "market capitalization", "dividend/price", "Y"),
    list("6_Portfolios_ME_DP_2x3_Wout_Div", "market capitalization", "dividend/price", "N"),
    list("25_Portfolios_ME_AC_5x5", "market capitalization", "accruals", "Y"),
    list("25_Portfolios_ME_BETA_5x5", "market capitalization", "market beta", "Y"),
    list("25_Portfolios_ME_NI_5x5", "market capitalization", "net share issues", "Y"),
    list("25_Portfolios_ME_VAR_5x5", "market capitalization", "variance", "Y"),
    list("25_Portfolios_ME_RESVAR_5x5", "market capitalization", "residual variance", "Y"),
    list("25_Portfolios_BEME_OP_5x5", "book/market", "operating profitability", "Y"),
    list("25_Portfolios_BEME_OP_5x5_Wout_Div", "book/market", "operating profitability", "N"),
    list("25_Portfolios_BEME_OP_5x5_daily", "book/market", "operating profitability", "Y"),
    list("25_Portfolios_BEME_INV_5x5", "book/market", "investment", "Y"),
    list("25_Portfolios_BEME_INV_5x5_Wout_Div", "book/market", "investment", "N"),
    list("25_Portfolios_BEME_INV_5x5_daily", "book/market", "investment", "Y"),
    list("25_Portfolios_OP_INV_5x5", "operating profitability", "investment", "Y"),
    list("25_Portfolios_OP_INV_5x5_Wout_Div", "operating profitability", "investment", "N"),
    list("25_Portfolios_OP_INV_5x5_daily", "operating profitability", "investment", "Y"))
  us <- data.table::data.table(
    file = vapply(us_rows, `[[`, "", 1L),
    region = "US",
    `sort variable 1` = vapply(us_rows, `[[`, "", 2L),
    `sort variable 2` = vapply(us_rows, `[[`, "", 3L),
    dividend = vapply(us_rows, `[[`, "", 4L))
  regions <- list(
    list("developed", "Developed_"),
    list("developed (ex US)", "Developed_ex_US_"),
    list("Europe", "Europe_"),
    list("JP", "Japan_"),
    list("Asia-Pacific (ex JP)", "Asia_Pacific_ex_Japan_"),
    list("North America", "North_America_"))
  regional <- data.table::rbindlist(lapply(regions, function(x) {
    data.table::data.table(
      file = paste0(x[[2L]], c("25_Portfolios_ME_BE-ME", "25_Portfolios_ME_BE-ME_daily",
                               "25_Portfolios_ME_OP", "25_Portfolios_ME_OP_Daily",
                               "25_Portfolios_ME_INV", "25_Portfolios_ME_INV_Daily",
                               "25_Portfolios_ME_Prior_12_2", "25_Portfolios_ME_Prior_250_20_daily")),
      region = x[[1L]],
      `sort variable 1` = "market capitalization",
      `sort variable 2` = rep(c("book/market", "operating profitability", "investment", "momentum"), each = 2L),
      dividend = "Y")
  }))
  sources <- data.table::rbindlist(list(us, regional))
  sources[, weights := rep(list(c("value", "equal")), .N)]
  sources[]
}

#' Build the `portfolios_bivariate` dataset
#'
#' Concrete `DatasetBuilder`: reads every bivariate portfolio file listed in
#' `sources` through a `LinesSource`, parses it with a `PortfolioParser`, tags
#' the region, sort and dividend labels from the mapping and keeps only the
#' committed field vocabulary.
#'
#' The rebuilt dataset spans the full library history (tens of millions of
#' rows), so the build is memory-bounded: `read_tables()` converts each file
#' to the shipped column types and spills it to `spill_dir` as an uncompressed
#' RDS, and `assemble()` pre-allocates the final table once and fills it block
#' by block. No step holds two copies of the full dataset, which keeps the
#' build inside the 3 GB container.
#'
#' @noRd
BivariateBuilder <- R6::R6Class(
  "BivariateBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = PortfolioParser$new(), sources = bivariate_sources(),
                          spill_dir = tempfile(pattern = "bivariate-")) {
      super$initialize("portfolios_bivariate")
      private$source <- source
      private$parser <- parser
      private$sources <- sources
      private$spill_dir <- spill_dir
    }
  ),
  private = list(
    source = NULL,
    parser = NULL,
    sources = NULL,
    spill_dir = NULL,
    read_tables = function() {
      dir.create(private$spill_dir, recursive = TRUE, showWarnings = FALSE)
      blocks <- list()
      for (i in seq_len(nrow(private$sources))) {
        table <- private$read_file(private$sources[i, ])
        for (freq in levels(table$frequency)) {
          block <- table[frequency == freq]
          if (!nrow(block)) next
          data.table::setorder(block, weights, portfolio, field, period)
          path <- file.path(private$spill_dir, paste0("block-", length(blocks) + 1L, ".rds"))
          saveRDS(block, path, compress = FALSE)
          blocks[[length(blocks) + 1L]] <- data.table::data.table(
            path = path, nrow = nrow(block),
            region = block$region[[1L]], frequency = factor(freq, levels(table$frequency)),
            `sort variable 1` = block$`sort variable 1`[[1L]],
            `sort variable 2` = block$`sort variable 2`[[1L]],
            dividend = block$dividend[[1L]])
          rm(block)
        }
        rm(table)
        gc()
      }
      data.table::rbindlist(blocks)
    },
    read_file = function(row) {
      lines <- private$source$read_lines(row$file)
      table <- private$parser$parse(lines)
      table <- table[field %in% bivariate_fields()]
      levels <- bivariate_levels()
      table[, `:=`(region = factor(row$region, levels$region),
                   `sort variable 1` = factor(row$`sort variable 1`, levels$`sort variable 1`),
                   `sort variable 2` = factor(row$`sort variable 2`, levels$`sort variable 2`),
                   dividend = factor(row$dividend, levels$dividend),
                   weights = factor(weights, levels$weights),
                   field = factor(field, levels$field),
                   frequency = factor(frequency, levels$frequency))]
      table[]
    },
    assemble = function(tables) {
      on.exit(unlink(private$spill_dir, recursive = TRUE))
      blocks <- tables
      data.table::setorder(blocks, region, frequency, `sort variable 1`, `sort variable 2`, dividend)
      final <- private$allocate(sum(blocks$nrow))
      offset <- 0L
      for (i in seq_len(nrow(blocks))) {
        block <- readRDS(blocks$path[[i]])
        rows <- offset + seq_len(nrow(block))
        for (column in names(final)) {
          value <- block[[column]]
          if (is.factor(value)) value <- as.integer(value)
          data.table::set(final, i = rows, j = column, value = value)
        }
        offset <- offset + nrow(block)
        rm(block)
      }
      private$label_factors(final)
      if (anyDuplicated(final, by = bivariate_key()) > 0L) {
        stop("`portfolios_bivariate` has duplicate observations on its key.", call. = FALSE)
      }
      final[]
    },
    allocate = function(n) {
      data.table::data.table(
        region = integer(n), frequency = integer(n),
        `sort variable 1` = integer(n), `sort variable 2` = integer(n),
        dividend = integer(n), weights = integer(n),
        portfolio = character(n), field = integer(n),
        period = character(n), value = numeric(n))
    },
    label_factors = function(table) {
      levels <- bivariate_levels()
      for (column in names(levels)) {
        data.table::set(table, j = column,
                        value = structure(table[[column]], levels = levels[[column]], class = "factor"))
      }
      invisible(table)
    }
  )
)

#' Create the bivariate builder
#'
#' `BivariateBuilderFactory$create()` wires a `BivariateBuilder` to the live
#' library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`. `spill_dir` holds the intermediate blocks
#' during the build; point it at a roomy disk for the full regeneration.
#'
#' @noRd
BivariateBuilderFactory <- R6::R6Class(
  "BivariateBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new(),
                      spill_dir = tempfile(pattern = "bivariate-")) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      BivariateBuilder$new(source, spill_dir = spill_dir)
    }
  )
)

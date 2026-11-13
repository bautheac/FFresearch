# Breakpoints dataset -----------------------------------------------------------------

#' Build the `breakpoints` dataset
#'
#' Concrete `DatasetBuilder`: reads every breakpoints file listed in `sources`
#' through a `LinesSource`, parses it with a `BreakpointsParser`, factors the
#' key columns with the committed levels and returns one long table of NYSE
#' breakpoints ordered by variable, frequency, percentile and period. All
#' files are US; the dataset has no region column.
#'
#' @noRd
BreakpointsBuilder <- R6::R6Class(
  "BreakpointsBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = BreakpointsParser$new(), sources = breakpoints_sources()) {
      super$initialize("breakpoints")
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
        private$parser$parse(lines, private$sources$variable[[i]])
      })
      data.table::rbindlist(tables)
    },
    assemble = function(tables) {
      breakpoints <- tables[, .(variable = factor(variable, breakpoints_variables()),
                                frequency = factor(frequency, c("month", "year")),
                                percentile = factor(percentile, breakpoints_percentiles()),
                                period, value)]
      data.table::setorder(breakpoints, variable, frequency, percentile, period)
      breakpoints[]
    }
  )
)

#' Create the breakpoints builder
#'
#' `BreakpointsBuilderFactory$create()` wires a `BreakpointsBuilder` to the
#' live library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`.
#'
#' @noRd
BreakpointsBuilderFactory <- R6::R6Class(
  "BreakpointsBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new()) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      BreakpointsBuilder$new(source)
    }
  )
)

breakpoints_variables <- function() {
  c("size", "book/market", "operating profitability", "investment",
    "earnings/price", "cash flow/price", "dividend/price", "pior returns")
}

breakpoints_percentiles <- function() {
  c("# positive", paste0(seq(5, 100, by = 5), "%"), "# negative")
}

# One row per library file: variable label, file stem. All files are US.
# "pior returns" keeps the committed typo for compatibility (spec #3, story 7).
breakpoints_sources <- function() {
  data.table::data.table(
    variable = c("size", "book/market", "operating profitability", "investment",
                 "earnings/price", "cash flow/price", "dividend/price", "pior returns"),
    file = c("ME_Breakpoints", "BE-ME_Breakpoints", "OP_Breakpoints", "INV_Breakpoints",
             "E-P_Breakpoints", "CF-P_Breakpoints", "D-P_Breakpoints", "Prior_2-12_Breakpoints"))
}

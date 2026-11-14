# Dataset builders ------------------------------------------------------------------

## Abstract implementation -----------------------------------------------------------

#' Dataset builder role
#'
#' `DatasetBuilder` implements `build()` as a Template Method: it fixes a
#' two-step algorithm and leaves the steps to private hooks that concrete
#' builders (for example `FactorsBuilder`) must override.
#'
#' 1. **Read tables** (`read_tables()`): fetch and parse the library files the
#'    dataset is made from.
#' 2. **Assemble** (`assemble(tables)`): combine the tables into the data frame
#'    shipped as `data/<name>.rda`.
#'
#' @noRd
DatasetBuilder <- R6::R6Class(
  "DatasetBuilder",
  public = list(
    name = NULL,
    initialize = function(name) {
      if (identical(class(self)[[1]], "DatasetBuilder")) {
        stop("`DatasetBuilder` is abstract and cannot be instantiated directly.", call. = FALSE)
      }
      self$name <- name
    },
    build = function() {
      tables <- private$read_tables()
      private$assemble(tables)
    }
  ),
  private = list(
    read_tables = function() {
      stop("`read_tables()` must be implemented by a dataset builder.", call. = FALSE)
    },
    assemble = function(tables) {
      stop("`assemble()` must be implemented by a dataset builder.", call. = FALSE)
    }
  )
)

## Coverage start ------------------------------------------------------------------------

#' Coverage start of the shipped time series
#'
#' Maintainer decision (2026-11-14, spec #3 follow-up): every series starts
#' in 1971. R's lazyload database cannot serialise objects larger than
#' 2^31 - 1 bytes: the full-history bivariate (34.8M rows) serialises to
#' 2,363,328,315 bytes and fails standard installation on every platform.
#' Starting in 1971 keeps every dataset under the limit. The decision was
#' extended to `factors` the same day; `variables` has no periods. This
#' overrides spec #3's no-trimming rule.
#'
#' @noRd
coverage_start <- function() {
  c(year = "1971", month = "197101", day = "19710101")
}

#' Drop observations before the coverage start
#'
#' Filters a parsed long table (character `frequency` and `period` columns) to
#' the coverage start of its frequency. Builders apply it per library file,
#' before tables are combined, so pre-1971 rows never reach the assembled
#' dataset.
#'
#' @noRd
keep_coverage_start <- function(table) {
  start <- coverage_start()
  table[period >= start[as.character(frequency)]]
}

## Writer ------------------------------------------------------------------------------

#' Save a built dataset
#'
#' `DatasetWriter$write(builder)` builds the dataset and saves it as
#' `<dir>/<name>.rda`, returning the path invisibly.
#'
#' @noRd
DatasetWriter <- R6::R6Class(
  "DatasetWriter",
  public = list(
    initialize = function(dir = "data") {
      private$dir <- dir
    },
    write = function(builder) {
      if (!inherits(builder, "DatasetBuilder")) {
        stop("`builder` must be a `DatasetBuilder`.", call. = FALSE)
      }
      dataset <- builder$build()
      path <- file.path(private$dir, paste0(builder$name, ".rda"))
      assign(builder$name, dataset)
      save(list = builder$name, file = path, compress = "xz", version = 2L)
      invisible(path)
    }
  ),
  private = list(
    dir = NULL
  )
)

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

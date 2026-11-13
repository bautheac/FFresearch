# Sources of library file contents -----------------------------------------------

## Interface -----------------------------------------------------------------------

#' Lines source role
#'
#' `LinesSource` is the abstract role every source of Kenneth French library
#' files fulfils: `read_lines(file)` returns the lines of the CSV stored in
#' the library archive named by the file stem (for example
#' `"F-F_Momentum_Factor"`). Concrete sources are `HttpZipSource` and the
#' `CachedSource` decorator; tests supply their own subclass so that no
#' network access is needed.
#'
#' @noRd
LinesSource <- R6::R6Class(
  "LinesSource",
  public = list(
    initialize = function() {
      if (identical(class(self)[[1]], "LinesSource")) {
        stop("`LinesSource` is abstract and cannot be instantiated directly.", call. = FALSE)
      }
    },
    read_lines = function(file) {
      stop("`read_lines()` must be implemented by a lines source.", call. = FALSE)
    }
  )
)

## Implementations -------------------------------------------------------------------

#' Download library files over HTTP
#'
#' Downloads `<base_url><file>_CSV.zip` and returns the lines of the CSV inside
#' it, retrying failed downloads up to `retries` times. The `download()` hook
#' performs one attempt and may be overridden by subclasses.
#'
#' @noRd
HttpZipSource <- R6::R6Class(
  "HttpZipSource",
  inherit = LinesSource,
  public = list(
    initialize = function(base_url = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/",
                          retries = 3L) {
      private$base_url <- base_url
      private$retries <- retries
    },
    read_lines = function(file) {
      url <- paste0(private$base_url, file, "_CSV.zip")
      private$download_with_retries(url)
    }
  ),
  private = list(
    base_url = NULL,
    retries = NULL,
    download_with_retries = function(url) {
      for (attempt in seq_len(private$retries)) {
        result <- tryCatch(private$download(url), error = function(error) error)
        if (!inherits(result, "error")) return(result)
      }
      stop("Could not download ", url, ": ", conditionMessage(result), call. = FALSE)
    },
    download = function(url) {
      archive <- tempfile(fileext = ".zip")
      on.exit(unlink(archive))
      utils::download.file(url, archive, mode = "wb", quiet = TRUE)
      readLines(unz(archive, utils::unzip(archive, list = TRUE)$Name[[1L]]), warn = FALSE)
    }
  )
)

#' Cache another source on disk
#'
#' Decorates a `LinesSource`: a file is read from `source` once, stored under
#' `cache_dir`, and served from there afterwards.
#'
#' @noRd
CachedSource <- R6::R6Class(
  "CachedSource",
  inherit = LinesSource,
  public = list(
    initialize = function(source, cache_dir) {
      private$source <- source
      private$cache_dir <- cache_dir
    },
    read_lines = function(file) {
      path <- file.path(private$cache_dir, paste0(file, ".csv"))
      if (file.exists(path)) return(readLines(path, warn = FALSE))

      lines <- private$source$read_lines(file)
      dir.create(private$cache_dir, showWarnings = FALSE, recursive = TRUE)
      writeLines(lines, path)
      lines
    }
  ),
  private = list(
    source = NULL,
    cache_dir = NULL
  )
)

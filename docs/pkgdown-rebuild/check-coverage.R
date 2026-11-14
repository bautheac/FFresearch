#!/usr/bin/env Rscript
# Assert the coverage the rebuilt site claims, against the shipped datasets.
#
#   check-coverage.R [repo-root]
#
# The rebuilt site's headline claim is 1971 -> 2026-09 for every series (the
# maintainer trim decision recorded in docs/verification-spec-3.md) with regions
# labelled `developed` / `developed (ex US)`. HTML that says so is only correct
# if the data does, so this reads the committed data/ .rda files and reports, per
# dataset and per series, the earliest and latest period plus the region levels.
#
# The expected boundary is restated here rather than read from coverage_start()
# in R/dataset-builder.R: a check that inherits its expectation from the code it
# checks proves nothing.
#
# Memory: one dataset per iteration, released before the next. portfolios_bivariate
# alone is ~1.9 GB, so holding two at once OOMs a 3-4 GB container.
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) normalizePath(args[1]) else "/work"
data_dir <- file.path(root, "data")
stopifnot(dir.exists(data_dir))
suppressPackageStartupMessages(library(data.table))

BOUNDARY <- list(day = 19710101L, month = 197101L, year = 1971L)
EXPECTED_REGIONS <- c("US", "developed", "developed (ex US)", "Europe", "JP",
                      "Asia-Pacific (ex JP)", "North America")

# Minimum period per (series keys, frequency), checked against the boundary for
# that frequency. period is a character "YYYYMMDD"/"YYYYMM"/"YYYY", so integers
# compare numerically and stay sortable as text.
check_dataset <- function(nm, path) {
  e <- new.env(parent = emptyenv())
  load(path, envir = e)
  x <- as.data.table(get(nm, envir = e))
  cat("\n===", nm, "---", nrow(x), "rows |", paste(names(x), collapse = ", "), "\n")
  if (!"period" %in% names(x)) {
    cat("no period column: helper dataset, the site makes no coverage claim for it\n")
    rm(list = ls(e), envir = e); gc(verbose = FALSE)
    return(data.table(dataset = nm, series = "<no periods>", frequency = NA_character_,
                      min_period = NA_character_, max_period = NA_character_,
                      n = nrow(x), starts_ok = NA, regions = NA_character_))
  }
  extra <- intersect(c("region", "variable", "factor"), names(x))
  by <- c(extra, "frequency")
  agg <- x[, list(min_period = min(period), max_period = max(period), n = .N), by = by]
  agg[, starts_ok := mapply(function(freq, p) {
    b <- BOUNDARY[[freq]]
    if (is.null(b)) return(NA)
    as.integer(p) >= b
  }, as.character(frequency), as.character(min_period))]
  agg[, series := if (length(extra)) do.call(paste, c(.SD, list(sep = "/"))) else "<all>",
      .SDcols = extra]
  print(agg[, c("series", "frequency", "min_period", "max_period", "n", "starts_ok")],
        row.names = FALSE, digits = 12)
  # NA means an unrecognised frequency: not verifiable, so not a pass.
  bad <- agg[isFALSE(starts_ok) | is.na(starts_ok), ]
  if (nrow(bad)) {
    cat("FAIL: series not starting at the 1971 boundary (or with an unknown frequency):\n")
    print(bad)
    stop("COVERAGE_FAIL")
  }
  if ("region" %in% names(x)) {
    regs <- levels(x$region)
    cat("region levels:", paste(regs, collapse = " | "), "\n")
    stale <- intersect(regs, c("global", "global (ex US)"))
    if (length(stale)) stop("STALE_REGION_LABELS in ", nm, ": ", paste(stale, collapse = ", "))
    unexpected <- setdiff(regs, c(EXPECTED_REGIONS, "US"))
    if (length(unexpected)) warning("unexpected region labels in ", nm, ": ",
                                    paste(unexpected, collapse = ", "))
  } else {
    cat("region levels: (no region column)\n")
  }
  cat(sprintf("coverage: %d series, periods %s .. %s\n", nrow(agg),
              min(agg$min_period), max(agg$max_period)))
  rm(list = ls(e), envir = e); gc(verbose = FALSE)
  invisible(agg)
}

rdas <- sort(list.files(data_dir, pattern = "[.]rda$"))
stopifnot(length(rdas) == 7L)
cat("datasets:", paste(sub("[.]rda$", "", rdas), collapse = ", "), "\n")

for (f in rdas) check_dataset(sub("[.]rda$", "", f), file.path(data_dir, f))

cat("\nCOVERAGE_OK: every period-bearing series in the shipped data starts at or",
    "after the 1971 boundary\n")

#!/usr/bin/env Rscript
# Write fixture data directories for tests.sh: seven .rda files shaped like the
# real package's, in three variants.
#
#   negative-fixtures.R <out-root>
#     <out-root>/good/data          coverage from 197101, regions relabelled
#     <out-root>/stale-start/data   a series starting 197012 (pre-trim)
#     <out-root>/stale-label/data   a region still labelled 'global'
#
# Each variant is a fake repo root: check-coverage.R takes a root and reads
# root/data/*.rda.
#
# Object names must match the file names: check-coverage.R asserts that, as
# R CMD INSTALL's lazyload step does.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else stop("usage: negative-fixtures.R <out-root>")

names <- c("breakpoints", "factors", "portfolios_bivariate", "portfolios_industries",
            "portfolios_trivariate", "portfolios_univariate", "variables")

mk <- function(dir, nm, df) {
  e <- new.env()
  assign(nm, df, envir = e)
  save(list = nm, file = file.path(dir, paste0(nm, ".rda")), envir = e)
}

fill <- function(dir, period, region) {
  dir <- file.path(dir, "data")   # a repo root holds its .rda files in data/
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  for (nm in names) {
    if (nm == "variables") {
      mk(dir, nm, data.frame(name = "market capitalization", symbol = "ME",
                             description = "size"))
    } else if (nm == "breakpoints") {
      mk(dir, nm, data.frame(variable = factor("size"), frequency = factor("month"),
                             percentile = factor("0"), period = period, value = 1))
    } else if (nm == "factors") {
      mk(dir, nm, data.frame(region = factor(region), frequency = factor("month"),
                             factor = factor("market"), period = period, value = 1))
    } else {
      mk(dir, nm, data.frame(region = factor(region), frequency = factor("month"),
                             period = period, value = 1))
    }
  }
}

fill(file.path(out, "good"), "197101", "developed")
fill(file.path(out, "stale-start"), "197012", "developed")
fill(file.path(out, "stale-label"), "197101", "global")
cat("NEGATIVE_FIXTURES_OK", out, "\n")

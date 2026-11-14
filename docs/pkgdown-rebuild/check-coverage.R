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

# This process's resident-set high-water mark, from /proc. Deliberately not
# /sys/fs/cgroup/memory.peak: that is the container's init-cgroup counter, and a
# process started by `docker exec` lands in a different subtree, so it read
# 0.06 GiB for a run that had held a 1.4 GB object.
peak <- function() {
  f <- "/proc/self/status"
  if (!file.exists(f)) return(NA_real_)
  line <- grep("^VmHWM:", readLines(f, warn = FALSE), value = TRUE)
  if (!length(line)) return(NA_real_)
  as.numeric(sub("VmHWM:\\s+([0-9]+).*", "\\1", line[1])) * 1024
}

# Minimum period per (series keys, frequency), checked against the boundary for
# that frequency. period is a character "YYYYMMDD"/"YYYYMM"/"YYYY", so integers
# compare numerically and stay sortable as text.
check_dataset <- function(nm, path) {
  e <- new.env(parent = emptyenv())
  load(path, envir = e)
  x <- get(nm, envir = e)
  # Do NOT wrap this in as.data.table(): the shipped datasets are already
  # data.tables (only `variables`, a 0 MB tibble, is not), and as.data.table()
  # on a data.table is a full copy -- 1.4 GB for the bivariate, which got this
  # pass OOM-killed. See the peak note at the foot of the script.
  if (!inherits(x, "data.table")) x <- as.data.table(x)
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
  # Region levels are a claim the site makes, so read them before the table is
  # reduced to the columns the aggregation needs.
  regs <- if ("region" %in% names(x)) levels(x$region) else NULL
  # Reduce in place before aggregating: :=(col = NULL) frees those columns,
  # while subsetting into a new table (x[, c(by, "period"), with = FALSE])
  # holds the original and the copy at once.
  x[, (setdiff(names(x), c(by, "period"))) := NULL]
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
  if (is.null(regs)) {
    cat("region levels: (no region column)\n")
  } else {
    cat("region levels:", paste(regs, collapse = " | "), "\n")
    stale <- intersect(regs, c("global", "global (ex US)"))
    if (length(stale)) stop("STALE_REGION_LABELS in ", nm, ": ", paste(stale, collapse = ", "))
    unexpected <- setdiff(regs, c(EXPECTED_REGIONS, "US"))
    if (length(unexpected)) warning("unexpected region labels in ", nm, ": ",
                                    paste(unexpected, collapse = ", "))
  }
  rss <- peak()
  cat(sprintf("coverage: %d series, periods %s .. %s%s\n", nrow(agg),
              min(agg$min_period), max(agg$max_period),
              if (is.na(rss)) "" else sprintf(" | peak RSS %.2f GiB", rss / 1073741824)))
  rm(list = ls(e), envir = e); gc(verbose = FALSE)
  invisible(agg)
}

rdas <- sort(list.files(data_dir, pattern = "[.]rda$"))
stopifnot(length(rdas) == 7L)
cat("datasets:", paste(sub("[.]rda$", "", rdas), collapse = ", "), "\n")

checked <- character()
for (f in rdas) {
  nm <- sub("[.]rda$", "", f)
  check_dataset(nm, file.path(data_dir, f))
  checked <- c(checked, nm)
}
# Vacuity guard: COVERAGE_OK below is a claim about the data, so it must not
# print unless every dataset was actually examined. (An edit once deleted this
# loop and the script reported success having loaded nothing.)
if (length(checked) != 7L) {
  stop("checked ", length(checked), " of 7 datasets: ",
       paste(setdiff(sub("[.]rda$", "", rdas), checked), collapse = ", "),
       call. = FALSE)
}

cat("\nCOVERAGE_OK: every period-bearing series in the shipped data starts at or",
    "after the 1971 boundary\n")
p <- peak()
if (!is.na(p)) {
  cat(sprintf("process peak RSS: %.2f GiB\n", p / 1073741824))
}
# Peak note: the obvious implementation -- as.data.table() on every dataset and
# a fresh table for the aggregation -- was OOM-killed (exit 137) on the
# bivariate in a 4 GiB container, because it held the original and two copies at
# once. Loading without copying, and :=(col = NULL) to drop unneeded columns in
# place, fits. The peak RSS printed above is the reliable figure: the container's
# /sys/fs/cgroup/memory.peak disagrees with it in both directions (it counted
# 0.06 GiB for a run that had held a 1.4 GB object, since docker exec lands in a
# different cgroup subtree). If the datasets grow, run one dataset per fresh
# process, as the finRes article checks do.

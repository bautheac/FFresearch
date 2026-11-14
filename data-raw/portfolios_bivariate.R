# Rebuild `data/portfolios_bivariate.rda` from Kenneth French's data library.
# Run from the package root: Rscript data-raw/portfolios_bivariate.R
#
# The dataset spans 1971 onwards (maintainer decision 2026-11-14: R's
# lazyload DB cannot serialise objects above 2^31 - 1 bytes; see
# coverage_start() in R/dataset-builder.R). Tens of millions of rows: the
# builder spills typed blocks to `spill_dir` and fills one pre-allocated
# table, so the build stays inside the 3 GB container. Keep the spill on a
# roomy disk.
#
# The parse phase leaves freed memory in the allocator's arenas; without
# MALLOC_ARENA_MAX=2 the assemble allocation can OOM the 3 GB container.
# The variable must be set before the process starts, so re-exec once.
if (Sys.getenv("FFRESEARCH_BIV_BUILD") != "1") {
  Sys.setenv(FFRESEARCH_BIV_BUILD = "1", MALLOC_ARENA_MAX = "2")
  status <- system2("Rscript", "data-raw/portfolios_bivariate.R")
  quit(save = "no", status = status)
}
for (f in list.files("R", pattern = "[.]r$", ignore.case = TRUE, full.names = TRUE)) {
  if (!basename(f) %in% c("data.r", "FFresearch-package.R")) source(f)
}
library(data.table)
DatasetWriter$new("data")$write(BivariateBuilderFactory$new()$create(
  cache_dir = "data-raw/cache", spill_dir = "data-raw/cache/bivariate-spill"))

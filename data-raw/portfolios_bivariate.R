# Rebuild `data/portfolios_bivariate.rda` from Kenneth French's data library.
# Run from the package root: Rscript data-raw/portfolios_bivariate.R
#
# The full library history is tens of millions of rows; the builder spills
# typed blocks to `spill_dir` and fills one pre-allocated table, so the build
# stays inside the 3 GB container. Keep the spill on a roomy disk.
for (f in list.files("R", pattern = "[.]r$", ignore.case = TRUE, full.names = TRUE)) {
  if (!basename(f) %in% c("data.r", "FFresearch-package.R")) source(f)
}
library(data.table)
DatasetWriter$new("data")$write(BivariateBuilderFactory$new()$create(
  cache_dir = "data-raw/cache", spill_dir = "data-raw/cache/bivariate-spill"))

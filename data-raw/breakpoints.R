# Rebuild `data/breakpoints.rda` from Kenneth French's data library.
# Run from the package root: Rscript data-raw/breakpoints.R
for (f in list.files("R", pattern = "[.]r$", ignore.case = TRUE, full.names = TRUE)) {
  if (!basename(f) %in% c("data.r", "FFresearch-package.R")) source(f)
}
library(data.table)
DatasetWriter$new("data")$write(BreakpointsBuilderFactory$new()$create(cache_dir = "data-raw/cache"))

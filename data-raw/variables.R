# Rebuild `data/variables.rda` from the field inventories of the other
# shipped datasets. Run from the package root, with the package installed
# carrying the rebuilt datasets: Rscript data-raw/variables.R
for (f in list.files("R", pattern = "[.]r$", ignore.case = TRUE, full.names = TRUE)) {
  if (!basename(f) %in% c("data.r", "FFresearch-package.R")) source(f)
}
library(data.table)
DatasetWriter$new("data")$write(VariablesBuilderFactory$new()$create())

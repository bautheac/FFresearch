#!/usr/bin/env Rscript
# Ticket #16: the finRes asset-pricing article's `load FFresearch` chunk
# VERBATIM (all seven datasets in one data() call), plus the article's head()
# chunks. Runs in the 3 GB ffr-r container; the rebuilt datasets total
# ~2.3 GB in memory, so this also measures whether the article's
# load-everything-at-once pattern still fits.
.libPaths(c("/work/.worktrees/rlib-t16", .libPaths()))
cat("FFresearch from:", find.package("FFresearch"), "\n")
library(FFresearch)
data(list = c(
  "factors", "portfolios_univariate", "portfolios_bivariate", "portfolios_trivariate",
  "portfolios_industries", "variables", "breakpoints"),
  package = "FFresearch"
  )
for (nm in c("portfolios_univariate", "portfolios_bivariate",
             "portfolios_trivariate", "portfolios_industries", "factors",
             "variables", "breakpoints")) {
  cat("--- head(", nm, ")\n", sep = "")
  print(head(get(nm)))
}
cat("ARTICLE_LOAD_VERBATIM_OK\n")

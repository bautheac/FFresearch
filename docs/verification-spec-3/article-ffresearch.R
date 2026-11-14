#!/usr/bin/env Rscript
# Ticket #16: finRes asset-pricing article, FFresearch + factors sections.
# Vignette chunks executed: `load FFresearch` (all seven dataset names),
# head() of each dataset, `factors load`, head(fama_french), head(stambaugh).
# Deviations: the article loads all seven datasets in one data() call; the
# rebuilt data totals ~2.3 GB in memory, above the 2 GB fct-r container, so
# each dataset is loaded in its own fresh R process here (argument = dataset
# name; no argument = the article's factors section). The verbatim
# all-at-once load was executed separately in the 3 GB ffr-r container and
# passed (peak ~2.6 GB).
.libPaths(c("/tmp/rlib-t16", .libPaths()))
args <- commandArgs(trailingOnly = TRUE)

contract <- list(
  breakpoints = c("variable", "frequency", "percentile", "period", "value"),
  factors = c("region", "frequency", "factor", "period", "value"),
  portfolios_univariate = c("region", "frequency", "sort variable", "dividend",
                            "weights", "portfolio", "field", "period", "value"),
  portfolios_bivariate = c("region", "frequency", "sort variable 1",
                           "sort variable 2", "dividend", "weights",
                           "portfolio", "field", "period", "value"),
  portfolios_trivariate = c("region", "frequency", "sort variable 1",
                            "sort variable 2", "sort variable 3", "dividend",
                            "weights", "portfolio", "field", "period", "value"),
  portfolios_industries = c("region", "frequency", "dividend", "weights",
                            "portfolio", "field", "period", "value"),
  variables = c("name", "symbol", "description"))
rows <- c(breakpoints = 61044L, factors = 598646L, variables = 48L,
          portfolios_industries = 4734188L, portfolios_univariate = 4309354L,
          portfolios_trivariate = 1439544L, portfolios_bivariate = 34827461L)

if (length(args)) {
  nm <- args[[1L]]
  cat("FFresearch from:", find.package("FFresearch"), "\n")
  library(FFresearch)
  e <- new.env()
  data(list = nm, package = "FFresearch", envir = e)
  d <- e[[nm]]
  stopifnot(identical(names(d), contract[[nm]]), nrow(d) == rows[[nm]])
  cat("---", nm, ":", nrow(d), "rows,", ncol(d), "cols (contract OK)\n")
  print(head(d))
  if ("region" %in% names(d)) {
    lv <- levels(d$region)
    stopifnot(!any(grepl("global", lv, fixed = TRUE)))
    if (nm %in% c("factors", "portfolios_bivariate", "portfolios_trivariate"))
      stopifnot(all(c("developed", "developed (ex US)") %in% lv))
    cat("regions:", paste(lv, collapse = " | "), "\n")
  }
  cat("ARTICLE_DATASET_OK:", nm, "\n")
} else {
  # article `factors load` chunk + head chunks
  library(factors)
  data(list = c("fama_french", "stambaugh"), package = "factors")
  print(head(fama_french))
  print(head(stambaugh))
  stopifnot(nrow(fama_french) == 598646L)
  cat("ARTICLE_FACTORS_OK\n")
}

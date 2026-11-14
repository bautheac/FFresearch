#!/bin/sh
# Ticket #16 downstream setup in fct-r: PRIVATE library /tmp/rlib-t16 with
# the rebuilt FFresearch (hybrid: factors-only lazyload DB so FFresearch::factors
# resolves for the factors drift test; the other six datasets as plain .rda,
# which utils::data() falls back to) + factors installed from /work/factors.
# Shared fct-rlib volume is NOT mutated.
set -e
rm -rf /tmp/rlib-t16 /tmp/ffsrc-factors-only
mkdir -p /tmp/rlib-t16 /tmp/ffsrc-factors-only/data
cd /tmp/FFresearch-t16
tar --exclude=.git -cf - . | (cd /tmp/ffsrc-factors-only && tar -xf -)
rm -f /tmp/ffsrc-factors-only/data/*.rda
cp data/factors.rda /tmp/ffsrc-factors-only/data/
R CMD INSTALL --no-docs --library=/tmp/rlib-t16 /tmp/ffsrc-factors-only > /tmp/fct-install.log 2>&1
lib=/tmp/rlib-t16/FFresearch
cp data/*.rda "$lib/data/"
Rscript -e '
  titles <- c(breakpoints = "Fama/French variable breakpoints",
              factors = "Fama/French research factors",
              portfolios_bivariate = "Fama/French bivariate sorts",
              portfolios_industries = "Fama/French industry portfolios",
              portfolios_trivariate = "Fama/French three-way sorts",
              portfolios_univariate = "Fama/French univariate sorts",
              variables = "Fama/French variables")
  saveRDS(cbind(names(titles), unname(titles)),
          "/tmp/rlib-t16/FFresearch/Meta/data.rds")
'
R CMD INSTALL --no-docs --library=/tmp/rlib-t16 /work/factors >> /tmp/fct-install.log 2>&1
Rscript -e '
  .libPaths(c("/tmp/rlib-t16", .libPaths()))
  cat("FFresearch:", find.package("FFresearch"), "\n")
  cat("factors:", find.package("factors"), "\n")
  cat(":: factors rows:", nrow(FFresearch::factors), "\n")
'
echo FCT_SETUP_OK

#!/usr/bin/env Rscript
# Ticket #16: memory-safe data placement for FFresearch.
# A standard lazyload install loads all seven datasets at once (>3 GB with
# the rebuilt 34.8M-row bivariate) and OOMs the 3 GB container. Even a
# single-dataset lazyload insert of the bivariate OOMs (object ~1.8 GB plus
# the serialization buffer). So: build the lazyload DB one dataset at a
# time for the six datasets that fit, reproducing tools:::data2LazyLoadDB +
# tools:::makeLazyLoadDB output:
#   data/Rdata.rdb  serialized values (xz)
#   data/Rdata.rdx  list(variables, references, compressed)
#   data/Rdata.rds  file-stem -> object-names index
# and keep portfolios_bivariate.rda as a plain file: utils::data() falls
# back to it for names absent from the DB index (verified against the
# utils::data source). All seven datasets load via data() as usual.
args <- commandArgs(trailingOnly = TRUE)
lib <- args[1]          # library containing the installed FFresearch
srcdata <- args[2]      # directory holding the seven .rda files
compress <- 3L          # xz, per DESCRIPTION LazyDataCompression

pkg <- "FFresearch"
datadir <- file.path(lib, pkg, "data")
dir.create(datadir, showWarnings = FALSE, recursive = TRUE)
rdas <- sort(list.files(srcdata, pattern = "[.]rda$", full.names = TRUE))
stopifnot(length(rdas) == 7L)
stopifnot(all(file.copy(rdas, datadir, overwrite = TRUE)))

dbbase <- file.path(datadir, "Rdata")
close(file(paste0(dbbase, ".rdb"), "wb"))
vars <- list()
dlist <- list()
dlist_all <- character()
for (f in sort(list.files(datadir, pattern = "[.]rda$"))) {
  nm <- sub("[.]rda$", "", f)
  e <- new.env(hash = TRUE)
  load(file.path(datadir, f), envir = e)
  objs <- ls(e, all.names = TRUE)
  stopifnot(identical(objs, nm))
  dlist_all <- c(dlist_all, nm)
  if (nm == "portfolios_bivariate") {
    # Too large to serialize into the DB within 3 GB; keep the .rda and let
    # utils::data() fall back to it. It must stay OUT of the Rdata.rds index:
    # data() only falls back to file loading for names absent from that index.
    cat("kept as plain rda:", nm, "\n")
  } else {
    key <- .Internal(lazyLoadDBinsertValue(e[[nm]], paste0(dbbase, ".rdb"),
                                           0L, compress, NULL))
    vars[[nm]] <- key
    dlist[[nm]] <- objs
    cat(sprintf("lazyload insert: %s (%d rows)\n", nm, nrow(e[[nm]])))
  }
  rm(e)
  invisible(gc())
}
saveRDS(list(variables = vars,
             references = structure(list(), names = character()),
             compressed = compress),
        paste0(dbbase, ".rdx"))
saveRDS(dlist, file.path(datadir, "Rdata.rds"), compress = compress)
unlink(setdiff(list.files(datadir, pattern = "[.]rda$", full.names = TRUE),
               file.path(datadir, "portfolios_bivariate.rda")))

# Data index for data(package = "FFresearch") listings: all seven datasets.
titles <- c(breakpoints = "Fama/French variable breakpoints",
            factors = "Fama/French research factors",
            portfolios_bivariate = "Fama/French bivariate sorts",
            portfolios_industries = "Fama/French industry portfolios",
            portfolios_trivariate = "Fama/French three-way sorts",
            portfolios_univariate = "Fama/French univariate sorts",
            variables = "Fama/French variables")
meta <- file.path(lib, pkg, "Meta")
dir.create(meta, showWarnings = FALSE, recursive = TRUE)
saveRDS(cbind(names(titles), unname(titles)), file.path(meta, "data.rds"))

# Verify: data() for every dataset (one at a time) and :: access to factors.
.libPaths(c(lib, .libPaths()))
for (nm in dlist_all) {
  e <- new.env()
  utils::data(list = nm, package = pkg, envir = e)
  stopifnot(nrow(e[[nm]]) > 0L)
  cat(sprintf("data(%s): %d rows OK\n", nm, nrow(e[[nm]])))
  rm(e)
  invisible(gc())
}
stopifnot(nrow(FFresearch::factors) == 598646L)
cat("FFresearch::factors OK\n")
cat("PLACE_DATA_OK\n")

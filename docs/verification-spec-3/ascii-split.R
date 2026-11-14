#!/usr/bin/env Rscript
# Ticket #16: memory-safe equivalent of R CMD check's "checking data for
# non-ASCII characters". That check (tools:::.check_package_datasets) loads
# ALL datasets into one environment and OOMs the 3 GB container. Run the
# identical function on one-dataset directories instead.
src <- "/work/.worktrees/t16-scratch/tar-src/FFresearch/data"
rdas <- sort(list.files(src, pattern = "[.]rda$", full.names = TRUE))
stopifnot(length(rdas) == 7L)
for (f in rdas) {
  d <- tempfile()
  dir.create(file.path(d, "data"), recursive = TRUE)
  stopifnot(file.copy(f, file.path(d, "data")))
  res <- tools:::.check_package_datasets(d)
  cat(basename(f), ": latin1 =", res$latin1, "utf8 =", res$utf8,
      "bytes =", res$bytes, "unknown =", nrow(res$unknown), "\n")
  if (nrow(res$unknown)) print(res$unknown)
  stopifnot(nrow(res$unknown) == 0L, res$latin1 == 0L, res$bytes == 0L)
  unlink(d, recursive = TRUE)
  invisible(gc())
}
cat("ASCII_SPLIT_OK\n")

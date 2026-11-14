#!/bin/sh
# usage: safe-install.sh <libdir> <rda-source-dir> <install-log>
set -e
lib=$1; srcdata=$2; log=$3
mkdir -p "$lib"
cd /work/.worktrees/t16-scratch
R CMD INSTALL --no-docs --no-data -l "$lib" FFresearch_0.0.1.0.tar.gz > "$log" 2>&1
{
  echo "* ticket #16 manual data placement: the full lazyload install OOMs the"
  echo "* 3 GB container (all datasets held at once; even inserting the 34.8M-row"
  echo "* bivariate alone exceeds 3 GB). place-data.R builds the lazyload DB one"
  echo "* dataset at a time for the six smaller datasets (xz, matching"
  echo "* LazyDataCompression) and keeps portfolios_bivariate.rda as a plain"
  echo "* file; utils::data() falls back to it. All seven load via data()."
} >> "$log"
Rscript place-data.R "$lib" "$srcdata" >> "$log" 2>&1
echo "* DONE (FFresearch, data placed manually)" >> "$log"

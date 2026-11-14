#!/bin/sh
# Ticket #16 task 2: full suite on the integration tip, private rlib-t16.
# The literal full install (R CMD INSTALL --no-docs --library=rlib-t16 .)
# OOMs at the lazyload step — demonstrated twice under exclusive lock by the
# R CMD check install attempts (00install.out: Killed). Documented fallback:
# --no-data + manual data placement (same hybrid layout as the check install).
cd /work/.worktrees/t16 || exit 1
lib=/work/.worktrees/rlib-t16
log=/work/.worktrees/t16-scratch/rlib-t16-install.log
rm -rf "$lib"
mkdir -p "$lib"

(
  while :; do
    anon=$(awk '/^anon /{print $2}' /sys/fs/cgroup/memory.stat)
    echo "$(date +%H:%M:%S) anon=$anon" >> /work/.worktrees/t16-scratch/mem-suite.log
    sleep 15
  done
) &
sampler=$!

R CMD INSTALL --no-docs --no-data --library="$lib" . > "$log" 2>&1
echo "install exit=$?"
Rscript /work/.worktrees/t16-scratch/place-data.R "$lib" /work/.worktrees/t16/data >> "$log" 2>&1
echo "place-data exit=$?"
tail -12 "$log"

Rscript -e '.libPaths(c("/work/.worktrees/rlib-t16", .libPaths())); testthat::test_dir("tests/testthat", package="FFresearch", load_package="installed", reporter="summary")'
echo "suite exit=$?"

echo "=== finRes article load chunk, verbatim (all seven at once)"
Rscript /work/.worktrees/t16-scratch/article-load-verbatim.R
echo "verbatim load exit=$?"

kill "$sampler" 2>/dev/null
echo "--- peak anon bytes:"
sort -t= -k2 -n /work/.worktrees/t16-scratch/mem-suite.log | tail -1

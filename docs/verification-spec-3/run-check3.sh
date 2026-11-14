#!/bin/sh
# Ticket #16: memory-safe install + full R CMD check via --install=check:.
# Stage 1: install code (--no-data), place data + build lazyload DB one
#          dataset at a time (place-data.R), log everything.
# Stage 2: R CMD check --install=check:<log> --library=<lib> (uses the
#          pre-installed package; runs ALL checks incl. the full test suite).
#          _R_CHECK_ASCII_DATA_=FALSE: that check loads all seven datasets
#          into one environment (>3 GB, OOM); it is run per-dataset instead
#          in stage 3 with the identical tools function.
# Stage 3: per-dataset non-ASCII data check (memory-safe equivalent).
cd /work/.worktrees/t16-scratch || exit 1

(
  while :; do
    anon=$(awk '/^anon /{print $2}' /sys/fs/cgroup/memory.stat)
    echo "$(date +%H:%M:%S) anon=$anon" >> mem3.log
    sleep 15
  done
) &
sampler=$!

echo "=== STAGE 1: memory-safe install"
rm -rf lib tar-src install.log
mkdir -p lib tar-src
tar -xzf FFresearch_0.0.1.0.tar.gz -C tar-src
sh safe-install.sh /work/.worktrees/t16-scratch/lib \
  /work/.worktrees/t16-scratch/tar-src/FFresearch/data \
  /work/.worktrees/t16-scratch/install.log
echo "safe-install exit=$?"
tail -15 install.log

echo "=== STAGE 2: full check against pre-installed package"
rm -rf FFresearch.Rcheck
_R_CHECK_ASCII_DATA_=FALSE R CMD check --no-manual \
  --library=/work/.worktrees/t16-scratch/lib \
  --install=check:/work/.worktrees/t16-scratch/install.log \
  FFresearch_0.0.1.0.tar.gz > check4.log 2>&1
echo "check exit=$?"
tail -25 check4.log

echo "=== STAGE 3: per-dataset non-ASCII data check"
Rscript ascii-split.R > ascii-split.log 2>&1
echo "ascii-split exit=$?"
tail -12 ascii-split.log

kill "$sampler" 2>/dev/null
echo "--- peak anon bytes:"
sort -t= -k2 -n mem3.log | tail -1

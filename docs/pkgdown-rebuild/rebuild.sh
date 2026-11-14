#!/bin/sh
# Rebuild the pkgdown site end to end: container, toolchain, build, sync, gates.
#
#   rebuild.sh [repo-root] [--container <name>] [--no-sync]
#
# The one command a reviewer can rerun to reproduce docs/ from the package.
# Steps:
#   1. ensure a rocker/r-ver container with this repo mounted at /work
#   2. install the toolchain if the build preflight says it is missing
#   3. build-site.R into the container's /scratch/site-new
#   4. copy it out to a host temp directory (the build chowns it to us)
#   5. sync-into-docs.sh it into docs/   (skipped with --no-sync: report only)
#   6. check-site.py + tests.sh; a failing gate leaves docs/ untouched
#      (--no-sync) or is reported after the sync (default)
#
# Host RAM note: the build is memory-safe (~500 MB), but a full
# R CMD INSTALL of this package is not, so nothing here installs the package.
# See docs/pkgdown-rebuild.md for the measurement.
set -e

repo=$(realpath "${1:-$(dirname "$0")/../..}")
here=$repo/docs/pkgdown-rebuild
container=ffr-r
sync=yes
while [ $# -gt 0 ]; do
  case "$1" in
    --container) container=$2; shift 2 ;;
    --no-sync) sync=no; shift ;;
    *) shift ;;
  esac
done

image=rocker/r-ver:4.5.3
if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    echo "starting existing container $container"
    docker start "$container" >/dev/null
  else
    echo "creating container $container (4g limit: the host has ~4 GB free)"
    # /scratch is a host bind so build output survives container restarts and
    # can be removed from either side. Docker creates a *missing* bind source as
    # root, which would leave the directory itself undeletable by us (the build
    # chowns site-new, not its parent) -- so create it first, as ourselves.
    mkdir -p /tmp/ffr-scratch
    chown "$(id -u):$(id -g)" /tmp/ffr-scratch 2>/dev/null || true
    docker run -d --name "$container" --memory 4g \
      -v ffr-rlib:/usr/local/lib/R/site-library \
      -v "$repo":/work -v /tmp/ffr-scratch:/scratch \
      "$image" sleep infinity >/dev/null
  fi
fi

echo "== preflight =="
if ! docker exec "$container" Rscript /work/docs/pkgdown-rebuild/build-site.R \
       --preflight-only >/tmp/rebuild-preflight.log 2>&1; then
  grep -A6 'missing build prerequisites' /tmp/rebuild-preflight.log ||
    cat /tmp/rebuild-preflight.log
  echo "== installing the toolchain it asked for =="
  docker exec "$container" sh -c 'apt-get update -qq && apt-get install -y -qq pandoc libuv1' >/dev/null 2>&1
  docker exec "$container" Rscript -e 'install.packages(c("pkgdown","roxygen2","data.table"), Ncpus=4)' >/tmp/rebuild-install.log 2>&1
fi

# Piped output must not decide the exit status: `cmd | grep` succeeds when grep
# matches, whatever the build did. So capture to a log, keep the status.
echo "== build =="
build_log=$(mktemp /tmp/ffr-build.XXXXXX)
set +e
docker exec "$container" sh -c 'rm -rf /scratch/site-new; Rscript /work/docs/pkgdown-rebuild/build-site.R' \
  >"$build_log" 2>&1
build_rc=$?
set -e
grep -Ev '^--|Reading |Writing |Copying |Adding |Bootstrap 3|tidyverse.org|Learn more|URLs ok|Favicons ok|graph metadata|Articles metadata|Reference metadata' \
  "$build_log" || true
if [ "$build_rc" -ne 0 ]; then
  echo "FAIL: build-site.R exited $build_rc; full log: $build_log"
  exit "$build_rc"
fi

out=$(mktemp -d /tmp/ffr-site.XXXXXX)
echo "== copy out to $out =="
docker cp "$container":/scratch/site-new/. "$out"/
# Ownership comes from the build's --chown; verify rather than assume.
if [ -z "$(find "$out" ! -user "$(id -u)" -print -quit)" ]; then
  echo "ok: build output is owned by uid $(id -u)"
else
  echo "NOTE: build output is not all ours; chowning via the container"
  docker run --rm -v "$out":/o "$image" chown -R "$(id -u):$(id -g)" /o
fi

echo "== gate: check the built site BEFORE touching docs/ =="
# Checking first is the point: a build that fails check-site.py must not have
# already replaced the committed site.
python3 "$here/check-site.py" "$repo" --dst "$out"

if [ "$sync" = yes ]; then
  echo "== sync into docs/ =="
  sh "$here/sync-into-docs.sh" "$out" "$repo/docs"
  echo "== gate: the synced docs/ =="
  python3 "$here/check-site.py" "$repo"
fi

echo "== gate tests =="
tlog=$(mktemp /tmp/ffr-tests.XXXXXX)
set +e
sh "$here/tests.sh" "$repo" --in-container "$container" >"$tlog" 2>&1
tests_rc=$?
set -e
tail -3 "$tlog"
if [ "$tests_rc" -ne 0 ]; then
  echo "FAIL: tests.sh exited $tests_rc; full log: $tlog"
  exit "$tests_rc"
fi

echo "== result =="
git -C "$repo" status --short -- docs _pkgdown.yml | sed 's/^/  /'
git -C "$repo" diff --stat -- docs _pkgdown.yml | tail -1
rm -rf "$out"
echo "REBUILD_OK (container $container left running; tear down with: docker rm -f $container && docker volume rm ffr-rlib)"

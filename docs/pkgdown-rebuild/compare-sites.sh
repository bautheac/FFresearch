#!/bin/sh
# Compare two built pkgdown sites, ignoring the build timestamp in pkgdown.yml.
#
#   compare-sites.sh <site-a> <site-b>
#
# Exits 0 with SITES_IDENTICAL when they hold the same files with the same
# bytes. Used to prove the install-less build in build-site.R produces exactly
# what pkgdown's normal path produces (docs/pkgdown-rebuild.md, "equivalence").
set -e

a=$(realpath "${1:?usage: compare-sites.sh <site-a> <site-b>}")
b=$(realpath "${2:?usage: compare-sites.sh <site-a> <site-b>}")

tmp_a=$(mktemp -d); tmp_b=$(mktemp -d)
trap 'rm -rf "$tmp_a" "$tmp_b"' EXIT INT TERM
cp -a "$a"/. "$tmp_a"/
cp -a "$b"/. "$tmp_b"/
for f in "$tmp_a/pkgdown.yml" "$tmp_b/pkgdown.yml"; do
  [ -f "$f" ] && sed -i 's/^last_built:.*/last_built: X/' "$f"
done

if diff -r "$tmp_a" "$tmp_b"; then
  echo "SITES_IDENTICAL"
else
  echo "SITES_DIFFER"
  exit 1
fi

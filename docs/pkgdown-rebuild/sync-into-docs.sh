#!/bin/sh
# Sync pkgdown build output into docs/ while preserving the repo's own content
# under docs/.
#
#   sync-into-docs.sh <site-src> <docs-dst>
#
# docs/ holds two kinds of file: pkgdown output (HTML pages, pkgdown.yml,
# sitemap.xml, the BS3 assets) and repo documentation that happens to live
# inside the ignored docs/ directory (docs/agents/, docs/verification-spec-3*,
# docs/pkgdown-build/, and the rebuild record). Only the former is replaced or
# pruned.
#
# Pruning matters: pkgdown only writes, it never removes, so a page renamed or
# dropped upstream would otherwise linger in the committed site forever.
# pkgdown never emits markdown, R, shell or Python, so those extensions are
# never candidates for deletion, and nothing inside a PRESERVE directory is
# ever touched at all -- an earlier version of this script deleted the rebuild
# record sitting next to index.html.
set -e

site_src=$(realpath "${1:?usage: sync-into-docs.sh <site-src> <docs-dst>}")
docs_dst=$(realpath "${2:?usage: sync-into-docs.sh <site-src> <docs-dst>}")

# Paths under docs_dst that belong to the repo, not pkgdown. This script's own
# directory is always preserved -- derived from $0 rather than hardcoded, so the
# list cannot drift when the tooling is renamed (which it has been once).
here=$(realpath "$(dirname "$(readlink -f "$0" || echo "$0")")")
self_rel=$(realpath -m --relative-to="$docs_dst" "$here")
PRESERVE="agents verification-spec-3.md verification-spec-3"
case "$self_rel" in
  ../*|/*) : ;;                      # script lives outside docs_dst: nothing to add
  .) : ;;                            # script sits at the docs root itself
  *) PRESERVE="$PRESERVE $self_rel" ;;
esac

# Extensions pkgdown 2.x emits: HTML pages, pkgdown.yml, sitemap.xml, the BS3
# assets, search/docsearch JSON, and image assets (logo, favicons). Anything
# else in docs/ is repo content and is never deleted, even outside a preserved
# path. Deliberately conservative: under-pruning leaves a stale page that a
# later rebuild report can name, over-pruning destroys documentation.
PRUNEABLE="html css js xml json svg png ico yml"

preserved() {
  for p in $PRESERVE; do
    case "$1" in
      "$p"|"$p"/*) return 0 ;;
    esac
  done
  return 1
}

pruneable() {
  ext=${1##*.}
  for e in $PRUNEABLE; do
    [ "$ext" = "$e" ] && return 0
  done
  return 1
}

# 0. Guards.
# A crashed build leaves an empty or half-written site dir; pruning against it
# would delete the committed site. Require the pages a rebuild always emits.
for required in index.html reference/index.html pkgdown.yml sitemap.xml; do
  if [ ! -f "$site_src/$required" ]; then
    echo "FAIL: build output has no $required -- refusing to prune against it" >&2
    exit 1
  fi
done
# The build must not write into a preserved path.
build_files=$(cd "$site_src" && find . -type f | sed 's|^\./||')
for rel in $build_files; do
  if preserved "$rel"; then
    echo "FAIL: build output contains preserved path $rel" >&2
    exit 1
  fi
done

# 1. Copy the build output in.
for rel in $build_files; do
  mkdir -p "$docs_dst/$(dirname "$rel")"
  cp "$site_src/$rel" "$docs_dst/$rel"
done

# 2. Prune pkgdown-owned files this build did not produce.
cd "$docs_dst"
removed=0
for rel in $(find . -type f | sed 's|^\./||'); do
  preserved "$rel" && continue
  [ -e "$site_src/$rel" ] && continue
  if pruneable "$rel"; then
    echo "stale: removing $rel" >&2
    rm -f "$rel"
    removed=$((removed + 1))
  fi
done

# 3. Drop directories pkgdown used to have but no longer does.
for d in $(find . -mindepth 1 -type d | sed 's|^\./||'); do
  preserved "$d" && continue
  [ -z "$(ls -A "$d" 2>/dev/null)" ] && rmdir "$d" 2>/dev/null || true
done

echo "SYNC_OK (pruned $removed stale file(s))"

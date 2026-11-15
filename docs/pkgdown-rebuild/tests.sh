#!/bin/sh
# tests.sh -- negative tests for the gates and tools in this directory.
#
#   tests.sh [repo-root] [--in-container <name>]
#
# Every checker here has, at some point during this rebuild, passed vacuously:
# check-site.py matched no _pkgdown.yml topics after a config edit and reported
# seven legitimate links as unexpected; sync-into-docs.sh deleted the rebuild
# record that sat next to index.html. A tool that silently destroys or silently
# approves is worse than no tool, so each one runs here against input it must
# reject AND against input it must not touch.
#
# python3 and git are needed on the host. The R gates need the pkgdown toolchain
# and run only when --in-container names a live container with this repo at /work.
set -e

repo=$(realpath "${1:-$(dirname "$0")/../..}")
here=$(realpath "$(dirname "$0")")   # this suite lives beside the tools it tests
container=
if [ "$2" = "--in-container" ]; then container=$3; fi

scratch=$(mktemp -d /tmp/ffr-gate-tests.XXXXXX)
trap 'rm -rf "$scratch"' EXIT INT TERM

fails=0
expect_fail() { label=$1; shift
  if "$@" >"$scratch/out" 2>&1; then
    echo "WRONG: $label passed on input it must reject"; sed 's/^/    /' "$scratch/out" | head -5
    fails=$((fails + 1))
  else echo "ok: $label"; fi
}
expect_pass() { label=$1; shift
  if "$@" >"$scratch/out" 2>&1; then echo "ok: $label"
  else echo "WRONG: $label failed on valid input:"; sed 's/^/    /' "$scratch/out" | head -10
    fails=$((fails + 1)); fi
}
expect_line() { # label, fixed-string, file
  if grep -qF "$2" "$3"; then echo "ok: $1"
  else echo "WRONG: $1 -- no '$2' in:"; sed 's/^/    /' "$3" | head -8
    fails=$((fails + 1)); fi
}
expect_exists() { # label, path
  if [ -e "$2" ]; then echo "ok: $1"; else
    echo "WRONG: $1 -- $2 is gone"; fails=$((fails + 1)); fi
}
expect_absent() { # label, path
  if [ ! -e "$2" ]; then echo "ok: $1"; else
    echo "WRONG: $1 -- $2 still exists"; fails=$((fails + 1)); fi
}

# --------------------------------------------------------------------------
echo "== check-site.py rejects a broken site =="
broken=$scratch/broken; mkdir -p "$broken/reference"
cat >"$broken/index.html" <<'EOF'
<html><body><a href="reference/factors.html">f</a><a href="gone.html">gone</a></body></html>
EOF
cat >"$broken/reference/index.html" <<'EOF'
<html><body><a href="factors.html">factors</a><a href="ghost.html">ghost</a></body></html>
EOF
cat >"$broken/reference/factors.html" <<'EOF'
<html><body><a href="http://x.example/y">x</a><p>region: global (ex US)</p>
<p>period: observation period</p></body></html>
EOF
printf 'pkgdown: 2.2.0\n' >"$broken/pkgdown.yml"
python3 "$here/check-site.py" "$repo" --dst "$broken" >"$scratch/broken.out" 2>&1 || true
for what in "insecure link" "broken link" "stale label" "coverage start" \
            "not in _pkgdown.yml" "no last_built" "has no reference/"; do
  expect_line "detects $what" "$what" "$scratch/broken.out"
done

echo "== check-site.py rejects vacuity =="
mkdir -p "$scratch/empty"
expect_fail "empty site dir" python3 "$here/check-site.py" "$repo" --dst "$scratch/empty"
mkdir -p "$scratch/vacuous/reference"
echo '<html><body>nothing here</body></html>' >"$scratch/vacuous/reference/index.html"
printf 'pkgdown: 2.2.0\nlast_built: 2026-11-14T00:00Z\n' >"$scratch/vacuous/pkgdown.yml"
expect_fail "site with no comparable pages" \
  python3 "$here/check-site.py" "$repo" --dst "$scratch/vacuous"

echo "== check-site.py passes the rebuilt site =="
expect_pass "docs/ as committed" python3 "$here/check-site.py" "$repo"

# The stub check must be driven by _pkgdown.yml, not hardcoded: copy the tree,
# delete the redirects: block, and the stub in docs/ must now be reported.
# Without this, a parser that matches nothing looks identical to a site with no
# stubs (which is exactly how the topic parser passed vacuous output earlier).
mroot=$scratch/mroot
mkdir -p "$mroot"
# check-site.py reads _pkgdown.yml, man/ and the site under docs/. Copy those,
# not .git/ or data/.
cp "$repo/_pkgdown.yml" "$mroot/"
cp -a "$repo/man" "$mroot/"
cp -a "$repo/docs" "$mroot/"
python3 - "$mroot" <<'EOF'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / "_pkgdown.yml"
s = p.read_text()
if "redirects:" in s:
    i, j = s.index("redirects:"), s.index("navbar:")
    p.write_text(s[:i] + s[j:])
EOF
expect_fail "a redirect stub with no redirects: entry is reported" \
  python3 "$here/check-site.py" "$mroot"

echo "== a stale site is the positive control =="
# The control proves these gates fire on real stale output rather than only on
# hand-written fixtures. It must NOT be "HEAD": before the rebuild commit HEAD
# was the stale site, and once that commit lands the same line silently checks
# the current site and passes for the wrong reason -- which is exactly what it
# did. So select by content: the newest commit whose committed docs/ still
# carries pkgdown 1.x output, and refuse to run the section if none exists.
stale_rev=
for rev in $(git -C "$repo" log --format=%H -- docs/pkgdown.yml); do
  if git -C "$repo" show "$rev:docs/pkgdown.yml" 2>/dev/null | grep -q '^pkgdown: 1\.' \
     && git -C "$repo" show "$rev:docs/reference/factors.html" 2>/dev/null \
        | grep -q 'href=.http://'; then
    stale_rev=$rev
    break
  fi
done
if [ -z "$stale_rev" ]; then
  echo "WRONG: no pre-rebuild site found in history -- the control ran nothing"
  fails=$((fails + 1))
else
  echo "ok: control commit found ($(git -C "$repo" log -1 --format='%h %s' "$stale_rev" | head -c 60)...)"
  old=$scratch/old; mkdir -p "$old"
  git -C "$repo" archive "$stale_rev" docs | tar -x -C "$old" --strip-components=1
  expect_fail "stale committed site fails these gates" \
    python3 "$here/check-site.py" "$repo" --dst "$old"
  python3 "$here/check-site.py" "$repo" --dst "$old" >"$scratch/old.out" 2>&1 || true
  expect_line "stale site flagged on coverage text" "coverage start" "$scratch/old.out"
  expect_line "stale site flagged on http links" "insecure link" "$scratch/old.out"
fi

# --------------------------------------------------------------------------
echo "== compare-sites.sh =="
a=$scratch/a; b=$scratch/b; mkdir -p "$a" "$b"
echo same >"$a/x.html"; echo same >"$b/x.html"
expect_pass "identical sites compare equal" sh "$here/compare-sites.sh" "$a" "$b"
echo different >"$b/y.html"
expect_fail "an extra page is a difference" sh "$here/compare-sites.sh" "$a" "$b"
rm "$b/y.html"
printf 'pkgdown: 2.2.0\nlast_built: 2020-01-01T00:00Z\n' >"$a/pkgdown.yml"
printf 'pkgdown: 2.2.0\nlast_built: 2026-11-14T00:00Z\n' >"$b/pkgdown.yml"
expect_pass "a differing last_built alone is not a difference" \
  sh "$here/compare-sites.sh" "$a" "$b"

# --------------------------------------------------------------------------
echo "== sync-into-docs.sh preserves repo content =="
d=$scratch/docs; s=$scratch/site
mkdir -p "$d/agents" "$d/verification-spec-3" "$d/unlisted" "$d/reference"
mkdir -p "$s/reference"
printf '<html>new home</html>\n' >"$s/index.html"
printf '<html>new ref index</html>\n' >"$s/reference/index.html"
printf '<html>new ref</html>\n' >"$s/reference/factors.html"
printf 'pkgdown: 2.2.0\nlast_built: 2026-11-14T00:00Z\n' >"$s/pkgdown.yml"
printf '<urlset/>\n' >"$s/sitemap.xml"
echo '<html>old home</html>' >"$d/index.html"
echo '<html>old ref</html>'  >"$d/reference/factors.html"
echo '<html>now-deleted upstream</html>' >"$d/reference/portfolios_bivariate.html"
echo '# agent doc'      >"$d/agents/issue-tracker.md"
echo '# verification'   >"$d/verification-spec-3.md"
echo 'x <- 1'           >"$d/verification-spec-3/place-data.R"
echo '# rebuild record' >"$d/pkgdown-rebuild.md"
# A directory that is neither preserved nor pkgdown-owned, holding one file of
# a pruneable extension and one of a non-pruneable extension: the extension rule
# saves .txt, the .html must be pruned. Naming each case by the rule that
# decides it is deliberate -- an earlier version claimed "kept pkgdown-build/"
# when what saved the file was its .R extension, and the real preservation
# mechanism was untested.
echo 'build'            >"$d/unlisted/build.html"
echo 'notes'            >"$d/unlisted/notes.txt"
# A repo .html inside a preserved directory: the preserve list, not the
# extension rule, is what must save it.
echo '<html>agent page</html>' >"$d/agents/skills.html"

sh "$here/sync-into-docs.sh" "$s" "$d" >"$scratch/sync.out" 2>&1 || {
  echo "WRONG: sync of a valid build failed:"; sed 's/^/    /' "$scratch/sync.out"; fails=$((fails + 1)); }

expect_line "copied the new home page" "new home" "$d/index.html"
expect_line "copied the new reference page" "new ref" "$d/reference/factors.html"
expect_absent "pruned a page the build no longer emits" "$d/reference/portfolios_bivariate.html"
expect_exists "kept agents/"                   "$d/agents/issue-tracker.md"
expect_exists "kept verification-spec-3.md"    "$d/verification-spec-3.md"
expect_exists "kept verification-spec-3/"      "$d/verification-spec-3/place-data.R"
expect_exists "kept a .md at the docs root"    "$d/pkgdown-rebuild.md"
expect_exists "kept a non-pkgdown extension outside any preserved dir" "$d/unlisted/notes.txt"
expect_absent "pruned a pkgdown-extension file outside any preserved dir" "$d/unlisted/build.html"
expect_exists "kept an .html inside a preserved directory (preserve list, not extension)" \
  "$d/agents/skills.html"

# The tooling preserves its own directory because it derives it from $0, so it
# survives a rename. Run a *copy* of the script from inside the fixture docs/
# and feed it an .html file there -- html is pruneable, so only the derived
# preserve entry can save it. (A plain .R file would pass for the extension
# reason and prove nothing.)
mkdir -p "$d/tooling"
cp "$here/sync-into-docs.sh" "$d/tooling/sync-into-docs.sh"
echo '<html>the tooling page</html>' >"$d/tooling/index.html"
sh "$d/tooling/sync-into-docs.sh" "$s" "$d" >"$scratch/selfsync.out" 2>&1
expect_exists "keeps the tooling's own directory (html inside it survives pruning)" \
  "$d/tooling/index.html"

# Refusal cases, each missing/adding exactly one thing so it fails for its own
# stated reason rather than an unintended one.
bad_site=$scratch/bad-site; mkdir -p "$bad_site/reference" "$bad_site/agents"
cp "$s/index.html" "$s/pkgdown.yml" "$s/sitemap.xml" "$bad_site/"
cp "$s/reference/index.html" "$s/reference/factors.html" "$bad_site/reference/"
echo 'overwrite attempt' >"$bad_site/agents/issue-tracker.md"
expect_fail "refuses build output inside a preserved path" \
  sh "$here/sync-into-docs.sh" "$bad_site" "$d"

crashed=$scratch/crashed; mkdir -p "$crashed"          # empty: a crashed build
expect_fail "refuses an empty build output" \
  sh "$here/sync-into-docs.sh" "$crashed" "$d"
expect_exists "site survives a refused sync" "$d/reference/factors.html"
expect_exists "index survives a refused sync" "$d/index.html"

partial=$scratch/partial; mkdir -p "$partial/reference"   # no sitemap.xml
cp "$s/index.html" "$s/pkgdown.yml" "$partial/"
cp "$s/reference/index.html" "$s/reference/factors.html" "$partial/reference/"
expect_fail "refuses a build output with no sitemap.xml" \
  sh "$here/sync-into-docs.sh" "$partial" "$d"
expect_exists "nothing pruned by the refused sync" "$d/reference/factors.html"

# --------------------------------------------------------------------------
if [ -n "$container" ]; then
  echo "== R gates in $container =="
  docker cp "$here/negative-fixtures.R" "$container":/scratch/negative-fixtures.R
  docker exec "$container" rm -rf /scratch/fixtures
  docker exec "$container" Rscript /scratch/negative-fixtures.R /scratch/fixtures
  expect_pass "check-coverage.R accepts current-shaped data" \
    docker exec "$container" Rscript /work/docs/pkgdown-rebuild/check-coverage.R /scratch/fixtures/good
  expect_fail "check-coverage.R rejects a pre-1971 series" \
    docker exec "$container" Rscript /work/docs/pkgdown-rebuild/check-coverage.R /scratch/fixtures/stale-start
  expect_fail "check-coverage.R rejects the stale 'global' label" \
    docker exec "$container" Rscript /work/docs/pkgdown-rebuild/check-coverage.R /scratch/fixtures/stale-label
  expect_pass "check-coverage.R accepts the shipped data" \
    docker exec "$container" Rscript /work/docs/pkgdown-rebuild/check-coverage.R /work
  # Two distinct missing-toolchain states, each asserted on its message rather
  # than its exit code: an earlier version crashed inside rmarkdown:: and the
  # "it fails" assertion passed anyway, for the wrong reason.
  #   (a) no R packages at all
  docker run --rm -v "$repo":/work -v ffr-none:/usr/local/lib/R/site-library \
    rocker/r-ver:4.5.3 Rscript /work/docs/pkgdown-rebuild/build-site.R \
    >"$scratch/pre-none.log" 2>&1 || true
  expect_line "preflight: bare library reports missing prerequisites" \
    "missing build prerequisites" "$scratch/pre-none.log"
  expect_line "preflight: bare library names pkgdown" \
    "pkgdown: install.packages" "$scratch/pre-none.log"
  #   (b) pkgdown installed, system libuv1 absent (base image has no libuv1)
  docker run --rm -v "$repo":/work -v ffr-rlib:/usr/local/lib/R/site-library \
    rocker/r-ver:4.5.3 Rscript /work/docs/pkgdown-rebuild/build-site.R \
    >"$scratch/pre-uv.log" 2>&1 || true
  expect_line "preflight: missing libuv1 named" \
    "libuv1 (fs dyn.loads it)" "$scratch/pre-uv.log"
  for f in "$scratch/pre-none.log" "$scratch/pre-uv.log"; do
    if grep -q "there is no package called" "$f"; then
      echo "WRONG: preflight crashed inside a dependency instead of naming the fix:"
      sed 's/^/    /' "$f" | head -4; fails=$((fails + 1))
    else
      echo "ok: preflight does not crash inside a dependency ($(basename "$f"))"
    fi
  done
else
  echo "(R gates skipped: pass --in-container <name> to run them)"
fi

echo
if [ "$fails" -eq 0 ]; then echo "GATE_TESTS_OK"; else echo "GATE_TESTS_FAILED: $fails"; exit 1; fi

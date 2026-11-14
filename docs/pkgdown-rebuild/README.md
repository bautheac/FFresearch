# Rebuilding the pkgdown site

`docs/` is the committed pkgdown output, published by GitHub Pages (legacy
build, source `master:/docs`). After any change to `man/`, `README.rmd` or
`_pkgdown.yml`, regenerate the site and commit the output.

The record of the 2026-11-14 rebuild, including the equivalence measurement
below, is `../pkgdown-rebuild.md`.

## Build

One command, from a clean checkout:

```sh
sh docs/pkgdown-rebuild/rebuild.sh
git add -A docs/ _pkgdown.yml && git commit
```

It creates the container if missing (4 GB limit — the host has ~4 GB free, so
do not raise it), installs the toolchain the build preflight asks for, builds,
copies the output out, syncs it into `docs/`, runs `check-site.py` and
`tests.sh`, and prints the resulting diff. `--no-sync` stops before touching
`docs/` (report only); `--container <name>` picks the container.

The individual steps, if you want to run them by hand:

```sh
docker exec ffr-r Rscript /work/docs/pkgdown-rebuild/build-site.R   # -> /scratch/site-new
docker cp ffr-r:/scratch/site-new /tmp/site-new
sh docs/pkgdown-rebuild/sync-into-docs.sh /tmp/site-new docs/
python3 docs/pkgdown-rebuild/check-site.py "$PWD"
sh docs/pkgdown-rebuild/tests.sh "$PWD" --in-container ffr-r
```

`build-site.R` chowns its output to the repo owner, so the host can move and
delete it. Without that, container-built files are root-owned — the chore
noted in `../verification-spec-3.md`. Tear down with
`docker rm -f ffr-r && docker volume rm ffr-rlib`.

## Why not just `pkgdown::build_site()`

The default `install = TRUE` runs a full source install, whose lazyload step
loads all seven datasets at once and OOM-kills a 3–4 GB container — the failure
recorded in `../verification-spec-3.md`, which is why the hybrid install scripts
live next door. `pkgload::load_all()` (used for examples) does the same.

Neither is needed: the package ships no `\examples` blocks and no articles, so
help pages render from `man/*.Rd` and the home page from `README.md` without
executing package code. `build-site.R` therefore passes
`examples = FALSE, new_process = FALSE, install = FALSE`. Measured peak container
memory is 429 MB instead of an install that never completes.

That shortcut is only safe if the output matches the normal path, so it was
measured rather than assumed: install the package `--no-data`, build with
`examples = TRUE`, then `compare-sites.sh` the two — `SITES_IDENTICAL` apart
from the deliberate `AGENTS.html` drop.

## Files

| file | what it does |
| --- | --- |
| `build-site.R` | the build, with preflight and the AGENTS drop |
| `sync-into-docs.sh` | copies build output into `docs/`, prunes stale pkgdown output, preserves repo content |
| `check-site.py` | the gate: links, http, reference index, stale labels, coverage text, completeness, freshness |
| `check-coverage.R` | asserts the site's coverage and region claims against `data/*.rda` |
| `compare-sites.sh` | diffs two built sites, ignoring `last_built` |
| `tests.sh` | negative tests for all of the above |
| `negative-fixtures.R` | fixture data for `tests.sh` (pre-1971 series, stale `global` label) |

`check-site.py` and `check-coverage.R` both pass on the current tree;
`tests.sh` reports `GATE_TESTS_OK`. Run `check-site.py --dst <dir>` against the
pre-rebuild site to see it report 23 defects — the positive control that the
gates are not vacuous.

## Things pkgdown does that are not obvious

- Every unhandled `*.md` at the package root becomes a site page, including
  `AGENTS.md`. That file is agent infrastructure, so `build-site.R` drops
  `AGENTS.html` and its sitemap entry; pass `--keep-agents` to publish it.
- `README.md` links to `docs/verification-spec-3.md` (repo documentation, not
  pkgdown output). pkgdown rewrites the link to `docs/verification-spec-3.html`,
  which has no page behind it; the `redirects:` block in `_pkgdown.yml` points
  it at `verification-spec-3.html`, the path Jekyll gives that markdown file
  when Pages builds `docs/`. `check-site.py` is what proves that link resolves.
- pkgdown writes pages, it never deletes them: a page renamed or dropped
  upstream stays published until `sync-into-docs.sh` prunes it.
- Bootstrap 3 is what this site uses (no `template.bslib` in `_pkgdown.yml`),
  and pkgdown 2.x prints a deprecation warning about it on every build.
  Migrating to BS5 changes every page and is a separate decision.

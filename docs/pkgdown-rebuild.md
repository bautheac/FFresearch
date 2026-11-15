# pkgdown site rebuild (2026-11-14)

`docs/` is the committed pkgdown output, published by GitHub Pages as a legacy
`docs/`-source build (`master:/docs`). It had not been rebuilt since the dataset
rebuild. This branch regenerates it from the package at `master` @ `691c19f`
(PR #18, spec #3) and commits the output as-is, which is what the repo has
historically done.

All R ran in the `ffr-r` container (`rocker/r-ver:4.5.3`, 4 GiB cgroup limit);
the host has no R. Tooling is committed under `pkgdown-rebuild/` and is
reproducible: `sh docs/pkgdown-rebuild/tests.sh` re-verifies it.

## What was stale

`docs/pkgdown.yml` recorded `pkgdown: 1.6.1`, `last_built: 2021-06-04T15:29Z`.
The committed pages predate the dataset rebuild:

- no region labels at all in the `format` sections (the old `factors` page just
  says "region: geographical market considered for factor construction", no
  level list, so neither `global` nor `developed` appears — the labels were
  missing rather than wrong);
- no coverage statement on any dataset page; the home page still carried spec
  #3's removed note "Size concerns limit the data history to the last ten
  years; the full time series are available from the author upon request";
- every `Source:` URL was `http://` (11 links), including
  `http://bautheac.github.io/FFresearch` on the package page.

## How it was built

    docker exec ffr-r Rscript /work/docs/pkgdown-rebuild/build-site.R
    docker cp ffr-r:/scratch/final /tmp/final
    sh docs/pkgdown-rebuild/sync-into-docs.sh /tmp/final docs/
    python3 docs/pkgdown-rebuild/check-site.py "$PWD"

`build-site.R` calls `pkgdown::build_site(examples = FALSE, new_process = FALSE,
install = FALSE)`. That deviates from the default on purpose. `build_site()`
defaults to `install = TRUE`, which runs a full source install: its lazyload
step loads all seven datasets at once and is OOM-killed at 3 GiB — the exact
failure that forced the hybrid install scripts in `verification-spec-3/`
(`safe-install.sh` + `place-data.R`). `pkgload::load_all()`, used to run
examples, loads every `.rda` in `data/` into one environment with the same
footprint.

Neither step is needed here: the package ships no `\examples` blocks (none in
`man/*.Rd`; `checking examples ... NONE` in the spec #3 check log) and no
vignettes or articles. Help pages render from `man/*.Rd` and the home page from
`README.md`, with no package code executed. The load-bearing claim is
qualitative: **the build never touches `data/`**, so there is no dataset in
memory to OOM over, whereas the default `build_site()` puts all seven there at
once and is killed. `build-site.R` prints its own `VmHWM` on success (~136 MB of
R's RSS; the container cgroup showed 424 MB for the same run, which additionally
covers the pandoc subprocess and page cache).

Those numbers are approximate and should not be quoted to three significant
figures. Two counters disagreed throughout measurement — `/sys/fs/cgroup/
memory.peak` read 0.06 GiB for a run that had held a 1.4 GB object and 376 MB
before a build had started (`apt-get` alone raised it) — and the host held 4.1
GB of swap in use during this work, which moves anonymous memory in and out of
RSS. `VmHWM` is reported because it is the process's own high-water mark.
`check-coverage.R`, which does load the data, prints 1.81 GiB of peak RSS and
completes; the copy-based version of it was OOM-killed (exit 137) at the 4 GiB
limit, where the container counter had reached 3.29 GiB. Those are two different
counters of two different runs and are not comparable to each other — what is
comparable is that one was killed and one is not.

### Equivalence — measured, not asserted

Skipping the install is only safe if the output is what the normal path
produces. So the package was installed code-only (`R CMD INSTALL --no-data`;
data is not needed, since there are no examples to evaluate), the site built
through pkgdown's normal path with `examples = TRUE`, and the two compared:

    sh docs/pkgdown-rebuild/compare-sites.sh /scratch/site-new /scratch/site-full
    SITES_IDENTICAL

Byte-identical on every file except `AGENTS.html` and its `sitemap.xml` line,
which `build-site.R` drops deliberately (decision 1 below). `pkgdown.yml`
differs only in `last_built`. A plain `pkgdown::build_site()` run on a machine
with enough RAM produces this same site.

Two further reproducibility checks: two clean builds in separate containers
compare identical (`SITES_IDENTICAL`), and the synced `docs/` matches the build
output exactly apart from the preserved repo content.

## Toolchain

Installed into the `ffr-rlib` volume: **pkgdown 2.2.0**, **roxygen2 7.3.3**
(matches `RoxygenNote`), **data.table 1.18.2.1**, plus system packages
**pandoc 3.1.3** and **libuv1**. `build-site.R` preflights all three and names
the fix for each, because each fails later with a message that does not:

    Error: missing build prerequisites:
      - libuv1 (fs dyn.loads it): apt-get install -y libuv1
      - pandoc (renders README.md into the home page): apt-get install -y pandoc

`libuv1` is needed because the p3m binary build of `fs` does not bundle it;
without it `library(pkgdown)` dies inside `dyn.load`. `DESCRIPTION` was not
touched and `man/` was not regenerated: the site is package *output*, and
`man/*.Rd` was already current at `691c19f` (the handoff's starting point).

## Decisions

1. **`AGENTS.html` is dropped from the site.** pkgdown 2.x renders *every*
   unhandled `*.md` at the package root into a page, so upgrading from 1.6.1
   turns `AGENTS.md` (agent conventions, added in `00a1ab9`) into a public page
   plus a sitemap entry. It is not package documentation. `build-site.R`
   deletes the page and its sitemap line after the build; `--keep-agents`
   restores pkgdown's default behaviour. **Flagged for the maintainer** — it is
   a one-word change if publishing it is preferred.
2. **`redirects:` added to `_pkgdown.yml`.** `README.rmd`/`README.md` link to
   `docs/verification-spec-3.md`. pkgdown rewrites that link to
   `docs/verification-spec-3.html`, and nothing generates that page: the first
   rebuild shipped two links to a 404 (`check-site.py` reported exactly
   `index.html: broken link 'docs/verification-spec-3.html'` twice), and the
   live site returns 404 for that path today. The link is new since 2021 — the
   old committed home page had no reference to the verification record at all —
   so this is a defect the rebuild introduces unless handled, not a carried-over
   one. GitHub Pages builds `docs/` with Jekyll, which converts that
   markdown to `verification-spec-3.html` **at the site root** — verified live:
   `/verification-spec-3.html` → 200 (Jekyll page titled "Spec #3 final
   verification (ticket #16)"). The redirect entry maps the pkgdown path onto
   the Jekyll one and emits a `noindex` meta-refresh stub. Jekyll passes `.html`
   through untouched (`/index.html` and `/reference/factors.html` are served
   byte-identical to the committed files), so the stub is served verbatim.
3. **Bootstrap 3 kept.** No `template.bslib` in `_pkgdown.yml`, so pkgdown 2.2.0
   builds BS3 and warns `Bootstrap 3 is deprecated` on every run. Migrating to
   BS5 rewrites every page and asset; out of scope for a rebuild. Left as found,
   so the diff stays reviewable as a content refresh.
4. **`reference/FFresearch.html` is new.** pkgdown 2.x emits an alias redirect
   stub for `\alias{FFresearch}` in `man/FFresearch-package.Rd`, which 1.6.1 did
   not. It is refresh-only and `noindex`, keeping old inbound links alive. The
   package page itself stays out of the reference index because it is
   `@keywords internal` — unchanged from the old site.
5. **Repo content under `docs/` is untouched.** `docs/agents/`,
   `docs/verification-spec-3.md`, `docs/verification-spec-3/` and
   `docs/pkgdown-rebuild/` are repo content that happens to live inside a
   `.Rbuildignore`d directory. `sync-into-docs.sh` preserves them explicitly and
   refuses to copy build output onto them; it also prunes pkgdown-extension files
   the build no longer emits, so a renamed or removed page cannot linger
   published. The tooling preserves its own directory by deriving it from `$0`,
   so a future rename cannot leave it exposed to pruning.

## Verification

The acceptance criteria from the handoff, each driven by a check that
demonstrably fails when the criterion is not met:

    $ python3 docs/pkgdown-rebuild/check-site.py "$PWD"
    CHECK_SITE: 14 pages, 381 refs, 6 coverage pages, 7 _pkgdown.yml topics, 0 problem(s)

- **no `http://` links** — 381 link references parsed across 14 pages, none
  insecure. On the pre-rebuild site the same check reports 23 problems, 11 of
  them `http://` links (`git archive HEAD docs | ...` → `--dst`), which is the
  positive control that the checker is not vacuous.
- **reference index matches `_pkgdown.yml`** — the seven topics listed in the
  `reference:` block are exactly the topics linked from
  `reference/index.html`; internal topics are excluded as pkgdown does.
- **1971→2026-09 coverage and `developed` labels** — asserted on the *data*,
  not just the HTML, by `check-coverage.R` against the seven committed `.rda`
  files: 202 region/frequency series across the six period-bearing datasets,
  every one starting at or after the 1971 boundary, latest period `20260930`,
  region levels `US | developed | developed (ex US) | Europe | JP |
  Asia-Pacific (ex JP) | North America`, no `global` anywhere. Row counts match
  the trim addendum in `verification-spec-3.md` exactly: bivariate 28,565,801 ·
  univariate 2,449,450 · industries 2,610,678 · trivariate 1,333,200 ·
  breakpoints 35,378 · factors 549,426 · variables 48. `EXPECTED_REGIONS` and
  the 1971 boundary are restated in the script rather than read from
  `coverage_start()`, so the check does not inherit its expectation from the
  code it checks.
- **pages read, not just counted** — `reference/factors.html` and
  `reference/portfolios_bivariate.html` carry the region level list and the
  2^31 − 1 byte rationale; the home page shows current `head()` output from the
  README (periods beginning `19710104`), the 28.6-million-row memory note, and
  no "last ten years" text. `reference/variables.html` correctly has no coverage
  sentence: it has no `period` column, and the checker skips it by construction
  rather than by exception.

### Gate tests

Because a checker that silently matches nothing reports success on a broken
site, `tests.sh` runs every gate against input it must reject and against input
it must not touch — 44 assertions, all passing (35 on the host, 9 involving the
build container):

    $ sh docs/pkgdown-rebuild/tests.sh
    GATE_TESTS_OK

The checks are individually probed: a broken site must be flagged for an
insecure link, a broken link, a stale label, missing coverage text, an
undeclared reference entry, a missing page and a missing build stamp; an empty
or vacuous site must be rejected rather than passed; `compare-sites.sh` must
notice an added page but ignore a `last_built` difference; `sync-into-docs.sh`
must prune a page the build no longer emits while keeping `agents/`,
`verification-spec-3*`, a `.md` at the docs root, and a non-pkgdown extension
outside any preserved directory, and must refuse to sync an empty or
sitemap-less build output (a crashed build would otherwise delete the site).
Two of these caught real defects while being written: `check-site.py`'s topic
parser matched no topics after `_pkgdown.yml` gained the `redirects:` block and
reported the seven legitimate links as unexpected, and `sync-into-docs.sh`
deleted `docs/pkgdown-rebuild.md` because the preserve rule was
extension-blind. The sensitivity of the preserve-list assertions was confirmed
by mutating `PRESERVE` and watching exactly those two assertions fail.

## Not done

- Site not deployed: Pages rebuilds from `master` on merge, no workflow to run.
- No BS5 migration, no logo/favicon, no search or docsearch configuration change.
- `ffr-r` + `ffr-rlib` still up for review; teardown per the ticket #16 pattern.
  `fct-r` (other repos) left as found.

## Defect found in the documentation source, deliberately not fixed

Five dataset pages render this tail sentence, in the published site:

> … which the full-history bivariate exceeded; all series, `factors` included,
> start in 1971 (`variables` has no periods).

Two problems, both inherited from `R/data.r` and already committed in `man/`:

1. **Backticks survive into HTML.** Roxygen markdown is not applied inside
   `@description`, so `` `factors` `` renders as literal backticks, not code
   font. Affects all five: `R/data.r:10,71,106,140,177` →
   `man/breakpoints.Rd:35`, `portfolios_bivariate.Rd:39`,
   `portfolios_univariate.Rd:38`, `portfolios_trivariate.Rd:38`,
   `portfolios_industries.Rd:34`. `\code{factors}` is the fix.
2. **A lowercase sentence start, in the bivariate only.** `R/data.r:106` reads
   `… keeps it under the limit. all series, …` where the other four use `;`.
   The sentence should begin "All series".

Not fixed here because the handoff scopes this change to the site rebuild and
states `man/` is current, and because `man/` cannot be regenerated to prove a
hand-edit: `roxygen2::roxygenise()` fails in this tree with

    R6 class <BivariateBuilder> lacks source references.

(the `load_source` path cannot introspect the R6 builders; the check log in
`verification-spec-3.md` got round the analogous problem by installing with
`--with-keep.source`). Editing `R/data.r` and `man/*.Rd` by hand in step with
each other, with no roxygen run to confirm they agree, is precisely how a
generated file drifts from its source. It belongs in a documentation pass that
can run roxygen — one `s/`/`s/\`/\\code{/` in five places, then `roxygenise`,
then rebuild.

The site as delivered is therefore a faithful render of the current `man/`,
defects included.

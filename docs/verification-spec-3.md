# Spec #3 final verification (ticket #16)

Date: 2026-11-14. Verified at integration tip `fd2396a` (`rebuild-datasets`),
worktree branch `ticket-16-verification`. Container `ffr-r` (R 4.5.3, 3 GiB),
downstream container `fct-r` (R 4.5.3, 2 GiB). All heavy work serialised under
`flock /tmp/ffr-3/heavy.lock`.

## R CMD check

Result: **0 errors, 0 warnings, 1 NOTE** (`R CMD check` exit 0,
`Status: 1 NOTE`). Full log: `.worktrees/t16-scratch/FFresearch.Rcheck/00check.log`.
Tests inside the check: **FAIL 0 | WARN 0 | SKIP 6 | PASS 423** (216 s).
Skips are by design: 5 network-gated tests (`FFRESEARCH_NETWORK` not true)
and `test-docs-readme.R` (README.rmd is `.Rbuildignore`d, absent from the
tarball).

### The NOTE, verbatim

```
* checking R code for possible problems ... NOTE
bivariate_sources: no visible binding for global variable ‘weights’
bivariate_sources: no visible binding for global variable ‘.N’
Undefined global functions or variables:
  .N weights
Consider adding
  importFrom("stats", "weights")
to your NAMESPACE file.
```

Assessment: false positive from data.table non-standard evaluation in
`R/bivariate-builder.R:116`
(`sources[, weights := rep(list(c("value", "equal")), .N)]`) — `weights`
is a column name (and masks `stats::weights`), `.N` a data.table symbol.
Fixable via `utils::globalVariables(c(".N", "weights"))` or local bindings;
the check's `importFrom("stats", "weights")` suggestion is not the right
fix. Will be addressed in the code-review fix pass, not in this ticket.

### Notes and INFO list (from 00check.log)

- NOTE "checking R code for possible problems" — the only NOTE; verbatim
  and assessed above.
- INFO "checking installed package size": 58.1 Mb (data 57.3 Mb). Expected
  for a data package; informational, not a NOTE.
- "checking examples ... NONE" — the package ships no examples.
- "checking data for non-ASCII characters" was disabled via
  `_R_CHECK_ASCII_DATA_=FALSE` (OOM, see below) and run per-dataset instead:
  all seven datasets clean (0 latin1, 0 bytes, 0 unknown; `variables` has
  5 UTF-8 strings, consistent with `Encoding: UTF-8`).

### Install OOM and the documented workaround

The rebuilt `portfolios_bivariate` has 34,827,461 rows (~1.8 GiB in memory;
45 MB xz-compressed rda). A standard `R CMD INSTALL` loads all seven datasets
at once to build the lazyload DB (`tools:::data2LazyLoadDB`) and is OOM-killed
at the 3 GiB cgroup limit ("*** moving datasets to lazyload DB / Killed").
Confirmed twice under exclusive lock (no other R process in the container);
peak container anon memory ~3.0 GiB both times (limit 3 GiB). Even inserting the bivariate
alone into a lazyload DB OOMs (object + serialization buffer > 3 GiB).

What was done instead (scripts committed under `docs/verification-spec-3/`;
working copies and logs in `.worktrees/t16-scratch/`):

1. Tarball built with `R CMD build` from a clean `git archive` export of the
   tip (a worktree build carries the `.git` pointer file, which trips the
   hidden-files NOTE).
2. `R CMD INSTALL --no-docs --no-data` (code only), then `place-data.R`:
   copies the seven `.rda` files into the installed `data/`, builds the
   lazyload DB **one dataset at a time** for the six datasets that fit
   (`.Internal(lazyLoadDBinsertValue)`, xz per `LazyDataCompression`,
   reproducing `Rdata.rdb`/`Rdata.rdx`/`Rdata.rds`), and keeps
   `portfolios_bivariate.rda` as a plain file **outside** the DB index —
   `utils::data()` falls back to file loading for names absent from
   `Rdata.rds` (verified against the `utils::data` source). All seven
   datasets load via `data()`; `FFresearch::factors` resolves via the DB.
3. `R CMD check --no-manual --library=<lib> --install=check:<install.log>`
   on the tarball: check uses the pre-installed package and the recorded
   install log (the mechanism R provides for externally performed installs)
   and runs every remaining check, including the full test suite.
4. `_R_CHECK_ASCII_DATA_=FALSE`: the "data for non-ASCII characters" check
   (`tools:::.check_package_datasets`) loads all seven datasets into one
   environment and OOMs. It was run instead **per dataset** with the
   identical tools function on one-dataset directories (`ascii-split.R`):
   all seven clean (0 latin1, 0 bytes, 0 unknown; `variables` has 5 UTF-8
   strings, consistent with `Encoding: UTF-8`).
5. `--no-manual`: no LaTeX in the container.

The successful check peaked at ~2.8 GiB anon memory (contract tests on the
34.8M-row bivariate), within the 3 GiB limit.

## Full test suite (private library rlib-t16)

`R CMD INSTALL --no-docs --library=rlib-t16 .` (the literal task command)
would OOM at the lazyload step — the same failure demonstrated twice by the
check install attempts — so the documented `--no-data` + data-placement
fallback was used (same hybrid layout as the check install).

Result: **exit 0, FAIL 0 | WARN 0 | SKIP 5** — all tests pass; the 5 skips
are the network-gated tests (`FFRESEARCH_NETWORK` not true, by design).
`test-docs-readme.R` passes here (README.rmd present in the worktree; it is
skipped inside the check tarball, which `.Rbuildignore`s it).

The finRes article's `load FFresearch` chunk was also run **verbatim** (all
seven datasets in one `data()` call) plus every `head()` chunk, against
rlib-t16 in the 3 GiB container: **passed**, peak anon memory ~2.5 GiB. The
rebuilt data raises that chunk's footprint from well under 1 GiB to ~2.5 GiB;
it fits a 3 GiB session but not a 2 GiB one.

## Downstream

Private library `/tmp/rlib-t16` inside `fct-r` (rebuilt FFresearch installed
from the tip with the same hybrid layout; `factors` installed from
`/work/factors`). Shared `fct-rlib` volume not mutated.

### finRes (asset-pricing article)

- **FFresearch section**: all seven datasets loaded by name and checked
  against the dataset contract (columns, row counts) with the article's
  `head()` chunks: factors 598,646; univariate 4,309,354; bivariate
  34,827,461; trivariate 1,439,544; industries 4,734,188; variables 48;
  breakpoints 61,044. All pass. No `global`/`global (ex US)` labels remain;
  bivariate/trivariate/factors carry `developed` / `developed (ex US)`.
  Run one dataset per fresh R process: holding the bivariate (~1.8 GiB)
  after other loads OOMs the 2 GiB fct-r container. The verbatim
  all-at-once load passed in the 3 GiB ffr-r container (see above).
- **factors section**: `library(factors)` + `data(fama_french, stambaugh)`
  + head chunks: pass.
- **Core analysis ("factor'em!" section)**: all eval=TRUE chunks executed —
  pullit equity/futures/CFTC/aggregate pulls from the bundled sqlite,
  `factorem()` workhorse, equity market/momentum and futures
  market/momentum/CHP/OI-nearby/OI-aggregate/TS wrappers, all accessors,
  `summary()`, plotit performance/positions plots: **pass, no errors or
  warnings**. Deviation: the sqlite is resolved via
  `system.file(..., package = "finRes")` in the article; finRes is not
  installed, so the identical bundled file
  (`finRes/inst/extdata/storethat.sqlite`) was used directly.
- **Not exercised**: full `rmarkdown::render()` knit — finRes itself and
  fewISOs/GICS/storethat are not installed in fct-r and have no host
  checkout (GitHub Remotes, network); the `datasets.Rmd` vignette's
  BBGsymbols/fewISOs/GICS sections; Bloomberg chunks (eval=FALSE in the
  article). The seven-dataset load in `datasets.Rmd` is identical to the
  asset-pricing one and is covered.

### factors

Full suite against the rebuilt FFresearch (private library prepended):
**all pass, 0 failures, 0 skips** with `NOT_CRAN=true`. The drift test
(`test-fama_french-drift.R`) confirms the shipped `fama_french` snapshot
matches rebuilt `FFresearch::factors` (598,646 rows, canonical order,
version attribute). The only region filter in the package is
`region == "US"` — unaffected by the relabel.

### factorem

**Independent of FFresearch**: no FFresearch (or factors) in
Imports/Suggests; no usage in R/, tests or vignettes (the Fama-McBeth
functions take user-supplied returns). Load check passes
(`library(factorem)`, 0.0.1.0). Its suite was also run: 2 tests, 4 failures
in `test_factor_positions.r` — **pre-existing**: the fixtures use unseeded
`runif()` and the identical failures occur with the private FFresearch
library removed from the search path. Unaffected by the refresh.

### Relabelled regions

`global` → `developed`, `global (ex US)` → `developed (ex US)` in
`portfolios_bivariate` and `portfolios_trivariate` (already done for
`factors` on the test-pipeline branch). No downstream code filters on the
old labels: finRes vignettes/doc load and print the datasets without level
filters (the only "global" hits are unrelated chunk names in
`bloomberg.Rmd`); the only region filter in factors is `region == "US"`
(`test-fama_french.R`), unaffected; factorem has none. The `pior returns`
typo in `breakpoints$variable` is kept for compatibility (plan decision 2).

## Deviations from the ticket body

- Container/volume teardown deferred by the orchestrator until after the
  code-review pass (ticket acceptance item 3 not executed here).
- Check install performed manually (OOM workaround above); the non-ASCII
  data check ran per-dataset instead of in one pass.
- finRes full vignette knit not possible offline: finRes and its dependencies
  fewISOs/GICS/storethat are not installed in `fct-r` and have no host
  checkout (GitHub Remotes, network). The article's code was executed
  directly instead (see above).
- Nothing pushed or merged.

## Addendum: code-review fix pass (2026-11-14)

The single NOTE above was fixed in the review pass (branch `review-fixes`):
the data.table NSE in `bivariate_sources()` was replaced with
`rep(list(c("value", "equal")), nrow(sources))`. The pass also extracted
shared test helpers, unified the region relabel lookup, reused
`factors_regions()`, renamed a shadowed local, and documented the
install-memory needs in the README. One regression was caught and fixed
during the pass: the extracted `period_frequency()` helper could not cross
the bivariate worker-process boundary, so the portfolio parser keeps the
frequency map inline (self-contained serialisation).

Re-verification at the fix-pass tip: full suite green; `R CMD check` via
the same memory-safe machinery: **Status: OK (0 errors, 0 warnings,
0 NOTEs)**; per-dataset non-ASCII check clean; peak container memory
2.58 GiB. Logs: `.worktrees/t-fix-scratch/check-fix.log`,
`FFresearch.Rcheck/00check.log`.

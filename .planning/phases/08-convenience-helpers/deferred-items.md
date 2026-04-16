# Phase 08 — Deferred Items

Issues discovered during execution that are out-of-scope for Phase 08 plans
(pre-existing in the codebase before Phase 08 began) and therefore not fixed
in this phase's commits. Listed here for a future phase to address.

## 1. R CMD check failure: `test-workflow.R` legacy wrapper script test

**Found during:** Plan 08-03 Task 4 (R CMD check regression sweep)

**Symptom:** Under `devtools::check(args = c('--no-manual', '--no-vignettes'),
error_on = 'warning')`, four assertions inside
`tests/testthat/test-workflow.R:247-250` fail:

- `attr(status, "status")` is `1` (expected NULL)
- `dir.exists(output_dir)` is `FALSE`
- `file.exists(file.path(output_dir, "sube_results.csv"))` is `FALSE`
- `file.exists(file.path(output_dir, "sube_tidy.csv"))` is `FALSE`

The test spawns an `Rscript` subprocess that runs
`inst/scripts/run_legacy_pipeline.R`; the subprocess exits with status 1
(silently on stderr) and therefore no output directory is created.

**Status:** **Pre-existing.** The same four failures reproduce on the Phase 8
base commit (c874484 `docs(08-02): complete batch-sube plan summary`) with no
Plan 08-03 changes applied. `devtools::test()` run outside the check sandbox
continues to pass the full 195-test suite cleanly; this is an R-CMD-check-only
environment interaction.

**Root cause hypothesis:** the Rscript subprocess spawned inside the check's
test_check() runs `library(sube)` but cannot locate the still-being-checked
package in its library paths. The subprocess therefore errors out with status
1 before producing any output file.

**Not fixed in Plan 08-03 because:** Plan 08-03 scope is
documentation/packaging (man pages, pkgdown, NEWS, vignette, cross-links);
the legacy wrapper script test is unrelated to those changes. Per the
`deviation_rules` SCOPE BOUNDARY: "Only auto-fix issues DIRECTLY caused by
the current task's changes. Pre-existing warnings, linting errors, or
failures in unrelated files are out of scope."

**Suggested follow-up:** a future tech-debt plan can either (a) make the
legacy wrapper test resilient to the R-CMD-check library-path environment
(e.g. by passing `.libPaths()` to the subprocess explicitly), or (b) guard
the test with `skip_on_check()` (it already guards on
`Sys.which("Rscript") == ""`).

## 2. R CMD check NOTE: "no visible binding for global variable" in R/pipeline.R

**Found during:** Plan 08-03 Task 4 R CMD check

**Symptom:** the check produces a NOTE enumerating unbound globals in
`R/pipeline.R`:

```
.emit_batch_warning: no visible binding for global variable 'N'
.emit_batch_warning: no visible binding for global variable 'status'
.emit_pipeline_warning: no visible binding for global variable 'status'
.emit_pipeline_warning: no visible binding for global variable 'N'
.extend_compute_diagnostics: no visible binding for global variable 'stage'
.extend_compute_diagnostics: no visible binding for global variable 'n_rows'
.extend_compute_diagnostics: no visible binding for global variable 'country'
.extend_compute_diagnostics: no visible binding for global variable 'year'
batch_sube: no visible global function definition for 'setNames'
batch_sube : <anonymous>: no visible binding for global variable 'group_key'
batch_sube: no visible binding for global variable 'group_key'
```

**Status:** This is a NOTE (not a WARNING or ERROR); it is standard data.table
noise from non-standard-evaluation column references (`status`, `N`, `stage`,
`n_rows`, `country`, `year`, `group_key`) and a missing `stats::setNames`
import.

**Not a blocker:** `error_on = "warning"` tolerates NOTEs. These notes exist
alongside identical-shape notes from Phase 5-7 code in `R/build_matrices.R`
(`..common_vars`, `INDUSTRIES`), indicating this is an established project
convention and no Phase 5-7 plan added these identifiers to `R/globals.R`.

**Suggested follow-up:** a future tech-debt plan can extend `R/globals.R`
with `utils::globalVariables(c("N", "stage", "status", "n_rows", "country",
"year", "group_key"))` and add `@importFrom stats setNames` to
`R/pipeline.R`, silencing the NOTE without functional change.

## 3. R CMD check NOTE: Rd line widths > 90 in filter_plot_write.Rd / paper_tools.Rd

**Found during:** Plan 08-03 Task 4 R CMD check

**Symptom:** two hand-written `.Rd` files contain `\usage` lines longer than
90 characters. These will be truncated in the PDF manual (not affected here
because `--no-manual`).

**Status:** Pre-existing; these are hand-written (not roxygen-generated) Rd
files shipped before Phase 8.

**Not fixed in Plan 08-03 because:** out-of-scope for doc/vignette updates;
a future tech-debt plan can wrap the long `\usage` lines or migrate
`filter_plot_write.Rd` / `paper_tools.Rd` to roxygen-generated output.

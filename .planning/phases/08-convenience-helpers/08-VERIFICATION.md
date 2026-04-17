---
phase: 08-convenience-helpers
verified: 2026-04-16T22:35:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 8: Convenience Helpers Verification Report

**Phase Goal:** Researchers can run the full SUBE workflow through a single exported `run_sube_pipeline()` call or batch it across countries and years via `batch_sube()`, with visibility into silent data-quality issues through diagnostic warnings.

**Verified:** 2026-04-16T22:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | User can call a single exported `run_sube_pipeline()` function that chains import → matrix → compute with argument pass-through and returns one structured result object | ✓ VERIFIED | `run_sube_pipeline` in NAMESPACE:11 (`export(run_sube_pipeline)`); function in R/pipeline.R:241 with signature `(path, cpa_map, ind_map, inputs, source, domestic_only, estimate, ...)`; dispatches via `switch(source, ...)` (R/pipeline.R:262) to `import_suts`/`read_figaro`, calls `build_matrices` (L280), `compute_sube` (L299), optional `estimate_elasticities` (L340). Returns `c("sube_pipeline_result","list")` with `$results/$models/$diagnostics/$call`. Live spot-check on sample data produced `class="sube_pipeline_result"`, 4 named fields, 6-column diagnostics, and 2-row summary. |
| 2  | User can call an exported `batch_sube()` that loops `run_sube_pipeline()` over supplied country × year sets and returns collected results in a tidy structure | ✓ VERIFIED | `batch_sube` in NAMESPACE:1 (`export(batch_sube)`); function in R/pipeline.R:639. Splits via `.batch_split` by `country_year` (default)/`country`/`year` (L535–564), runs `.batch_run_one` per group (L381–497) which internally chains `build_matrices` → `compute_sube` → optional `estimate_elasticities`. Returns `c("sube_batch_result","list")` with `$results` (named list of `sube_pipeline_result`), `$summary`/`$tidy`/`$diagnostics` (`rbindlist`), plus `$call` carrying `by/n_groups/n_errors`. Live spot-check on 2-year fixture: 2 groups (`AAA_2020`, `AAA_2021`), merged diagnostics carries `group_key`, `$call$n_groups = 2`. |
| 3  | When rows are dropped by coercion, matrices are skipped due to missing data, or singular branches are hit, the helpers surface human-readable diagnostic warnings that pinpoint the country, year, and cause | ✓ VERIFIED | Four detection helpers in R/pipeline.R: `.detect_coerced_na` (L32–46), `.detect_skipped_alignment` (L51–68), `.detect_inputs_misaligned` (L73–100), `.extend_compute_diagnostics` (L105–130). Each emits rows with country/year/stage/status/message. `.emit_pipeline_warning` (L134–148) and `.emit_batch_warning` (L501–530) emit exactly one summary `warning()` with status counts. Live spot-check: NA-corrupted SUT produces `"Pipeline completed with issues: 1 coerced_na, 1 inputs_misaligned. See result$diagnostics for details."`; `skipped_alignment` row pinpoints country=`AAA`, year=`2020` and cause=`"Country-year AAA_2020 present in SUT data but absent from build_matrices output (missing CPA/industry alignment after correspondence merge)."` |
| 4  | Both helpers are exported with roxygen docs, NAMESPACE entries, pkgdown group assignment, and testthat coverage exercising success paths, skip paths, and warning paths | ✓ VERIFIED | Roxygen blocks at R/pipeline.R:173–240 and 580–638; `man/run_sube_pipeline.Rd` (94 lines) and `man/batch_sube.Rd` (86 lines) contain `\name{}`, `\title{}`, `\usage{}`, `\arguments{}`, `\value{}`, `\details{}`, `\examples{}`, `\seealso{}`. NAMESPACE exports both (lines 1 & 11). `_pkgdown.yml:11–19` lists both under "Data import and preparation" after `build_matrices`; "Pipeline Helpers" articles group inserted at position 4 of 7 (L49–51). `tests/testthat/test-pipeline.R` has 25 `test_that` blocks covering happy path (wiod + FIGARO), skip paths (inputs_misaligned, skipped_alignment), warning paths (summary warning emitted exactly once), resilience (per-group tryCatch), and Pitfall-10 mutation guard. Full suite: 197 pass / 0 fail / 5 expected skip. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/pipeline.R` | `run_sube_pipeline()`, `batch_sube()`, constructors, 4 detection helpers, 2 warning emitters, batch helpers, upfront validation | ✓ VERIFIED | 728 lines. Exports both functions via roxygen `@export`. Contains 10 helper functions matching Plan 01+02 provides list (`.empty_diagnostics`, `.sube_pipeline_result`, `.sube_batch_result`, `.validate_pipeline_inputs`, `.detect_coerced_na`, `.detect_skipped_alignment`, `.detect_inputs_misaligned`, `.extend_compute_diagnostics`, `.emit_pipeline_warning`, `.emit_batch_warning`, `.batch_run_one`, `.batch_split`). |
| `NAMESPACE` | `export(run_sube_pipeline)` + `export(batch_sube)` | ✓ VERIFIED | Line 1: `export(batch_sube)`; line 11: `export(run_sube_pipeline)`. Both present exactly once. |
| `man/run_sube_pipeline.Rd` | Roxygen-generated manpage with \name, \title, \usage, \arguments, \value, \details, \examples, \seealso | ✓ VERIFIED | 94 lines. All eight sections present. roxygen2 header line 1: `% Generated by roxygen2: do not edit by hand`. |
| `man/batch_sube.Rd` | Same structure | ✓ VERIFIED | 86 lines. All eight sections present. |
| `_pkgdown.yml` | run_sube_pipeline + batch_sube in "Data import and preparation" reference group after build_matrices; "Pipeline Helpers" articles group between Modeling and Package Design | ✓ VERIFIED | L11–19 exact order: `import_suts, read_figaro, extract_domestic_block, sube_example_data, build_matrices, run_sube_pipeline, batch_sube`. Articles L38–60: Workflow Start Here → Inputs and Preparation → Modeling, Comparison, and Outputs → **Pipeline Helpers** → Package Design and Paper Context → Paper replication → FIGARO workflow. |
| `NEWS.md` | 3 new bullets under dev version: run_sube_pipeline, batch_sube, unified diagnostics | ✓ VERIFIED | Lines 3–23 of NEWS.md contain three bullets covering `run_sube_pipeline()`, `batch_sube()`, and the unified pipeline diagnostics layer (naming all four silent-issue categories and the single summary warning). |
| `vignettes/pipeline-helpers.Rmd` | 7 sections, live eval=TRUE chunks, FIGARO eval=FALSE | ✓ VERIFIED | 171 lines. Seven section headers: (1) When to reach for helpers, (2) run_sube_pipeline() on sample data, (3) Inspecting $results/$diagnostics/$call, (4) Switching to FIGARO (eval=FALSE), (5) batch_sube() across groups, (6) Turning on estimate=TRUE, (7) Reading the diagnostic warnings. |
| `vignettes/paper-replication.Rmd` | Cross-link to run_sube_pipeline + pipeline-helpers | ✓ VERIFIED | Blockquote at L33–34: `[run_sube_pipeline()](../reference/run_sube_pipeline.html)` and `[Pipeline Helpers vignette](pipeline-helpers.html)`. |
| `vignettes/figaro-workflow.Rmd` | Cross-link to run_sube_pipeline(source="figaro") + pipeline-helpers | ✓ VERIFIED | Blockquote at L41–42: `[run_sube_pipeline(source = "figaro", ...)](../reference/run_sube_pipeline.html)` and `[Pipeline Helpers vignette](pipeline-helpers.html)`. |
| `tests/testthat/test-pipeline.R` | ≥ 25 test_that blocks covering CONV-01/02/03 | ✓ VERIFIED | 438 lines, 25 `test_that` blocks. Full suite: 197 pass / 0 fail / 5 expected skip. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| R/pipeline.R | R/import.R::import_suts / read_figaro | `switch(source, wiod = import_suts, figaro = read_figaro)` | ✓ WIRED | R/pipeline.R:262 `sut_raw <- switch(source,` dispatches to `do.call(import_suts, ...)` (L263) or `do.call(read_figaro, ...)` (L267). (Tool's false-negative: regex escape handling.) |
| R/pipeline.R | R/compute.R::compute_sube | `compute_sube(matrix_bundle, inputs, ...)` after `build_matrices` | ✓ WIRED | L299 `do.call(compute_sube, c(list(matrix_bundle=...), compute_dots))` wrapped in `tryCatch`. Also at L409 inside `.batch_run_one`. |
| R/pipeline.R | R/models.R::estimate_elasticities | conditional call when `estimate = TRUE` and `nrow(matrix_bundle$model_data) > 0` | ✓ WIRED | L340: `models <- estimate_elasticities(matrix_bundle$model_data)` inside `if (isTRUE(estimate) && !is.null(matrix_bundle$model_data) && nrow(matrix_bundle$model_data) > 0L)`. Same guard at L447 inside `.batch_run_one`. |
| R/pipeline.R::batch_sube | R/pipeline.R::.batch_run_one | `tryCatch` wrapper per group | ✓ WIRED | L667–669: `lapply(groups, function(g) .batch_run_one(g, ...))`. `.batch_run_one` itself wraps body in `tryCatch` (L385) with per-group error handler (L477). |
| R/pipeline.R::batch_sube | R/pipeline.R::.sube_pipeline_result | per-group result construction | ✓ WIRED | L474: `.sube_pipeline_result(results, models, diagnostics, call_meta)` success path; L494 error path. Both inside `.batch_run_one`. |
| vignettes/pipeline-helpers.Rmd | R/pipeline.R::run_sube_pipeline | live code chunk using `sube_example_data` paths | ✓ WIRED | L45, L88, L139 contain live `run_sube_pipeline(...)` calls; L116 contains `batch_sube(...)`. Chunks at `eval = TRUE` (L12). Vignette knits cleanly per Plan 03 SUMMARY. |
| _pkgdown.yml | man/run_sube_pipeline.Rd + man/batch_sube.Rd | reference group "Data import and preparation" listing | ✓ WIRED | `_pkgdown.yml:18–19` `- run_sube_pipeline` / `- batch_sube`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `run_sube_pipeline()` return | `$results` | `compute_sube(matrix_bundle, inputs, ...)` — L299 | Yes — DB-equivalent query (live spot-check: nrow(summary)=2 on sample) | ✓ FLOWING |
| `run_sube_pipeline()` return | `$diagnostics` | `rbindlist(list(diag_import, diag_build, diag_compute), fill=TRUE)` — L344 | Yes — populated by four detection helpers that read real input/output data (live spot-check: 2 diagnostic rows produced) | ✓ FLOWING |
| `run_sube_pipeline()` return | `$models` | `estimate_elasticities(matrix_bundle$model_data)` — L340, conditional | Yes when model_data non-empty; `NULL` by contract when inputs misalign (D-8.4) | ✓ FLOWING |
| `run_sube_pipeline()` return | `$call` | Constructed L356 from real `source/path/match.call()/R.version.string/utils::packageVersion()` | Yes — spot-check shows 8 named fields populated with real values | ✓ FLOWING |
| `batch_sube()` return | `$summary` | `rbindlist(lapply(per_group, ...$summary), fill=TRUE)` — L678 | Yes — spot-check on 2-year fixture produced nrow ≥ 2 merged summary | ✓ FLOWING |
| `batch_sube()` return | `$tidy` | `rbindlist(...$tidy, fill=TRUE)` — L684 | Yes | ✓ FLOWING |
| `batch_sube()` return | `$diagnostics` | `rbindlist(..., fill=TRUE)` with `group_key` added — L690 | Yes — spot-check confirms `group_key` populated for every row | ✓ FLOWING |
| `batch_sube()` return | `$call$n_errors` | `sum(vapply(processed, ...$errored))` — L675 | Yes — derived from real per-group `errored` flags that include compute-stage errors (per Plan 02 deviation #1) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Both functions exported | `"run_sube_pipeline" %in% getNamespaceExports("sube")`; same for batch_sube | Both TRUE | ✓ PASS |
| `run_sube_pipeline()` returns structured result on sample data | Live call on `sube_example_data` WIOD path | class=`sube_pipeline_result,list`; fields=`results,models,diagnostics,call`; diagnostics=6 cols; summary=2 rows; call=8 fields | ✓ PASS |
| `batch_sube()` produces tidy merged tables over 2-year fixture | Live call with `sut_multi` (AAA × 2020, 2021) | class=`sube_batch_result,list`; 2 groups `{AAA_2020, AAA_2021}`; diagnostics=7 cols (adds `group_key`); call=7 fields including `by, n_groups, n_errors` | ✓ PASS |
| Summary warning fires exactly once on NA-coerced input | `tryCatch(run_sube_pipeline(...), warning=...)` | `"Pipeline completed with issues: 1 coerced_na, 1 inputs_misaligned. See result$diagnostics for details."` | ✓ PASS |
| Diagnostic rows pinpoint country/year/cause | `res$diagnostics[stage=="build" & status=="skipped_alignment"]` with ZZZ cpa_map | `country=AAA, year=2020, stage=build, status=skipped_alignment, message="Country-year AAA_2020 present in SUT data but absent..."` | ✓ PASS |
| `.Rd` files contain all required sections | Verified `\name, \title, \usage, \arguments, \value, \details, \examples, \seealso` in both files | All present | ✓ PASS |
| pkgdown reference group order preserved | `_pkgdown.yml:11–19` | `build_matrices, run_sube_pipeline, batch_sube` in that order under "Data import and preparation" | ✓ PASS |
| "Pipeline Helpers" articles group placement | `_pkgdown.yml:49–51` | Position 4 of 7, between "Modeling, Comparison, and Outputs" and "Package Design and Paper Context" | ✓ PASS |
| Full test suite green | `Rscript -e 'devtools::test()'` | 197 pass / 0 fail / 5 skip (all gated-data env-var skips) | ✓ PASS |
| Pipeline-filtered test suite | `Rscript -e 'devtools::test(filter = "pipeline")'` | 87 pass / 0 fail / 2 skip | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| CONV-01 | 08-01, 08-03 | User can call a single exported `run_sube_pipeline()` function that chains import → matrix → compute with arg pass-through and returns a single structured result object | ✓ SATISFIED | Truth #1 + artifacts `R/pipeline.R::run_sube_pipeline` exported in NAMESPACE, documented in `man/run_sube_pipeline.Rd`, listed in pkgdown reference group, demonstrated in `vignettes/pipeline-helpers.Rmd` §2–3 |
| CONV-02 | 08-02, 08-03 | User can call an exported `batch_sube()` that loops `run_sube_pipeline()` over supplied country × year sets and returns collected results in a tidy structure | ✓ SATISFIED | Truth #2 + artifacts `R/pipeline.R::batch_sube` exported, documented in `man/batch_sube.Rd`, listed in pkgdown reference group, demonstrated in `vignettes/pipeline-helpers.Rmd` §5. Live spot-check produced 2-group merged tables with per-group `sube_pipeline_result` preserved |
| CONV-03 | 08-01, 08-02, 08-03 | `run_sube_pipeline()` and `batch_sube()` surface human-readable diagnostic warnings when rows are dropped by coercion, matrices are skipped due to missing data, or singular branches are hit | ✓ SATISFIED | Truth #3 + four detection helpers in R/pipeline.R with unified 6-column diagnostics schema (7 with `group_key` at batch scope), single summary warning emitters (`.emit_pipeline_warning` / `.emit_batch_warning`), test-pipeline.R has 7+ blocks exercising each diagnostic category and warning behavior |

No orphan requirements. All three Phase 8 requirement IDs in REQUIREMENTS.md:66–68 are claimed by at least one plan's frontmatter and have been implemented.

### Anti-Patterns Found

No anti-patterns found.

| Pattern | Scope | Count | Severity | Impact |
|---------|-------|-------|----------|--------|
| TODO / FIXME / XXX / HACK | R/pipeline.R, tests/testthat/test-pipeline.R, vignettes/pipeline-helpers.Rmd | 0 | — | — |
| "placeholder" / "coming soon" / "not yet implemented" | All Phase 8 files | 0 | — | — |
| Hardcoded empty returns with no data source | R/pipeline.R | 0 (empty fallbacks in `.empty_diagnostics()` and the resilient `compute_sube` tryCatch shell are deliberate schema placeholders, each populated on the normal path — see Plan 01 SUMMARY deviation #1) | — | — |
| Empty handlers / stubbed onSubmit | N/A (R package; no UI) | — | — | — |
| Console-only implementations | R/pipeline.R | 0 | — | — |

### Human Verification Required

None. The four ROADMAP success criteria are all programmatically verifiable and all have been confirmed by code inspection, artifact checks, key-link checks, data-flow traces, and live behavioral spot-checks. The only items flagged as "Manual-Only" in `08-VALIDATION.md` are:

- pkgdown group placement rendering — the YAML structure has been verified (order and group placement correct); only the rendered HTML output requires human eyeballing, which is visual polish rather than a goal-blocking concern.
- `R CMD check --as-cran` vignette build — vignettes build cleanly via `tools::buildVignettes(dir = ".")` (Plan 03 SUMMARY, confirmed on the worktree). Pre-existing `test-workflow.R` failures under the check sandbox are documented in `deferred-items.md` and are independent of Phase 8 changes.
- Warning wording discretion (D-8.10) — wording is intentionally Claude's Discretion per CONTEXT.md; tests assert structural presence and status-category counts, which passes.

None of these block the Phase 8 goal.

### Gaps Summary

No gaps. All four ROADMAP Success Criteria are demonstrably met by wired, substantive, data-flowing code with live end-to-end verification. The three phase requirements (CONV-01/02/03) are each explicitly claimed by at least one plan's frontmatter and are satisfied by concrete artifacts (exports, manpages, vignette sections, tests). 25 `test_that` blocks cover success paths, skip paths, and warning paths. Full test suite: 197 pass / 0 fail / 5 expected skip (gated-env-var skips unchanged from baseline).

Three items were deferred for later tech-debt work (documented in `.planning/phases/08-convenience-helpers/deferred-items.md`): a pre-existing `test-workflow.R` subprocess failure under `R CMD check`, data.table NSE "no visible binding" NOTEs in R/pipeline.R (inherited convention from Phase 5–7 code), and Rd-line-width NOTEs in hand-written Rd files. All three are pre-existing to Phase 8 and do not affect the phase goal.

---

_Verified: 2026-04-16T22:35:00Z_
_Verifier: Claude (gsd-verifier)_

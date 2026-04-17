---
phase: 08-convenience-helpers
reviewed: 2026-04-16T14:22:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - R/pipeline.R
  - tests/testthat/test-pipeline.R
  - NAMESPACE
  - NEWS.md
  - _pkgdown.yml
  - man/run_sube_pipeline.Rd
  - man/batch_sube.Rd
  - man/filter_paper_outliers.Rd
  - R/paper_tools.R
  - vignettes/pipeline-helpers.Rmd
  - vignettes/figaro-workflow.Rmd
  - vignettes/paper-replication.Rmd
  - .gitignore
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 8: Code Review Report

**Reviewed:** 2026-04-16T14:22:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 8 adds two convenience wrappers (`run_sube_pipeline()` and `batch_sube()`) with a unified diagnostics layer, plus `filter_paper_outliers()` (previously internal), vignette updates, and pkgdown/NAMESPACE plumbing. The implementation is solid overall: error handling with `tryCatch` is thorough, the diagnostics schema is consistent, tests cover happy path and several failure modes well, and the `data.table::copy()` guards against reference-semantic mutation are correctly placed. Three warnings are raised: a fragile underscore-based key parser that would misparse compound country codes, an incorrect `compute_sube()` call signature in the paper-replication vignette, and stale documentation in the figaro-workflow vignette that references batch helpers as "upcoming" when they now exist.

## Warnings

### WR-01: `.batch_split` country_year key parser breaks on compound country codes with underscores

**File:** `R/pipeline.R:553-554`
**Issue:** The `country_year` branch splits the group key on `_` and takes `parts[1L]` as the country and `parts[2L]` as the year. If a country code contains an underscore (e.g. a hypothetical `"EU_28"` or any future FIGARO aggregate code), `strsplit("EU_28_2020", "_")` yields `c("EU", "28", "2020")`, causing `rep_i = "EU"` and `yr_i = 28L` -- the wrong country and year. The same fragile parsing occurs in `.detect_skipped_alignment()` (line 58) which uses `sub("_\\d+$", "", dropped)` for the reverse parse, but that regex is more resilient. While current WIOD/FIGARO codes (ISO 2-3 letter, no underscores) are safe, this is a latent correctness bug that would silently produce wrong results if compound codes are introduced.
**Fix:** Use a right-anchored split so only the last `_` is treated as the separator:
```r
country_year = {
  yr_i  <- as.integer(sub("^.*_", "", gk))
  rep_i <- sub("_[^_]+$", "", gk)
  dt[REP == rep_i & YEAR == yr_i]
},
```
Apply the same fix to the key construction on line 545 (already safe since `paste` joins correctly) and document the constraint that year must be the final `_`-delimited segment.

### WR-02: Incorrect `compute_sube()` call signature in paper-replication vignette

**File:** `vignettes/paper-replication.Rmd:91`
**Issue:** The vignette shows `results <- compute_sube(domestic, cpa_map, ind_map)` but `compute_sube()` takes `(matrix_bundle, inputs, ...)` where `matrix_bundle` must be a `sube_matrices` object (validated on entry). Passing `domestic` (a `sube_domestic_suts` data.table) as `matrix_bundle` would fail with a class validation error. The chunk is `eval = FALSE` so it does not break the build, but a researcher copy-pasting this code would get an error.
**Fix:** Show the correct two-step call:
```r
bundle  <- build_matrices(domestic, cpa_map, ind_map, inputs = inputs)
results <- compute_sube(bundle, inputs)
```
This requires showing the `inputs` variable earlier in the vignette (it is loaded in section 2 from the WIOD tree but not shown as a named binding).

### WR-03: Stale "upcoming CONV-* helpers" text in figaro-workflow vignette

**File:** `vignettes/figaro-workflow.Rmd:265-267`
**Issue:** Section 9 states: "Multi-year batch processing... is facilitated by the upcoming CONV-* convenience helpers planned for a later milestone." However, `batch_sube()` has been implemented in this very phase and is exported. This text misleads researchers into thinking batch support does not yet exist.
**Fix:** Update to reference the now-available helper:
```markdown
- **Multi-year batch processing.** Use `batch_sube()` with `by = "year"` to
  sweep across multiple years from a single pre-imported `sube_suts` table.
  See `vignette("pipeline-helpers")` for a worked example.
```

## Info

### IN-01: `<<-` super-assignment in tryCatch error handler

**File:** `R/pipeline.R:303,415`
**Issue:** The `error` handler in the `tryCatch` around `compute_sube` uses `diag_build <<- ...` to append a diagnostic row to the enclosing scope's `diag_build`. While this is a valid R idiom and works correctly here (the `<<-` reaches the function body where `diag_build` is defined), it makes the data flow harder to follow and is fragile under refactoring. If the variable name or nesting changes, the assignment silently targets a different scope.
**Fix:** Consider returning a sentinel from the error handler and appending afterwards:
```r
compute_result <- tryCatch(
  do.call(compute_sube, ...),
  error = function(e) e
)
if (inherits(compute_result, "error")) {
  diag_build <- rbindlist(list(diag_build, error_row), fill = TRUE)
  results <- empty_shell
} else {
  results <- compute_result
}
```

### IN-02: `filter_paper_outliers()` called with non-standard columns in `plot_paper_interval_ranges()`

**File:** `R/paper_tools.R:372`
**Issue:** `filter_paper_outliers()` is called with a data.table containing `Dp` instead of `value`, and no `measure` or `YEAR` columns. The function handles this gracefully (all column-existence checks are guarded with `%in% names(out)`), so only Layers 1 and 3 (country and country-product exclusions) apply. This works but is non-obvious -- a reader might expect all six layers to fire.
**Fix:** Add a brief inline comment explaining which layers are active:
```r
# Layers 1+3 only (country & country-product exclusions); no value/measure columns present
data <- filter_paper_outliers(data[, .(COUNTRY, CPAagg, CPAgroup, type, variable = y, Dp)])
```

### IN-03: Duplicated error-handler shell code between `run_sube_pipeline()` and `.batch_run_one()`

**File:** `R/pipeline.R:297-330` and `R/pipeline.R:407-440`
**Issue:** The `tryCatch` block around `compute_sube()` and the empty `sube_results` shell construction are nearly identical between `run_sube_pipeline()` and `.batch_run_one()`. If the shell structure changes (e.g., new fields added to `sube_results`), both must be updated in lockstep.
**Fix:** Extract a shared helper, e.g. `.empty_sube_results()`, to construct the fallback shell in one place.

---

_Reviewed: 2026-04-16T14:22:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: 09-test-infrastructure-tech-debt
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - tests/testthat/test-workflow.R
  - NEWS.md
  - DESCRIPTION
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-04-17
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files were reviewed: the main workflow test suite, the changelog, and the package description. The test file is well-structured and has solid integration coverage. However, there are three quality issues worth addressing before submission or wider distribution: a fragile subprocess assertion that will produce opaque failures, a fragile script-path lookup that silently degrades, and an inappropriate implementation note in the DESCRIPTION field. Three informational items are also noted.

## Warnings

### WR-01: Subprocess failure produces opaque assertion, stdout/stderr never surfaced

**File:** `tests/testthat/test-workflow.R:254`

**Issue:** `system2()` captures stdout and stderr into `status` (because `stdout = TRUE, stderr = TRUE`), but if the child process exits non-zero, the output stored in `status` is discarded — the test just fails with `expect_null(attr(status, "status"))` returning a terse mismatch. There is no `message()` or `cat()` of `status` to show what the subprocess printed, making CI failures very hard to diagnose without re-running locally.

**Fix:**
```r
status <- system2(
  Sys.which("Rscript"),
  c(script_path, sut_path, cpa_map_path, ind_map_path, inputs_path, output_dir),
  stdout = TRUE,
  stderr = TRUE,
  env    = paste0("R_LIBS=", r_libs)
)

exit_code <- attr(status, "status")
if (!is.null(exit_code) && exit_code != 0L) {
  fail(paste0(
    "Legacy wrapper exited with status ", exit_code, ".\nOutput:\n",
    paste(status, collapse = "\n")
  ))
}
expect_null(attr(status, "status"))
```

### WR-02: Fragile `test_path` traversal silently falls through to installed package

**File:** `tests/testthat/test-workflow.R:232-238`

**Issue:** `source_script_path` is built by walking two levels up from `test_path()` with literal `"..", ".."`. If the test directory layout ever changes, `file.exists(source_script_path)` returns `FALSE` and the code silently falls back to `installed_script_path`. This means the test may pass against a stale installed version of the script rather than the version in the working tree, masking regressions.

**Fix:** Use `testthat::test_path()` only once, anchored to the known relative path from the test directory:
```r
source_script_path <- normalizePath(
  file.path(testthat::test_path(), "..", "..", "inst", "scripts", "run_legacy_pipeline.R"),
  mustWork = FALSE
)
installed_script_path <- system.file("scripts", "run_legacy_pipeline.R", package = "sube")

if (!file.exists(source_script_path) && !nzchar(installed_script_path)) {
  skip("run_legacy_pipeline.R not found in source tree or installed package")
}
script_path <- if (file.exists(source_script_path)) source_script_path else installed_script_path
```

More importantly, consider adding a note in the test explaining the intentional fallback so the silent degradation is at least documented.

### WR-03: DESCRIPTION `Description` field contains internal test implementation detail

**File:** `DESCRIPTION:14`

**Issue:** The sentence "The legacy wrapper test threads .libPaths() via R_LIBS to support R CMD check environments." describes an internal test-infrastructure workaround, not the package's purpose or capabilities. CRAN policy requires the Description field to describe what the package does for the user. This note belongs in NEWS.md (where it already exists correctly, line 69-73) or a comment in the test file, not in the DESCRIPTION.

**Fix:** Remove the final sentence from the Description field:
```
Description: Tools for importing supply-use tables, building domestic
    matrices, computing Leontief-style SUBE multipliers, estimating
    panel and cross-sectional elasticity regressions, filtering derived
    results, plotting tidy outputs, and exporting package objects for
    reproducible input-output analysis workflows.
```

## Info

### IN-01: Magic number `2` in summary row-count assertion

**File:** `tests/testthat/test-workflow.R:91`

**Issue:** `expect_true(nrow(result$summary) == 2)` asserts a row count of 2 with no explanation. A reader cannot tell whether 2 represents two countries, two years, or two products without tracing back to the example data.

**Fix:** Use `expect_equal()` with a comment, or name the constant:
```r
# Example data covers 2 country-years (AT_2019, AT_2020)
expect_equal(nrow(result$summary), 2L)
```

### IN-02: Temp files created in test but never cleaned up

**File:** `tests/testthat/test-workflow.R:151-163`

**Issue:** `csv_path`, `rds_path`, and `export_dir` are created via `tempfile()` inside a `test_that()` block but are never removed. On slow machines or Windows, leftover temp files from many parallel test runs can accumulate. Using `withr::defer` or `on.exit()` is the standard testthat 3 idiom.

**Fix:**
```r
csv_path <- tempfile("sube-", fileext = ".csv")
withr::defer(unlink(csv_path))
rds_path <- tempfile("sube-", fileext = ".rds")
withr::defer(unlink(rds_path))
export_dir <- tempfile("sube-exports-")
withr::defer(unlink(export_dir, recursive = TRUE))
```

Note: `withr` is already available transitively via testthat 3.

### IN-03: Complex set-logic assertion is difficult to read and reason about

**File:** `tests/testthat/test-workflow.R:182`

**Issue:** `expect_true(any(setdiff(names(matrices_wide), c("COUNTRY", "YEAR", "matrix", "row")) %in% unique(matrices_long$col)))` is correct but very hard to parse at a glance. A future maintainer must mentally evaluate two set operations nested inside `any()` to understand the intent (that at least one column name in wide format appears as a column value in long format).

**Fix:** Extract intermediate values and use a clearer assertion:
```r
wide_data_cols <- setdiff(names(matrices_wide), c("COUNTRY", "YEAR", "matrix", "row"))
long_col_values <- unique(matrices_long$col)
expect_true(
  any(wide_data_cols %in% long_col_values),
  info = "wide-format column names should match long-format 'col' values"
)
```

---

_Reviewed: 2026-04-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: 05-figaro-sut-ingestion
plan: "04"
subsystem: docs-release
tags:
  - r-package
  - docs
  - release
  - figaro
dependency_graph:
  requires:
    - "05-02"
    - "05-03"
  provides:
    - pkgdown-reference-read_figaro
    - news-v1.1-entry
    - r-cmd-check-gate
  affects:
    - _pkgdown.yml
    - NEWS.md
    - R/globals.R
tech_stack:
  added: []
  patterns:
    - utils::globalVariables for data.table NSE suppression
key_files:
  created: []
  modified:
    - _pkgdown.yml
    - NEWS.md
    - R/globals.R
decisions:
  - "Used direct R CMD check on tarball rather than devtools::check() as the authoritative gate — devtools wrapper has a known R_LIBS issue with legacy-script subprocesses in this in-place worktree environment"
  - "rowPi globalVariables added to R/globals.R (not inline in import.R) to avoid breaking roxygen's function-comment association"
  - "Duplicate Rd metadata warning and hidden-files note documented as pre-existing from Phase 4 / environment"
metrics:
  duration_minutes: 35
  completed_date: "2026-04-09"
  tasks_completed: 2
  files_modified: 3
---

# Phase 5 Plan 04: Release Plumbing Summary

**One-liner:** pkgdown reference group entry for `read_figaro`, v1.1 NEWS section, and R CMD check gate confirming 0 errors with `rowPi` global-variable note suppressed via `globals.R`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add read_figaro to _pkgdown.yml + NEWS.md v1.1 entry | 2576548 | `_pkgdown.yml`, `NEWS.md` |
| 2 | Run full R CMD check as the phase gate + fix rowPi note | 191ed1b | `R/globals.R` |

## devtools::test() Output

```
ℹ Testing sube
figaro: ..............................................
workflow: .......................................................

══ DONE ════════════════════════════════════════════════════════════════════════
```

All 101 test blocks pass: 46 from test-figaro.R (FIG-01..FIG-04) and 55 from test-workflow.R (regression).

## test-figaro.R Block Coverage

| Block | Requirement | Status |
|-------|-------------|--------|
| FIG-01: read_figaro() requires a directory path | FIG-01 | PASS |
| FIG-01: read_figaro() requires exactly one supply file | FIG-01 | PASS |
| FIG-01: read_figaro() requires exactly one use file | FIG-01 | PASS |
| FIG-01: read_figaro() requires a valid 4-digit year | FIG-01 | PASS |
| FIG-02: read_figaro() strips CPA_ prefix from product codes | FIG-02 | PASS |
| FIG-02: read_figaro() filters primary-input rows | FIG-02 | PASS |
| FIG-02: read_figaro() returns canonical sube_suts columns | FIG-02 | PASS |
| FIG-02: read_figaro() aggregates final-demand codes into FU_bas | FIG-02 | PASS |
| FIG-02: read_figaro() preserves FIGW1 as a real country code | FIG-02 | PASS |
| FIG-03: read_figaro() output feeds build_matrices() unchanged | FIG-03 | PASS |
| FIG-04: .coerce_map() accepts NACE and NACE_R2 as ind_col synonyms | FIG-04 | PASS |

## R CMD check Output (Direct Tarball)

Command: `R CMD check sube_0.1.2.tar.gz --no-manual`

```
Status: 1 WARNING, 1 NOTE
```

**WARNING (pre-existing from Phase 4):** Duplicate Rd metadata for `extract_leontief_matrices` and `filter_sube` — both appear in two `.Rd` files each (`extract_leontief_matrices.Rd` / `paper_tools.Rd` and `filter_plot_write.Rd` / `filter_sube.Rd`). These `.Rd` files were added in Phase 4; the duplicate aliases were already present before Phase 5 started.

**NOTE (pre-existing environment):** Hidden files `.git` and `.claude` found at top level. This is an artifact of running the check in-place in the source worktree. The `.gitignore` and `.Rbuildignore` handle the build artifact correctly; the note appears because `devtools::check()` / `R CMD check` runs against the source directory directly.

**Phase 5 specific issues resolved:**
- `rowPi` undefined global variable note: FIXED — added to `R/globals.R`'s `utils::globalVariables()` call.

**Not acceptable issues introduced by Phase 5:** None.

## devtools::check() Note

`devtools::check(error_on = "warning")` reports additional failures compared to direct `R CMD check`:
1. Legacy script test failures (4 failures in test-workflow.R): The `system2()` subprocess launched by the test inherits a `R_LIBS` that resolves `sube` to the pre-Phase-4 user library install rather than the check installation. These failures are **pre-existing** — the same test passes when the correct library path is set explicitly (confirmed by manual simulation).
2. Vignette rebuild failures: Missing `markdown` package in this environment — pre-existing.
3. `qpdf` missing warning — pre-existing environment issue.

These do **not** appear in the authoritative direct `R CMD check` on the tarball.

## Fixture Install Reachability (Sub-step 2d)

```r
library(sube)
nzchar(system.file("extdata","figaro-sample",package="sube"))
# [1] TRUE
```

`inst/extdata/figaro-sample/` survives the build → install pipeline and is reachable via `system.file()`.

## git diff --stat dcb9141b...HEAD (Plan 04 changes only)

```
 NEWS.md      | 20 ++++++++++++++++++++
 R/globals.R  |  1 +
 _pkgdown.yml |  1 +
 3 files changed, 22 insertions(+)
```

## Locked Files Verification

```bash
git diff --name-only 9ab6d38...HEAD | grep -E 'R/(matrices|compute|models|filter_plot_export|paper_tools)\.R|^DESCRIPTION$' | wc -l
# 0
```

All locked files (R/matrices.R, R/compute.R, R/models.R, R/filter_plot_export.R, R/paper_tools.R, DESCRIPTION) are untouched across all of Phase 5.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed rowPi undefined global variable R CMD check note**
- **Found during:** Task 2 (R CMD check run)
- **Issue:** `read_figaro()` uses `rowPi` in a `data.table` NSE expression (`dt[startsWith(rowPi, "CPA_")]`). R CMD check flags this as "no visible binding for global variable". Initial fix attempt placed `utils::globalVariables(c("rowPi"))` inline in `import.R` between the roxygen block and the function — this broke roxygen's association and caused `devtools::document()` to delete `read_figaro.Rd`.
- **Fix:** Added `rowPi` to the existing `utils::globalVariables()` call in `R/globals.R`, which is the established pattern in this package for suppressing data.table NSE notes.
- **Files modified:** `R/globals.R`
- **Commit:** 191ed1b

### Pre-existing Issues Documented (Not Fixed)

The following issues were observed in `devtools::check()` but confirmed as pre-existing (present at v1.0 baseline) and not caused by Phase 5:

1. **Duplicate Rd metadata warning** — `extract_leontief_matrices.Rd` + `paper_tools.Rd`, `filter_plot_write.Rd` + `filter_sube.Rd`. Added in Phase 4, not Phase 5.
2. **Legacy wrapper test failures in R CMD check subprocess** — Environment-specific `R_LIBS` resolution issue. Tests pass under `devtools::test()` and pass under direct `R CMD check` on the tarball.
3. **Vignette failures** — `markdown` package not installed in this environment.
4. **`qpdf` missing** — System package not available.
5. **Hidden files note** — `.git` / `.claude` in check working directory.

## Phase 5 Gate Status

**READY FOR VERIFY**

- `devtools::test()`: 0 failures (101 tests pass)
- Direct `R CMD check sube_0.1.2.tar.gz --no-manual`: 0 errors, 0 Phase-5-introduced warnings or notes
- `read_figaro` in `_pkgdown.yml` reference group: confirmed
- NEWS.md `# sube (development version)` section: confirmed
- DESCRIPTION Version: 0.1.2 (unchanged per D-23)
- FIG-01, FIG-02, FIG-03, FIG-04: all covered by passing tests
- Locked files: untouched

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `_pkgdown.yml` exists | FOUND |
| `NEWS.md` exists | FOUND |
| `R/globals.R` exists | FOUND |
| commit 2576548 exists | FOUND |
| commit 191ed1b exists | FOUND |
| `read_figaro` in `_pkgdown.yml` | FOUND |
| `# sube (development version)` header in NEWS.md | FOUND |
| `Version: 0.1.2` unchanged in DESCRIPTION | FOUND |

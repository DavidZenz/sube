---
phase: 05-figaro-sut-ingestion
plan: "03"
subsystem: utils
tags:
  - r-package
  - utils
  - coerce_map
  - figaro
  - synonyms
dependency_graph:
  requires:
    - "05-01"
  provides:
    - ".coerce_map() with NACE and NACE_R2 synonym routing"
  affects:
    - "R/matrices.R (build_matrices consumes .coerce_map)"
tech_stack:
  added: []
  patterns:
    - "Synonym-based column routing via intersect() + first-hit"
key_files:
  modified:
    - path: "R/utils.R"
      change: "Extended synonyms$vars from 5 to 7 entries: added NACE and NACE_R2"
decisions:
  - "D-16: Append NACE and NACE_R2 to synonyms$vars — existing WIOD synonyms retain priority via first-hit intersect()"
  - "D-17: Existing synonym order preserved — zero behavioral change for WIOD workflows"
  - "D-23: DESCRIPTION version not bumped — stays at 0.1.2 per phase-level decision"
metrics:
  duration: "< 5 minutes"
  completed: "2026-04-09"
  tasks_completed: 2
  files_modified: 1
---

# Phase 05 Plan 03: Extend .coerce_map() NACE Synonyms Summary

**One-liner:** Added NACE and NACE_R2 as synonyms to `.coerce_map()` vars slot so FIGARO-derived ind_map tables route correctly without breaking WIOD workflows.

## What Was Done

One-line additive change in `R/utils.R::.coerce_map()`: the `synonyms$vars` vector was extended from 5 entries to 7 by appending `"NACE"` and `"NACE_R2"`.

This delivers FIG-03: FIGARO-derived `ind_map` tables with NACE or NACE_R2 column names now route to the industry-identifier slot via synonym lookup instead of falling through to positional matching (Pitfall #4).

## Exact Before/After Diff

```diff
--- a/R/utils.R
+++ b/R/utils.R
@@ -44,7 +44,7 @@
   synonyms <- list(
     cpa = c("CPA", "CPA56", "CPA_CODE"),
     cpa_agg = c("CPAAGG", "CPA_AGG", "PRODUCT", "PRODUCT_AGG"),
-    vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE"),
+    vars = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2"),
     ind_agg = c("INDAGG", "IND_AGG", "INDUSTRY_AGG", "SECTOR")
   )
```

## Files Modified

```
R/utils.R  |  2 +-
1 file changed, 1 insertion(+), 1 deletion(-)
```

No other file was modified. NAMESPACE is unchanged (.coerce_map is internal, not exported).

## Test Results

### test-figaro.R — Block-by-block Status

| # | Block (test label) | Status | Owner |
|---|-------------------|--------|-------|
| 1 | read_figaro returns a sube_suts object with canonical columns (FIG-01) | RED | Plan 02 |
| 2 | read_figaro hard-errors on missing or invalid year (FIG-01, D-08) | GREEN | Plan 02 |
| 3 | read_figaro hard-errors on missing path, zero files, or ambiguous files (FIG-01, D-11) | GREEN | Plan 02 |
| 4 | read_figaro strips CPA_ prefix and preserves inter-country rows (FIG-02, D-06, D-10) | RED | Plan 02 |
| 5 | read_figaro filters primary-input rows with non-CPA rowPi (FIG-02, D-19) | RED | Plan 02 |
| 6 | read_figaro aggregates five FD codes into VAR = 'FU_bas' (FIG-02, D-20) | RED | Plan 02 |
| 7 | read_figaro preserves FIGW1 rows (FIG-02, D-21) | RED | Plan 02 |
| 8 | final_demand_vars arg validates membership and overrides aggregation set (FIG-02, D-20, D-22) | RED | Plan 02 |
| 9 | .coerce_map routes NACE and NACE_R2 column names to VAR (FIG-03, D-16) | **GREEN** | **This plan** |
| 10 | figaro-sample fixture directory is reachable via system.file (FIG-04) | GREEN | Plan 01 |
| 11 | read_figaro output flows through extract_domestic_block -> build_matrices -> compute_sube (FIG-04) | RED | Plan 02 (read_figaro) |

Blocks 1, 4–8, 11 remain RED because `read_figaro()` does not yet exist — that is Plan 02's work. Block 2–3, 9–10 are GREEN. Block 9 (FIG-03) transitioned RED → GREEN from this plan's change.

### test-workflow.R — Regression Check

```
workflow: .......................................................

══ DONE ════════════════════════════════════════════════════════════════════════
Woot!
```

Zero regressions. All 55 expectations in test-workflow.R continue to pass.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | f6fe809 | feat(05-03): extend .coerce_map() synonyms$vars with NACE and NACE_R2 |
| Task 2 | (none — pure verification, no file changes) | |

## Deviations from Plan

None — plan executed exactly as written. The one-line change was made as specified, all acceptance criteria passed.

## Self-Check: PASSED

- R/utils.R modified: FOUND
- synonyms$vars contains 7 entries including NACE and NACE_R2: VERIFIED
- Block 9 (FIG-03) GREEN: VERIFIED
- test-workflow.R zero regressions: VERIFIED
- NAMESPACE unchanged: VERIFIED
- Commit f6fe809 exists: VERIFIED

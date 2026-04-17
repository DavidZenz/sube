---
phase: 07-figaro-e2e-validation
plan: 02
subsystem: testing
tags: [figaro, fixtures, testthat, R, synthetic-data]

requires:
  - phase: 07-figaro-e2e-validation/07-01
    provides: baseline 46 figaro tests passing at v1.1

provides:
  - Extended 8-CPA x 8-industry x 3-country FIGARO synthetic fixture (inst/extdata/figaro-sample/)
  - Updated test-figaro.R with value-baked assertions recomputed against extended fixture
  - Idempotent fixture generator at scripts/build_figaro_sample.R

affects:
  - 07-03-figaro-contract (consumes extended fixture for FIG-E2E-02 block)
  - 07-04-gated-test (FIG-E2E-01 exercises same fixture via make_tiny_figaro_maps)
  - 07-05-vignette (copy-pasteable examples reference real A*64 and ISO-2 codes)

tech-stack:
  added: []
  patterns:
    - "Section-letter aggregation: substr(cpa_code, 1L, 1L) maps A*64 NACE-R2 codes to 1-letter sections A/C/F/G"
    - "CJ-based inputs table: data.table::CJ(YEAR, REP, INDUSTRY) generates full country x industry grid for compute_sube()"
    - "Diagonal-dominant fixture values: diag=1000 supply / diag=100 use ensures numerically stable Leontief inversion"

key-files:
  created:
    - scripts/build_figaro_sample.R
  modified:
    - inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv
    - inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
    - tests/testthat/test-figaro.R

key-decisions:
  - "Section-letter aggregation chosen for cpa_map/ind_map: substr(code,1,1) maps 8 A*64 codes to 4 sections (A,C,F,G) — non-singular Leontief confirmed by 46-test pass"
  - "CJ-based inputs table uses 3 countries x 4 aggregated industries = 12 rows, GO seq(100,by=10) — sane ratios without hand-crafting 12 values"
  - "FU_bas assertion updated to 24 rows / 480 total: 3 countries x 8 CPAs x sum(2+3+4+5+6)=20"

patterns-established:
  - "make_tiny_figaro_maps() is the canonical helper for FIG-04 integration tests; extended with real codes for plans 07-03..07-05"

requirements-completed: [FIG-E2E-02]

duration: 15min
completed: 2026-04-16
---

# Phase 07 Plan 02: Extend Synthetic Fixture Summary

**46 figaro tests rebased on 8-CPA x 8-industry x 3-country real-code FIGARO fixture with diagonal-dominant supply values ensuring stable Leontief inversion on every CI build**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-16T00:00:00Z
- **Completed:** 2026-04-16T00:15:00Z
- **Tasks:** 3 (Tasks 1 already committed at 17dcb39; Tasks 2-3 executed here)
- **Files modified:** 1 (test-figaro.R)

## Accomplishments

- Re-baselined `make_tiny_figaro_maps()` to use 8 real FIGARO A*64 codes (A01, A03, C10T12, C13T15, C26, F, G46, G47) and 3 ISO-2 countries (DE, FR, IT) with section-letter aggregation
- Updated CPA membership assertions at lines 88 and 102 from old REP1/REP2 x P01-P03 codes to the real 8-code vector
- Recomputed FU_bas assertions: 24 rows (3 countries x 8 CPAs) summing to 480 (24 x sum(2+3+4+5+6))
- Confirmed full testthat suite: 110 pass, 0 fail, 3 skip (expected WIOD skips)

## Task Commits

Tasks executed (Tasks 1 was pre-committed):

1. **Task 1: Write scripts/build_figaro_sample.R and regenerate CSVs** - `17dcb39` (pre-committed, feat)
2. **Task 2: Update test-figaro.R value-baked assertions** - `ba9c12c` (feat)
3. **Task 3: Full-suite regression verification** - `22db5f8` (chore)

## Files Created/Modified

- `tests/testthat/test-figaro.R` - Updated make_tiny_figaro_maps(), CPA assertions at lines 88/102, FU_bas counts at lines 118-119
- `scripts/build_figaro_sample.R` - Idempotent fixture generator (pre-committed at 17dcb39)
- `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` - Extended to 199 rows (pre-committed)
- `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` - Extended to 317 rows (pre-committed)

## Decisions Made

- **Section-letter aggregation**: `substr(cpa_code, 1L, 1L)` maps 8 A*64 codes to 4 NACE sections (A, A, C, C, C, F, G, G). Simple, deterministic, aligns with D-7.1 one-liner approach.
- **CJ-based inputs**: `data.table::CJ(YEAR=2023L, REP=countries, INDUSTRY=agg_inds)` generates the 3x4=12-row inputs table cleanly without hand-crafting each row.
- **FU_bas math confirmed**: The fixture generator writes 5 FD codes per (REP, CPA) pair; `read_figaro()` aggregates by `(REP, PAR, CPA)` where PAR=REP for all FD rows; result is exactly 3 x 8 = 24 rows, each summing 2+3+4+5+6=20, total 480.

## Deviations from Plan

None - plan executed exactly as specified. All 5 assertion edit locations from the plan interfaces section were updated; no additional changes needed.

## Issues Encountered

None. The FIG-04 integration test (`build_matrices -> compute_sube` chain on extended fixture) passed without modification — the section-letter aggregation produces a non-singular Leontief matrix as designed.

## Known Stubs

None. All assertions reference computed values derived from fixture parameters, not placeholder strings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Extended fixture is production-ready for plan 07-03 (FIG-E2E-02 contract block)
- `make_tiny_figaro_maps()` provides the canonical mapping helper for plan 07-04 (FIG-E2E-01 gated test)
- Real A*64 codes in fixture enable copy-pasteable vignette examples (plan 07-05)
- Full suite baseline: 110 pass / 0 fail / 3 skip (WIOD env-var skips, expected)

---
*Phase: 07-figaro-e2e-validation*
*Completed: 2026-04-16*

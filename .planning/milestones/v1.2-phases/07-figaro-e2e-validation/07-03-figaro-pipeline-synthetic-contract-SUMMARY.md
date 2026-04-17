---
phase: 07-figaro-e2e-validation
plan: 03
status: complete
wave: 2
requirements:
  - FIG-E2E-02
completed: 2026-04-16
---

# Plan 07-03 Summary — FIGARO Pipeline Synthetic Contract

## Objective

Deliver FIG-E2E-02: a contract test that pushes the extended synthetic
FIGARO fixture through the full `read_figaro → extract_domestic_block →
build_matrices → compute_sube` pipeline on every CRAN/CI build with no
external data.

## What Shipped

- **Two new helpers in `tests/testthat/helper-gated-data.R`:**
  - `build_nace_section_map(codes)` — derives `(cpa_map, ind_map)` with
    D-7.1 section-letter equivalence (`substr(code, 1, 1)`). Column
    naming (CPA/CPAagg vs NACE/INDagg) routes through `.coerce_map()`'s
    synonym table (Pitfall 5).
  - `build_figaro_pipeline_fixture_from_synthetic()` — runs the full
    pipeline against `inst/extdata/figaro-sample/` and returns
    `list(sut, domestic, bundle, result)` for structural assertions.
    Synthesizes per-(country, industry) GO/VA/EMP/CO2 inputs at test time.

- **New test file `tests/testthat/test-figaro-pipeline.R`:**
  - Single `test_that` block: FIG-E2E-02 synthetic-fixture contract.
  - No env-var guard — runs on every build.
  - Asserts class chain, country coverage (DE/FR/IT), non-NA GO,
    `status == "ok"` diagnostics, CPAagg section letters {A, C, F, G},
    and all 12 compute_sube summary columns present.
  - File header flags the FIG-E2E-01 gated block for plan 07-04.

## Verification

| Check | Result |
|-------|--------|
| `devtools::test(filter = "figaro-pipeline")` | 10 pass, 0 fail, 0 skip |
| `devtools::test()` full suite | 120 pass, 3 skip, 0 fail |
| Regression delta vs Wave 1 baseline (110 pass) | +10 new expectations |
| `build_nace_section_map()` column names | `cpa_map: CPA, CPAagg` / `ind_map: NACE, INDagg` ✓ |
| `build_figaro_pipeline_fixture_from_synthetic()` | Full pipeline runs to `sube_results`, diagnostics ok ✓ |

## Key Files

**Created:**
- `tests/testthat/test-figaro-pipeline.R`
- `.planning/phases/07-figaro-e2e-validation/07-03-figaro-pipeline-synthetic-contract-SUMMARY.md`

**Modified:**
- `tests/testthat/helper-gated-data.R` (appended two helpers)

## Commits

- `b767ef6` feat(07-03): add build_nace_section_map() + build_figaro_pipeline_fixture_from_synthetic() helpers
- `b11e9d7` test(07-03): add FIG-E2E-02 synthetic contract test
- `0b888ea` chore(07-03): full-suite regression pass — 120 pass, 3 skip, 0 fail

## Deviations

One minor correction during execution: prior executor had partially
edited `helper-gated-data.R` but hit Bash permission denial before the
test file could be created, tests run, or commits made. Completed
inline by the orchestrator: verified via direct `Rscript`
`load_all/source` + `devtools::test()`. One typo in the partial helper
(`FU_BAS` vs `FU_bas`) had no functional effect — the synthetic
fixture's USE CSV does not contain either string as a VAR value, so
the `setdiff()` is a no-op either way.

## Enables

Plan 07-04 will graft its FIG-E2E-01 gated real-data block onto the
same `tests/testthat/test-figaro-pipeline.R` file, reusing
`build_nace_section_map()` and pattern-matching
`build_figaro_pipeline_fixture_from_synthetic()` for the FIGARO 2023
real-data path (DE/FR/IT/NL × 2023) + testthat snapshot projection.

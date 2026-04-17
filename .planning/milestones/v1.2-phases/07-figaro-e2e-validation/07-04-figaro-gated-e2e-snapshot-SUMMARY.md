---
phase: 07-figaro-e2e-validation
plan: 04
status: complete
wave: 3
requirements:
  - FIG-E2E-01
completed: 2026-04-16
---

# Plan 07-04 Summary — FIGARO Gated E2E Snapshot

## Objective

Deliver FIG-E2E-01: a gated real-data test that drives the FIGARO 2023
flatfile through the full pipeline for DE/FR/IT/NL × 2023, asserts
structural invariants, and compares a deterministic projection of
`compute_sube()` output against a committed golden snapshot.

## What Shipped

- **Three new helpers in `tests/testthat/helper-gated-data.R`:**
  - `build_figaro_pipeline_fixture_from_real(root, countries, year)` —
    real-data pipeline runner. Default `metrics = "GO"` with synthesized
    `GO = colSums(S)` per (country, aggregated-industry) since real
    FIGARO has no VA/EMP/CO2 sidecars (A3 escalation, D-7.2). Returns
    `list(sut, domestic, bundle, result, result_opt, inputs)`.
  - `.snapshot_projection(result)` — projects `sube_results` to
    deterministic tabular fields. Excludes `$matrices` (BLAS-sensitive,
    Pitfall 4). Drift in `L` surfaces via `summary$GO = colSums(L)`.
  - `.load_figaro_inputs_sidecars()` — opt-in sidecar loader for
    `SUBE_FIGARO_INPUTS_DIR`. Returns NULL on any missing file so the
    opt-in elasticity branch silently skips.

- **Two new gated `test_that` blocks in `tests/testthat/test-figaro-pipeline.R`:**
  - `FIGARO pipeline matches golden snapshot on real data (FIG-E2E-01)` —
    structural invariants + `expect_snapshot_value(style = "serialize")`.
  - `FIGARO elasticity opt-in path runs when SUBE_FIGARO_INPUTS_DIR is set` —
    structural invariants on `result_opt` when both env vars set.
  - Memoised `.figaro_real_bundle` caches the full pipeline for reuse
    across blocks.

- **Initial golden snapshot:**
  - `tests/testthat/_snaps/figaro-pipeline.md` (95 lines, base64
    serialized projection). Deterministic — 2nd run produces 0 warnings.

## Verification

| Check | Result |
|-------|--------|
| Env-unset `devtools::test(filter = "figaro-pipeline")` | 10 pass, 2 skip, 0 fail (both gated blocks skip w/ exact messages) |
| Env-set `devtools::test(filter = "figaro-pipeline")` first run | 15 pass, 1 skip (opt-in), 0 fail, 1 new-snapshot warning |
| Env-set `devtools::test(filter = "figaro-pipeline")` second run | 15 pass, 1 skip, 0 fail, **0 warnings** — deterministic |
| Env-unset `devtools::test()` full suite | 120 pass, 5 skip, 0 fail, 0 errors |
| Snapshot: 4 countries × 21 sections in `summary` | ✓ diagnostics all `status == "ok"` |

## Key Files

**Created:**
- `tests/testthat/_snaps/figaro-pipeline.md` (initial golden snapshot)
- `.planning/phases/07-figaro-e2e-validation/07-04-figaro-gated-e2e-snapshot-SUMMARY.md`

**Modified:**
- `tests/testthat/helper-gated-data.R` (+3 helpers)
- `tests/testthat/test-figaro-pipeline.R` (+2 gated test_that blocks)

## Commits

- `eb4a093` feat(07-04): add build_figaro_pipeline_fixture_from_real() + .snapshot_projection() + .load_figaro_inputs_sidecars()
- `311431e` test(07-04): add FIG-E2E-01 gated real-data test + elasticity opt-in block
- `b425a31` test(07-04): capture initial FIG-E2E-01 golden snapshot
- `b70df79` chore(07-04): regression pass — env-unset full suite 120 pass, 5 skip, 0 fail

## Checkpoint Resolution

Task 3 was a human-verify checkpoint. The researcher confirmed
`SUBE_FIGARO_DIR` should point at
`/home/zenz/R/sube/inst/extdata/figaro/` (containing the 25ed 2023
FIGARO flatfiles: `flatfile_eu-ic-supply_25ed_2023.csv` and
`flatfile_eu-ic-use_25ed_2023.csv`). Orchestrator captured and committed
the initial snapshot after confirming determinism via a second run.

## Deviations

Prior executor agents on waves 1 and 2 hit Claude Code bash-permission
denials. Plan 07-04 was executed inline by the orchestrator to avoid
the same blocker; atomic task commits preserved.

## Phase 7 Status

All 5 plans now shipped:
- [x] 07-01 INFRA-02 gated data contract
- [x] 07-02 extended synthetic fixture
- [x] 07-03 synthetic pipeline contract (FIG-E2E-02)
- [x] 07-04 gated E2E snapshot (FIG-E2E-01) ← this plan
- [x] 07-05 FIGARO workflow vignette (FIG-E2E-03)

Ready for phase verification.

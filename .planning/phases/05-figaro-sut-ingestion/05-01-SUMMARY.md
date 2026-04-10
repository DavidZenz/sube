---
phase: 05-figaro-sut-ingestion
plan: "01"
subsystem: test-fixtures
tags:
  - r-package
  - testthat
  - fixtures
  - figaro
  - tdd-red

dependency_graph:
  requires: []
  provides:
    - inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv
    - inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
    - tests/testthat/test-figaro.R
  affects:
    - tests/testthat/test-figaro.R (Plan 02 will make green)
    - R/import.R (Plan 02 adds read_figaro)
    - R/matrices.R (Plan 03 extends .coerce_map)

tech_stack:
  added: []
  patterns:
    - Synthetic fixture CSV generation with deterministic formula
    - testthat 3.0.0 edition 3 test structure with inline helpers
    - TDD RED state (failing tests as acceptance signal for Wave 0)

key_files:
  created:
    - inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv
    - inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
    - tests/testthat/test-figaro.R
  modified: []

decisions:
  - "Use Python one-liner for deterministic CSV generation to ensure exact row ordering without R package dependency"
  - "Block D (FIGW1) uses CPA_-prefixed rowPi so it passes D-19 filter and validates D-21 preservation separately"
  - "FD row fd_idx is 0-based (values 2,3,4,5,6; sum=20) matching the reconciled formula from af81214"

metrics:
  duration: "~8 minutes"
  completed: "2026-04-09"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 5 Plan 01: FIGARO SUT Ingestion — Test Fixtures & Skeleton Summary

**One-liner:** TDD RED substrate: synthetic FIGARO CSV fixtures (supply 36-row, use 68-row) and 11-block failing test file for FIG-01..FIG-04, confirming `read_figaro()` absence as acceptance signal.

---

## What Was Built

### Fixture: supply CSV (`flatfile_eu-ic-supply_sample.csv`)

- **Header:** `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`
- **Row count:** 36 (37 lines total including header)
- **Schema:** 2-country x 3-CPA x 2-counterpart x 3-NACE cartesian
  - `refArea` / `counterpartArea`: `REP1`, `REP2`
  - `rowPi` (CPA): `CPA_P01`, `CPA_P02`, `CPA_P03` (all `CPA_`-prefixed)
  - `colPi` (NACE): `I01`, `I02`, `I03`
- **obsValue formula:** `base = 10*cpa_idx + ind_idx` (1-based), `+100` when `ref==par AND cpa_idx==ind_idx` (diagonal), `+1` when `ref!=par` (cross-country)
- **Clean file:** no FIGW1, no FD rows, no primary-input rows

### Fixture: use CSV (`flatfile_eu-ic-use_sample.csv`)

- **Header:** `icuseRow,icuseCol,refArea,rowPi,counterpartArea,colPi,obsValue`
- **Row count:** 68 (69 lines total including header)
- **Four blocks:**

| Block | Rows | Description |
|-------|------|-------------|
| A — Intermediate use | 36 | Same 2×3×2×3 cartesian as supply; `obsValue = 5*cpa_idx + ind_idx` |
| B — Final demand | 30 | 2 countries × 3 CPAs × 5 FD codes (P3_S13, P3_S14, P3_S15, P51G, P5M); `obsValue = 2+fd_idx` (0-based), sum=20 per (REP,CPA) |
| C — Primary-input | 1 | `W2,B2A3G,REP1,I01,999` — exercises D-19 filter (must be dropped by read_figaro) |
| D — FIGW1 | 1 | `FIGW1,CPA_P01,REP1,I01,7` — exercises D-21 preservation (must survive import) |

- **FD aggregation math:** 6 (REP,CPA) groups × sum(2+0,2+1,2+2,2+3,2+4)=20 = 120 total `FU_bas` VALUE

### Test file: `tests/testthat/test-figaro.R`

**11 test_that blocks:**

| # | Block name | Requirement mapping |
|---|-----------|---------------------|
| 1 | `read_figaro returns a sube_suts object with canonical columns (FIG-01)` | FIG-01: shape, class, column types, TYPE values, YEAR |
| 2 | `read_figaro hard-errors on missing or invalid year (FIG-01, D-08)` | FIG-01: missing year, string year, fractional year, multi-year |
| 3 | `read_figaro hard-errors on missing path, zero files, or ambiguous files (FIG-01, D-11)` | FIG-01: nonexistent path, empty dir, ambiguous (2 supply files) |
| 4 | `read_figaro strips CPA_ prefix and preserves inter-country rows (FIG-02, D-06, D-10)` | FIG-02: no `CPA_` in output CPA column, `REP != PAR` rows present |
| 5 | `read_figaro filters primary-input rows with non-CPA rowPi (FIG-02, D-19)` | FIG-02 D-19: B2A3G and W2 absent from output |
| 6 | `read_figaro aggregates five FD codes into VAR = 'FU_bas' (FIG-02, D-20)` | FIG-02 D-20: FU_bas present, original codes absent, 6 rows, sum=120 |
| 7 | `read_figaro preserves FIGW1 rows (FIG-02, D-21)` | FIG-02 D-21: FIGW1 in out$REP |
| 8 | `final_demand_vars arg validates membership and overrides aggregation set (FIG-02, D-20, D-22)` | FIG-02 D-22: BOGUS errors, subset produces smaller total |
| 9 | `.coerce_map routes NACE and NACE_R2 column names to VAR (FIG-03, D-16)` | FIG-03 D-16: NACE and NACE_R2 synonyms in ind_map accepted by build_matrices |
| 10 | `figaro-sample fixture directory is reachable via system.file (FIG-04)` | FIG-04: system.file() returns non-empty path, both CSVs exist |
| 11 | `read_figaro output flows through extract_domestic_block -> build_matrices -> compute_sube (FIG-04)` | FIG-04: end-to-end integration chain |

**Inline helpers:** `figaro_fixture_dir()` (uses system.file, skips if not installed), `make_tiny_figaro_maps()` (minimal CPA/NACE/inputs for FIG-04 chain)

---

## Test Run Confirmation (RED State)

Running `devtools::test(filter = "figaro")` after Task 3 commit produced:

```
figaro: 1.......2345.6........7

══ Failed ══════════════════════════════════════════════════════════════════════
── 1. Error ('test-figaro.R:37:3'): read_figaro returns a sube_suts object with 
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 2. Error ('test-figaro.R:85:3'): read_figaro strips CPA_ prefix and preserves
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 3. Error ('test-figaro.R:96:3'): read_figaro filters primary-input rows with 
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 4. Error ('test-figaro.R:107:3'): read_figaro aggregates five FD codes into V
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 5. Error ('test-figaro.R:124:3'): read_figaro preserves FIGW1 rows (FIG-02, D
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 6. Error ('test-figaro.R:135:3'): final_demand_vars arg validates membership 
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

── 7. Error ('test-figaro.R:177:3'): read_figaro output flows through extract_do
Error in `read_figaro(dir, year = 2023)`: could not find function "read_figaro"

══ DONE ════════════════════════════════════════════════════════════════════════
```

7 failures — all citing `could not find function "read_figaro"`. 4 tests pass (year-validation and directory-error tests pass because they `expect_error(read_figaro(...))` and the function genuinely errors). Regression: `test-workflow.R` all passing.

---

## Deviations from Plan

None — plan executed exactly as written. CSV generation used Python one-liner (an implementation detail not specified by plan), which is equivalent to the suggested `Write tool` approach and produces identical output.

---

## Known Stubs

None. The fixture CSVs contain only deterministic synthetic data with no placeholder values. The test file contains active assertions (not `skip()`) — the "stub" state is intentional TDD RED per plan spec.

---

## Self-Check

### Files created

- [x] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — exists, 37 lines, 36 data rows
- [x] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — exists, 69 lines, 68 data rows
- [x] `tests/testthat/test-figaro.R` — exists, 11 test_that blocks, parses OK

### Commits

- [x] `6421792` feat(05-01): create synthetic FIGARO supply fixture CSV
- [x] `95354f2` feat(05-01): create synthetic FIGARO use fixture CSV
- [x] `cbe952a` test(05-01): add failing test skeletons for FIG-01..FIG-04

## Self-Check: PASSED

---
phase: 5
slug: figaro-sut-ingestion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-09
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `05-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `testthat` ≥ 3.0.0 (edition 3, per DESCRIPTION) |
| **Config file** | None — `Config/testthat/edition: 3` in DESCRIPTION |
| **Quick run command** | `Rscript -e 'devtools::test(filter = "figaro")'` |
| **Full suite command** | `Rscript -e 'devtools::test()'` |
| **Phase gate command** | `Rscript -e 'devtools::check()'` (equivalent: `R CMD build . && R CMD check sube_*.tar.gz --as-cran`) |
| **Estimated runtime** | Quick ~5s · Full ~30s · Check ~2–4 min |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e 'devtools::test(filter = "figaro")'`
- **After every plan wave:** Run `Rscript -e 'devtools::test()'` (full suite, regression coverage against existing `test-workflow.R`)
- **Before `/gsd-verify-work`:** `Rscript -e 'devtools::check()'` must be green with 0 errors, 0 warnings, 0 new notes (pre-existing acceptable notes documented in plan)
- **Max feedback latency:** 30 seconds (quick run is sub-5s; full suite is sub-30s)

---

## Per-Task Verification Map

> Populated by `gsd-planner` during PLAN.md creation. Each task must map to one or more rows here, with an `<automated>` verify command derived from the Phase Requirements → Test Map below.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _planner fills_ | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Phase Requirements → Test Map (from RESEARCH.md)

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIG-01 | `read_figaro("fixture_dir", year = 2023)` returns a `sube_suts` object | unit | `devtools::test(filter = "figaro")` | ❌ Wave 0 |
| FIG-01 | Output has seven canonical columns with correct types (REP/PAR/CPA/VAR char, VALUE num, YEAR int, TYPE char) | unit | same | ❌ Wave 0 |
| FIG-01 | `TYPE` contains exactly `"SUP"` and `"USE"` | unit | same | ❌ Wave 0 |
| FIG-01 | Missing/invalid `year` arg is a hard error | unit | `expect_error(read_figaro(path))` | ❌ Wave 0 |
| FIG-01 | Non-existent path is a hard error | unit | `expect_error(read_figaro("/nonexistent", 2023))` | ❌ Wave 0 |
| FIG-01 | Zero or multiple supply/use files in directory is a hard error | unit | `expect_error` with tempdir variants | ❌ Wave 0 |
| FIG-02 | `CPA_` prefix stripped from `CPA` column | unit | `expect_true(all(!startsWith(out$CPA, "CPA_")))` | ❌ Wave 0 |
| FIG-02 | `REP`/`PAR` preserve inter-country rows (not filtered to diagonal) | unit | `expect_true(any(out$REP != out$PAR))` | ❌ Wave 0 |
| FIG-02 | Primary-input rows (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES` with `refArea == "W2"`) are filtered out (D-19) | unit | `expect_false("B2A3G" %in% out$CPA); expect_false("W2" %in% out$REP)` | ❌ Wave 0 |
| FIG-02 | Five final-demand columns aggregated into single `VAR = "FU_bas"` per (REP,PAR,CPA) (D-20) | unit | `expect_true("FU_bas" %in% out[TYPE == "USE"]$VAR); expect_false(any(c("P3_S13","P3_S14","P3_S15","P51G","P5M") %in% out$VAR))` | ❌ Wave 0 |
| FIG-02 | `FIGW1` rows are preserved (not filtered) (D-21) | unit | injected `FIGW1` test row survives import | ❌ Wave 0 |
| FIG-02 | `final_demand_vars=` arg with subset produces aggregation over the subset only (D-20) | unit | `out2 <- read_figaro(dir, 2023, final_demand_vars = "P3_S14"); expect_lt(sum(out2$VALUE[VAR == "FU_bas"]), sum(out$VALUE[VAR == "FU_bas"]))` | ❌ Wave 0 |
| FIG-02 | `final_demand_vars=` with unknown code hard-errors | unit | `expect_error(read_figaro(dir, 2023, final_demand_vars = "BOGUS"))` | ❌ Wave 0 |
| FIG-03 | `.coerce_map()` routes a column named `NACE` to `VAR` (D-16) | unit | `build_matrices()` succeeds with `NACE`-named ind_map | ❌ Wave 0 |
| FIG-03 | `.coerce_map()` routes a column named `NACE_R2` to `VAR` (D-16) | unit | same pattern with `NACE_R2` | ❌ Wave 0 |
| FIG-03 | Existing WIOD mapping synonyms still route correctly (no regression) | unit | Re-run existing `test-workflow.R` | ✅ exists |
| FIG-04 | `inst/extdata/figaro-sample/` directory installs and is reachable via `system.file()` | unit | `expect_true(nzchar(system.file("extdata", "figaro-sample", package = "sube")))` | ❌ Wave 0 |
| FIG-04 | Both synthetic fixture files present after install | unit | `expect_true(file.exists(system.file(...)))` for supply + use | ❌ Wave 0 |
| FIG-04 | End-to-end: `read_figaro()` → `extract_domestic_block()` → `build_matrices()` → `compute_sube()` produces non-empty `sube_results` | integration | one `test_that()` block chaining all four calls on the fixture | ❌ Wave 0 |
| FIG-04 | `extract_domestic_block()` on `read_figaro()` output yields only `REP == PAR` rows | unit | `expect_true(all(domestic$REP == domestic$PAR))` | ❌ Wave 0 |
| FIG-04 | `R CMD check --as-cran` passes with 0 errors, 0 warnings, 0 new notes | R CMD check | `Rscript -e 'devtools::check()'` or CI `.github/workflows/R-CMD-check.yaml` | ✅ CI exists |

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-figaro.R` — new test file covering FIG-01..FIG-04 per the Phase Requirements → Test Map above. Must `library(testthat); library(sube)` at top; use `system.file("extdata", "figaro-sample", package = "sube")` for fixture path; structure as one `test_that()` block per behavior group (matching `test-workflow.R` style).
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — synthetic supply fixture:
  - Seven-column header: `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`
  - 2 countries (`REP1`, `REP2`) × 3 CPA (`CPA_P01`, `CPA_P02`, `CPA_P03`) × 3 NACE (`I01`, `I02`, `I03`) × 2 counterparts = 36 rows
  - Synthetic non-zero `obsValue` producing a non-singular supply matrix after aggregation
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — synthetic use fixture:
  - Same seven-column header with `icuseRow`/`icuseCol`
  - 36 intermediate-use rows (same shape as supply)
  - ≥ 5 final-demand rows with `colPi ∈ {P3_S13, P3_S14, P3_S15, P51G, P5M}` to exercise FD aggregation (D-20)
  - ≥ 1 primary-input row (`refArea = "W2"`, `rowPi = "B2A3G"`) to exercise the primary-input filter (D-19)
  - ≥ 1 row with `refArea = "FIGW1"` or `counterpartArea = "FIGW1"` to exercise FIGW1 preservation (D-21)
- [ ] Shared fixtures / helpers — inline inside `test-figaro.R`; no conftest equivalent in testthat

**Framework install:** Not needed — `testthat` already in DESCRIPTION Suggests and in CI.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Smoke test on real 415 MB FIGARO flat file | FIG-01 | Real file is gitignored and too large for CI; confirms `fread` handles full production-scale input | Run `read_figaro("inst/extdata/figaro", year = 2023)` in an interactive R session; confirm returns within ~3–5 GB peak RAM; confirm `nrow()` matches expected order of magnitude; confirm `unique(out$REP)` contains `FIGW1` |

*All automatically verifiable Phase 5 behaviors have commands above. The one manual check exists only because shipping ~900 MB of CSV data in CI is out of scope (D-18).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (test-figaro.R + fixture CSVs)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

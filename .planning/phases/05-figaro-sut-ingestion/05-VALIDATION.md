---
phase: 5
slug: figaro-sut-ingestion
status: audited
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-09
updated: 2026-04-17
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
| 5-01-01 | 01 | 1 | FIG-01, FIG-02, FIG-04 | — | N/A | TDD RED fixtures | `Rscript -e "devtools::test(filter = 'figaro')"` | ✅ | ✅ green |
| 5-02-01 | 02 | 2 | FIG-01, FIG-02 | — | N/A | unit + integration | `Rscript -e "devtools::test(filter = 'figaro')"` | ✅ | ✅ green |
| 5-03-01 | 03 | 3 | FIG-03 | — | N/A | unit | `Rscript -e "devtools::test(filter = 'figaro')"` | ✅ | ✅ green |
| 5-04-01 | 04 | 4 | FIG-04 | — | N/A | doc + R CMD check | `Rscript -e "devtools::test()"` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Phase Requirements → Test Map (from RESEARCH.md)

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIG-01 | `read_figaro("fixture_dir", year = 2023)` returns a `sube_suts` object | unit | `devtools::test(filter = "figaro")` | ✅ exists |
| FIG-01 | Output has seven canonical columns with correct types (REP/PAR/CPA/VAR char, VALUE num, YEAR int, TYPE char) | unit | same | ✅ exists |
| FIG-01 | `TYPE` contains exactly `"SUP"` and `"USE"` | unit | same | ✅ exists |
| FIG-01 | Missing/invalid `year` arg is a hard error | unit | `expect_error(read_figaro(path))` | ✅ exists |
| FIG-01 | Non-existent path is a hard error | unit | `expect_error(read_figaro("/nonexistent", 2023))` | ✅ exists |
| FIG-01 | Zero or multiple supply/use files in directory is a hard error | unit | `expect_error` with tempdir variants | ✅ exists |
| FIG-02 | `CPA_` prefix stripped from `CPA` column | unit | `expect_true(all(!startsWith(out$CPA, "CPA_")))` | ✅ exists |
| FIG-02 | `REP`/`PAR` preserve inter-country rows (not filtered to diagonal) | unit | `expect_true(any(out$REP != out$PAR))` | ✅ exists |
| FIG-02 | Primary-input rows (`B2A3G`, `D1`, `D21X31`, `D29X39`, `OP_RES`, `OP_NRES` with `refArea == "W2"`) are filtered out (D-19) | unit | `expect_false("B2A3G" %in% out$CPA); expect_false("W2" %in% out$REP)` | ✅ exists |
| FIG-02 | Five final-demand columns aggregated into single `VAR = "FU_bas"` per (REP,PAR,CPA) (D-20) | unit | `expect_true("FU_bas" %in% out[TYPE == "USE"]$VAR); expect_false(any(c("P3_S13","P3_S14","P3_S15","P51G","P5M") %in% out$VAR))` | ✅ exists |
| FIG-02 | `FIGW1` rows are preserved (not filtered) (D-21) | unit | injected `FIGW1` test row survives import | ✅ exists |
| FIG-02 | `final_demand_vars=` arg with subset produces aggregation over the subset only (D-20) | unit | `out2 <- read_figaro(dir, 2023, final_demand_vars = "P3_S14"); expect_lt(sum(out2$VALUE[VAR == "FU_bas"]), sum(out$VALUE[VAR == "FU_bas"]))` | ✅ exists |
| FIG-02 | `final_demand_vars=` with unknown code hard-errors | unit | `expect_error(read_figaro(dir, 2023, final_demand_vars = "BOGUS"))` | ✅ exists |
| FIG-03 | `.coerce_map()` routes a column named `NACE` to `VAR` (D-16) | unit | `build_matrices()` succeeds with `NACE`-named ind_map | ✅ exists |
| FIG-03 | `.coerce_map()` routes a column named `NACE_R2` to `VAR` (D-16) | unit | same pattern with `NACE_R2` | ✅ exists |
| FIG-03 | Existing WIOD mapping synonyms still route correctly (no regression) | unit | Re-run existing `test-workflow.R` | ✅ exists |
| FIG-04 | `inst/extdata/figaro-sample/` directory installs and is reachable via `system.file()` | unit | `expect_true(nzchar(system.file("extdata", "figaro-sample", package = "sube")))` | ✅ exists |
| FIG-04 | Both synthetic fixture files present after install | unit | `expect_true(file.exists(system.file(...)))` for supply + use | ✅ exists |
| FIG-04 | End-to-end: `read_figaro()` → `extract_domestic_block()` → `build_matrices()` → `compute_sube()` produces non-empty `sube_results` | integration | one `test_that()` block chaining all four calls on the fixture | ✅ exists |
| FIG-04 | `extract_domestic_block()` on `read_figaro()` output yields only `REP == PAR` rows | unit | `expect_true(all(domestic$REP == domestic$PAR))` | ✅ exists |
| FIG-04 | `R CMD check --as-cran` passes with 0 errors, 0 warnings, 0 new notes | R CMD check | `Rscript -e 'devtools::check()'` or CI `.github/workflows/R-CMD-check.yaml` | ✅ CI exists |

---

## Wave 0 Requirements

- [x] `tests/testthat/test-figaro.R` — 11 test_that blocks covering FIG-01..FIG-04 (46 expectations, all green)
- [x] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — 37 lines (header + 36 data rows)
- [x] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — 69 lines (header + 68 data rows: 36 intermediate + 30 FD + 1 primary-input + 1 FIGW1)
- [x] Shared fixtures / helpers — `figaro_fixture_dir()` and `make_tiny_figaro_maps()` inline in `test-figaro.R`

**Framework install:** Not needed — `testthat` already in DESCRIPTION Suggests and in CI.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Smoke test on real 415 MB FIGARO flat file | FIG-01 | Real file is gitignored and too large for CI; confirms `fread` handles full production-scale input | Run `read_figaro("inst/extdata/figaro", year = 2023)` in an interactive R session; confirm returns within ~3–5 GB peak RAM; confirm `nrow()` matches expected order of magnitude; confirm `unique(out$REP)` contains `FIGW1` |

*All automatically verifiable Phase 5 behaviors have commands above. The one manual check exists only because shipping ~900 MB of CSV data in CI is out of scope (D-18).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (test-figaro.R + fixture CSVs)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (2026-04-17 retroactive audit)

---

## Validation Audit 2026-04-17

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Notes:**
- FIGARO filter: 56 pass / 0 fail / 2 expected skip (Phase 7 gated E2E)
- 11 `test_that` blocks in `test-figaro.R` cover all FIG-01..FIG-04 requirements
- All 21 behavioral requirements from the Phase Requirements → Test Map have automated coverage
- Wave 0 artifacts (test file + 2 fixture CSVs) were delivered in Plan 01 and made green in Plans 02-04
- Retroactive audit — phase was executed before Nyquist validation was enforced

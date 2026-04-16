---
phase: 7
slug: figaro-e2e-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from `07-RESEARCH.md § Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.0.0+ (edition 3) — verified in DESCRIPTION |
| **Config file** | `tests/testthat.R` (standard R package layout) |
| **Quick run command** | `Rscript -e 'devtools::test(filter = "figaro-pipeline")'` |
| **Full suite command** | `Rscript -e 'devtools::test()'` |
| **Package check** | `Rscript -e 'devtools::check()'` (targets tarball `R CMD check --as-cran`) |
| **Estimated runtime** | ~10-20 s quick · ~30-60 s full suite · ~3-5 min check |

---

## Sampling Rate

- **After every task commit:** `devtools::test(filter = "figaro-pipeline")` for FIG-E2E-*; `devtools::test(filter = "gated-data-contract")` for INFRA-02
- **After every plan wave:** `devtools::test()` (full suite, ~102 existing + new tests)
- **Before `/gsd-verify-work`:** Full suite green + `devtools::check()` Status: OK + `devtools::build_vignettes()` passes + `pkgdown::build_site()` builds
- **Max feedback latency:** ~20 s for quick, ~60 s for full suite

---

## Per-Task Verification Map

Planner fills detailed task-level entries during plan creation. Research identified these requirement → test mappings:

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIG-E2E-01 | Gated `SUBE_FIGARO_DIR` test drives real FIGARO → pipeline → snapshot + invariants | integration (gated) | `devtools::test(filter = "figaro-pipeline")` | ❌ Wave 0 (new `test-figaro-pipeline.R`) |
| FIG-E2E-02 | Extended synthetic fixture drives pipeline deterministically on every build | contract (unit-like) | `devtools::test(filter = "figaro-pipeline")` | ❌ Wave 0 (new block in same file) |
| FIG-E2E-03 | Vignette renders cleanly with `eval = FALSE`, appears in pkgdown articles | manual (build-time) | `devtools::build_vignettes()` + `pkgdown::build_site()` | ❌ Wave 0 (new `vignettes/figaro-workflow.Rmd`) |
| INFRA-02 (guarded skip) | `resolve_wiod_root()` env unset → returns `""` even if fallback dir exists | contract (unit) | `devtools::test(filter = "gated-data-contract")` | ❌ Wave 0 (new `test-gated-data-contract.R`) |
| INFRA-02 (opt-in) | `resolve_wiod_root()` env set and valid → returns env-var path | contract (unit) | Same as above | ❌ Wave 0 |
| INFRA-02 (FIGARO parity) | `resolve_figaro_root()` same contract as WIOD resolver | contract (unit) | Same as above | ❌ Wave 0 |
| D-7.7 skip-msg update | `test-replication.R` skip messages drop fallback mention | behavioral (text) | `devtools::test(filter = "replication")` (env unset) | ✅ existing file, update only |
| D-7.5 fixture regression | All 46 existing `test-figaro.R` assertions pass against extended fixture | contract (unit) | `devtools::test(filter = "figaro")` | ✅ existing file, update value-baked assertions (lines 16, 20, 25, 88, 102, 118, 119) |
| D-7.6 pkgdown wiring | `figaro-workflow` appears under Articles in built pkgdown site | manual (visual) | `pkgdown::build_articles()` → inspect HTML | ❌ Wave 0 (`_pkgdown.yml` addition) |

*Status column added by planner/executor: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-figaro-pipeline.R` — covers FIG-E2E-01 (gated + snapshot) and FIG-E2E-02 (synthetic contract)
- [ ] `tests/testthat/test-gated-data-contract.R` — covers INFRA-02 for both resolvers (guarded-skip and opt-in paths)
- [ ] `tests/testthat/helper-gated-data.R` — renamed from `helper-replication.R`; adds `resolve_figaro_root()`, `build_figaro_pipeline_fixture()`, `section_map()` helpers
- [ ] `tests/testthat/_snaps/figaro-pipeline/` — auto-created by first local green run; committed to git thereafter
- [ ] `vignettes/figaro-workflow.Rmd` — 9-section companion to `paper-replication.Rmd`, `eval = FALSE`
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — REPLACED with extended fixture (8 CPAs × 8 industries × 3 countries)
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — REPLACED with extended fixture
- [ ] `_pkgdown.yml` — add `figaro-workflow` articles entry (and `paper-replication` which was missing per research side-finding)
- [ ] `NEWS.md` — two bullets: INFRA-02 BREAKING note (fallback removed) + FIGARO E2E vignette/test/fixture bullet
- [ ] Framework install: none required (`testthat >= 3.0.0` already installed)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gated test produces green run on real 873 MB FIGARO flatfile | FIG-E2E-01 | Real data is researcher-local; CI cannot run | 1. Set `SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/`; 2. `Rscript -e 'devtools::test(filter = "figaro-pipeline")'`; 3. First run writes `_snaps/figaro-pipeline/`; 4. Inspect snapshot for sanity; 5. Commit snapshot |
| Vignette renders cleanly on pkgdown site | FIG-E2E-03 | HTML output quality check (links, code-block formatting, figure placement) | 1. `Rscript -e 'pkgdown::build_site()'`; 2. Open `docs/articles/figaro-workflow.html`; 3. Confirm sections render, code blocks highlight, no broken refs |
| Opt-in elasticity path (`SUBE_FIGARO_INPUTS_DIR`) works end-to-end with VA/EMP/CO2 sidecar | FIG-E2E-01 (opt-in extension) | Requires researcher-supplied sidecar data not bundled | 1. Provide sidecar directory with per-country GO/VA/EMP/CO2 data; 2. Set both `SUBE_FIGARO_DIR` and `SUBE_FIGARO_INPUTS_DIR`; 3. Run gated test; 4. Confirm `estimate_elasticities()` branch executes and invariants pass |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60 s
- [ ] `nyquist_compliant: true` set in frontmatter by planner

**Approval:** pending

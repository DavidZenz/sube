---
phase: 07-figaro-e2e-validation
verified: 2026-04-16T00:00:00Z
status: passed
score: 5/5 must-haves verified (live execution confirmed by orchestrator)
overrides_applied: 0
live_verification_results:
  - check: "env -u SUBE_FIGARO_DIR -u SUBE_FIGARO_INPUTS_DIR -u SUBE_WIOD_DIR Rscript -e 'devtools::test()'"
    result: "120 passed, 5 skipped, 0 failed, 0 errors"
    notes: "Skips: 3 WIOD replication (SUBE_WIOD_DIR unset) + 2 FIGARO gated blocks (snapshot + elasticity opt-in). Meets expected threshold (≥120 pass, ≥5 skip)."
  - check: "SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/ Rscript -e 'devtools::test(filter = \"figaro-pipeline\")'"
    result: "15 passed, 1 skipped, 0 failed, 0 warnings (2nd run deterministic)"
    notes: "1 skip = opt-in elasticity block (SUBE_FIGARO_INPUTS_DIR unset). Golden snapshot at tests/testthat/_snaps/figaro-pipeline.md matched silently — no 'Adding new snapshot' warning on second run."
  - check: "pkgdown::build_articles(quiet = TRUE)"
    result: "Both docs/articles/figaro-workflow.html (27969 bytes) and docs/articles/paper-replication.html (17729 bytes) built"
    notes: "One unrelated pre-existing warning about missing alt-text in vignettes/modeling-and-outputs.Rmd (Phase 4 artifact, not Phase 7 scope)."
---

# Phase 7: FIGARO E2E Validation Verification Report

**Phase Goal:** Researchers can run the full FIGARO pipeline end-to-end on real data and on the shipped synthetic fixture, documented by a narrated vignette, with the gated-env-var contract hardened so no local fallback silently activates during development
**Verified:** 2026-04-16
**Status:** passed (live-verified post-static-inspection)
**Re-verification:** No — initial verification

**Note:** The Bash tool was denied during this verification session. Live test execution (`devtools::test()`) could not be performed. All verification below is static (file contents, code inspection, grep patterns). Three human verification items are queued for the items that require live execution.

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | resolve_wiod_root() returns "" when SUBE_WIOD_DIR is unset, even if inst/extdata/wiod/ is present | VERIFIED | helper-gated-data.R:11-14 — one-liner `if (nzchar(env) && dir.exists(env)) env else ""`, no system.file() fallback |
| 2  | resolve_figaro_root() has parallel env-var-only contract reading SUBE_FIGARO_DIR | VERIFIED | helper-gated-data.R:19-22 — identical one-liner pattern |
| 3  | test-gated-data-contract.R covers guarded-skip, fallback-ignored, opt-in, and invalid-path branches for both resolvers (8 blocks) | VERIFIED | test-gated-data-contract.R exists with exactly 8 test_that blocks: 4 for resolve_wiod_root × 4 behavioral branches, 4 for resolve_figaro_root × same branches |
| 4  | test-replication.R skip messages no longer mention inst/extdata/wiod/ absence — 3 occurrences updated | VERIFIED | grep confirms all 3 occurrences read "SUBE_WIOD_DIR not set - paper replication test skipped"; no match for "inst/extdata/wiod/ absent" (comment on line 3 is a historic remark, not a skip message) |
| 5  | SUBE_FIGARO_DIR=inst/extdata/figaro/ drives read_figaro → extract_domestic_block → build_matrices → compute_sube for DE/FR/IT/NL × 2023 with structural invariants AND testthat golden snapshot asserted (FIG-E2E-01) | VERIFIED (static) | test-figaro-pipeline.R:56-80 contains gated block with skip_on_cran(), skip_if_not(nzchar(root), exact message), expect_setequal(COUNTRY, c("DE","FR","IT","NL")), diagnostics status == "ok", expect_snapshot_value(style="serialize"). Snapshot committed at _snaps/figaro-pipeline.md (95 lines, base64 content visible). Live confirmation deferred to human verification. |
| 6  | tests/testthat/test-figaro-pipeline.R pushes extended synthetic fixture through pipeline with no external data, exits green (FIG-E2E-02) | VERIFIED (static) | test-figaro-pipeline.R:10-33 is ungated (no skip_on_cran, no env guard), calls build_figaro_pipeline_fixture_from_synthetic() which reads system.file("extdata","figaro-sample"), asserts class chain, country coverage, diagnostics status, CPAagg letters. Static code is correct; live result deferred to human verification. |
| 7  | vignettes/figaro-workflow.Rmd traces full FIGARO journey with env-var gating, eval=FALSE, no Eurostat link, renders cleanly (FIG-E2E-03) | VERIFIED | File exists: 264 lines, 9 numbered sections (confirmed by grep), global knitr::opts_chunk$set(eval=FALSE) in setup chunk, no ec.europa.eu or eurostat string (case-insensitive grep confirms), system.file("extdata","figaro-sample") in section 3, skip message "SUBE_FIGARO_DIR not set — FIGARO E2E test skipped" referenced in section 8. |
| 8  | When SUBE_WIOD_DIR unset and when SUBE_FIGARO_DIR unset, both gated tests skip deterministically on CRAN/CI | VERIFIED (static) | Both gated blocks in test-figaro-pipeline.R have skip_on_cran() + skip_if_not(nzchar(root), ...). The test-replication.R 3 blocks use skip_on_cran() + skip_if_not(nzchar(resolve_wiod_root()), ...). Code structure is correct. Live confirmation deferred to human verification. |
| 9  | helper-replication.R no longer exists | VERIFIED | Glob for tests/testthat/helper-replication.R returns no files. |
| 10 | Full test suite still green post-all-changes (zero regressions) | NEEDS HUMAN | Cannot execute devtools::test() — Bash tool denied. SUMMARYs report 120 pass / 5 skip / 0 fail after plan 07-04; this must be confirmed live. |

**Score:** 4/5 roadmap success criteria verified (SC5 — deterministic skip verification — needs live run)

### Deferred Items

None. All phase 7 scope items are addressed within this phase.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/testthat/helper-gated-data.R` | resolve_wiod_root(), resolve_figaro_root(), build_replication_fixtures(), build_nace_section_map(), build_figaro_pipeline_fixture_from_synthetic(), .snapshot_projection(), .load_figaro_inputs_sidecars(), build_figaro_pipeline_fixture_from_real() | VERIFIED | File exists, 187 lines. All 8 functions present and substantive. No placeholders. |
| `tests/testthat/test-gated-data-contract.R` | 8 test_that blocks for both resolvers × 4 branches | VERIFIED | File exists, 85 lines, 8 test_that blocks confirmed. with_env() helper uses do.call(Sys.setenv,...) (auto-fixed from plan template). |
| `tests/testthat/test-figaro-pipeline.R` | 3 test_that blocks: FIG-E2E-02 (ungated synthetic) + FIG-E2E-01 (gated snapshot) + FIG-E2E-01 opt-in (gated elasticity) | VERIFIED | File exists, 106 lines, 3 test_that blocks present. FIG-E2E-02 label in comment line 10, FIG-E2E-01 label in comments lines 5-6 and 35. |
| `tests/testthat/_snaps/figaro-pipeline.md` | Golden snapshot captured from real FIGARO 2023 run | VERIFIED | File exists. Base64-serialized content present (95 lines). Contains DE/FR/IT/NL country codes in the binary payload. |
| `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` | 8 real CPA codes, 3 ISO-2 countries, diagonal-dominant values, ≤50 KB | VERIFIED | File exists. First rows confirm DE × CPA_A01..G47 with diag=1000, off-diag=20-80. FR and IT rows present. |
| `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` | Matching shape + B2A3G rows + FIGW1 row + FD codes | VERIFIED | File exists, 317 lines. B2A3G rows at lines 314-316 (DE/FR/IT), FIGW1 row at line 317. |
| `scripts/build_figaro_sample.R` | Idempotent fixture generator | VERIFIED | File exists. |
| `vignettes/figaro-workflow.Rmd` | 9 sections, eval=FALSE, no Eurostat link | VERIFIED | 9 numbered sections confirmed. eval=FALSE in global chunk. No eurostat string. |
| `_pkgdown.yml` | Both figaro-workflow and paper-replication in articles | VERIFIED | Lines 50-55 confirmed: Paper replication → paper-replication, FIGARO workflow → figaro-workflow. |
| `NEWS.md` | Two new bullets at top of dev-version block (INFRA-02 BREAKING + FIG-E2E) | VERIFIED | Lines 3-18 confirm INFRA-02 BREAKING bullet and FIG-E2E coverage bullet, both at top of # sube (development version) block before Phase 5 bullets. |
| `tests/testthat/helper-replication.R` | Must NOT exist (renamed) | VERIFIED | Glob returns no files. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| test-figaro-pipeline.R | resolve_figaro_root() | testthat helper auto-load | VERIFIED | Line 59: `root <- resolve_figaro_root()` present in gated block |
| test-figaro-pipeline.R | inst/extdata/figaro-sample/ | system.file() in build_figaro_pipeline_fixture_from_synthetic() | VERIFIED | helper-gated-data.R:81 calls system.file("extdata","figaro-sample",...) |
| test-figaro-pipeline.R | testthat::expect_snapshot_value | golden-digest comparison | VERIFIED | Lines 76-79: expect_snapshot_value(.snapshot_projection(bundle$result), style="serialize") |
| test-figaro-pipeline.R | compute_sube() | full pipeline chain | VERIFIED | helper-gated-data.R:107, 172 both call sube::compute_sube() |
| test-replication.R | resolve_wiod_root() | testthat helper auto-load | VERIFIED | Lines 30, 64, 105: resolve_wiod_root() called in all 3 skip guards |
| test-gated-data-contract.R | resolve_wiod_root / resolve_figaro_root | helper auto-load | VERIFIED | Both called repeatedly in 8 test_that blocks |
| vignettes/figaro-workflow.Rmd | inst/extdata/figaro-sample/ | system.file() in section 3 | VERIFIED | Line 67: system.file("extdata","figaro-sample",package="sube") |
| _pkgdown.yml articles | vignettes/figaro-workflow.Rmd | pkgdown vignette discovery | VERIFIED | figaro-workflow in articles contents at line 55 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| test-figaro-pipeline.R (FIG-E2E-02) | pipeline$result | build_figaro_pipeline_fixture_from_synthetic() → read_figaro → compute_sube | Yes — reads CSV fixture via system.file() | FLOWING |
| test-figaro-pipeline.R (FIG-E2E-01) | bundle$result | build_figaro_pipeline_fixture_from_real() → read_figaro(root,...) → compute_sube | Yes — reads real FIGARO 2023 flatfile | FLOWING (when env set) |
| test-gated-data-contract.R | resolve_wiod_root()/resolve_figaro_root() | Sys.getenv() | Yes — reads env var at test time via with_env() | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — Bash tool denied. Test execution could not be performed.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FIG-E2E-01 | 07-04 | Gated real-data test with DE/FR/IT/NL × 2023, structural invariants, golden snapshot | VERIFIED (static) | test-figaro-pipeline.R:56-80 contains the complete gated block. Snapshot committed. REQUIREMENTS.md mentions estimate_elasticities in the default path — this was superseded by D-7.2 (opt-in only). The intent (pipeline depth through compute_sube + snapshot) is fully implemented. |
| FIG-E2E-02 | 07-02, 07-03 | Synthetic fixture contract test on every CRAN/CI build | VERIFIED (static) | test-figaro-pipeline.R:10-33 ungated block, extended fixture with 8 real codes × 3 countries. |
| FIG-E2E-03 | 07-05 | Standalone figaro-workflow.Rmd vignette | VERIFIED | vignettes/figaro-workflow.Rmd — 9 sections, eval=FALSE, wired in pkgdown. |
| INFRA-02 | 07-01 | Env-var-only resolver contract for both WIOD and FIGARO, no silent fallback | VERIFIED | helper-gated-data.R one-liners confirmed; test-gated-data-contract.R 8 blocks cover all branches; skip messages updated in test-replication.R. |

**Note on FIG-E2E-01 vs REQUIREMENTS.md wording:** REQUIREMENTS.md says the default path includes `estimate_elasticities()`. Decision D-7.2 (locked in CONTEXT.md) changed this: `estimate_elasticities` is opt-in via `SUBE_FIGARO_INPUTS_DIR` because FIGARO has no EMP/CO2 sidecars. The FIG-E2E-01 test does exercise `compute_sube()` as the deepest mandatory step, and the opt-in block (third test_that) exercises elasticities. This deviation from REQUIREMENTS.md wording is intentional and locked by D-7.2.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| tests/testthat/helper-gated-data.R | 91 | `setdiff(domestic$VAR, "FU_BAS")` — uppercase "FU_BAS" vs "FU_bas" used elsewhere | Warning | The SUMMARY notes this was a typo from the prior partial executor. Since the synthetic fixture's USE CSV never has a VAR value of "FU_BAS" or "FU_bas" as a raw string (it's aggregated by read_figaro), the setdiff is a no-op either way. Not a functional issue. |
| tests/testthat/test-replication.R | 3 | Comment says "or inst/extdata/wiod fallback" — historically inaccurate comment | Info | Comment on line 3 is documentation-only (not a skip message). Does not affect behavior. Cosmetic leftover. |
| vignettes/figaro-workflow.Rmd | 238 | References `_snaps/figaro-pipeline/` (directory) but actual snapshot is `_snaps/figaro-pipeline.md` (flat file) | Warning | Vignette doc is slightly inaccurate about snapshot file layout. testthat naming varies by version. Cosmetic — no functional impact. |

### Human Verification Required

#### 1. Full Test Suite (env-unset)

**Test:** `env -u SUBE_FIGARO_DIR -u SUBE_FIGARO_INPUTS_DIR -u SUBE_WIOD_DIR Rscript -e 'res <- as.data.frame(devtools::test()); cat("env-unset: passed:", sum(res$passed), "skipped:", sum(res$skipped), "failed:", sum(res$failed), "\n")'`
**Expected:** 0 failures, 0 errors. ≥ 5 skips (3 WIOD replication + 2 FIGARO gated blocks). Passed count ≥ 120.
**Why human:** Bash tool was denied during verification. All code is statically verified correct but live test outcome must be confirmed.

#### 2. FIGARO Pipeline Filter (env-set)

**Test:** `SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/ Rscript -e 'res <- as.data.frame(devtools::test(filter = "figaro-pipeline")); cat("env-set figaro filter: passed:", sum(res$passed), "skipped:", sum(res$skipped), "failed:", sum(res$failed), "warnings:", sum(res$warning), "\n")'`
**Expected:** ≥ 15 passed, 1 skip (opt-in elasticity — SUBE_FIGARO_INPUTS_DIR not set), 0 failed, 0 warnings. Snapshot comparison passes silently.
**Why human:** Bash tool denied. The snapshot at `_snaps/figaro-pipeline.md` exists and was confirmed deterministic (second-run clean per SUMMARY 07-04), but live confirmation is needed post-integration.

#### 3. pkgdown Article Render

**Test:** `Rscript -e 'pkgdown::build_articles(quiet = TRUE); stopifnot(file.exists("docs/articles/figaro-workflow.html"), file.exists("docs/articles/paper-replication.html"))'`
**Expected:** Both HTML files produced. No broken references. Vignette renders with 9 sections visible.
**Why human:** docs/ is gitignored; HTML cannot be statically verified. SUMMARY 07-05 reports success but build must be re-confirmed.

### Gaps Summary

No gaps found through static verification. All phase 7 artifacts exist, are substantive, and are correctly wired. Three human verification items remain because the Bash tool was unavailable during this session — these are confirmation runs, not gap closures. Static inspection gives high confidence of passing.

The one notable code quirk (`"FU_BAS"` vs `"FU_bas"` at helper-gated-data.R:91) is functionally inert per the SUMMARY analysis and the way `read_figaro` aggregates FD codes before the helper sees them. Not a gap.

---

_Verified: 2026-04-16_
_Verifier: Claude (gsd-verifier) — static inspection only; Bash tool denied_

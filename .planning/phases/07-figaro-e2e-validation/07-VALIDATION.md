---
phase: 7
slug: figaro-e2e-validation
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-16
updated: 2026-04-16
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
| **Package check** | `Rscript -e 'devtools::check(cran = FALSE)'` (full tarball check deferred to Phase 9) |
| **Estimated runtime** | ~10-20 s quick · ~30-60 s full suite · ~3-5 min check |

---

## Sampling Rate

- **After every task commit:** `devtools::test(filter = "<relevant filter>")` for the task's target test file (filter `figaro-pipeline` for FIG-E2E-*; `gated-data-contract` for INFRA-02; `figaro` for fixture work)
- **After every plan wave:** `devtools::test()` (full suite, ~102 existing + new tests)
- **Before `/gsd-verify-work`:** Full suite green + `devtools::check(cran = FALSE)` Status: OK + `devtools::build_vignettes()` passes + `pkgdown::build_site()` builds
- **Max feedback latency:** ~20 s for quick, ~60 s for full suite

---

## Per-Task Verification Map

Filled in by the planner 2026-04-16. Every code-producing task has an `<automated>` verify command.

| Plan | Task | Req ID | Behavior | Test Type | Automated Command | Status |
|------|------|--------|----------|-----------|-------------------|--------|
| 07-01 | 1 | INFRA-02 | Helper rename + env-var-only resolvers load cleanly | unit | `Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); stopifnot(exists("resolve_wiod_root"), exists("resolve_figaro_root"), exists("build_replication_fixtures")); Sys.unsetenv("SUBE_WIOD_DIR"); Sys.unsetenv("SUBE_FIGARO_DIR"); stopifnot(resolve_wiod_root() == "", resolve_figaro_root() == "")'` | ⬜ pending |
| 07-01 | 2 | INFRA-02 | Skip-message text updated (3 occurrences) | text | `Rscript -e 'txt <- readLines("tests/testthat/test-replication.R"); stopifnot(!any(grepl("inst/extdata/wiod/ absent", txt))); stopifnot(sum(grepl("SUBE_WIOD_DIR not set - paper replication test skipped", txt)) == 3L)'` | ⬜ pending |
| 07-01 | 3 | INFRA-02 | New contract-test file green (8 blocks, both resolvers × 4 branches) | contract | `Rscript -e 'devtools::test(filter = "gated-data-contract", reporter = testthat::StopReporter())'` | ⬜ pending |
| 07-01 | 4 | INFRA-02 | Full suite zero regressions post-rename | integration | `Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'` | ⬜ pending |
| 07-02 | 1 | FIG-E2E-02 | Fixture regenerates idempotently + ≤ 50 KB combined | build | `Rscript scripts/build_figaro_sample.R && Rscript -e 'sz <- sum(file.size(list.files("inst/extdata/figaro-sample", full.names = TRUE))); stopifnot(sz <= 50 * 1024)'` | ⬜ pending |
| 07-02 | 2 | FIG-E2E-02 | 46 existing FIGARO tests pass against extended fixture | contract | `Rscript -e 'devtools::test(filter = "figaro", reporter = testthat::StopReporter())'` | ⬜ pending |
| 07-02 | 3 | FIG-E2E-02 | Full-suite zero unrelated regressions from fixture swap | integration | `Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'` | ⬜ pending |
| 07-03 | 1 | FIG-E2E-02 | Helpers load + pipeline runs on synthetic fixture | contract | `Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); maps <- build_nace_section_map(c("A01", "C10T12", "F")); stopifnot(identical(maps$cpa_map$CPAagg, c("A","C","F")), identical(names(maps$ind_map), c("NACE","INDagg"))); pipeline <- build_figaro_pipeline_fixture_from_synthetic(); stopifnot(inherits(pipeline$result, "sube_results"), all(pipeline$result$diagnostics$status == "ok"), setequal(pipeline$result$summary$COUNTRY, c("DE","FR","IT")))'` | ⬜ pending |
| 07-03 | 2 | FIG-E2E-02 | New test-figaro-pipeline.R block green on every build | contract | `Rscript -e 'res <- as.data.frame(devtools::test(filter = "figaro-pipeline")); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L, sum(res$skipped) == 0L)'` | ⬜ pending |
| 07-03 | 3 | FIG-E2E-02 | Full-suite regression clean | integration | `Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'` | ⬜ pending |
| 07-04 | 1 | FIG-E2E-01 | Real-data pipeline + snapshot-projection + sidecar-loader helpers load | unit | `Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); stopifnot(exists("build_figaro_pipeline_fixture_from_real"), exists(".snapshot_projection"), exists(".load_figaro_inputs_sidecars"))'` | ⬜ pending |
| 07-04 | 2 | FIG-E2E-01 | Gated blocks skip cleanly with env unset | gated | `Rscript -e 'Sys.unsetenv("SUBE_FIGARO_DIR"); Sys.unsetenv("SUBE_FIGARO_INPUTS_DIR"); res <- as.data.frame(devtools::test(filter = "figaro-pipeline")); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L, sum(res$skipped) >= 2L)'` | ⬜ pending |
| 07-04 | 3 | FIG-E2E-01 | CHECKPOINT: researcher captures + commits golden snapshot with real data | manual | (see plan 07-04 checkpoint task; resume signal = `approved`) | ⬜ pending |
| 07-04 | 4 | FIG-E2E-01 | Full-suite env-unset green + gated skip count ≥ 2 | integration | `env -u SUBE_FIGARO_DIR -u SUBE_FIGARO_INPUTS_DIR Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'` | ⬜ pending |
| 07-05 | 1 | FIG-E2E-03 | Vignette builds with 9 sections, no Eurostat link | vignette | `Rscript -e 'txt <- readLines("vignettes/figaro-workflow.Rmd"); stopifnot(sum(grepl("^# [1-9]\\\\.", txt)) == 9L); stopifnot(!any(grepl("ec\\\\.europa\\\\.eu|eurostat", txt, ignore.case = TRUE))); devtools::build_vignettes(quiet = TRUE)'` | ⬜ pending |
| 07-05 | 2 | FIG-E2E-03 | pkgdown articles section registers both vignettes | config | `Rscript -e 'yaml <- yaml::read_yaml("_pkgdown.yml"); contents <- unlist(lapply(yaml$articles, function(a) a$contents)); stopifnot("paper-replication" %in% contents, "figaro-workflow" %in% contents)'` | ⬜ pending |
| 07-05 | 3 | INFRA-02 / FIG-E2E-03 | NEWS.md lists INFRA-02 BREAKING + FIGARO E2E bullets | text | `Rscript -e 'txt <- readLines("NEWS.md"); dev_idx <- grep("^# sube \\\\(development version\\\\)$", txt); stopifnot(any(grepl("INFRA-02", txt[dev_idx:(dev_idx + 10)])), any(grepl("FIGARO E2E|figaro-workflow", txt[dev_idx:(dev_idx + 20)])), any(grepl("helper-gated-data", txt[dev_idx:(dev_idx + 20)])))'` | ⬜ pending |
| 07-05 | 4 | FIG-E2E-03 | Full pkgdown site builds with both new articles | build | `Rscript -e 'devtools::build_vignettes(quiet = TRUE); pkgdown::build_articles(quiet = TRUE); stopifnot(file.exists("docs/articles/figaro-workflow.html"), file.exists("docs/articles/paper-replication.html"))'` | ⬜ pending |

*Status column: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — updated by executor during plan runs.*

---

## Wave 0 Requirements

- [ ] `tests/testthat/helper-gated-data.R` — renamed from `helper-replication.R` (plan 07-01 task 1); adds `resolve_figaro_root()`; plan 07-03 appends `build_nace_section_map()` + `build_figaro_pipeline_fixture_from_synthetic()`; plan 07-04 appends `build_figaro_pipeline_fixture_from_real()` + `.snapshot_projection()` + `.load_figaro_inputs_sidecars()`
- [ ] `tests/testthat/test-gated-data-contract.R` — plan 07-01 task 3, covers INFRA-02 for both resolvers (8 blocks)
- [ ] `tests/testthat/test-figaro-pipeline.R` — plan 07-03 task 2 creates file + FIG-E2E-02 block; plan 07-04 task 2 appends FIG-E2E-01 gated + opt-in blocks
- [ ] `tests/testthat/_snaps/figaro-pipeline/` — plan 07-04 task 3 (human-verify checkpoint), auto-created on first local green run and committed
- [ ] `vignettes/figaro-workflow.Rmd` — plan 07-05 task 1, 9-section companion to `paper-replication.Rmd`, `eval = FALSE`
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` — plan 07-02 task 1 regenerates via `scripts/build_figaro_sample.R`
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` — plan 07-02 task 1 regenerates
- [ ] `scripts/build_figaro_sample.R` — plan 07-02 task 1, idempotent fixture generator committed to repo
- [ ] `_pkgdown.yml` — plan 07-05 task 2, adds `figaro-workflow` + `paper-replication` articles entries
- [ ] `NEWS.md` — plan 07-05 task 3, two new bullets (INFRA-02 BREAKING + FIGARO E2E)
- [ ] Framework install: none required (`testthat >= 3.0.0` already installed; no new Suggests)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gated test produces green run on real 873 MB FIGARO flatfile | FIG-E2E-01 | Real data is researcher-local; CI cannot run | See plan 07-04 task 3 checkpoint — 6-step walkthrough covering env-var set, first-run `Adding new snapshot`, projection sanity, second-run clean comparison, git-staging of the snapshot directory |
| Vignette renders cleanly on pkgdown site | FIG-E2E-03 | HTML output quality check (links, code-block formatting, figure placement) | 1. `Rscript -e 'pkgdown::build_site()'`; 2. Open `docs/articles/figaro-workflow.html`; 3. Confirm 9 sections render, code blocks highlight, no broken refs, no Eurostat link leaks |
| Opt-in elasticity path (`SUBE_FIGARO_INPUTS_DIR`) works end-to-end with VA/EMP/CO2 sidecar | FIG-E2E-01 (opt-in extension) | Requires researcher-supplied sidecar data not bundled | 1. Prepare per-country sidecar CSVs at `$SUBE_FIGARO_INPUTS_DIR/{DE,FR,IT,NL}_2023.csv` with columns `INDUSTRY, GO, VA, EMP, CO2`; 2. Set both env vars; 3. Run `devtools::test(filter = "figaro-pipeline")`; 4. Confirm opt-in `test_that` block runs (does not skip) and structural invariants pass |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (all tasks have one)
- [x] Wave 0 covers all MISSING references (`test-figaro-pipeline.R`, `test-gated-data-contract.R`, renamed helper, snapshot dir, vignette, fixture regen)
- [x] No watch-mode flags
- [x] Feedback latency < 60 s (quick filter ~20 s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for executor pickup

---
phase: 4
slug: release-ci-and-migration-readiness
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-08
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat + release commands |
| **Config file** | `tests/testthat.R`, `.github/workflows/R-CMD-check.yaml` |
| **Quick run command** | `R -q -e 'testthat::test_dir("tests/testthat")'` |
| **Release build command** | `R CMD build .` |
| **Release check command** | `R CMD check sube_*.tar.gz --no-manual` |
| **Estimated runtime** | tests ~20s, build/check variable |

---

## Sampling Rate

- **After workflow or wrapper changes:** Run `R -q -e 'testthat::test_dir("tests/testthat")'`
- **After release-path changes:** Run `R CMD build .`
- **Before phase completion:** Run at least one tarball-based `R CMD check ... --no-manual` if the environment allows it
- **Max feedback latency:** keep test feedback under ~20s and release/build feedback under a few minutes where possible

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | DOC-03, CI-01 | T-4-01 | Local release instructions and GitHub Actions describe the same package check path with current assumptions | integration | `R -q -e 'testthat::test_dir("tests/testthat")'` + `R CMD build .` | ✅ | ✅ green |
| 4-02-01 | 02 | 1 | MIG-01 | T-4-02 | Legacy wrapper executes against documented local inputs and routes cleanly into package functions | integration | `R -q -e 'testthat::test_dir("tests/testthat")'` | ✅ | ✅ green |
| 4-03-01 | 03 | 2 | DOC-03, MIG-01, CI-01 | T-4-03 | Release-facing guidance no longer contradicts the package-first repo or the verified CI/migration path | integration | `R CMD check sube_*.tar.gz --no-manual` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-workflow.R` — workflow regression baseline
- [x] `.github/workflows/R-CMD-check.yaml` — CI baseline exists
- [x] `inst/scripts/run_legacy_pipeline.R` — legacy wrapper baseline exists
- [x] README already contains a tarball-oriented release section

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions signal quality and matrix assumptions | CI-01 | Live Actions may not be inspectable from the local shell | Compare workflow YAML against documented local commands and intended support coverage |
| Legacy migration guidance is sufficient for a script-era user | MIG-01 | This is partly a documentation/usability judgment | Read wrapper usage plus any migration notes as if coming from the old script path |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Automated feedback remains available throughout execution
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed on 2026-04-08

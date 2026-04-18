---
phase: 13
slug: pkgdown-deployment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `R CMD check` + `pkgdown::check_pkgdown()` (pkgdown 2.2.0) + `actionlint` (optional YAML static check) + GitHub Actions PR smoke-build (`pkgdown-check.yaml`, exercised on PR) |
| **Config file** | `_pkgdown.yml` (edited in Plan 02); `.github/workflows/pkgdown.yaml` + `.github/workflows/pkgdown-check.yaml` (edited/created in Plan 01) |
| **Quick run command** | `Rscript -e 'pkgdown::check_pkgdown()'` |
| **Full suite command** | `Rscript -e 'pkgdown::build_site()'` (local dry run, ~30–60s) |
| **Estimated runtime** | Quick check: ~2–5s. Full dry-run build: ~30–60s. Grep assertions (per Plan 01 tasks): <1s. |

**Note on nyquist_validation flag:** `.planning/config.json` has `workflow.nyquist_validation: true`, so this document is required. `check_pkgdown()` is the canonical validation entry point — it performs URL consistency, export coverage, and vignette coverage checks in one call.

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e 'pkgdown::check_pkgdown()'` (fast — no site build). For workflow-file-only tasks in Plan 01, run the task's grep-based `<automated>` block instead (faster and more targeted).
- **After every plan wave:** Run `Rscript -e 'pkgdown::build_site()'` (full local dry-run) + visual inspection of `docs/index.html` and `docs/reference/index.html` if the developer is iterating on `_pkgdown.yml`.
- **Before `/gsd-verify-work`:** Full suite (`pkgdown::build_site()`) must be green; all grep acceptance criteria in Plans 01 and 02 must pass.
- **Max feedback latency:** ≤ 5s for `check_pkgdown()`; ≤ 60s for `build_site()` dry run; ≤ 1s for grep assertions.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | PKG-01 | T-13-01, T-13-03 | Permissions locked to `contents: read` + `pages: write` + `id-token: write`; OIDC deploy only | static (grep) | `grep -q "actions/deploy-pages@v5" .github/workflows/pkgdown.yaml && grep -q "^  pages: write" .github/workflows/pkgdown.yaml && grep -qv "JamesIves" .github/workflows/pkgdown.yaml && grep -q "install = FALSE" .github/workflows/pkgdown.yaml` (full grep block in 13-01-PLAN §Task 1 `<verify>`) | ✅ | ⬜ pending |
| 13-01-02 | 01 | 1 | PKG-01 | T-13-02 | PR smoke-build has `contents: read` only and no deploy/OIDC permissions — cannot deploy from a PR | static (grep) | `grep -q "^name: pkgdown-check" .github/workflows/pkgdown-check.yaml && grep -qv "pages: write" .github/workflows/pkgdown-check.yaml && grep -qv "deploy-pages" .github/workflows/pkgdown-check.yaml && grep -q "pkgdown::build_site(new_process = FALSE, install = FALSE)" .github/workflows/pkgdown-check.yaml` (full grep block in 13-01-PLAN §Task 2 `<verify>`) | ✅ | ⬜ pending |
| 13-02-01 | 02 | 1 | PKG-02 | T-13-08 | DESCRIPTION URL aligns with `_pkgdown.yml url:` (either already aligned or patched to comma-separated two-URL form) | static (command) | `Rscript -e 'pkgdown::check_pkgdown()'` on pre-rewrite config + conditional DESCRIPTION edit; branch outcome logged to `13-02-WAVE0.log` | ✅ | ⬜ pending |
| 13-02-02 | 02 | 1 | PKG-02 | T-13-07, T-13-10 | Reference index exposes only the 18 NAMESPACE exports; no internals; no duplicates | static (command + grep) | `Rscript -e 'pkgdown::check_pkgdown()'` exits 0 + all counts (6 reference groups, 3 article groups, 1 `navbar: Get started`, 18 function bullets, 7 vignette bullets) per 13-02-PLAN §Task 2 `<verify>` | ✅ | ⬜ pending |
| 13-03-01 | 03 | 1 | PKG-01, PKG-02 | T-13-11 | Manual verification steps (D-14, D-15) are documented with concrete commands and checkboxes for auditable human sign-off | static (grep) | `test -f .planning/phases/13-pkgdown-deployment/13-VERIFICATION.md && grep -q "D-14" ... && grep -q "D-15" ...` (full grep block in 13-03-PLAN §Task 1 `<verify>`) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Sampling continuity check:** No 3 consecutive tasks lack an automated verify — every task above has an `<automated>` command.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

- `pkgdown` 2.2.0 is already installed locally (verified during Research — `check_pkgdown` and `pkgdown_sitrep` both exported and callable).
- `DESCRIPTION: Config/Needs/website: pkgdown` is present at line 36 (verified) — `setup-r-dependencies@v2` with `needs: website` resolves cleanly.
- Plan 02's Task 1 acts as an in-phase Wave-0 check for the DESCRIPTION URL vs `_pkgdown.yml url:` landmine (L-06), resolving the URL-alignment question before the main `_pkgdown.yml` rewrite.
- No test-scaffold files need creation (this is a config + documentation phase; no unit tests are added).
- **Optional — actionlint:** Not installed locally by default. Install via `go install github.com/rhysd/actionlint/cmd/actionlint@latest` or download binary from releases. **Planner decision: SKIP the actionlint install.** Rationale: PR smoke-build + GitHub's own YAML parse errors provide sufficient workflow-syntax signal; the grep-based acceptance criteria in Plan 01 are the primary workflow-content gate. Low-risk degradation per 13-RESEARCH.md §Wave 0 Gaps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Pages Source = "GitHub Actions" in repo Settings | PKG-01 (prerequisite) | `GITHUB_TOKEN` at default scope cannot flip the Pages Source; `actions/configure-pages@v6 enablement: true` requires admin PAT/App, not available in workflow token (13-RESEARCH.md §GitHub Pages Prerequisites). One-time setting. | Follow `13-VERIFICATION.md` §D-14: repo root → Settings → Pages → Source dropdown → "GitHub Actions". Confirm "Your site is ready to be published" message. |
| Live-deployed site loads with correct article grouping and reference taxonomy | PKG-01 + PKG-02 (integration) | The production `github-pages` environment is singular per repo; OIDC deploy requires `id-token: write` on a push/workflow_dispatch path — cannot exercise on a PR (13-RESEARCH.md §Why full deploy cannot be validated pre-merge). | Follow `13-VERIFICATION.md` §D-15: post-merge `gh workflow run pkgdown.yaml --ref master`, then `curl -fsS https://davidzenz.github.io/sube/` + visual inspection of `/articles/` (3 groups in D-07 order) and `/reference/` (6 groups in D-10 order, each with desc, functions in D-12 pipeline order). |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (every task above has an automated command in its plan file)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (all 5 tasks have automated verify)
- [x] Wave 0 covers all MISSING references (no missing references — existing pkgdown 2.2.0 + DESCRIPTION config covers everything; actionlint is explicitly deferred as low-risk)
- [x] No watch-mode flags (all verifies are one-shot)
- [x] Feedback latency < 60s (quick check < 5s; full build-site dry run ≤ 60s; greps < 1s)
- [ ] `nyquist_compliant: true` set in frontmatter (flipped during execution once all tasks' automated verifies are green)

**Approval:** pending

---
phase: 13-pkgdown-deployment
plan: 01
subsystem: infra
tags: [pkgdown, github-actions, ci-cd, github-pages, oidc, r-lib]

# Dependency graph
requires:
  - phase: 13-pkgdown-deployment
    provides: "Locked decisions D-01..D-05 in 13-CONTEXT.md and canonical r-lib Pages YAML in 13-RESEARCH.md"
provides:
  - "Modern r-lib + GitHub Pages artifact deploy workflow (actions/configure-pages@v6 -> upload-pages-artifact@v5 -> deploy-pages@v5)"
  - "PR smoke-build workflow that runs pkgdown::build_site() with minimal read-only permissions"
  - "Retirement of JamesIves/github-pages-deploy-action + gh-pages branch flow"
  - "install=FALSE flip (L-05) in build_site_github_pages call"
affects: [13-02, 13-03, pkgdown-config, vignettes, verification]

# Tech tracking
tech-stack:
  added:
    - "actions/configure-pages@v6"
    - "actions/upload-pages-artifact@v5"
    - "actions/deploy-pages@v5"
  patterns:
    - "Canonical r-lib + Pages artifact deploy pattern (no gh-pages branch)"
    - "Dual-workflow split: deploy on push-to-master, smoke-build on pull_request"
    - "Cross-workflow action-version lockstep (deploy and smoke share identical r-lib pins)"
    - "Minimal-permissions smoke-build (contents:read only) to prevent deploy-capability bleed on attacker-controlled PR content"
    - "Pages-recommended concurrency (group:pages, cancel-in-progress:false) for deploy; PR-safe concurrency (cancel-in-progress:true) for smoke"

key-files:
  created:
    - .github/workflows/pkgdown-check.yaml
  modified:
    - .github/workflows/pkgdown.yaml

key-decisions:
  - "D-01 implemented: retire JamesIves + gh-pages branch, adopt r-lib + Pages artifact pattern"
  - "D-02 implemented: deploy triggers are push[main,master] + workflow_dispatch (no tag triggers)"
  - "D-03 implemented: single ubuntu-latest job with R release (no matrix)"
  - "D-04 implemented: permissions pinned to contents:read, pages:write, id-token:write (exact set required by deploy-pages OIDC)"
  - "D-05 implemented: PR smoke-build lives in a separate pkgdown-check.yaml file with contents:read only, no deploy actions"
  - "L-04 applied: concurrency group=pages, cancel-in-progress=false on deploy to protect in-flight deploys"
  - "L-05 applied: install=FALSE in build_site_github_pages (setup-r-dependencies with local::. already installed the package)"
  - "Smoke-build uses pkgdown::build_site (not build_site_github_pages) to skip CNAME/.nojekyll writing on throwaway PR builds"

patterns-established:
  - "Split deploy/check workflows: deploy permissions (pages:write, id-token:write) never coexist with PR-triggered code paths"
  - "Pinned action majors in both workflows are kept in lockstep (r-lib setup-pandoc@v2, setup-r@v2, setup-r-dependencies@v2) so a future version bump updates both together"
  - "Block-literal extra-packages form (any::pkgdown / local::.) matches R-CMD-check.yaml for consistency across all R-repo workflows"

requirements-completed: [PKG-01]

# Metrics
duration: 2min
completed: 2026-04-18
---

# Phase 13 Plan 01: pkgdown Deploy + PR Smoke-Build Workflows Summary

**Modernized pkgdown deploy to use the r-lib + GitHub Pages artifact pattern (configure-pages@v6 -> upload-pages-artifact@v5 -> deploy-pages@v5) and added a separate PR smoke-build workflow with minimum permissions.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-18T18:26:28Z
- **Completed:** 2026-04-18T18:27:54Z
- **Tasks:** 2
- **Files modified:** 2 (1 rewritten, 1 created)

## Accomplishments
- Rewrote `.github/workflows/pkgdown.yaml` with the canonical r-lib + GitHub Pages deploy pipeline (D-01..D-04); retired JamesIves action and `gh-pages` branch path; flipped L-05 `install=TRUE` to `install=FALSE`.
- Created `.github/workflows/pkgdown-check.yaml` as a PR-only smoke-build (D-05) with `contents: read` alone — no `pages:write`, no `id-token:write`, no deploy actions; uses `pkgdown::build_site()` (not `build_site_github_pages`) and cancels superseded PR runs.
- Both workflows are in lockstep on r-lib pinned action majors (`setup-pandoc@v2`, `setup-r@v2`, `setup-r-dependencies@v2`) and share `use-public-rspm: true` + `needs: website`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite pkgdown.yaml for modern GitHub Pages deploy** — `9a0d221` (feat)
2. **Task 2: Create pkgdown-check.yaml PR smoke-build** — `262bfb3` (feat)

**Plan metadata:** _to be added with SUMMARY commit (`docs(13): add plan 13-01 summary`)_

## Files Created/Modified
- `.github/workflows/pkgdown.yaml` — Rewritten in place. Push-to-master + workflow_dispatch deploy using r-lib setup + `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` + `configure-pages@v6` / `upload-pages-artifact@v5` / `deploy-pages@v5`. Permissions: `contents: read`, `pages: write`, `id-token: write`. Concurrency `group: pages`, `cancel-in-progress: false`. `environment: github-pages` with deployment URL wired via `id: deployment`. `timeout-minutes: 20`.
- `.github/workflows/pkgdown-check.yaml` — New. PR-only (`pull_request: branches: [main, master]`) smoke-build running `pkgdown::build_site(new_process = FALSE, install = FALSE)`. Permissions: `contents: read` only. Concurrency `group: pkgdown-check-${{ github.ref }}`, `cancel-in-progress: true`. No artifact upload, no deploy steps, no `workflow_dispatch`, no `push:` trigger.

## Acceptance Criteria

All grep-based acceptance criteria from the plan passed:

**Task 1 (pkgdown.yaml — 19 checks):**
- Pinned actions: `deploy-pages@v5`, `upload-pages-artifact@v5`, `configure-pages@v6` — PASS
- Permissions: `contents: read` + `pages: write` + `id-token: write` — PASS; old `contents: write` removed — PASS
- Legacy `JamesIves/github-pages-deploy-action` absent — PASS; `branch: gh-pages` absent — PASS
- `install = FALSE` present — PASS; `install = TRUE` absent — PASS
- Concurrency `group: pages` + `cancel-in-progress: false` — PASS
- Environment `name: github-pages` + step `id: deployment` — PASS
- Build call `build_site_github_pages(new_process = FALSE, install = FALSE)` — PASS
- `needs: website` + `use-public-rspm: true` + `push:` + `workflow_dispatch:` + `timeout-minutes: 20` — PASS

**Task 2 (pkgdown-check.yaml — 19 checks):**
- File exists; `name: pkgdown-check`; `pull_request:` trigger — PASS
- No `push:`, no `workflow_dispatch:` — PASS
- Permission `contents: read`; no `pages: write`, no `id-token: write` — PASS
- No `deploy-pages`, no `upload-pages-artifact`, no `configure-pages`, no `environment:` — PASS
- Concurrency `group: pkgdown-check-${{ github.ref }}` + `cancel-in-progress: true` — PASS
- Build call `pkgdown::build_site(new_process = FALSE, install = FALSE)`; no `build_site_github_pages`; no `install = TRUE` — PASS
- `use-public-rspm: true` + `needs: website` — PASS

**Plan-level overall verification:**
- Both files exist — PASS
- `grep -l "JamesIves" .github/workflows/ | wc -l` = 0 — PASS
- `grep -l "branch: gh-pages" .github/workflows/ | wc -l` = 0 — PASS
- Cross-workflow r-lib lockstep: `setup-pandoc@v2`, `setup-r@v2`, `setup-r-dependencies@v2` (exactly 3 unique lines) — PASS
- `use-public-rspm: true` present in both files — PASS
- `actionlint`: not installed in worktree environment — SKIPPED (explicitly flagged as optional in plan)

## Decisions Made
None new — the plan prescribed verbatim YAML and all decisions (D-01..D-05, L-04, L-05) were pre-locked in 13-CONTEXT.md and 13-RESEARCH.md. Implementation followed the plan's `<action>` blocks byte-for-byte.

## Deviations from Plan

None — plan executed exactly as written. The YAML contents of both files were specified verbatim in the plan's `<action>` blocks and used as-is.

## Issues Encountered

The phase directory `.planning/phases/13-pkgdown-deployment/` did not yet exist in the worktree (its creation is part of the planning artifacts living only in main). Created the directory so this SUMMARY.md could be written at its prescribed path. This is infrastructural, not a plan deviation.

## User Setup Required

**External services require manual configuration (Plan 03 scope; flagged here for traceability):**

- **D-14 (one-time manual prerequisite):** After merge, a repository admin must set GitHub Pages Source to "GitHub Actions" in repo Settings → Pages → Build and deployment → Source. Without this, the `actions/deploy-pages@v5` step will fail on the first run with "Pages site not yet created". This is documented in the plan's `<verification>` block and deferred to Plan 03's VERIFICATION.md.
- **D-15 (post-merge manual smoke):** After first successful deploy, trigger `workflow_dispatch` once and visually verify the published site at https://davidzenz.github.io/sube/ loads (home, reference index, at least one vignette). Also deferred to Plan 03's VERIFICATION.md.

No environment variables or secrets need to be added — the workflow uses only the default `GITHUB_TOKEN` (GitHub-managed OIDC) for Pages deploy.

## Next Phase Readiness
- Workflow files are ready. The `push → deploy` and `pull_request → smoke` paths will activate automatically once the branch merges to `master` (subject to the one-time D-14 toggle for the first deploy).
- Both files pass all 38+ grep acceptance criteria and the plan-level cross-workflow consistency checks.
- Plan 13-02 (pkgdown config updates, separate worktree) and Plan 13-03 (verification + D-14/D-15 user-setup docs, separate worktree) can proceed in parallel as their orchestrator intended; neither modifies `.github/workflows/*.yaml`, so no merge conflict risk with this plan's output.

## Self-Check: PASSED

- FOUND: `.github/workflows/pkgdown.yaml` (rewritten)
- FOUND: `.github/workflows/pkgdown-check.yaml` (created)
- FOUND: `.planning/phases/13-pkgdown-deployment/13-01-SUMMARY.md` (this file, verified below)
- FOUND commit: `9a0d221` — feat(13): rewrite pkgdown.yaml for modern GitHub Pages deploy
- FOUND commit: `262bfb3` — feat(13): add pkgdown-check.yaml PR smoke-build

---
*Phase: 13-pkgdown-deployment*
*Completed: 2026-04-18*

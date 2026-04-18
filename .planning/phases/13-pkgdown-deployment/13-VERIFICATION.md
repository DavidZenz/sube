# Phase 13 — Verification

**Phase:** 13-pkgdown-deployment
**Requirements:** PKG-01 (GitHub Actions deploy), PKG-02 (_pkgdown.yml alignment)
**Verified:** <filled in by /gsd-verify-work after manual steps complete>

> Phase 13 delivers a new GitHub Pages deploy path plus a realigned pkgdown site taxonomy. Most verification is automated (grep assertions + `pkgdown::check_pkgdown()` — see §Automated Checks) but two steps are intrinsically manual: D-14 (enabling Pages Source in repo Settings; `GITHUB_TOKEN` lacks the admin scope to flip it via API) and D-15 (validating the live deploy post-merge; the production `github-pages` environment is singular per repo and cannot be exercised on a PR).

---

## D-14 — Manual Prerequisite (ONE-TIME, BEFORE FIRST PUSH-TRIGGERED DEPLOY)

**Locked decision (from 13-CONTEXT.md):** User manually enables GitHub Pages Source → "GitHub Actions" in repo settings before first deploy.

**Why this is manual:** `actions/configure-pages@v6` supports `enablement: true` to flip the Pages Source via API, but that call requires a PAT with `repo` scope or a GitHub App with `administration:write` — the default `GITHUB_TOKEN` scope is insufficient. A one-time manual flip is the pragmatic trade-off.

### Steps for the user

1. Open https://github.com/davidzenz/sube/settings/pages (or navigate: repo root → **Settings** → **Pages** in the left sidebar).
2. Under **Build and deployment**, find the **Source** dropdown.
3. Select **GitHub Actions** (not "Deploy from a branch").
4. No "Save" button is needed — the change is applied immediately.

### What happens if this step is skipped

The first run of `.github/workflows/pkgdown.yaml` will fail at the `actions/configure-pages@v6` step with an error along the lines of "Get Pages site failed. Please verify that the repository has Pages enabled and configured to build using GitHub Actions." No partial deploy occurs; no artifact lingers. Fix by completing the steps above, then re-run the workflow (`workflow_dispatch` or push).

### Confirmation

- [ ] User has performed the Settings → Pages → Source = "GitHub Actions" flip
- [ ] Confirmed visually: the Pages settings page shows "Your site is ready to be published" (or equivalent) before first deploy

---

## D-15 — Post-Merge Live-Site Verification

**Locked decision (from 13-CONTEXT.md):** After merging Phase 13, manually trigger the workflow via `workflow_dispatch`, then verify `https://davidzenz.github.io/sube/` loads with the correct article ordering and reference groups.

**Why this is manual:** The PR smoke-build (Plan 01's `pkgdown-check.yaml`) validates the site **builds** but cannot validate it **deploys** — OIDC token exchange requires `id-token: write` on a push/workflow_dispatch path, and the production `github-pages` environment in GitHub is singular per repo. Post-merge is the only path.

### Steps for the user (after the Phase 13 PR is merged to master)

1. The push to master will fire `.github/workflows/pkgdown.yaml` automatically. Wait 2–3 minutes.
2. (Optional, if a fresh run is desired) Trigger via CLI or UI:
   - CLI: `gh workflow run pkgdown.yaml --ref master`
   - UI: Actions tab → `pkgdown` workflow → "Run workflow" button (master branch)
3. Watch the run: `gh run watch` (or observe in the Actions UI). Expected: all steps green; the `deploy` step surfaces a `page_url` output in the job summary.
4. Fetch the root page:
   ```bash
   curl -fsS https://davidzenz.github.io/sube/ | head -40
   ```
   Expected: HTML containing `<title>sube` (the home block title).
5. Visual check — open https://davidzenz.github.io/sube/articles/ in a browser:
   - [ ] Three sections visible, in order: **Getting started**, **Workflow**, **Data sources in practice**
   - [ ] Within **Getting started**: `getting-started` appears before `package-design`
   - [ ] Within **Workflow**: `data-preparation` → `modeling-and-outputs` → `pipeline-helpers` in that order
   - [ ] Within **Data sources in practice**: `paper-replication` → `figaro-workflow` in that order
   - [ ] The top-nav "Get started" link (or dropdown) resolves to the `getting-started` article
6. Visual check — open https://davidzenz.github.io/sube/reference/ in a browser:
   - [ ] Six sections visible: **Data import**, **Matrix building**, **Compute & models**, **Pipeline helpers**, **Paper replication**, **Output & export**
   - [ ] Each section shows its one-sentence `desc:` below the title
   - [ ] Functions within each section are in pipeline order:
     - Data import: `import_suts` → `read_figaro` → `sube_example_data`
     - Matrix building: `extract_domestic_block` → `build_matrices` → `extract_leontief_matrices`
     - Compute & models: `compute_sube` → `estimate_elasticities`
     - Pipeline helpers: `run_sube_pipeline` → `batch_sube`
     - Paper replication: `filter_paper_outliers` → `prepare_sube_comparison` → `plot_paper_comparison` → `plot_paper_regression` → `plot_paper_interval_ranges`
     - Output & export: `filter_sube` → `plot_sube` → `write_sube`
7. Visual check — navbar:
   - [ ] Left: reference, articles, paper, news
   - [ ] Right: search icon, GitHub icon
   - [ ] "Paper" link resolves to `https://link.springer.com/article/10.1186/s40008-024-00331-4`
   - [ ] "News" link resolves to a changelog/news page (may be empty if no NEWS.md yet — that's fine; the target of the navbar link just needs to not 404)

### Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Workflow fails at `configure-pages@v6` with "Get Pages site failed" | D-14 not done | Complete D-14 steps, re-run workflow |
| `curl https://davidzenz.github.io/sube/` returns 404 after workflow green | DNS/CDN propagation (rare, minutes) or stale `gh-pages` branch still configured as source | Re-check Settings → Pages; if a `gh-pages` branch somehow exists with Source pointing to it, delete the branch and reconfirm Source = "GitHub Actions" |
| Article order wrong on live site but `pkgdown::check_pkgdown()` passed locally | Cached build output in a fork or a stale deploy | Trigger a fresh run via `gh workflow run pkgdown.yaml --ref master`; check commit SHA in Actions matches the merged PR |
| Reference section missing a function | Executor regression between Plans 02 and merge | Check `_pkgdown.yml` diff against this PLAN's task-2 spec; rerun `pkgdown::check_pkgdown()` locally |

---

## Automated Checks (already performed by Plans 01 and 02 — recap, no rerun needed)

### From Plan 01 (`.github/workflows/pkgdown.yaml` + `.github/workflows/pkgdown-check.yaml`)

- `actions/deploy-pages@v5`, `actions/upload-pages-artifact@v5`, `actions/configure-pages@v6` all pinned and present in the deploy workflow
- Permissions in deploy workflow: exactly `contents: read`, `pages: write`, `id-token: write` (D-04)
- Legacy `JamesIves/github-pages-deploy-action` and `branch: gh-pages` fully removed (D-01)
- `install = FALSE` flipped from `install = TRUE` (L-05)
- Concurrency: `group: pages`, `cancel-in-progress: false` (L-04)
- Environment: `github-pages` with `page_url` output wired
- `pkgdown-check.yaml` runs on `pull_request` only with `contents: read` and no deploy steps

### From Plan 02 (`_pkgdown.yml` + conditional DESCRIPTION patch)

- `Rscript -e 'pkgdown::check_pkgdown()'` exits 0 — URL consistency, export coverage, vignette coverage
- 6 reference groups with one-sentence `desc:` each (D-10, D-11)
- 3 article groups in D-07 order, `navbar: Get started` on Getting started only (D-08)
- All 18 NAMESPACE exports indexed, all 7 vignettes indexed, no duplicates, no internals (D-13)
- `url:`, `template:`, `home:`, `navbar:` blocks byte-identical to pre-rewrite state (D-09)
- DESCRIPTION URL: unchanged (Case A/C) OR extended to comma-separated two-URL form (Case B, if L-06 fired) — recorded in `13-02-WAVE0.log`

---

## Requirement Closure

| Requirement | Closure Evidence |
|-------------|------------------|
| PKG-01 — GitHub Actions workflow deploys pkgdown site to GitHub Pages on push to master | Plan 01 automated checks (grep assertions on workflow contents) + D-14 manual prerequisite + D-15 post-merge live-site verification |
| PKG-02 — `_pkgdown.yml` reviewed and updated — article grouping, navbar, reference sections reflect the documentation narrative | Plan 02 `pkgdown::check_pkgdown()` exit 0 + Plan 02 grep/count acceptance criteria + D-15 post-merge visual inspection of article/reference taxonomy |

---

*Verification document created during Plan 03; populated with user sign-off during `/gsd-verify-work` after D-14 and D-15 manual steps complete.*

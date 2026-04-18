# Phase 13: pkgdown Deployment - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deploy a live pkgdown site to GitHub Pages on every push to master via GitHub Actions, and realign `_pkgdown.yml` article grouping, ordering, and reference sections to the documentation narrative established in Phases 11–12. No new R code or exported functions — workflow YAML and `_pkgdown.yml` only.

</domain>

<decisions>
## Implementation Decisions

### Deploy Workflow
- **D-01:** Replace `.github/workflows/pkgdown.yaml` in place with the modern r-lib pattern: `actions/checkout` + `r-lib/actions/setup-pandoc` + `r-lib/actions/setup-r` + `r-lib/actions/setup-r-dependencies` (needs: website) + `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` + `actions/configure-pages` + `actions/upload-pages-artifact` + `actions/deploy-pages`. Retire the `JamesIves/github-pages-deploy-action` flow; no `gh-pages` branch.
- **D-02:** Triggers: `on: push: branches: [main, master]` and `workflow_dispatch`. No tag triggers.
- **D-03:** Runner matrix: single job on `ubuntu-latest` with R release. R-CMD-check already covers the multi-OS surface.
- **D-04:** Permissions: `contents: read`, `pages: write`, `id-token: write` (minimal set required by `actions/deploy-pages`).
- **D-05:** Add a second workflow (or job) triggered on `pull_request` that runs `pkgdown::build_site()` as a smoke check — no artifact upload, no deploy. Catches broken vignettes/reference entries before merge.

### Article Ordering & Grouping (_pkgdown.yml)
- **D-06:** Article order realigned to Phase 12 D-04 canonical reading order: `getting-started` → `package-design` → `data-preparation` → `modeling-and-outputs` → `paper-replication` → `figaro-workflow` → `pipeline-helpers`.
- **D-07:** Consolidate the 7 single-article groups into 3 narrative groups:
  - **Getting started:** `getting-started`, `package-design`
  - **Workflow:** `data-preparation`, `modeling-and-outputs`, `pipeline-helpers`
  - **Data sources in practice:** `paper-replication`, `figaro-workflow`
- **D-08:** Keep `getting-started.Rmd` as the explicit `navbar: Get started` landing (existing behavior).
- **D-09:** Keep current navbar: left = `[reference, articles, paper, news]`, right = `[search, github]`. No additional entries.

### Reference Section Taxonomy
- **D-10:** Split the current 4 reference groups into 6:
  - **Data import:** `import_suts`, `read_figaro`, `sube_example_data`
  - **Matrix building:** `extract_domestic_block`, `build_matrices`, `extract_leontief_matrices`
  - **Compute & models:** `compute_sube`, `estimate_elasticities`
  - **Pipeline helpers:** `run_sube_pipeline`, `batch_sube`
  - **Paper replication:** `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges`
  - **Output & export:** `filter_sube`, `plot_sube`, `write_sube`
- **D-11:** Each reference group gets a one-sentence `desc:` field explaining what the group covers.
- **D-12:** Order functions within each group by pipeline flow (the order a user would call them), not alphabetically.
- **D-13:** Expose exported symbols only (the 18 in `NAMESPACE`). No internals.

### First-Deploy Verification
- **D-14:** User manually enables GitHub Pages Source → "GitHub Actions" in repo settings before first deploy. Document this prerequisite in Phase 13 VERIFICATION.md.
- **D-15:** After merging Phase 13, manually trigger the workflow via `workflow_dispatch`, then verify `https://davidzenz.github.io/sube/` loads with the correct article ordering and reference groups.

### Claude's Discretion
- Exact YAML formatting, step names, and comments in the workflow file
- Exact one-sentence `desc:` text for each reference group (aligned with function purpose)
- Whether to pin a specific `pkgdown` version or let `any::pkgdown` resolve to current release (default: unpinned, matches current workflow)
- Caching strategy for R packages (inherit r-lib/actions defaults unless a concrete need arises)
- Whether the PR smoke-build is a separate workflow file or a conditional job inside `pkgdown.yaml`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Target files (will be edited)
- `.github/workflows/pkgdown.yaml` — Replace in place with modern r-lib + GitHub Pages artifact deploy pattern
- `_pkgdown.yml` — Realign article order, consolidate article groups, split reference groups, add group descriptions

### Prior phase decisions that constrain this phase
- `.planning/phases/12-vignette-readme-refresh/12-CONTEXT.md` §Decisions D-04 — Canonical article reading order (7 vignettes)
- `.planning/phases/12-vignette-readme-refresh/12-CONTEXT.md` §Decisions D-06 — pipeline-helpers stays last
- `.planning/phases/12-vignette-readme-refresh/12-CONTEXT.md` §Decisions D-07 — Article grouping is Phase 13's responsibility

### Requirement source
- `.planning/REQUIREMENTS.md` §pkgdown & Deployment — PKG-01 (GHA deploy) and PKG-02 (_pkgdown.yml alignment)
- `.planning/ROADMAP.md` §Phase 13 — success criteria (push-deploy without manual steps; article grouping reflects narrative; reference/navbar consistent with exports and vignette titles)

### Reference — upstream docs and patterns
- r-lib/actions canonical pkgdown workflow (GitHub Pages artifact flavor): https://github.com/r-lib/actions/tree/v2/examples — "pkgdown-pages.yaml" style
- pkgdown site config reference: https://pkgdown.r-lib.org/reference/build_site.html and https://pkgdown.r-lib.org/articles/customise.html
- GitHub Pages deployment via Actions: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow

### Source of truth for exports and vignettes
- `NAMESPACE` — 18 exported functions (verify reference group membership)
- `DESCRIPTION` — package metadata, URL (should match `_pkgdown.yml: url`)
- `vignettes/*.Rmd` — 7 vignettes; titles/filenames are authoritative for article entries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/pkgdown.yaml` — existing workflow provides the scaffolding (checkout, pandoc, R setup, r-lib/actions/setup-r-dependencies); replace only the deploy steps plus permissions
- `.github/workflows/R-CMD-check.yaml` — reference pattern for concurrency group, action versions, and setup-r-dependencies usage
- `_pkgdown.yml` — already has `url:`, `template: bootstrap: 5`, `home:`, working reference and article scaffolding; edit in place
- 7 vignettes already exist and their titles/filenames are stable after Phase 12

### Established Patterns
- `docs/` is in both `.gitignore` and `.Rbuildignore` — site is built fresh on every deploy, never committed
- `gh-pages` branch does NOT exist on remote (deploy has never run) — switching to GitHub Pages artifact avoids creating it
- r-lib/actions use-public-rspm: true pattern is already in place for fast dependency install
- Workflow permissions currently `contents: write` (for JamesIves push) — needs to change with D-01
- `pkgdown::build_site_github_pages()` is already the build call; keep it for its GitHub-specific site hygiene (CNAME, .nojekyll)

### Integration Points
- GitHub Actions → Pages: user must enable Pages Source = "GitHub Actions" in repo settings (one-time manual step)
- `DESCRIPTION` `URL:` field should match `_pkgdown.yml url:` (both currently point to `https://davidzenz.github.io/sube/`)
- R-CMD-check workflow is independent; no changes needed there
- No changes to `.Rbuildignore` needed — `^\.github$` and `^docs$` already excluded

</code_context>

<specifics>
## Specific Ideas

- The modern r-lib pattern is what `usethis::use_pkgdown_github_pages()` generates today — follow that template, not a hand-rolled variant
- Keep `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` as the build call; the existing site workflow already uses this and it sets up CNAME/.nojekyll correctly for Pages
- PR smoke-build should be fast — skip artifact upload, skip deploy, just confirm the site builds

</specifics>

<deferred>
## Deferred Ideas

- pkgdown custom templates, logos, or theming beyond `bootstrap: 5` — out of scope for v1.3; reconsider if/when branding work lands
- docsearch / Algolia integration — not worth the setup for this audience; revisit if traffic warrants it
- Analytics (Google Analytics / Plausible) on the pkgdown site — deferred; no current need
- Versioned documentation (dev vs release) — deferred until multiple release lines exist

</deferred>

---

*Phase: 13-pkgdown-deployment*
*Context gathered: 2026-04-18*

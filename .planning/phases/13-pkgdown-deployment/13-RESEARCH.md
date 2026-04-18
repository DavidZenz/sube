# Phase 13: pkgdown-deployment - Research

**Researched:** 2026-04-18
**Domain:** GitHub Actions deployment of pkgdown → GitHub Pages; `_pkgdown.yml` article/reference taxonomy
**Confidence:** HIGH (workflow pattern, action versions, pkgdown YAML schema); MEDIUM (edge-case failure modes of deploy-pages on misconfigured Source)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Deploy Workflow**
- **D-01:** Replace `.github/workflows/pkgdown.yaml` in place with the modern r-lib pattern: `actions/checkout` + `r-lib/actions/setup-pandoc` + `r-lib/actions/setup-r` + `r-lib/actions/setup-r-dependencies` (needs: website) + `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` + `actions/configure-pages` + `actions/upload-pages-artifact` + `actions/deploy-pages`. Retire the `JamesIves/github-pages-deploy-action` flow; no `gh-pages` branch.
- **D-02:** Triggers: `on: push: branches: [main, master]` and `workflow_dispatch`. No tag triggers.
- **D-03:** Runner matrix: single job on `ubuntu-latest` with R release. R-CMD-check already covers the multi-OS surface.
- **D-04:** Permissions: `contents: read`, `pages: write`, `id-token: write` (minimal set required by `actions/deploy-pages`).
- **D-05:** Add a second workflow (or job) triggered on `pull_request` that runs `pkgdown::build_site()` as a smoke check — no artifact upload, no deploy. Catches broken vignettes/reference entries before merge.

**Article Ordering & Grouping (_pkgdown.yml)**
- **D-06:** Article order realigned to Phase 12 D-04 canonical reading order: `getting-started` → `package-design` → `data-preparation` → `modeling-and-outputs` → `paper-replication` → `figaro-workflow` → `pipeline-helpers`.
- **D-07:** Consolidate the 7 single-article groups into 3 narrative groups:
  - **Getting started:** `getting-started`, `package-design`
  - **Workflow:** `data-preparation`, `modeling-and-outputs`, `pipeline-helpers`
  - **Data sources in practice:** `paper-replication`, `figaro-workflow`
- **D-08:** Keep `getting-started.Rmd` as the explicit `navbar: Get started` landing (existing behavior).
- **D-09:** Keep current navbar: left = `[reference, articles, paper, news]`, right = `[search, github]`. No additional entries.

**Reference Section Taxonomy**
- **D-10:** Split the current 4 reference groups into 6:
  - **Data import:** `import_suts`, `read_figaro`, `sube_example_data`
  - **Matrix building:** `extract_domestic_block`, `build_matrices`, `extract_leontief_matrices`
  - **Compute & models:** `compute_sube`, `estimate_elasticities`
  - **Pipeline helpers:** `run_sube_pipeline`, `batch_sube`
  - **Paper replication:** `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges`
  - **Output & export:** `filter_sube`, `plot_sube`, `write_sube`
- **D-11:** Each reference group gets a one-sentence `desc:` field.
- **D-12:** Order functions within each group by pipeline flow, not alphabetically.
- **D-13:** Expose exported symbols only (the 18 in `NAMESPACE`). No internals.

**First-Deploy Verification**
- **D-14:** User manually enables GitHub Pages Source → "GitHub Actions" in repo settings before first deploy. Document this prerequisite in VERIFICATION.
- **D-15:** After merging Phase 13, manually trigger the workflow via `workflow_dispatch`, then verify `https://davidzenz.github.io/sube/` loads with the correct article ordering and reference groups.

### Claude's Discretion
- Exact YAML formatting, step names, and comments in the workflow file
- Exact one-sentence `desc:` text for each reference group
- Whether to pin a specific `pkgdown` version or let `any::pkgdown` resolve to current release (default: unpinned)
- Caching strategy for R packages (inherit r-lib/actions defaults)
- Whether the PR smoke-build is a separate workflow file or a conditional job inside `pkgdown.yaml`

### Deferred Ideas (OUT OF SCOPE)
- pkgdown custom templates, logos, or theming beyond `bootstrap: 5`
- docsearch / Algolia integration
- Analytics (Google Analytics / Plausible)
- Versioned documentation (dev vs release)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | GitHub Actions workflow deploys pkgdown site to GitHub Pages on push to master | §Canonical r-lib pkgdown-pages.yaml + §Repo-Specific Adaptations + §GitHub Pages Prerequisites |
| PKG-02 | `_pkgdown.yml` reviewed and updated — article grouping, navbar, reference sections reflect the documentation narrative | §_pkgdown.yml Schema Notes + §Reference Group Function Order + §Reference Group Descriptions |
</phase_requirements>

## Summary

- **Action versions are the only non-obvious research output for the workflow.** Everything else is settled by D-01..D-05. Current latest (as of 2026-04): `actions/checkout@v4`, `r-lib/actions/*@v2` (sliding tag, includes 2.11.x), `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`. GitHub's own starter-workflow lags slightly (v5/v3/v5); we recommend the current latest. `[VERIFIED: github.com/actions/*/releases]`
- **r-lib's canonical `pkgdown.yaml` still uses `JamesIves/github-pages-deploy-action` + `gh-pages` branch** — D-01 diverges intentionally. The "modern" pattern is a blend: r-lib setup actions + GitHub's official Pages artifact flow (as seen in GitHub's `actions/starter-workflows` pages/static.yml). `[VERIFIED: raw.githubusercontent.com/r-lib/actions/v2/examples/pkgdown.yaml; actions/starter-workflows pages/static.yml]`
- **PR smoke-build (D-05): recommend a separate workflow file `pkgdown-check.yaml`.** Clearer status-check name in the PR UI, cleaner permissions (no `pages:`/`id-token:` on the PR path), trivially disabled. Condition-gating inside one file works but tangles the permissions model.
- **`pkgdown::check_pkgdown()` and `pkgdown_sitrep()` both exist in pkgdown 2.2.0 and validate `_pkgdown.yml` — use them as the static check for PKG-02.** `check_pkgdown()` errors at the first problem; `pkgdown_sitrep()` reports all. Locally verified on the researcher's machine. `[VERIFIED: local R session, pkgdown 2.2.0]`
- **D-14 (manual Pages Source switch) is still the pragmatic path.** A REST API endpoint exists (`PUT /repos/{owner}/{repo}/pages` with `build_type: "workflow"`), and `configure-pages@v6` has an `enablement: true` input that can flip the setting — but both require an elevated token (admin / PAT with `repo` or a GitHub App with `administration:write`). `GITHUB_TOKEN` at default scopes does not suffice. Document D-14 as a one-time manual step. `[VERIFIED: docs.github.com/rest/pages; actions/configure-pages action.yml]`

**Primary recommendation:** Write the workflow body largely as a superset of GitHub's starter-workflow pages/static.yml with r-lib setup actions grafted in before the upload step; mirror R-CMD-check.yaml's `use-public-rspm: true` + `concurrency` naming; keep `build_site_github_pages(new_process = FALSE, install = FALSE)` (existing call) but remove `install = TRUE` typo in current file.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Site build (R + pkgdown) | CI runner (build job) | — | R-world orchestration belongs on a GitHub-hosted Ubuntu runner with r-lib actions |
| Artifact staging | GitHub Actions artifact system | — | Bridge between build and deploy; tar.gz uploaded by `upload-pages-artifact` |
| Deployment | GitHub Pages (via OIDC) | `actions/deploy-pages` | Pages service consumes the artifact after OIDC handshake |
| Site metadata / taxonomy | `_pkgdown.yml` (source-tier config) | Vignette frontmatter | pkgdown YAML owns grouping + ordering; vignette YAML owns titles |
| Static validation | R runtime (`check_pkgdown`) + `actionlint` | — | Config validity (pkgdown) and workflow syntax (actionlint) are pre-merge gates |

## Canonical r-lib pkgdown-pages.yaml

### Pinned action versions (as of 2026-04)

| Action | Version | Verified | Notes |
|--------|---------|----------|-------|
| `actions/checkout` | `v4` | `[VERIFIED: github.com/actions/checkout]` | Matches current `pkgdown.yaml` and `R-CMD-check.yaml` |
| `r-lib/actions/setup-pandoc` | `v2` | `[VERIFIED: r-lib/actions releases]` | `v2` is a sliding tag; latest 2.11.4 (2025-10-08) |
| `r-lib/actions/setup-r` | `v2` | `[VERIFIED: r-lib/actions releases]` | Same sliding tag |
| `r-lib/actions/setup-r-dependencies` | `v2` | `[VERIFIED: r-lib/actions releases]` | Reads `Config/Needs/website: pkgdown` via `needs: website` |
| `actions/configure-pages` | `v6` | `[VERIFIED: github.com/actions/configure-pages/releases]` | v6 (2025-03-25); GitHub's starter-workflow still shows v5 |
| `actions/upload-pages-artifact` | `v5` | `[VERIFIED: github.com/actions/upload-pages-artifact/releases]` | v5 (2025-04-10); starter-workflow still shows v3 |
| `actions/deploy-pages` | `v5` | `[VERIFIED: github.com/actions/deploy-pages/releases]` | v5 (2025-03-25); Node 24. v4 (v4.0.5) also current if desired |

> **Discretion call for planner:** The gap between "current latest" (configure-pages v6, upload v5, deploy v5) and GitHub's own starter-workflow (v5/v3/v5) means either choice is defensible. Recommendation: adopt the latest because they are all post-v4 artifact-actions (v3 artifact actions hit full EOL Jan 2025). `[VERIFIED: github.blog/changelog 2024-12-05]`

### Shape decision: single job vs two jobs

**GitHub's official starter-workflow `pages/static.yml` uses one `deploy` job** (checkout → configure-pages → upload → deploy). The r-lib canonical `pkgdown.yaml` also uses one job (but with JamesIves). For Phase 13:

- **Recommend: single job** on `ubuntu-latest` with `environment: github-pages`. Simpler, matches D-03's "single job" wording, matches R-CMD-check.yaml's single-job layout.
- **Two-job variant** (separate `build` + `deploy`) is standard in GitHub's Jekyll/bundler templates where build is resource-heavy and deploy is trivial. For pkgdown it adds no value and doubles dependency-install time unless caching survives across jobs.

### Annotated YAML skeleton (planner adapts; do not copy verbatim until planner approves step names/comments)

```yaml
name: pkgdown

on:
  push:
    branches: [main, master]
  workflow_dispatch:

# Required by actions/deploy-pages (D-04)
permissions:
  contents: read
  pages: write
  id-token: write

# GitHub's recommendation for Pages: serialize, do not cancel a live deploy
# (see landmine §L-04 for the alternative "cancel-in-progress: true" tradeoff)
concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::pkgdown, local::.
          needs: website

      - name: Build site
        run: pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
        shell: Rscript {0}

      - uses: actions/configure-pages@v6

      - uses: actions/upload-pages-artifact@v5
        with:
          path: docs

      - id: deployment
        uses: actions/deploy-pages@v5
```

Notes on the skeleton:
- `shell: Rscript {0}` is the r-lib idiom and matches the current workflow. Safer than `run: Rscript -e '...'` because pkgdown error messages propagate cleanly.
- `install = FALSE` in `build_site_github_pages()` relies on `local::.` having been installed by `setup-r-dependencies@v2`; this is the r-lib pattern. **Current workflow has `install = TRUE` which is a small defect** — the local install is redundant and slows the build.
- `path: docs` matches `pkgdown`'s default output directory (already in `.gitignore` and `.Rbuildignore`).
- `environment: github-pages` surfaces the deploy URL in the Actions UI and is required for the production-Pages environment's branch-protection rules to apply.

## Repo-Specific Adaptations

What to preserve from current files:

- **`use-public-rspm: true`** on `setup-r@v2` — already in both workflows; keeps binary-package install fast. `[VERIFIED: .github/workflows/pkgdown.yaml:21, R-CMD-check.yaml:38]`
- **`extra-packages: any::pkgdown, local::.`** — current form with `|` block literal also works; inline comma form matches r-lib canonical and is shorter.
- **`needs: website`** — `Config/Needs/website: pkgdown` is already present in `DESCRIPTION` line 36, so this is wired up correctly. `[VERIFIED: DESCRIPTION:36]`
- **Concurrency group naming** — `R-CMD-check.yaml` uses `r-cmd-check-${{ github.workflow }}-${{ github.ref }}` (line 11). For pkgdown, the GitHub-Pages-recommended group name is simply `pages` (not the workflow name), because only one Pages environment exists per repo. Do **not** clone the R-CMD-check naming convention here.
- **Env vars** — no `_R_CHECK_SYSTEM_CLOCK_` or similar in either file. Nothing to port.
- **`timeout-minutes`** — R-CMD-check sets `30`; pkgdown has none currently. Reasonable default: `timeout-minutes: 20`. Discretionary.
- **What to drop:** `permissions: contents: write` (current pkgdown.yaml line 9), the `Deploy` step using `JamesIves/github-pages-deploy-action@v4`, and the `branch: gh-pages` pointer (no gh-pages branch exists on remote — confirmed in CONTEXT.md §code_context).

## PR Smoke-Build Recommendation

**Recommendation: option (A) — separate workflow file `.github/workflows/pkgdown-check.yaml`.**

### Comparison

| Criterion | (A) Separate file | (B) Conditional job in pkgdown.yaml |
|-----------|------------------|-------------------------------------|
| PR status-check name clarity | ✅ "pkgdown / check" vs. "pkgdown / deploy" | ⚠️ Same workflow name; step visibility only |
| Permission hygiene | ✅ `contents: read` only — no `pages:`/`id-token:` on PR path | ⚠️ Must `permissions:` per-job or scope conditionals carefully |
| Ease of disabling (e.g., draft PR churn) | ✅ Delete/disable one file | ⚠️ Edit conditional block |
| Avoids deploy-step bleed into PR runs | ✅ Impossible — different workflow | ⚠️ Depends on `if: github.event_name != 'pull_request'` on every deploy step |
| Concurrency collisions | ✅ Separate group per file | ⚠️ Same `pages` group may cancel/queue confusingly |
| Maintenance | ⚠️ Two files to touch if r-lib action versions change | ✅ One file |

### Recommended shape for `pkgdown-check.yaml`

```yaml
name: pkgdown-check

on:
  pull_request:
    branches: [main, master]

permissions:
  contents: read

concurrency:
  group: pkgdown-check-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-pandoc@v2
      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true
      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::pkgdown, local::.
          needs: website
      - name: Smoke-build site
        run: pkgdown::build_site(new_process = FALSE, install = FALSE)
        shell: Rscript {0}
```

Notes:
- Uses `build_site()` not `build_site_github_pages()` — D-05 language says "smoke check"; no need for CNAME/.nojekyll writing in a throwaway PR build.
- No artifact upload, no deploy steps → no `pages:`/`id-token:` permissions needed → no chance of accidental deploy.
- `cancel-in-progress: true` is safe here (unlike the deploy workflow) because a superseded PR build is worthless.

## _pkgdown.yml Schema Notes

### Articles section

- Keys per entry: `title` (required), `desc` (optional markdown, rendered beneath section heading on `/articles/`), `navbar` (optional — label for navbar dropdown; `~` means "show heading only"), `contents` (required, list of article basenames). `[CITED: pkgdown.r-lib.org/reference/build_articles.html]`
- A vignette whose filename matches the package name (`vignettes/sube.Rmd`) would auto-become "Get started" — we don't have one and don't want one. D-08's explicit `navbar: Get started` on `getting-started.Rmd` is the correct path. `[CITED: pkgdown.r-lib.org/reference/build_articles.html]`
- `desc:` at the articles-group level **is** rendered on the articles index page. If D-11's description scope is extended to articles, each of the 3 groups can carry a one-sentence `desc:` — discretionary; CONTEXT.md only mandates desc for reference groups.

### Reference section

- Keys: `title`, `desc` (rendered as h2 subtitle on `/reference/`), `subtitle` (+ desc → h3), `contents`. `[CITED: pkgdown.r-lib.org/reference/build_reference.html]`
- `contents` accepts: bare names, `starts_with("x")`, `ends_with("x")`, `matches("regexp")`, `has_keyword()`, `has_concept()`, `has_lifecycle()`, cross-package refs (`pkg::fn`), and exclusions prefixed with `-`. Pattern functions auto-exclude internal topics unless `internal = TRUE`. `[CITED: pkgdown.r-lib.org/reference/build_reference.html]`
- **Duplicate-topic behavior:** pkgdown's documentation is silent on explicit duplicate-group handling; community reports indicate pkgdown de-duplicates silently and `check_pkgdown()` errors only when topics are **missing** from the index, not when they appear twice. For our phase this is moot — D-10 assigns every topic to exactly one group (verified below, §Reference Group Function Order). `[VERIFIED: pkgdown source docs; UNVERIFIED in changelog — LOW confidence on duplicate-warning semantics]`
- **Missing-topic error is enforced:** `check_pkgdown()` errors if any non-internal exported symbol is absent from the reference index. This is the gate that catches D-13 violations (new export added without `_pkgdown.yml` update).

### `build_site_github_pages()` specifics

- Writes `.nojekyll` and `CNAME` (when `url:` is set) into `docs/`. `[CITED: pkgdown.r-lib.org/reference/build_site_github_pages.html]`
- `new_process = FALSE` — run build in current process. CI runners are fresh per-job so the reproducibility benefit of `new_process = TRUE` is already achieved by the ephemeral runner. Keeping `FALSE` is the canonical r-lib choice for CI.
- `install = FALSE` — skip installing the package to a temp library. Safe because `setup-r-dependencies@v2` with `local::.` has already installed it. Flipping this to `TRUE` (as the current workflow has) doubles install time.
- Respects `url:` in `_pkgdown.yml` (currently `https://davidzenz.github.io/sube/`) for canonical links and sitemap generation. `[CITED: pkgdown.r-lib.org/reference/build_site.html]`

## Reference Group Function Order (D-12)

Ordered by pipeline flow — the sequence a user would call them. Cross-checked against all 18 exports in `NAMESPACE`: every export is placed exactly once (verified count below). `[VERIFIED: NAMESPACE grep ^export returns 18]`

| # | Group | Ordered Functions | Pipeline Rationale |
|---|-------|-------------------|--------------------|
| 1 | **Data import** | `import_suts` → `read_figaro` → `sube_example_data` | Workbook import comes first; FIGARO CSV import parallel alternative; shipped example data is a fallback/demo route |
| 2 | **Matrix building** | `extract_domestic_block` → `build_matrices` → `extract_leontief_matrices` | Cut the domestic block out of imported SUTs, build S/U/tax/margin matrices, then derive Leontief structure |
| 3 | **Compute & models** | `compute_sube` → `estimate_elasticities` | Compute SUBE multipliers first; elasticity regressions operate on computed results |
| 4 | **Pipeline helpers** | `run_sube_pipeline` → `batch_sube` | Single-run wrapper first; batch/multi-year wrapper after |
| 5 | **Paper replication** | `filter_paper_outliers` → `prepare_sube_comparison` → `plot_paper_comparison` → `plot_paper_regression` → `plot_paper_interval_ranges` | Filter outliers → shape comparison tibble → three plot styles (comparison overview → regression diagnostic → interval ranges) |
| 6 | **Output & export** | `filter_sube` → `plot_sube` → `write_sube` | Filter results → inspect visually → write to disk |

### Coverage verification

| # | Group | Count | Functions (NAMESPACE names) |
|---|-------|-------|------------------------------|
| 1 | Data import | 3 | `import_suts`, `read_figaro`, `sube_example_data` |
| 2 | Matrix building | 3 | `extract_domestic_block`, `build_matrices`, `extract_leontief_matrices` |
| 3 | Compute & models | 2 | `compute_sube`, `estimate_elasticities` |
| 4 | Pipeline helpers | 2 | `run_sube_pipeline`, `batch_sube` |
| 5 | Paper replication | 5 | `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges` |
| 6 | Output & export | 3 | `filter_sube`, `plot_sube`, `write_sube` |
| — | **Total** | **18** | Matches NAMESPACE export count ✅ |

No export is duplicated, no export is missing, no internal symbol leaks in.

## Reference Group Descriptions (D-11)

Six candidate one-sentence descriptions, each ≤ 15 words, aligned with function purpose and the Phase 12 vignette narrative:

| Group | `desc:` candidate |
|-------|-------------------|
| Data import | Ingest supply-use tables from WIOD workbooks, FIGARO CSVs, or shipped example datasets. |
| Matrix building | Extract the domestic block and assemble the supply, use, and Leontief matrices. |
| Compute & models | Compute SUBE multipliers and estimate panel or cross-sectional elasticity regressions. |
| Pipeline helpers | One-call wrappers from raw input paths to SUBE results, for single runs or batches. |
| Paper replication | Filter outliers, prepare comparison tibbles, and plot the paper's three diagnostic views. |
| Output & export | Filter, visualize, and write SUBE results to CSV, Excel, Stata, or PDF. |

Each sentence is under 15 words, uses source-agnostic language where applicable (per Phase 12 VIG-01), and names the verbs a user would recognize from the vignette narrative. The planner is free to adapt wording.

## GitHub Pages Prerequisites & Deploy Mechanics

### Manual prerequisite (D-14)

Before the first push-triggered deploy, a repo admin must:

1. Navigate to **Settings → Pages**.
2. Under **Build and deployment → Source**, select **GitHub Actions** (not "Deploy from a branch").

This is a one-time setting. After it's flipped:
- Subsequent runs of the `pkgdown` workflow deploy automatically.
- The `gh-pages` branch (if any) is ignored (we don't have one — confirmed in CONTEXT.md).

**Automation alternatives (NOT recommended for this phase):**
- `actions/configure-pages@v6` supports `enablement: true` which attempts to enable Pages via API. Requires an elevated token (PAT with `repo` scope, or GitHub App with `administration:write`) — `GITHUB_TOKEN` at default scopes does **not** suffice. `[VERIFIED: actions/configure-pages action.yml]`
- `PUT /repos/{owner}/{repo}/pages` with `{"build_type": "workflow"}` flips the source but also requires admin or "manage GitHub Pages settings" permission. `[VERIFIED: docs.github.com/en/rest/pages/pages]`

Given the one-time nature and the elevated-token cost, D-14's manual approach is the pragmatic call.

### What happens on first deploy if Source is still "Deploy from a branch"

- `actions/configure-pages@v6` (without `enablement: true`) fails with an error along the lines of "Get Pages site failed. Please verify that the repository has Pages enabled and configured to build using GitHub Actions." (Exact text varies by version.)
- The workflow fails fast at the `configure-pages` step — no partial deploy, no artifact lingers. `[ASSUMED: inferred from configure-pages docs; not reproduced in a sandbox. Confidence MEDIUM.]`

### Permissions requirement (D-04)

| Permission | Required by | Rationale |
|-----------|-------------|-----------|
| `contents: read` | `actions/checkout` | Clone the repo |
| `pages: write` | `actions/deploy-pages` | Publish the artifact to the Pages site |
| `id-token: write` | `actions/deploy-pages` | OIDC token exchange; proves the deploy originated from an authorized workflow. Required since `deploy-pages@v4`. `[VERIFIED: github.com/actions/deploy-pages README]` |

These three together are the minimum and match GitHub's official starter-workflow.

## Validation Architecture

> Required because `.planning/config.json` has `workflow.nyquist_validation: true` and the key is not explicitly `false`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pkgdown 2.2.0 (`check_pkgdown()`, `pkgdown_sitrep()`) + actionlint (YAML static check) + GitHub Actions (PR smoke-build) |
| Config file | `_pkgdown.yml` (edited in this phase); `.github/workflows/pkgdown.yaml` + `pkgdown-check.yaml` (edited in this phase) |
| Quick run command | `R -q -e 'pkgdown::pkgdown_sitrep()'` |
| Full suite command | `R -q -e 'pkgdown::build_site()'` (local dry run) + `actionlint .github/workflows/*.yaml` |
| Verified locally | pkgdown 2.2.0 installed; `check_pkgdown`/`pkgdown_sitrep` both exported and callable. `[VERIFIED: local R session]` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PKG-01 | Workflow YAML is syntactically valid | static | `actionlint .github/workflows/pkgdown.yaml .github/workflows/pkgdown-check.yaml` | ❌ Wave 0: actionlint may not be installed locally; install via `go install` or download binary |
| PKG-01 | Workflow uses documented action versions | static | manual review against §Pinned action versions | n/a |
| PKG-01 | Site builds successfully (equivalent of CI build step) | integration | `R -q -e 'pkgdown::build_site(new_process = FALSE, install = FALSE)'` | ✅ pkgdown 2.2.0 installed |
| PKG-01 | PR smoke-build passes on an open PR | integration | triggered by PR event; observed in PR checks | — (runs in CI) |
| PKG-01 | Push-to-master deploys site (D-15 manual verification) | manual | workflow_dispatch run, then `curl -fsS https://davidzenz.github.io/sube/ | head` | — |
| PKG-02 | Every exported symbol is present in `_pkgdown.yml` reference | static | `R -q -e 'pkgdown::check_pkgdown()'` | ✅ |
| PKG-02 | Every vignette is present in `_pkgdown.yml` articles | static | `R -q -e 'pkgdown::check_pkgdown()'` | ✅ |
| PKG-02 | URL in `_pkgdown.yml` matches DESCRIPTION URL | static | `pkgdown::check_pkgdown()` (built-in check) | ✅ |
| PKG-02 | Article ordering matches D-06 | static | manual review of `_pkgdown.yml` articles section; `pkgdown_sitrep()` does not enforce order | n/a |
| PKG-02 | Reference groups match D-10 (6 groups, correct membership) | static | manual review + `pkgdown_sitrep()` confirms no orphan topics | n/a |

### Sampling Rate

- **Per task commit:** `R -q -e 'pkgdown::pkgdown_sitrep()'` (fast — no site build) + `actionlint` on any touched workflow file.
- **Per wave merge:** `R -q -e 'pkgdown::build_site(new_process = FALSE, install = FALSE)'` (full local dry run, ~30-60s) + visual inspection of `docs/index.html` and `docs/reference/index.html`.
- **Phase gate:** PR smoke-build green + full local `build_site()` clean + manual `workflow_dispatch` post-merge per D-15.

### Wave 0 Gaps

- [ ] **`actionlint` install** — not currently available on the developer machine (verified). Install via `go install github.com/rhysd/actionlint/cmd/actionlint@latest` or download binary from releases. If planner decides actionlint is not worth the setup, drop it and rely on the PR smoke-build + GitHub's own YAML parse errors. Low-risk degradation.
- [ ] **`pkgdown-check.yaml`** — does not yet exist (creating it is part of this phase per D-05).
- [ ] **Pages Source setting** — must be flipped to "GitHub Actions" by the user (D-14) before first deploy; this is a manual environmental prerequisite, not a test gap, but it blocks the phase-gate D-15 check.

*(Framework install for pkgdown itself is not a gap — 2.2.0 is present locally and is a `Suggests:` in DESCRIPTION.)*

### Why full deploy cannot be validated pre-merge

The PR smoke-build (D-05) validates the site **builds**, but it cannot validate that it **deploys** — OIDC token exchange requires `id-token: write` on a push/workflow_dispatch path, and the production `github-pages` environment in GitHub is singular. Post-merge manual `workflow_dispatch` + URL curl (D-15) is the only integration test for the deploy path. This is an intrinsic limitation of GitHub Pages single-production-environment design, not a gap in our test plan.

## Landmines

**L-01: `gh-pages` branch residue.** If the repo had an old `gh-pages` branch with the Pages Source still pointing to it, the new artifact-based deploy would either (a) fail at `configure-pages` or (b) silently continue to serve the stale branch. CONTEXT.md code_context confirms no `gh-pages` branch exists on remote — so L-01 is mitigated. Still: verify `git branch -r | grep gh-pages` returns empty before first deploy.

**L-02: `navbar: Get started` mechanics.** D-08 relies on pkgdown seeing `navbar: Get started` on the `getting-started` article group. This is the documented way to label the navbar dropdown. No separate wiring is needed; do **not** add a custom navbar component for "Get started" (would double-list). `[CITED: pkgdown.r-lib.org/reference/build_articles.html]`

**L-03: `Config/Needs/website` handling.** `DESCRIPTION:36` already has `Config/Needs/website: pkgdown` — `setup-r-dependencies@v2` with `needs: website` reads this field and installs the listed dev-deps. If this field were missing or restricted, pkgdown wouldn't be installed. Current state is correct. No action needed unless DESCRIPTION changes in this phase.

**L-04: Concurrency trade-off.** GitHub's official starter-workflow uses `group: "pages", cancel-in-progress: false` — serializes deploys, never cancels an in-flight one. The alternative `cancel-in-progress: true` would cancel an older deploy when a newer push arrives, which is fine for pkgdown (the content is deterministic from commit SHA, no side effects) but breaks the "never interrupt a production deploy" norm. **Recommendation: follow GitHub's default (`false`)** — safer, easier to reason about, and a single deploy takes ~2-3 min so queueing is harmless. Planner may override with justification.

**L-05: `install = TRUE` leftover.** The current `pkgdown.yaml` line 31 has `install = TRUE`. D-01's specification is `install = FALSE` (matches r-lib canonical). The replacement must flip this — do not copy the current line verbatim.

**L-06: `DESCRIPTION URL:` vs `_pkgdown.yml url:` mismatch.** `check_pkgdown()` errors if these don't agree. Current state: `DESCRIPTION URL: https://github.com/davidzenz/sube`, `_pkgdown.yml url: https://davidzenz.github.io/sube/`. These are **different** — one is the repo, one is the docs site. pkgdown treats the pkgdown `url:` as the site URL and expects the DESCRIPTION URL to include (as one entry) either the same pages URL or the repo URL — pkgdown's check is usually satisfied if the pages URL appears anywhere in DESCRIPTION's URL list. **Verify this explicitly** with `pkgdown::check_pkgdown()` during Wave 0; if it errors, extend `DESCRIPTION URL:` to `https://github.com/davidzenz/sube, https://davidzenz.github.io/sube/`. `[ASSUMED: URL-check behavior inferred from pkgdown docs; not explicitly tested in this session. MEDIUM confidence.]`

**L-07: Environment protection rules.** If a repo admin has configured branch-protection or deployment-protection rules on the `github-pages` environment, the deploy waits for approval. Unless D-14's setup also creates protection rules (it doesn't by default), this won't bite — but worth mentioning so D-15 verification doesn't mysteriously hang.

## Open Questions for Planner

1. **Pin `pkgdown` to a specific version or leave `any::pkgdown`?** CONTEXT.md §discretion defaults to unpinned. For a documentation-only phase with no functional dependency on pkgdown internals, unpinned is safe. Flag for planner only if a specific pkgdown release is known to affect our config (none known today).

2. **Include `desc:` on article groups too?** D-11 mandates `desc:` only for reference groups. Article-group `desc:` (rendered on `/articles/`) would parallel the reference-page treatment and improve the docs surface cheaply. Planner's call — this is an additive decision, no downside beyond 3 short sentences.

3. **Adopt `actionlint` as a Wave-0 install or skip?** Planner must decide whether the workflow-syntax static check is worth installing a Go binary locally. Skipping is fine if the PR smoke-build + GitHub's own parse errors are considered sufficient signal.

4. **Two-file (pkgdown.yaml + pkgdown-check.yaml) vs conditional single-file?** Research recommends separate file; planner confirms or overrides with justification.

5. **`environment: github-pages` on the deploy job?** The YAML skeleton includes it because GitHub's starter-workflow does. It's not strictly required for the deploy to function but is best practice. Planner confirms.

## Sources

### Primary (HIGH confidence)
- r-lib/actions v2 canonical `examples/pkgdown.yaml` — https://raw.githubusercontent.com/r-lib/actions/v2/examples/pkgdown.yaml (fetched 2026-04-18)
- r-lib/pkgdown repo's own deploy workflow — https://raw.githubusercontent.com/r-lib/pkgdown/main/.github/workflows/pkgdown.yaml (fetched 2026-04-18)
- GitHub Pages starter-workflow — github.com/actions/starter-workflows/blob/main/pages/static.yml
- `actions/configure-pages` — https://github.com/actions/configure-pages (releases + action.yml)
- `actions/upload-pages-artifact` — https://github.com/actions/upload-pages-artifact (v5, 2025-04-10)
- `actions/deploy-pages` — https://github.com/actions/deploy-pages (v5, 2025-03-25)
- pkgdown reference: build_site_github_pages — https://pkgdown.r-lib.org/reference/build_site_github_pages.html
- pkgdown reference: build_reference — https://pkgdown.r-lib.org/reference/build_reference.html
- pkgdown reference: build_articles — https://pkgdown.r-lib.org/reference/build_articles.html
- pkgdown reference: check_pkgdown — https://pkgdown.r-lib.org/reference/check_pkgdown.html
- GitHub Pages REST API — https://docs.github.com/en/rest/pages/pages
- GitHub Blog changelog (artifact v3 EOL) — https://github.blog/changelog/2024-12-05-deprecation-notice-github-pages-actions-to-require-artifacts-actions-v4-on-github-com/
- Local R session: pkgdown 2.2.0, `check_pkgdown` and `pkgdown_sitrep` both exported (verified 2026-04-18)
- Local `NAMESPACE`: 18 exports (verified by `grep -c '^export(' NAMESPACE`)
- Local `DESCRIPTION`: `Config/Needs/website: pkgdown` present at line 36

### Secondary (MEDIUM confidence)
- `usethis::use_pkgdown_github_pages()` — r-lib/usethis docs
- actionlint repo — https://github.com/rhysd/actionlint
- r-lib/actions releases — https://github.com/r-lib/actions/releases (v2.11.4, 2025-10-08)

### Tertiary (LOW confidence / inferred)
- Duplicate-topic handling in pkgdown reference (not explicitly documented; inferred from check_pkgdown's focus on missing topics)
- Exact error text from `configure-pages` when Pages source is misconfigured (not reproduced in sandbox)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `configure-pages@v6` fails fast with a recognizable error if Pages source is "Deploy from a branch" | GitHub Pages Prerequisites §First-deploy | If it instead silently continues or produces a cryptic error, first-deploy debugging is harder; mitigation is D-14 |
| A2 | pkgdown de-duplicates silently when a topic appears in multiple reference groups | `_pkgdown.yml` Schema Notes §duplicate-topic | Not material to this phase — D-10 assigns each topic to exactly one group |
| A3 | pkgdown's DESCRIPTION-URL vs `_pkgdown.yml url:` check passes if the pages URL appears anywhere in the DESCRIPTION URL list | L-06 | If it requires exact match, the planner must extend DESCRIPTION URL to include both strings; `check_pkgdown()` will catch this in Wave 0 |

## Metadata

**Confidence breakdown:**
- Canonical workflow shape and action versions: HIGH (verified against current releases)
- `_pkgdown.yml` schema and `check_pkgdown()` semantics: HIGH (pkgdown docs + local session)
- Reference-group function order (D-12) and coverage against NAMESPACE: HIGH (NAMESPACE grepped, all 18 placed)
- PR smoke-build placement: HIGH (reasoning-based; both options viable)
- First-deploy failure mode details: MEDIUM (not reproduced in sandbox)
- `DESCRIPTION URL:` match semantics in check_pkgdown: MEDIUM (see A3)

**Research date:** 2026-04-18
**Valid until:** 2026-05-18 (30 days) — action versions move quickly; verify pins again if phase execution slips past mid-May

## RESEARCH COMPLETE

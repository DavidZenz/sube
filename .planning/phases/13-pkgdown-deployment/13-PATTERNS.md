# Phase 13 — Pattern Map

**Mapped:** 2026-04-18
**Files analyzed:** 3 target files (2 workflow YAML, 1 pkgdown config) + 1 optional (DESCRIPTION URL check)
**Analogs found:** 3 / 3 (all strong analogs; two in-repo, one is the target file itself)

## File Classification

| Target File | Role | Data Flow | Closest Analog | Match Quality |
|-------------|------|-----------|----------------|---------------|
| `.github/workflows/pkgdown.yaml` | CI/CD workflow (deploy) | event-driven (push → build → artifact → deploy) | `.github/workflows/R-CMD-check.yaml` + current `pkgdown.yaml` | role-match + same-file (modify in place) |
| `.github/workflows/pkgdown-check.yaml` | CI/CD workflow (PR smoke build) | event-driven (PR → build → discard) | `.github/workflows/R-CMD-check.yaml` + current `pkgdown.yaml` | role-match (new file) |
| `_pkgdown.yml` | pkgdown site config (YAML) | config transform (exports + vignettes → site taxonomy) | `_pkgdown.yml` itself | same-file (modify in place) |
| `DESCRIPTION` (conditional) | package metadata | static config | — (no modification unless `check_pkgdown()` flags it) | n/a |

---

## Target Files

### 1. `.github/workflows/pkgdown.yaml` (MODIFY)

- **Role:** CI/CD — GitHub Actions workflow that builds and deploys pkgdown site to GitHub Pages on push to master.
- **Closest analog:** `.github/workflows/R-CMD-check.yaml` for concurrency / action-version / setup conventions; current `pkgdown.yaml` for the build-step shape to preserve.
- **What to mirror from R-CMD-check.yaml:**
  - `actions/checkout@v4`, `r-lib/actions/setup-pandoc@v2`, `r-lib/actions/setup-r@v2`, `r-lib/actions/setup-r-dependencies@v2` — same pinned action versions across both workflows
  - `use-public-rspm: true` on `setup-r@v2` (line 38 in R-CMD-check.yaml)
  - `extra-packages: |` block literal + `needs:` field on `setup-r-dependencies@v2` (lines 40–45 in R-CMD-check.yaml)
  - Concurrency block at top-level (lines 10–12 in R-CMD-check.yaml) — but rename group per L-04: research §Repo-Specific Adaptations mandates `group: pages` for the deploy workflow (not the R-CMD-check pattern of `r-cmd-check-${{ github.workflow }}-${{ github.ref }}`).
  - `timeout-minutes: 30` at job level (line 21 R-CMD-check.yaml) — research recommends `timeout-minutes: 20` for pkgdown as discretionary default.
- **What to preserve from current `pkgdown.yaml`:**
  - Overall triggers shape: `on: push: branches: [main, master]` + `workflow_dispatch:` (lines 3–6, matches D-02)
  - Build step shell: `shell: Rscript {0}` (line 32)
  - Build call: `pkgdown::build_site_github_pages(new_process = FALSE, ...)` but flip `install = TRUE` → `install = FALSE` per L-05
  - `extra-packages` contents: `any::pkgdown`, `local::.` (lines 25–27) with `needs: website` (line 28)
- **What to replace / remove:**
  - `permissions: contents: write` (line 9) → `contents: read` + `pages: write` + `id-token: write` per D-04
  - Entire `Deploy` step using `JamesIves/github-pages-deploy-action@v4` (lines 34–38) → replaced by `actions/configure-pages@v6` + `actions/upload-pages-artifact@v5` + `actions/deploy-pages@v5`
  - `install = TRUE` → `install = FALSE` (L-05)
- **What to add (not in either analog):**
  - `environment: github-pages` block with `url: ${{ steps.deployment.outputs.page_url }}` (new; follows GitHub starter-workflow pages/static.yml pattern per research §Canonical r-lib pkgdown-pages.yaml)
  - `id: deployment` on the `deploy-pages` step so the URL output is resolvable

#### Excerpts from analog `.github/workflows/R-CMD-check.yaml` (action versions + setup + concurrency)

Lines 1–16 (triggers, concurrency, permissions):

```yaml
name: R-CMD-check

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:

concurrency:
  group: r-cmd-check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
```

Lines 30–45 (setup actions that must match pkgdown.yaml):

```yaml
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::rcmdcheck
            local::.
          needs: check
```

> Note for pkgdown.yaml: drop the `r-version:` line (no matrix; default R release is fine). Change `any::rcmdcheck` → `any::pkgdown` and `needs: check` → `needs: website`.

#### Current state excerpt of `.github/workflows/pkgdown.yaml` (what's being replaced)

Full current file (39 lines):

```yaml
name: pkgdown

on:
  push:
    branches: [main, master]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  pkgdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::pkgdown
            local::.
          needs: website

      - name: Build site
        run: pkgdown::build_site_github_pages(new_process = FALSE, install = TRUE)
        shell: Rscript {0}

      - name: Deploy
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          branch: gh-pages
          folder: docs
```

**Lines to keep verbatim (after flipping `install = TRUE` → `install = FALSE`):** 1–6 (name + triggers), 13 (`runs-on: ubuntu-latest`), 15 (checkout), 17 (setup-pandoc), 19–21 (setup-r with `use-public-rspm: true`), 23–28 (setup-r-dependencies with extra-packages + needs), 30–32 (Build site step, with `install` flipped per L-05).

**Lines to replace / remove:** 8–9 (permissions — expand to 3 fields per D-04), 34–38 (Deploy step — replace with 3-action Pages artifact sequence).

**Lines to add (new, between old line 33 and a new id-`deployment` step):** top-level `concurrency: { group: pages, cancel-in-progress: false }` block (research §L-04); job-level `environment: { name: github-pages, url: ... }`; `configure-pages@v6`, `upload-pages-artifact@v5` with `path: docs`, `deploy-pages@v5` with `id: deployment`.

#### Read-before-edit list for executor

- `/home/zenz/R/sube/.github/workflows/pkgdown.yaml` (target)
- `/home/zenz/R/sube/.github/workflows/R-CMD-check.yaml` (sibling analog — action-version reference)
- `/home/zenz/R/sube/.planning/phases/13-pkgdown-deployment/13-RESEARCH.md` §Canonical r-lib pkgdown-pages.yaml (YAML skeleton to adapt) and §Landmines L-01..L-07

---

### 2. `.github/workflows/pkgdown-check.yaml` (CREATE NEW)

- **Role:** CI/CD — PR smoke-build workflow. Builds the pkgdown site on each pull request to confirm vignettes/reference entries are valid; no artifact upload, no deploy.
- **Closest analog:** Setup steps mirror `.github/workflows/R-CMD-check.yaml`; build-step shell mirrors current `.github/workflows/pkgdown.yaml`; overall shape follows research §PR Smoke-Build Recommendation.
- **What to mirror from R-CMD-check.yaml:**
  - Trigger shape `pull_request: branches: [main, master]` (lines 6–7)
  - Concurrency block with `cancel-in-progress: true` (research §PR Smoke-Build Recommendation § "Recommended shape for `pkgdown-check.yaml`" explicitly calls out `cancel-in-progress: true` as safe for PRs)
  - `permissions: contents: read` (line 15) — exact same scope; no `pages:` or `id-token:` since no deploy
  - Setup actions (lines 30–45 — checkout, setup-pandoc, setup-r with `use-public-rspm: true`, setup-r-dependencies with extra-packages + `needs: website`)
- **What to mirror from current pkgdown.yaml:**
  - Build step shell and Rscript pattern (lines 30–32) — but use `pkgdown::build_site(new_process = FALSE, install = FALSE)` (research D-05: "smoke check, no CNAME/.nojekyll writing needed on throwaway PR build")
  - `extra-packages: any::pkgdown, local::.` (lines 25–27) with `needs: website` (line 28)
- **What NOT to include (differs from deploy workflow):**
  - No top-level `concurrency: { group: pages }` — use a PR-scoped group like `pkgdown-check-${{ github.ref }}` instead
  - No `permissions: pages: write` / `id-token: write`
  - No `environment: github-pages` block
  - No `configure-pages`, `upload-pages-artifact`, `deploy-pages` steps
  - No `workflow_dispatch` (PR-only)

#### Excerpts from analog — permissions + concurrency shape

From R-CMD-check.yaml (lines 10–15):

```yaml
concurrency:
  group: r-cmd-check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
```

> Adapt for pkgdown-check.yaml: `group: pkgdown-check-${{ github.ref }}`, `cancel-in-progress: true`, `permissions: contents: read`.

#### Excerpts from analog — setup-actions block

From R-CMD-check.yaml (lines 30–45), identical shape to adopt (swapping `any::rcmdcheck` → `any::pkgdown` and `needs: check` → `needs: website`):

```yaml
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::rcmdcheck
            local::.
          needs: check
```

(Drop `r-version: ${{ matrix.config.r }}` — no matrix here.)

#### Excerpts from analog — build step shell pattern

From current pkgdown.yaml (lines 30–32):

```yaml
      - name: Build site
        run: pkgdown::build_site_github_pages(new_process = FALSE, install = TRUE)
        shell: Rscript {0}
```

> Adapt for pkgdown-check.yaml: swap `build_site_github_pages(...)` → `build_site(new_process = FALSE, install = FALSE)` (smoke check, no CNAME/.nojekyll, no local install since `setup-r-dependencies@v2` with `local::.` already installed the package).

#### Read-before-edit list for executor

- `/home/zenz/R/sube/.github/workflows/R-CMD-check.yaml` (setup + concurrency + permissions reference)
- `/home/zenz/R/sube/.github/workflows/pkgdown.yaml` (build-step shell reference)
- `/home/zenz/R/sube/.planning/phases/13-pkgdown-deployment/13-RESEARCH.md` §PR Smoke-Build Recommendation (full recommended shape, 31 lines)

---

### 3. `_pkgdown.yml` (MODIFY)

- **Role:** pkgdown site configuration (YAML) — defines URL, template, home page metadata, navbar, reference group taxonomy, article grouping.
- **Closest analog:** The current `_pkgdown.yml` itself — the structure is right; the `reference:` and `articles:` contents need rewriting per D-06..D-13.
- **What to rewrite (complete replacement):**
  - `reference:` block (current lines 10–36): 4 groups → 6 groups per D-10 with one-sentence `desc:` per D-11 and pipeline-order function lists per D-12.
  - `articles:` block (current lines 38–60): 7 single-article groups → 3 narrative groups per D-06/D-07, with order realigned per D-06.
- **What to keep unchanged (do NOT edit):**
  - `url:` (line 1): `https://davidzenz.github.io/sube/`
  - `template:` block (lines 2–3): `bootstrap: 5`
  - `home:` block (lines 5–8): title + description
  - `navbar:` block (lines 62–72): structure + components (matches D-09)

#### Current state excerpt — `reference:` block (lines 10–36, WILL BE REPLACED)

```yaml
reference:
  - title: Data import and preparation
    contents:
      - import_suts
      - read_figaro
      - extract_domestic_block
      - sube_example_data
      - build_matrices
      - run_sube_pipeline
      - batch_sube
  - title: Compute, model, and compare
    contents:
      - compute_sube
      - estimate_elasticities
  - title: Paper replication tools
    contents:
      - filter_paper_outliers
      - prepare_sube_comparison
      - plot_paper_comparison
      - plot_paper_regression
      - plot_paper_interval_ranges
  - title: Comparison and export helpers
    contents:
      - extract_leontief_matrices
      - filter_sube
      - plot_sube
      - write_sube
```

**Shape of the replacement** (per D-10 groups, D-11 desc, D-12 pipeline order — exact `desc:` text is Claude's discretion, candidates in 13-RESEARCH.md §Reference Group Descriptions):

```yaml
reference:
  - title: Data import
    desc: <one sentence per D-11>
    contents:
      - import_suts
      - read_figaro
      - sube_example_data
  - title: Matrix building
    desc: <one sentence per D-11>
    contents:
      - extract_domestic_block
      - build_matrices
      - extract_leontief_matrices
  - title: Compute & models
    desc: <one sentence per D-11>
    contents:
      - compute_sube
      - estimate_elasticities
  - title: Pipeline helpers
    desc: <one sentence per D-11>
    contents:
      - run_sube_pipeline
      - batch_sube
  - title: Paper replication
    desc: <one sentence per D-11>
    contents:
      - filter_paper_outliers
      - prepare_sube_comparison
      - plot_paper_comparison
      - plot_paper_regression
      - plot_paper_interval_ranges
  - title: Output & export
    desc: <one sentence per D-11>
    contents:
      - filter_sube
      - plot_sube
      - write_sube
```

#### Current state excerpt — `articles:` block (lines 38–60, WILL BE REPLACED)

```yaml
articles:
  - title: Workflow Start Here
    navbar: Get started
    contents:
      - getting-started
  - title: Inputs and Preparation
    contents:
      - data-preparation
  - title: Modeling, Comparison, and Outputs
    contents:
      - modeling-and-outputs
  - title: Pipeline Helpers
    contents:
      - pipeline-helpers
  - title: Package Design and Paper Context
    contents:
      - package-design
  - title: Paper replication
    contents:
      - paper-replication
  - title: FIGARO workflow
    contents:
      - figaro-workflow
```

**Shape of the replacement** (per D-06 order, D-07 grouping; D-08 keeps `navbar: Get started` on the Getting started group):

```yaml
articles:
  - title: Getting started
    navbar: Get started
    contents:
      - getting-started
      - package-design
  - title: Workflow
    contents:
      - data-preparation
      - modeling-and-outputs
      - pipeline-helpers
  - title: Data sources in practice
    contents:
      - paper-replication
      - figaro-workflow
```

> Note on article-group `desc:`: Research Open Question #2 flags it as additive/discretionary. CONTEXT.md D-11 mandates desc only for reference groups; planner's call whether to parallel that treatment on article groups.

#### Current state excerpt — blocks to keep verbatim (lines 1–8, 62–72)

```yaml
url: https://davidzenz.github.io/sube/
template:
  bootstrap: 5

home:
  title: sube
  description: Supply-use based econometric tools for Leontief benchmarks,
    SUBE models, and paper-style comparison workflows in R.
```

```yaml
navbar:
  structure:
    left:  [reference, articles, paper, news]
    right: [search, github]
  components:
    paper:
      text: Paper
      href: https://link.springer.com/article/10.1186/s40008-024-00331-4
    news:
      text: News
      href: news/index.html
```

> D-09 confirms navbar structure is unchanged. L-02 warns: do NOT add a custom `components.get-started:` entry — `navbar: Get started` on the articles group is the pkgdown-documented mechanism and adding a component would double-list the dropdown.

#### Read-before-edit list for executor

- `/home/zenz/R/sube/_pkgdown.yml` (target — full 73-line file)
- `/home/zenz/R/sube/NAMESPACE` (18 exports — verify reference coverage)
- `/home/zenz/R/sube/vignettes/` (7 Rmd basenames — verify article coverage)
- `/home/zenz/R/sube/.planning/phases/13-pkgdown-deployment/13-RESEARCH.md` §Reference Group Function Order (D-12 pipeline order table) and §Reference Group Descriptions (D-11 candidate sentences)

---

## Shared Patterns

### Action-version pinning policy

**Source:** `.github/workflows/R-CMD-check.yaml` (lines 31, 33, 35, 40) + research §Pinned action versions table
**Apply to:** Both workflow files (`pkgdown.yaml`, `pkgdown-check.yaml`)

```yaml
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-pandoc@v2
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-r-dependencies@v2
```

Additional versions for pkgdown.yaml deploy path (from research §Pinned action versions — not in repo yet):

```yaml
      - uses: actions/configure-pages@v6
      - uses: actions/upload-pages-artifact@v5
      - uses: actions/deploy-pages@v5
```

### `use-public-rspm: true` flag

**Source:** `.github/workflows/R-CMD-check.yaml` line 38, current `pkgdown.yaml` line 21
**Apply to:** Both workflow files on the `setup-r@v2` step

```yaml
      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true
```

### `setup-r-dependencies` with `needs: website`

**Source:** Current `pkgdown.yaml` lines 23–28 (the exact shape to port)
**Apply to:** Both workflow files

```yaml
      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::pkgdown
            local::.
          needs: website
```

> `Config/Needs/website: pkgdown` is present at DESCRIPTION:36, so `needs: website` resolves cleanly (verified in research L-03).

### Build-step shell idiom

**Source:** Current `pkgdown.yaml` lines 30–32
**Apply to:** Both workflow files

```yaml
      - name: Build site
        run: pkgdown::build_site<...>(new_process = FALSE, install = FALSE)
        shell: Rscript {0}
```

> pkgdown.yaml uses `build_site_github_pages(...)`; pkgdown-check.yaml uses `build_site(...)` per research §PR Smoke-Build Recommendation. Both use `new_process = FALSE, install = FALSE` per D-01 + L-05.

### Concurrency group naming (divergence note)

**Source:** `.github/workflows/R-CMD-check.yaml` lines 10–12 (shape) but with repo-specific group names per research §Repo-Specific Adaptations
**Apply differently per file:**

- `pkgdown.yaml` (deploy): `group: pages`, `cancel-in-progress: false` — GitHub's recommendation for Pages; L-04 explains why `false`.
- `pkgdown-check.yaml` (PR): `group: pkgdown-check-${{ github.ref }}`, `cancel-in-progress: true` — safe to cancel superseded PR builds.

Do NOT reuse the R-CMD-check.yaml group-name template `r-cmd-check-${{ github.workflow }}-${{ github.ref }}` for the deploy workflow — the Pages environment is singular per repo and `group: pages` is the canonical name (research §Repo-Specific Adaptations, final bullet).

---

## Source-of-Truth References (read-only)

### NAMESPACE — 18 exports

Grouped by D-10 assignment and sorted in D-12 pipeline order:

| # | Group | Functions |
|---|-------|-----------|
| 1 | Data import | `import_suts`, `read_figaro`, `sube_example_data` |
| 2 | Matrix building | `extract_domestic_block`, `build_matrices`, `extract_leontief_matrices` |
| 3 | Compute & models | `compute_sube`, `estimate_elasticities` |
| 4 | Pipeline helpers | `run_sube_pipeline`, `batch_sube` |
| 5 | Paper replication | `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges` |
| 6 | Output & export | `filter_sube`, `plot_sube`, `write_sube` |

**Total: 18** — matches `grep -c '^export(' NAMESPACE` (verified in research Coverage verification table). No exports missing, no duplicates, no internals.

Full raw export list from `/home/zenz/R/sube/NAMESPACE` (lines 1–18):

```
export(batch_sube)
export(build_matrices)
export(compute_sube)
export(estimate_elasticities)
export(extract_leontief_matrices)
export(extract_domestic_block)
export(filter_paper_outliers)
export(filter_sube)
export(import_suts)
export(read_figaro)
export(run_sube_pipeline)
export(plot_paper_comparison)
export(plot_paper_interval_ranges)
export(plot_paper_regression)
export(plot_sube)
export(prepare_sube_comparison)
export(sube_example_data)
export(write_sube)
```

### `vignettes/*.Rmd` — 7 files

| Basename (pkgdown article key) | File | Title (from YAML frontmatter) |
|---|---|---|
| `getting-started` | `/home/zenz/R/sube/vignettes/getting-started.Rmd` | "Getting Started with sube" |
| `package-design` | `/home/zenz/R/sube/vignettes/package-design.Rmd` | "Leontief, SUBE, and the Paper Workflow" |
| `data-preparation` | `/home/zenz/R/sube/vignettes/data-preparation.Rmd` | "Preparing Data for sube" |
| `modeling-and-outputs` | `/home/zenz/R/sube/vignettes/modeling-and-outputs.Rmd` | "Modeling and Outputs" |
| `paper-replication` | `/home/zenz/R/sube/vignettes/paper-replication.Rmd` | "Reproducing the SUBE Paper" |
| `figaro-workflow` | `/home/zenz/R/sube/vignettes/figaro-workflow.Rmd` | "FIGARO End-to-End Workflow" |
| `pipeline-helpers` | `/home/zenz/R/sube/vignettes/pipeline-helpers.Rmd` | "Pipeline Helpers — One Call from Path to Multipliers" |

**D-06 canonical reading order** (map basenames to the 3 D-07 groups):

1. `getting-started` → Getting started (with `navbar: Get started`)
2. `package-design` → Getting started
3. `data-preparation` → Workflow
4. `modeling-and-outputs` → Workflow
5. `paper-replication` → Data sources in practice
6. `figaro-workflow` → Data sources in practice
7. `pipeline-helpers` → Workflow (appended after modeling-and-outputs so it ends the Workflow section; D-06 ordering + Phase 12 D-06 "pipeline-helpers stays last" → it is the last entry within "Workflow," and "Data sources in practice" follows it as the final article group)

### `DESCRIPTION URL` (line 15)

Current value:

```
URL: https://github.com/davidzenz/sube
```

`_pkgdown.yml url:` (line 1): `https://davidzenz.github.io/sube/`

**These differ.** Research §L-06 notes `pkgdown::check_pkgdown()` may error on this — the fix if it does is to extend DESCRIPTION URL to a comma-separated list:

```
URL: https://github.com/davidzenz/sube, https://davidzenz.github.io/sube/
```

**Action for planner:** Treat as a Wave-0 verification step. If `check_pkgdown()` passes cleanly in Wave 0, DESCRIPTION stays untouched. If it errors on the URL check, extend DESCRIPTION:15 as above. Confidence MEDIUM per research Assumption A3.

---

## No Analog Found

No target files lack an analog. Every file either has an in-repo analog (R-CMD-check.yaml, current pkgdown.yaml, current `_pkgdown.yml`) or is the analog itself (modify in place). The new `pkgdown-check.yaml` has no existing in-repo twin, but its shape is fully determined by combining setup steps from R-CMD-check.yaml with the build-step shell from current pkgdown.yaml and the explicit skeleton in 13-RESEARCH.md §PR Smoke-Build Recommendation.

---

## Metadata

**Analog search scope:**
- `/home/zenz/R/sube/.github/workflows/` — 2 YAML files (both read)
- `/home/zenz/R/sube/_pkgdown.yml` — target + analog (read)
- `/home/zenz/R/sube/NAMESPACE` — source of truth for D-13 (read)
- `/home/zenz/R/sube/DESCRIPTION` — source of truth for URL check + `Config/Needs/website` (read)
- `/home/zenz/R/sube/vignettes/` — 7 Rmd files enumerated; titles greppred from YAML frontmatter

**Files scanned:** 5 (2 workflows, `_pkgdown.yml`, NAMESPACE, DESCRIPTION); 7 vignette filenames + titles extracted via grep.

**Pattern extraction date:** 2026-04-18

## PATTERN MAPPING COMPLETE

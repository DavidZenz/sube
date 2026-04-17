---
phase: 07-figaro-e2e-validation
plan: 05
type: execute
wave: 2
depends_on:
  - "07-01"
  - "07-02"
files_modified:
  - vignettes/figaro-workflow.Rmd
  - _pkgdown.yml
  - NEWS.md
autonomous: true
requirements:
  - FIG-E2E-03
  - INFRA-02
tags:
  - vignette
  - docs
  - pkgdown
  - figaro

must_haves:
  truths:
    - "vignettes/figaro-workflow.Rmd exists with 9 sections mirroring the paper-replication.Rmd skeleton"
    - "Every code chunk in vignettes/figaro-workflow.Rmd sets eval = FALSE (explicitly or via knitr::opts_chunk)"
    - "The vignette references the synthetic fixture in section 3 (copy-pasteable via system.file()) and the real-data gated-test flow in section 8 (SUBE_FIGARO_DIR)"
    - "The vignette contains NO Eurostat link and NO FIGARO citation per D-7.6"
    - "_pkgdown.yml articles section includes entries for both `figaro-workflow` AND the previously-unregistered `paper-replication` (research side-finding)"
    - "NEWS.md has two new bullets under `# sube (development version)`: one for INFRA-02 BREAKING behavior and one for the FIGARO E2E vignette/test/fixture set"
    - "devtools::build_vignettes() builds vignettes/figaro-workflow.Rmd cleanly (zero errors, zero warnings)"
    - "pkgdown::build_articles() renders both articles entries into docs/articles/"
  artifacts:
    - path: "vignettes/figaro-workflow.Rmd"
      provides: "9-section standalone FIGARO workflow vignette, eval = FALSE"
      contains: "FIGARO End-to-End Workflow"
    - path: "_pkgdown.yml"
      provides: "Updated articles section with figaro-workflow + paper-replication entries"
      contains: "figaro-workflow"
    - path: "NEWS.md"
      provides: "Two new bullets documenting INFRA-02 behavior change and FIG-E2E-0{1,2,3} additions"
      contains: "INFRA-02"
  key_links:
    - from: "vignettes/figaro-workflow.Rmd section 3"
      to: "inst/extdata/figaro-sample/"
      via: "system.file() example"
      pattern: "figaro-sample"
    - from: "_pkgdown.yml articles:"
      to: "vignettes/figaro-workflow.Rmd"
      via: "pkgdown vignette discovery"
      pattern: "figaro-workflow"
---

<objective>
Ship FIG-E2E-03: a standalone 9-section `vignettes/figaro-workflow.Rmd`
that narrates the full researcher journey from obtaining a FIGARO
flatfile to final elasticity output, wire both it and the
previously-unregistered `paper-replication.Rmd` into `_pkgdown.yml`
articles, and record the Phase 7 behavior changes in `NEWS.md`.

Purpose: Closes FIG-E2E-03 (standalone vignette) and completes the
INFRA-02 documentation trail. Per RESEARCH side-finding, the
`paper-replication.Rmd` from Phase 6 was never registered in
`_pkgdown.yml` articles — fixing this here costs one extra yaml line
and closes a pre-existing gap.

Output: new vignette file, updated pkgdown config, two new NEWS.md
bullets. This plan can run in parallel with plan 07-03 (wave 2) because
it touches an entirely disjoint file set.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md
@.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md
@.planning/phases/07-figaro-e2e-validation/07-VALIDATION.md

# Prior-plan outputs this plan references
@.planning/phases/07-figaro-e2e-validation/07-01-SUMMARY.md
@.planning/phases/07-figaro-e2e-validation/07-02-SUMMARY.md

# Structural template + source referenced by the vignette
@vignettes/paper-replication.Rmd
@_pkgdown.yml
@NEWS.md
@R/import.R
@R/compute.R
</context>

<interfaces>
<!-- Vignette YAML header template (mirrors vignettes/paper-replication.Rmd:1-7) -->
```yaml
---
title: "FIGARO End-to-End Workflow"
vignette: >
  %\VignetteIndexEntry{FIGARO End-to-End Workflow}
  %\VignetteEngine{knitr::knitr}
  %\VignetteEncoding{UTF-8}
---
```

<!-- knitr setup chunk (mirrors paper-replication.Rmd:9-15) -->
```r
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>",
  eval = FALSE
)
library(sube)
```

<!-- Current _pkgdown.yml articles section (lines 36-49) -->
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
  - title: Package Design and Paper Context
    contents:
      - package-design

<!-- Target _pkgdown.yml articles section — adds one new entry for FIGARO
     workflow and wires the paper-replication entry that was missing.
     Placement: after "Package Design and Paper Context" (the most
     topic-adjacent group; "paper" groups together). -->
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
  - title: Package Design and Paper Context
    contents:
      - package-design
  - title: Paper replication
    contents:
      - paper-replication
  - title: FIGARO workflow
    contents:
      - figaro-workflow

<!-- NEWS.md target — add two bullets at the top of the existing
     `# sube (development version)` block (NEWS.md:1). Current first bullet
     is the read_figaro announcement. The new bullets go FIRST so the
     INFRA-02 BREAKING note is prominent. -->

Target NEWS.md bullets (insert after line 1 `# sube (development version)`):
```md
- **BREAKING (development contract, INFRA-02):** `resolve_wiod_root()` no
  longer falls back to `inst/extdata/wiod/` when `SUBE_WIOD_DIR` is unset.
  The gated replication test now skips cleanly in that case instead of
  silently using locally-mounted data (which previously caused a known
  ~4.4% multiplier divergence). Introduced `resolve_figaro_root()` with
  the same env-var-only contract (`SUBE_FIGARO_DIR`). Test helper
  renamed `tests/testthat/helper-replication.R` →
  `tests/testthat/helper-gated-data.R`.
- Added end-to-end FIGARO validation coverage: a gated real-data test
  (`SUBE_FIGARO_DIR`, DE/FR/IT/NL × 2023) with a testthat golden snapshot,
  a synthetic-fixture contract test running on every CRAN build, and a
  new `figaro-workflow` vignette narrating the full pipeline from
  flatfile to multipliers. The shipped synthetic fixture under
  `inst/extdata/figaro-sample/` is extended to 8 real FIGARO A*64 codes
  × 3 countries to exercise a non-degenerate Leontief inversion on every
  build.
```

<!-- 9-section vignette outline (CONTEXT.md D-7.6 + RESEARCH § Vignette Structure) -->

# 1. What FIGARO is and what this vignette covers
  - FIGARO = Eurostat inter-country industry-by-industry SUTs.
  - This vignette: full path from downloading a flatfile → multipliers.
  - Every chunk is `eval = FALSE` so it renders on CRAN without data.

# 2. Obtaining the data
  - Expected layout under `$SUBE_FIGARO_DIR`:
      flatfile_eu-ic-supply_25ed_{YEAR}.csv
      flatfile_eu-ic-use_25ed_{YEAR}.csv
  - Size: ~400-500 MB per file.
  - Set the env var: `export SUBE_FIGARO_DIR=/path/to/figaro`
  - NO Eurostat link, NO FIGARO citation (D-7.6).

# 3. Reading the flatfile
  - Use the shipped synthetic fixture for copy-paste (no real download):
    ```r
    dir <- system.file("extdata", "figaro-sample", package = "sube")
    sut <- read_figaro(dir, year = 2023)
    ```
  - Output class: `sube_suts` (long data.table).
  - Explain primary-input row filtering (D-19) and CPA_ prefix stripping (D-06).

# 4. Preparing mapping tables
  - Explain D-7.1 NACE section equivalence. Then show the one-liner:
    ```r
    domestic <- extract_domestic_block(sut)
    codes <- sort(unique(c(domestic$CPA, setdiff(domestic$VAR, "FU_bas"))))
    cpa_map <- data.table::data.table(CPA = codes, CPAagg = substr(codes, 1, 1))
    ind_map <- data.table::data.table(NACE = codes, INDagg = substr(codes, 1, 1))
    ```
  - Note: different column names on each (CPA vs NACE) so
    `.coerce_map()` routes correctly — cite Pitfall 5 reasoning.

# 5. Building matrices
  - `bundle <- build_matrices(domestic, cpa_map, ind_map)`
  - Explain output shape: aggregated, final_demand, matrices list.

# 6. Computing multipliers
  - `compute_sube()` call. For the default (no VA/EMP/CO2 sidecars) path,
    synthesize `GO = colSums(S)` and pass `metrics = "GO"`:
    ```r
    inputs <- data.table::rbindlist(lapply(names(bundle$matrices), function(nm) {
      b <- bundle$matrices[[nm]]
      data.table::data.table(
        YEAR = b$year, REP = b$country, INDUSTRY = b$industries,
        GO = as.numeric(colSums(b$S))
      )
    }))
    result <- compute_sube(bundle, inputs, metrics = "GO")
    ```
  - Inspect `result$summary` columns.

# 7. Extending to elasticities
  - Pointer to `estimate_elasticities()` and the opt-in sidecar env var
    `SUBE_FIGARO_INPUTS_DIR` pointing at per-country CSVs with columns
    `INDUSTRY, GO, VA, EMP, CO2`.
  - Note: sidecar data is researcher-supplied; no bundled pipeline.

# 8. Running the gated test locally
  - Command:
    ```bash
    SUBE_FIGARO_DIR=/path/to/figaro Rscript -e 'devtools::test(filter = "figaro-pipeline")'
    ```
  - First run captures the golden snapshot; subsequent runs compare.
  - Without the env var (or on CRAN/CI):
    ```bash
    Rscript -e 'devtools::test(filter = "figaro-pipeline")'
    #> FIG-E2E-02 synthetic contract: PASS
    #> FIG-E2E-01 gated real-data: SKIP (SUBE_FIGARO_DIR not set — FIGARO E2E test skipped)
    ```

# 9. What's NOT covered in v1.2
  - FIGARO SIOT (product-by-product) tables — future milestone.
  - Auto-download helpers — future milestone (network/licensing).
  - Multi-year batch → CONV-* helpers in Phase 8.
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Write vignettes/figaro-workflow.Rmd with the 9-section structure</name>
  <files>vignettes/figaro-workflow.Rmd</files>
  <action>
    Per D-7.6 + RESEARCH § Vignette Structure.

    Create `vignettes/figaro-workflow.Rmd` by assembling the YAML header,
    the knitr setup chunk (with `eval = FALSE`), and the 9 narrative
    sections from the `<interfaces>` block above.

    Hard constraints:
    - **Every code chunk** has `eval = FALSE` — either via the global
      `knitr::opts_chunk$set(eval = FALSE)` in the setup chunk (preferred,
      matches `paper-replication.Rmd:9-13`) or per-chunk.
    - **No Eurostat link**, no URL to the FIGARO download page, no
      citation to any Eurostat PDF. D-7.6 is explicit about this.
    - **Real code** — the chunks must be actual runnable R (verified by
      the executor running each chunk in a scratch session without the
      `eval = FALSE` to confirm it would work — then the `eval = FALSE`
      keeps it from running on CRAN).
    - **Copy-pasteability** — section 3 uses `system.file("extdata",
      "figaro-sample", ...)` so a reader with the package installed can
      paste and run without needing real FIGARO data.
    - **Cross-reference section 8 skip message** matches the plan-01 and
      plan-04 skip-message text exactly: `"SUBE_FIGARO_DIR not set —
      FIGARO E2E test skipped"`.
    - **File length target:** ~150-200 lines (comparable to
      `paper-replication.Rmd`'s ~158 lines).

    After writing, verify by opening the file and confirming:
    1. YAML front-matter is valid (no `title` clash, `VignetteIndexEntry`
       matches the title exactly)
    2. Nine `# N.` top-level section headings
    3. No Eurostat hyperlinks
    4. No citation references like `[@...]`, `<doi:...>`, etc.
  </action>
  <verify>
    <automated>Rscript -e 'txt <- readLines("vignettes/figaro-workflow.Rmd"); stopifnot(sum(grepl("^# [1-9]\\.", txt)) == 9L); stopifnot(any(grepl("eval = FALSE", txt))); stopifnot(!any(grepl("ec\\.europa\\.eu|eurostat", txt, ignore.case = TRUE))); devtools::build_vignettes(quiet = TRUE); stopifnot(file.exists("doc/figaro-workflow.html") || file.exists("inst/doc/figaro-workflow.html") || file.exists("vignettes/figaro-workflow.html"))'</automated>
  </verify>
  <done>
    `vignettes/figaro-workflow.Rmd` exists with 9 numbered sections, every chunk `eval = FALSE`, no Eurostat link/citation; `devtools::build_vignettes()` builds it without errors or warnings; output HTML renders in one of the vignette output locations.
  </done>
</task>

<task type="auto">
  <name>Task 2: Register figaro-workflow AND paper-replication entries in _pkgdown.yml</name>
  <files>_pkgdown.yml</files>
  <action>
    Per D-7.6 + RESEARCH side-finding (`paper-replication.Rmd` was never
    wired into pkgdown articles in Phase 6).

    Append two new articles entries to the `articles:` block in
    `_pkgdown.yml`. Target the block after the existing `Package Design
    and Paper Context` entry (lines 47-49 in the current file).

    Insert after line 49:
    ```yaml
      - title: Paper replication
        contents:
          - paper-replication
      - title: FIGARO workflow
        contents:
          - figaro-workflow
    ```

    Validate by running `pkgdown::build_articles()` locally. Expected:
    two new HTML files appear under `docs/articles/` —
    `paper-replication.html` and `figaro-workflow.html` — and both
    titles appear in the pkgdown articles navigation dropdown.

    Do NOT modify other sections of `_pkgdown.yml` (reference, navbar,
    home). Do NOT change the URL/template settings.
  </action>
  <verify>
    <automated>Rscript -e 'yaml <- yaml::read_yaml("_pkgdown.yml"); article_titles <- vapply(yaml$articles, function(a) a$title, character(1)); article_contents <- unlist(lapply(yaml$articles, function(a) a$contents)); stopifnot("Paper replication" %in% article_titles, "FIGARO workflow" %in% article_titles, "paper-replication" %in% article_contents, "figaro-workflow" %in% article_contents)'</automated>
  </verify>
  <done>
    `_pkgdown.yml` has two new articles entries; `pkgdown::build_articles()` (or a full `pkgdown::build_site()`) renders both `paper-replication.html` and `figaro-workflow.html` with the new titles appearing in the articles navigation.
  </done>
</task>

<task type="auto">
  <name>Task 3: Add NEWS.md bullets for INFRA-02 BREAKING + FIGARO E2E additions</name>
  <files>NEWS.md</files>
  <action>
    Per D-7.6 + D-7.7 + RESEARCH § NEWS.md entry.

    Insert the two bullets from the `<interfaces>` block after the first
    line `# sube (development version)` but BEFORE the existing first
    bullet (the read_figaro announcement from Phase 5). This places the
    INFRA-02 BREAKING note prominently at the top of the dev-version
    section where users scanning release notes will see it first.

    Target ordering (after this task):
    ```
    # sube (development version)

    - **BREAKING (development contract, INFRA-02):** ... [full text from interfaces block]
    - Added end-to-end FIGARO validation coverage: ... [full text from interfaces block]
    - Added `read_figaro()` for importing Eurostat FIGARO ... [existing Phase 5 bullet, unchanged]
    - Extended `.coerce_map()` to recognize `NACE` and `NACE_R2` ... [existing, unchanged]
    [... rest of existing bullets unchanged ...]

    # sube 0.1.2
    [... unchanged below ...]
    ```

    Do NOT modify any bullet below the dev-version section. Do NOT
    alter the existing read_figaro / coerce_map / fixture bullets from
    Phase 5 — the new bullets describe NEW behaviors (INFRA-02 change +
    FIG-E2E-0{1,2,3} additions).
  </action>
  <verify>
    <automated>Rscript -e 'txt <- readLines("NEWS.md"); dev_idx <- grep("^# sube \\(development version\\)$", txt); stopifnot(length(dev_idx) == 1L); stopifnot(any(grepl("INFRA-02", txt[dev_idx:(dev_idx + 10)]))); stopifnot(any(grepl("FIGARO E2E|figaro-workflow", txt[dev_idx:(dev_idx + 20)]))); stopifnot(any(grepl("helper-gated-data", txt[dev_idx:(dev_idx + 20)])))'</automated>
  </verify>
  <done>
    `NEWS.md` has two new bullets at the top of the `# sube (development version)` block; bullets mention INFRA-02 (BREAKING), the resolver env-var-only contract, the helper rename, FIGARO E2E test coverage, and the `figaro-workflow` vignette + extended fixture.
  </done>
</task>

<task type="auto">
  <name>Task 4: Full-suite build + pkgdown smoke + vignette render verification</name>
  <files>(verification only — no file writes)</files>
  <action>
    Run three smoke commands to confirm the docs wiring ships correctly:

    1. **Vignette build:**
       ```bash
       Rscript -e 'devtools::build_vignettes()'
       ```
       Expected: both `paper-replication.html` and `figaro-workflow.html`
       (or `.Rnw` outputs depending on VignetteEngine) build in
       `vignettes/` or `doc/` — no errors or warnings.

    2. **pkgdown site build:**
       ```bash
       Rscript -e 'pkgdown::build_site()'
       ```
       Expected: `docs/articles/paper-replication.html` and
       `docs/articles/figaro-workflow.html` exist. The articles navbar
       dropdown contains both new titles. Zero broken cross-references,
       zero warnings about missing articles.

    3. **R CMD check (non-tarball):**
       ```bash
       Rscript -e 'devtools::check(cran = FALSE, vignettes = TRUE)'
       ```
       Expected: Status: OK or Status: 1 NOTE (acceptable — tarball
       checks are covered in Phase 9). No new WARNINGs from the vignette
       or NEWS.md additions.

    If `pkgdown::build_site()` complains that either vignette is missing,
    inspect the `_pkgdown.yml` article contents vs. actual `vignettes/*.Rmd`
    filenames — they must match (no `.Rmd` extension in the yaml).
  </action>
  <verify>
    <automated>Rscript -e 'devtools::build_vignettes(quiet = TRUE); pkgdown::build_articles(quiet = TRUE); stopifnot(file.exists("docs/articles/figaro-workflow.html"), file.exists("docs/articles/paper-replication.html"))'</automated>
  </verify>
  <done>
    Both vignettes render; pkgdown site includes `docs/articles/figaro-workflow.html` and `docs/articles/paper-replication.html`; `devtools::check(cran = FALSE)` reports no new warnings from the Phase 7 additions.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A — this plan edits a vignette, a pkgdown config file, and NEWS.md.
No executable code surface beyond `eval = FALSE` example chunks in the
vignette (which never execute at build time). No external input, no
network I/O, no authentication.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-06 | N/A | vignettes/figaro-workflow.Rmd | accept | Documentation artifact. All code chunks `eval = FALSE` — no runtime execution during vignette build. |
| T-07-07 | N/A | _pkgdown.yml, NEWS.md | accept | Build-configuration and changelog text files. Zero attack surface. |
</threat_model>

<verification>
- `devtools::build_vignettes()` — both vignettes build
- `pkgdown::build_articles()` — both article HTML files produced
- `_pkgdown.yml` YAML validates (parseable by yaml package) and contains both new article entries
- `NEWS.md` has the two new bullets in the correct position
- `devtools::check(cran = FALSE)` — no new warnings
</verification>

<success_criteria>
- [ ] `vignettes/figaro-workflow.Rmd` exists with 9 numbered sections, every chunk `eval = FALSE`
- [ ] No Eurostat link or FIGARO citation anywhere in the vignette
- [ ] `_pkgdown.yml` articles section lists both `paper-replication` and `figaro-workflow`
- [ ] `NEWS.md` has two new top-of-dev-version bullets for INFRA-02 and FIG-E2E-0{1,2,3}
- [ ] `devtools::build_vignettes()` succeeds with zero errors
- [ ] `pkgdown::build_articles()` produces both article HTMLs under `docs/articles/`
- [ ] `devtools::check(cran = FALSE)` reports no new warnings
</success_criteria>

<output>
After completion, create `.planning/phases/07-figaro-e2e-validation/07-05-SUMMARY.md`
</output>

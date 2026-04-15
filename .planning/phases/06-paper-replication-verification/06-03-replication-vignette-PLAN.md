---
phase: 06-paper-replication-verification
plan: 03
type: execute
wave: 2
depends_on: [01, 02]
files_modified:
  - vignettes/paper-replication.Rmd
  - _pkgdown.yml
  - NEWS.md
autonomous: true
requirements: [REP-02]
threat_model:
  note: "Documentation-only. Vignette is eval = FALSE so no code executes at build time. No inputs, HTTP surface, auth, or deserialization. ASVS V2/V3/V4/V5/V6 not applicable."
  boundaries: []
  threats: []

must_haves:
  truths:
    - "`vignettes/paper-replication.Rmd` exists with 9 sections per D-11 and eval = FALSE in the setup chunk"
    - "`devtools::build_vignettes()` produces `doc/paper-replication.html` without evaluating WIOD-dependent chunks"
    - "`_pkgdown.yml` has a new `Paper replication tools` reference group containing `filter_paper_outliers` plus the relocated `plot_paper_*` + `prepare_sube_comparison` entries"
    - "`NEWS.md` has 2-3 bullets under the existing `# sube (development version)` section mentioning the new export and new vignette"
    - "`R CMD check --as-cran` passes with the new vignette (vignette parses, does not try to evaluate)"
  artifacts:
    - path: "vignettes/paper-replication.Rmd"
      provides: "9-section narrated replication workflow"
      min_lines: 120
      contains: "eval = FALSE"
    - path: "_pkgdown.yml"
      provides: "New Paper replication tools reference group with filter_paper_outliers"
      contains: "Paper replication tools"
    - path: "NEWS.md"
      provides: "Phase 6 entries under v1.1"
      contains: "filter_paper_outliers"
  key_links:
    - from: "vignettes/paper-replication.Rmd"
      to: "filter_paper_outliers"
      via: "section 6 code block"
      pattern: "filter_paper_outliers\\("
    - from: "_pkgdown.yml Paper replication tools group"
      to: "filter_paper_outliers man page"
      via: "pkgdown reference contents list"
      pattern: "- filter_paper_outliers"
---

<objective>
Ship the replication vignette (REP-02) and polish package docs:
1. Create `vignettes/paper-replication.Rmd` — 9-section narrated walkthrough
   with `eval = FALSE` — mirroring `inst/scripts/replicate_paper.R`.
2. Update `_pkgdown.yml` — create a new "Paper replication tools" reference
   group containing `filter_paper_outliers` + the relocated paper-related
   entries.
3. Update `NEWS.md` — 2-3 bullets under the existing v1.1 (development
   version) section referencing the new export and vignette.

Purpose: Documents the full reproduction workflow step-by-step so
researchers can follow along without digging into `inst/scripts/`, per
REP-02 SC-3 and CONTEXT.md D-10..D-12 / D-17.

Output:
- vignettes/paper-replication.Rmd
- _pkgdown.yml (reference group edit)
- NEWS.md (bullet additions)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/06-paper-replication-verification/06-CONTEXT.md
@.planning/phases/06-paper-replication-verification/06-RESEARCH.md

@vignettes/getting-started.Rmd
@vignettes/data-preparation.Rmd
@_pkgdown.yml
@NEWS.md
@inst/scripts/replicate_paper.R

<interfaces>
<!-- YAML header style from vignettes/getting-started.Rmd:1-12 (verified) -->
```
~~~YAML-FRONT~~~
title: "Reproducing the SUBE Paper"
vignette: >
  %\VignetteIndexEntry{Reproducing the SUBE Paper}
  %\VignetteEngine{knitr::knitr}
  %\VignetteEncoding{UTF-8}
~~~YAML-END~~~

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>",
  eval = FALSE
)
library(sube)
```
```

<!-- Current _pkgdown.yml reference section (lines 12-31) to refactor -->
```
reference:
  - title: Data import and preparation
    contents:
      - import_suts
      - read_figaro
      - extract_domestic_block
      - sube_example_data
      - build_matrices
  - title: Compute, model, and compare
    contents:
      - compute_sube
      - estimate_elasticities
  - title: Comparison and export helpers
    contents:
      - extract_leontief_matrices
      - prepare_sube_comparison
      - plot_paper_comparison
      - plot_paper_regression
      - plot_paper_interval_ranges
      - filter_sube
      - plot_sube
      - write_sube
```

<!-- Representative replication numbers (from replicate_paper.R:741-747) for inline #> output -->
- Raw S/U matrices: exact match (bit-identical)
- Net-supply model matrix W: exact match
- Leontief multipliers after outlier treatment: ~2.7% mean absolute difference
- OLS coefficients for significant terms: match to 4+ decimal places

<!-- Current NEWS.md top section (first 22 lines) is the Phase 5 FIGARO entry
     under "# sube (development version)". Append NEW bullets to that same
     section — do NOT create a new version header. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create vignettes/paper-replication.Rmd (9-section walkthrough, eval = FALSE)</name>
  <files>vignettes/paper-replication.Rmd</files>
  <read_first>
    - vignettes/getting-started.Rmd (lines 1-12 — YAML + setup chunk style to mirror)
    - vignettes/data-preparation.Rmd (lines 1-12 — secondary style reference)
    - inst/scripts/replicate_paper.R (steps 1-9 — section content source; especially lines 31-99, 119-156, 596-625, 740-747)
    - .planning/phases/06-paper-replication-verification/06-CONTEXT.md (D-10, D-11, D-12 — section list + "Beyond this vignette" pointer)
  </read_first>
  <action>
Create `vignettes/paper-replication.Rmd` with the following exact structure. All chunks inherit `eval = FALSE` from the setup chunk (D-10). Use `AUS 2005` as the running example (CONTEXT.md "Claude's Discretion"). Inline `#>` comments quote representative output from `inst/scripts/replicate_paper.R:741-747`.

**NOTE:** In the literal file content below, `~~~YAML-FRONT~~~` and `~~~YAML-END~~~` are stand-in tokens for a literal `---` delimiter line. When writing the vignette, replace EACH stand-in with a line containing exactly three hyphens (`---`). The tokens exist only because this PLAN.md embeds YAML-delimiter-looking strings that would otherwise confuse YAML frontmatter parsers reading this plan.

```
~~~YAML-FRONT~~~
title: "Reproducing the SUBE Paper"
vignette: >
  %\VignetteIndexEntry{Reproducing the SUBE Paper}
  %\VignetteEngine{knitr::knitr}
  %\VignetteEncoding{UTF-8}
~~~YAML-END~~~

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>",
  eval = FALSE
)
library(sube)
```

# 1. What this vignette replicates

The 2018 SUBE paper computes Leontief multipliers, elasticities, and
regression coefficients from WIOD international supply-use tables. This
vignette walks through the end-to-end reproduction of the paper's raw
supply, use, and net-supply matrices using only the functions exported
by `sube`. All code chunks are shown `eval = FALSE` so the vignette
builds cleanly on CRAN and in CI without requiring the ~4 GB WIOD data
archive.

The gated test at `tests/testthat/test-replication.R` asserts bit-level
numerical equivalence for a representative subset (AUS, DEU, USA, JPN
for 2005). Running it locally is covered in section 9.

# 2. Obtaining the WIOD data

Download the WIOD international supply-use tables and companion files
from Eurostat / the WIOD website. The expected layout under
`$SUBE_WIOD_DIR`:

```
$SUBE_WIOD_DIR/
  International SUTs domestic/
    Int_SUTs_domestic_SUP_2005_May18.csv
    Int_SUTs_domestic_USE_2005_May18.csv
    ...
  Correspondences/
    CorrespondenceCPA56.dta
    CorrespondenceInd56.dta
  GOVAcur/      GO_{country}_{year}.dta
  EMP/          EMP_{country}_{year}.dta
  CO2/          CO2_{country}_{year}.dta
  Regression/data/   {country}_{year}.csv  (legacy ground-truth W matrices)
```

Set the environment variable before running the gated test:

```bash
export SUBE_WIOD_DIR=/path/to/wiod
```

# 3. Importing the domestic block

```{r}
sut <- import_suts(file.path(Sys.getenv("SUBE_WIOD_DIR"),
                             "International SUTs domestic"))
domestic <- extract_domestic_block(sut)
domestic[REP == "AUS" & YEAR == 2005][1:3]
#> Returns a sube_domestic_suts long table with REP == PAR rows only.
```

# 4. Aggregation via correspondence tables

```{r}
root <- Sys.getenv("SUBE_WIOD_DIR")
cpa_map <- data.table::data.table(haven::read_dta(
  file.path(root, "Correspondences", "CorrespondenceCPA56.dta")))
ind_map <- data.table::data.table(haven::read_dta(
  file.path(root, "Correspondences", "CorrespondenceInd56.dta")))
data.table::setnames(cpa_map, "CPAagg", "CPA_AGG")
data.table::setnames(ind_map, "Indagg", "IND_AGG")
```

The CPA56 and Ind56 maps project the raw 56-sector NACE codes onto the
22-sector aggregation used throughout the paper.

# 5. Computing Leontief multipliers and elasticities

```{r}
results <- compute_sube(domestic, cpa_map, ind_map)
results$tidy[COUNTRY == "AUS" & YEAR == 2005 & measure == "multiplier"][1:5]
```

`compute_sube()` builds the aggregated S and U matrices, inverts
`(I - A)`, and emits tidy multiplier and elasticity tables.

# 6. Applying the paper's outlier treatment

```{r}
models <- estimate_elasticities(results)
comp <- prepare_sube_comparison(results, models)
comp_filtered <- filter_paper_outliers(comp)
#> Applies the six exclusion layers from 08_outlier_treatment.R:89-181 —
#> see ?filter_paper_outliers for the full rule list.
```

Pass `apply_bounds = FALSE` to keep multiplier outliers in the output,
or pass `variables = c("GO", "VA", "EMP")` to skip the CO2-specific
rules when CO2 data is unavailable.

# 7. Running the regressions

```{r}
models <- estimate_elasticities(results)
models$OLS[term == "P01" & variable == "GO"]
#> The SUBE paper's OLS, pooled, and between estimators are all produced
#> in one call. See ?estimate_elasticities for the full return shape.
```

# 8. Comparing with the legacy paper output

Running the full pipeline on the 2018 WIOD data yields:

```
#> Raw supply and use matrices: exact match (bit-identical)
#> Net-supply model matrix W = t(SUP_agg - USE_agg): exact match
#> Leontief multipliers after outlier treatment: ~2.7% mean abs. diff.
#> OLS coefficients (significant terms): match to 4+ decimal places
```

The matrix-level differences are zero; the multiplier- and
coefficient-level differences are methodological (averaging order,
filter interaction) and are documented in full in
`inst/scripts/replicate_paper.R`.

# 9. Running the gated test locally

With `SUBE_WIOD_DIR` pointing at a populated WIOD tree:

```bash
SUBE_WIOD_DIR=/path/to/wiod Rscript -e 'devtools::test(filter = "replication")'
```

Without the env var (or on CRAN / CI), the test auto-skips:

```bash
Rscript -e 'devtools::test(filter = "replication")'
#> SKIP (SUBE_WIOD_DIR not set - paper replication test skipped)
```

# Beyond this vignette

- **IHS regression variants.** `archive/legacy-scripts/06_SUBE_ihs*.R`,
  `06_SUBE_lin-ihs*.R`, `06_SUBE_ihs-lin*.R` fit inverse-hyperbolic-sine
  transformed variants. Not part of `sube` v1.1; use the legacy scripts
  directly if needed.
- **Paper figures.** `plot_paper_comparison()`, `plot_paper_regression()`,
  and `plot_paper_interval_ranges()` reproduce the published figures.
  Each ships with its own man page.
- **Full comparison runbook.** `inst/scripts/replicate_paper.R` is the
  reference runbook; this vignette is the narrated subset.
```

Important formatting notes:
- Do NOT set `eval = TRUE` in any individual chunk (Pitfall 6).
- The first chunk must be `{r, include = FALSE}` (not `{r setup}`) to match existing vignette style.
- All fenced bash blocks use ``` ```bash ``` (plain, not evaluated).
- Use straight ASCII quotes and hyphens (no smart quotes or em dashes) — matches existing vignettes.
- File must contain exactly 9 top-level `# ` headers corresponding to the 9 sections, plus one `# Beyond this vignette` footer.
  </action>
  <verify>
    <automated>Rscript -e 'res <- devtools::build_vignettes(quiet = TRUE); built <- list.files("doc", pattern = "paper-replication\\.html$", full.names = TRUE); stopifnot(length(built) == 1); html <- paste(readLines(built), collapse = "\n"); stopifnot(grepl("1\\. What this vignette replicates", html)); stopifnot(grepl("9\\. Running the gated test", html)); stopifnot(grepl("Beyond this vignette", html)); cat("OK\n")'</automated>
  </verify>
  <acceptance_criteria>
    - `vignettes/paper-replication.Rmd` exists
    - File starts with YAML header containing `title: "Reproducing the SUBE Paper"` and `%\VignetteIndexEntry{Reproducing the SUBE Paper}`
    - File contains `eval = FALSE` inside a `knitr::opts_chunk$set(` block
    - `grep -c "^# [0-9]" vignettes/paper-replication.Rmd` returns exactly 9 (nine numbered section headers)
    - File contains `# Beyond this vignette` (footer section)
    - File contains `filter_paper_outliers(comp)` (section 6 demonstrates the new export)
    - File contains `SUBE_WIOD_DIR` at least 3 times
    - File contains `Int_SUTs_domestic_SUP_2005_May18.csv` (concrete filename in section 2)
    - File contains `06_SUBE_ihs` (IHS pointer in Beyond section per D-12)
    - File contains `plot_paper_comparison` (figures pointer in Beyond section per D-12)
    - `Rscript -e 'devtools::build_vignettes()'` exits 0 and produces `doc/paper-replication.html`
    - Rendered HTML contains exactly 9 numbered section titles
    - No chunk in the file contains `eval = TRUE`
  </acceptance_criteria>
  <done>Vignette file present with all 9 sections + Beyond, builds without evaluating WIOD code, section 6 demos filter_paper_outliers, section 9 shows gated-test command.</done>
</task>

<task type="auto">
  <name>Task 2: Update _pkgdown.yml reference groups + NEWS.md bullets, then run R CMD check --as-cran</name>
  <files>_pkgdown.yml, NEWS.md</files>
  <read_first>
    - _pkgdown.yml (entire file — need exact current reference group structure and surrounding YAML to preserve)
    - NEWS.md (lines 1-25 — confirm current "# sube (development version)" header is the Phase 5 FIGARO entry where bullets must be appended)
    - .planning/phases/06-paper-replication-verification/06-RESEARCH.md (Open Question 2 — recommendation on pkgdown group split)
  </read_first>
  <action>
**Edit 1: _pkgdown.yml — split the existing reference groups.**

Current `reference:` block (see <interfaces> for exact current state) lists a single "Comparison and export helpers" group bundling paper-specific helpers with generic helpers. Replace lines 12-31 (the entire `reference:` block) with:

```yaml
reference:
  - title: Data import and preparation
    contents:
      - import_suts
      - read_figaro
      - extract_domestic_block
      - sube_example_data
      - build_matrices
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

Changes:
- ADD new group `Paper replication tools` between `Compute, model, and compare` and `Comparison and export helpers`.
- MOVE `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges` from `Comparison and export helpers` to the new group.
- ADD `filter_paper_outliers` as the first entry of the new group.
- KEEP `extract_leontief_matrices`, `filter_sube`, `plot_sube`, `write_sube` in `Comparison and export helpers`.

Preserve exact 2-space indentation. Do NOT touch any other section of `_pkgdown.yml` (home, articles, navbar, etc.).

**Edit 2: NEWS.md — append 2-3 bullets to the existing `# sube (development version)` section (D-17).**

The existing top section starts at line 1 (`# sube (development version)`) and already lists three FIGARO-related bullets (Phase 5). Append the following bullets BELOW the existing FIGARO bullets but ABOVE the next header `# sube 0.1.2` (so the v1.1-development section grows; do NOT create a new version header — D-15 says version stays at 0.1.2):

```markdown
- Exported `filter_paper_outliers()` (formerly internal `.apply_paper_filters()`)
  with `variables` and `apply_bounds` arguments so researchers can apply the
  paper's six-layer outlier treatment directly to SUBE comparison or results
  tables. See `?filter_paper_outliers` for the full rule list with citations
  to `archive/legacy-scripts/08_outlier_treatment.R:89-181`.
- Added the `paper-replication` vignette: a nine-section walkthrough of the
  end-to-end reproduction of the 2018 paper's raw supply, use, and
  net-supply matrices from WIOD data. Builds with `eval = FALSE` so it
  renders cleanly on CRAN.
- Added the gated `tests/testthat/test-replication.R` suite (requires
  `SUBE_WIOD_DIR`; auto-skipped on CRAN and in CI) which asserts bit-level
  equality against the legacy paper ground-truth matrices for AUS, DEU,
  USA, and JPN in 2005.
```

Do NOT modify the existing FIGARO bullets, the `# sube 0.1.2` section, or
anything below. DESCRIPTION Version stays at `0.1.2` (D-15 + Phase 5 D-23).

**Edit 3: Verify R CMD check --as-cran passes.**

Run the full CRAN-style check. The new vignette must parse (though not
evaluate), and the new exported function must have no documentation
warnings. Expected: zero ERROR, zero WARNING; NOTE(s) acceptable only if
they predate this phase.

Command: `R CMD build . && R CMD check --as-cran sube_0.1.2.tar.gz`
  </action>
  <verify>
    <automated>Rscript -e 'yaml::read_yaml("_pkgdown.yml") -> y; titles <- vapply(y$reference, function(g) g$title, character(1)); stopifnot("Paper replication tools" %in% titles); grp <- y$reference[[which(titles == "Paper replication tools")]]; stopifnot("filter_paper_outliers" %in% grp$contents); stopifnot("prepare_sube_comparison" %in% grp$contents); news <- readLines("NEWS.md"); stopifnot(any(grepl("filter_paper_outliers", news))); stopifnot(any(grepl("paper-replication", news))); cat("OK\n")' && R CMD build . 2>&1 | tail -5 && R CMD check --as-cran sube_0.1.2.tar.gz 2>&1 | tail -30</automated>
  </verify>
  <acceptance_criteria>
    - `_pkgdown.yml` parses as valid YAML (`yaml::read_yaml` does not error)
    - `_pkgdown.yml` reference section contains a group titled exactly `Paper replication tools`
    - That group's `contents` list contains `filter_paper_outliers` as the first entry
    - That group's `contents` list contains `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges`
    - The `Comparison and export helpers` group no longer lists any `plot_paper_*` entries or `prepare_sube_comparison`
    - The `Comparison and export helpers` group still contains `extract_leontief_matrices`, `filter_sube`, `plot_sube`, `write_sube`
    - `NEWS.md` still starts with `# sube (development version)` (no new version header)
    - `NEWS.md` contains a bullet mentioning `filter_paper_outliers()`
    - `NEWS.md` contains a bullet mentioning the `paper-replication` vignette
    - `NEWS.md` contains a bullet mentioning the gated `tests/testthat/test-replication.R` suite
    - `NEWS.md` still contains the pre-existing `# sube 0.1.2` section unchanged
    - `grep -c "^Version: 0\\.1\\.2$" DESCRIPTION` returns 1 (unchanged per D-15)
    - `R CMD build .` succeeds (exit 0) and produces `sube_0.1.2.tar.gz`
    - `R CMD check --as-cran sube_0.1.2.tar.gz` reports 0 ERRORs and 0 WARNINGs (NOTEs acceptable if present pre-phase)
    - The check output confirms the new vignette was built (look for `paper-replication.html` in `sube.Rcheck/`)
  </acceptance_criteria>
  <done>pkgdown groups split correctly, NEWS.md has 3 new bullets under the existing v1.1 section, DESCRIPTION Version unchanged, R CMD check --as-cran clean.</done>
</task>

</tasks>

<verification>
- `Rscript -e 'devtools::build_vignettes()'` produces `doc/paper-replication.html` (REP-02 SC-3)
- `R CMD check --as-cran sube_0.1.2.tar.gz` green (REP-02 SC-3)
- `yaml::read_yaml("_pkgdown.yml")` parses cleanly with new group
- `NEWS.md` has 3 new bullets, no new version header
- DESCRIPTION Version still `0.1.2`
</verification>

<success_criteria>
- `vignettes/paper-replication.Rmd` committed with 9 sections + Beyond footer, eval = FALSE
- `_pkgdown.yml` has new "Paper replication tools" group; `Comparison and export helpers` group trimmed
- `NEWS.md` has 3 new bullets under the existing development-version header
- Full `R CMD check --as-cran` clean
- REP-02 satisfied end-to-end
</success_criteria>

<output>
After completion, create `.planning/phases/06-paper-replication-verification/06-03-SUMMARY.md`
</output>

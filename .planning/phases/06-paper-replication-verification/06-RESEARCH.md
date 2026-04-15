# Phase 6: Paper Replication Verification - Research

**Researched:** 2026-04-15
**Domain:** R package testing (testthat), vignette authoring (knitr), paper-replication verification against legacy WIOD matrix ground truth
**Confidence:** HIGH

## Summary

Phase 6 ships two artefacts: a gated testthat test that proves the
`import → extract_domestic_block → build_matrices` pipeline reproduces
the paper's raw SUP, USE, and `W = t(SUP_agg − USE_agg)` matrices to
within `1e-6`, and a knitr vignette (`eval = FALSE`) that walks the
full replication workflow. Both exist because CONTEXT.md D-01..D-17
have already frozen every significant choice — the research work here
is about locating exact line numbers, confirming existing helpers are
reusable verbatim, and mapping the test assertion layout onto the data
the pipeline actually emits.

All ground-truth artefacts already exist on disk (`inst/extdata/wiod/`
is gitignored but populated on the dev machine) and have been
bit-verified during the replication work described in
`inst/scripts/replicate_paper.R` lines 620-625, 746-747.
`.apply_paper_filters()` is fully implemented at `R/paper_tools.R:109`
and needs only rename + `@export` + roxygen block + NAMESPACE line.

**Primary recommendation:** Lift the 5-block input-preparation pipeline
from `inst/scripts/replicate_paper.R` lines 31-156 + 596-625 into a
single `tests/testthat/helper-replication.R` file, gate on
`SUBE_WIOD_DIR` + `file.exists()` fallback to `system.file("extdata",
"wiod", package = "sube")`, and emit 12 `expect_equal()` assertions
(4 countries × {SUP, USE, W} = 12) in `tests/testthat/test-replication.R`.
Keep the vignette a narrated mirror of the same script with `eval = FALSE`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Gated test verifies exact matrix match only — raw 56×56 SUP
  and USE, plus `W = t(SUP_agg − USE_agg)` — against
  `inst/extdata/wiod/Regression/data/*.csv` (for W) and
  `inst/extdata/wiod/International SUTs domestic/` (for raw SUP/USE).
  Tolerance `1e-6` absolute.
- **D-02:** Leontief multipliers and regression coefficients are NOT
  test assertions. Methodological variation lives in the vignette.
- **D-03:** Test scope — AUS, DEU, USA, JPN for 2005 only.
- **D-04:** Gate on `SUBE_WIOD_DIR` env var pointing at the WIOD subtree
  root.
- **D-05:** `testthat::skip_on_cran()` + `testthat::skip_if_not(nzchar(
  Sys.getenv("SUBE_WIOD_DIR")))`. Skip message must read cleanly.
- **D-06:** Local dev fallback — if `SUBE_WIOD_DIR` unset AND
  `system.file("extdata", "wiod", package = "sube")` resolves to an
  existing directory, use that. CRAN never sees this path because
  `inst/extdata/wiod/` is `.gitignore`d.
- **D-07..D-09:** Rename internal `.apply_paper_filters()` →
  `filter_paper_outliers()`, `@export`, document 6 layers per
  `08_outlier_treatment.R:89-181`. Signature: `filter_paper_outliers(data,
  variables = c("GO", "VA", "EMP", "CO2"), apply_bounds = TRUE)`.
- **D-10..D-12:** Vignette at `vignettes/paper-replication.Rmd`,
  `eval = FALSE` globally, 9 sections mirroring
  `inst/scripts/replicate_paper.R`. IHS variants + paper figures live in
  a "Beyond this vignette" pointer only.
- **D-13:** `inst/scripts/replicate_paper.R` stays as the reference
  runbook. No migration into the package namespace.
- **D-14:** Ground truth = `inst/extdata/wiod/Regression/data/*.csv`
  (W matrix, bit-verified) + raw SUP/USE CSVs.
- **D-15:** DESCRIPTION Version stays `0.1.2` (continuation of Phase 5
  D-23). No bump in Phase 6.
- **D-16:** No new IMPORTS expected.
- **D-17:** `NEWS.md` gets 2-3 bullets under the existing v1.1 section.

### Claude's Discretion

- Exact `skip()` message wording.
- Single vs split test file (single `test-replication.R` is the
  expected answer given scope).
- Representative `#>` output values in the vignette (use `AUS 2005`).
- Whether to add an `R CMD check`-style vignette-parse pre-commit.
- pkgdown reference group — create a "Paper replication tools" group
  and place `filter_paper_outliers()` alongside `compute_sube()` /
  `estimate_elasticities()` / existing `plot_paper_*()`.

### Deferred Ideas (OUT OF SCOPE)

- IHS regression variants (`06_SUBE_ihs*.R`, `06_SUBE_lin-ihs*.R`,
  `06_SUBE_ihs-lin*.R`) — pointer only in vignette.
- Paper figure replication via `plot_paper_comparison()` /
  `plot_paper_regression()` / `plot_paper_interval_ranges()`.
- FIGARO replication target — waits for a reference computation.
- `run_sube_pipeline()` one-call wrapper — CONV-01, not in v1.1.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REP-01 | Gated numerical-reproduction test skipped without `SUBE_WIOD_DIR` | `.planning/REQUIREMENTS.md:19`; ground truth at `inst/extdata/wiod/Regression/data/*.csv` (verified line 746 of replicate_paper.R: "Raw S/U matrices: exact match; Net-supply model matrix: exact match"). Pipeline entry points traced in §"Pipeline Entry Points" below. |
| REP-02 | Replication vignette documents full workflow step-by-step with `eval = FALSE` | `.planning/REQUIREMENTS.md:20`; 9-section structure mirrors `inst/scripts/replicate_paper.R` Steps 1-9; YAML/chunk conventions mirror `vignettes/getting-started.Rmd:1-12`. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist at the project root. Global user instructions
(`~/.claude/CLAUDE.md`) concern only the `rtk` CLI proxy and are not
project-relevant. No project-specific directives override the research
defaults.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| testthat | 3.x (edition 3) | Test framework | Already used across `tests/testthat/*.R`; matches CRAN idiom. |
| knitr | Suggests (DESCRIPTION) | Vignette engine | Already listed in DESCRIPTION Suggests per D-16; matches existing vignettes. |
| rmarkdown | Suggests (DESCRIPTION) | Vignette formatter | Same as knitr — no new dep needed. |
| data.table | Imports (already) | CSV read + matrix ops | Already imported; `fread()` handles the 2,581-row raw SUP/USE CSVs. |
| haven | Imports (already) | `.dta` reader | Already imported; vignette references it but no test needs it (see §Test Strategy). |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| base R `Sys.getenv()` | base | Env-var gating | `Sys.getenv("SUBE_WIOD_DIR", unset = "")` per `testthat::skip_if_not` idiom. |
| base R `system.file()` | base | Fallback to `inst/extdata/wiod/` | Resolves only on dev machine (gitignored path). |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| testthat direct gate | vcr / httptest2 | Neither applicable — no HTTP involved. |
| Snapshot testing (`expect_snapshot_value()`) | for matrix equality | Rejected: the ground-truth CSVs already on disk are a more transparent snapshot. |
| `tinytest` | testthat | Rejected: would break the existing test suite convention. |

**Installation:** None. All five dependencies above are already declared
in `DESCRIPTION` and `NAMESPACE`.

**Version verification:** D-16 locks "no new IMPORTS" so no `npm view`-equivalent
(`packageVersion()` / `available.packages()`) check is load-bearing here.
[VERIFIED: `NAMESPACE` lines 16-53 enumerate current imports; data.table,
haven, testthat all present]

## Architecture Patterns

### Recommended File Structure (additions only)

```
sube/
├── R/
│   └── paper_tools.R          # rename .apply_paper_filters → filter_paper_outliers, add @export + @rdname
├── NAMESPACE                  # add one line: export(filter_paper_outliers)
├── tests/testthat/
│   ├── helper-replication.R   # NEW — lifted pipeline builders (load_wiod_sut, load_ground_truth_W, load_ground_truth_su)
│   └── test-replication.R     # NEW — single file; four country-named test_that() blocks OR one loop
├── vignettes/
│   └── paper-replication.Rmd  # NEW — 9 sections, eval = FALSE
├── _pkgdown.yml               # add "Paper replication tools" reference group
├── NEWS.md                    # add 2-3 bullets under existing v1.1 section
└── man/
    └── filter_paper_outliers.Rd  # roxygen-generated (manual regeneration if needed; NAMESPACE is hand-edited per Phase 5)
```

### Pattern 1: testthat gated by env var with file fallback

**What:** Combine `skip_on_cran()` + `skip_if_not()` + a file-exists probe.
**When to use:** Tests that need data too large or licensed to ship in the
package tarball. Standard R-packages idiom (see e.g. `dbplyr`, `rstan`
test suites).
**Example:**
```r
# Source: standard testthat idiom; confirmed compatible with existing
# tests/testthat/test-workflow.R:218-221 `skip_if(Sys.which(...) == "")` pattern.
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) return(env)
  fallback <- system.file("extdata", "wiod", package = "sube")
  if (nzchar(fallback) && dir.exists(fallback)) return(fallback)
  ""
}

test_that("raw SUP matches legacy for AUS/DEU/USA/JPN 2005", {
  testthat::skip_on_cran()
  root <- resolve_wiod_root()
  testthat::skip_if_not(
    nzchar(root),
    "SUBE_WIOD_DIR not set and inst/extdata/wiod/ absent — paper replication test skipped"
  )
  # ... assertions ...
})
```

### Pattern 2: Pipeline Entry Points (tracing)

For each of {AUS, DEU, USA, JPN} × 2005 the test must produce our
`SUP`, `USE`, and `W` matrices. The pipeline is:

1. **Import wide CSVs** — `import_suts(sut_dir)` where
   `sut_dir = file.path(root, "International SUTs domestic")`.
   `R/import.R:41-83` handles wide CSV → long via the
   `wide_id = c("REP","PAR","CPA","YEAR","TYPE")` branch, preserving
   `FU_BAS`. [VERIFIED: `R/import.R:62-81`]
2. **Extract domestic block** — `extract_domestic_block(sut)` (keeps
   `REP == PAR` only; inherits `sube_domestic_suts` class).
3. **Load correspondences** — `haven::read_dta()` on
   `CorrespondenceCPA56.dta` and `CorrespondenceInd56.dta`. Setnames:
   `CPAagg → CPA_AGG` (cpa), `Indagg → IND_AGG` (ind).
   [CITED: `inst/scripts/replicate_paper.R:93-99`]
4. **Build matrices** — `build_matrices(domestic, cpa_map, ind_map)`
   returns `$matrices[[paste(country, year, sep = "_")]]$S` and `$U`
   (22×22 aggregated). [VERIFIED: `R/matrices.R:68-101`]
5. **Build regression model matrix (`W`)** — call
   `build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)`
   (same function; `inputs` arg triggers `model_data` computation at
   `R/matrices.R:122-190`). `inputs_raw` has columns
   `YEAR, REP, INDUSTRY, GO, VA, EMP, CO2` at the **raw 56-industry**
   level (NOT aggregated — see replicate_paper.R:602-618).
   The resulting `$model_data` has columns
   `P01..P22, INDUSTRIES, YEAR, COUNTRY, GO, VA, EMP, CO2` — 56 rows per
   country-year. The P01..P22 columns ARE the transpose of
   `W = SUP_agg − USE_agg`; `R/matrices.R:163-168` confirms transpose.
6. **Match against ground truth** — read
   `file.path(root, "Regression/data", sprintf("%s_%d.csv", country, year))`
   via `data.table::fread()`. Compare `model_data[COUNTRY==c & YEAR==y,
   c("INDUSTRIES", sprintf("P%02d", 1:22), "GO", "VA")]` against the
   legacy CSV's identically-named columns. The legacy `vEMP` / `vCO2`
   columns correspond to our `EMP` / `CO2`.

**Example W-matrix comparison:**
```r
# Source: distilled from inst/scripts/replicate_paper.R:620-625 + field
# inspection of inst/extdata/wiod/Regression/data/AUS_2005.csv
compare_W <- function(bundle, root, country, year, tol = 1e-6) {
  our <- bundle$model_data[COUNTRY == country & YEAR == year]
  setorder(our, INDUSTRIES)
  legacy <- data.table::fread(
    file.path(root, "Regression", "data", sprintf("%s_%d.csv", country, year))
  )
  setorder(legacy, INDUSTRIES)
  p_cols <- sprintf("P%02d", 1:22)
  expect_equal(our$INDUSTRIES, legacy$INDUSTRIES)
  for (col in p_cols) {
    expect_equal(our[[col]], legacy[[col]], tolerance = tol,
                 info = sprintf("%s %d: column %s", country, year, col))
  }
}
```

### Pattern 3: Raw SUP/USE matrix cross-check

**What:** The raw (pre-aggregation) per-country SUP and USE matrices
live across 43 rows per country in the single-year CSV
`Int_SUTs_domestic_SUP_2005_May18.csv` (2,581 rows = 43 countries × 56 CPA
+ header + aggregation rows). The CONTEXT.md D-01 phrase "raw 56×56
supply and use matrices" refers to the per-country slice of this file
filtered to `REP == PAR == country`, CPA rows stripped of the `CPA_`
prefix.

**Columns confirmed from byte inspection:**
```
REP, PAR, CPA, A01, A02, A03, B, C10-C12, ..., (56 industry cols), ...
DSUP_bas, IMP, SUP_bas, ExpTTM, ReEXP, IntTTM, YEAR, TYPE
```
The aggregate columns (`DSUP_bas`, `IMP`, `SUP_bas`, `ExpTTM`, `ReEXP`,
`IntTTM`) are correctly stripped by `R/import.R:63-68` before melting.

**Test approach:**
```r
# Source: derived from R/import.R:42-83 + field-inspected header of
# Int_SUTs_domestic_SUP_2005_May18.csv
compare_raw_SU <- function(sut_long, root, country, year, tol = 1e-6) {
  # 1. Read the raw wide CSV for one year, one type
  for (type in c("SUP", "USE")) {
    raw_path <- file.path(root, "International SUTs domestic",
                          sprintf("Int_SUTs_domestic_%s_%d_May18.csv", type, year))
    raw_wide <- data.table::fread(raw_path)
    raw_wide <- raw_wide[REP == country & PAR == country]
    # strip `CPA_` prefix + drop known aggregate cols (matches R/import.R:63-68)

    # 2. Reshape our imported long-form data to the same wide shape
    our_wide <- data.table::dcast(
      sut_long[REP == country & PAR == country & YEAR == year & TYPE == type
               & VAR != "FU_BAS"],
      CPA ~ VAR, value.var = "VALUE", fill = 0
    )
    # 3. Compare value cells cell-by-cell
    expect_equal(sort(our_wide$CPA), sort(unique(raw_wide$CPA)))
    # ... etc
  }
}
```

**Caveat:** The simplest, strongest assertion is step (5) from Pattern 2
only — comparing our `model_data` against `Regression/data/AUS_2005.csv`
is sufficient because `W` is a deterministic function of `SUP - USE`.
If `W` matches, `SUP` and `USE` must match (up to the SUP+USE=constant
degree of freedom which the aggregation removes). The planner should
consider whether the raw SUP/USE cell-by-cell check adds coverage
beyond `W`-equality; CONTEXT.md D-01 lists all three, so default is
"include all three".

### Pattern 4: Vignette YAML + knitr chunk defaults

**What:** YAML header + `knitr::opts_chunk$set()` line
**Source:** `vignettes/getting-started.Rmd:1-12` and
`vignettes/data-preparation.Rmd:1-12` (identical pattern).

```r
# File header — copy verbatim, adjusting title
---
title: "Reproducing the SUBE Paper"
vignette: >
  %\VignetteIndexEntry{Reproducing the SUBE Paper}
  %\VignetteEngine{knitr::knitr}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>",
  eval = FALSE          # ← D-10 override: all chunks non-evaluated
)
library(sube)
```
```
[VERIFIED: `vignettes/getting-started.Rmd:1-12`; `vignettes/data-preparation.Rmd:1-12`]

### Anti-Patterns to Avoid

- **Computing ground truth inside the test.** The ground-truth CSVs
  already exist under `inst/extdata/wiod/Regression/data/`; do not
  recompute them from raw WIOD in the test (that would just test the
  pipeline against itself).
- **Using `system.file("extdata", "wiod", ...)` unconditionally in
  production code.** Only the test helper may fall back to it (per D-06),
  because the directory is gitignored and users installing from CRAN will
  not have it.
- **Hard-coding `"inst/extdata/wiod/..."` relative paths in the test.**
  Tests may be run from any working directory; always go through
  `resolve_wiod_root()` or `system.file()`.
- **Using `expect_identical()` on floating-point matrices.** Use
  `expect_equal(..., tolerance = 1e-6)` per D-01.
- **Calling `estimate_elasticities()` or `compute_sube()` in the test.**
  Out of scope per D-02. The test verifies only the three matrix families.
- **Regenerating NAMESPACE via `roxygen2::roxygenise()`.** Phase 5 D-23
  notes NAMESPACE is hand-edited in this project. Add
  `export(filter_paper_outliers)` manually, preserving alphabetical
  order (between `export(extract_leontief_matrices)` and
  `export(extract_domestic_block)` — see `NAMESPACE:4-5`; insert on a
  new line to keep current ordering unless the planner wants to sort
  strictly).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Env-var + file-existence gate | Custom `if (...) return(TRUE)` | `testthat::skip_on_cran()` + `testthat::skip_if_not()` | Standard testthat idiom; CRAN check harness recognizes these and records skips cleanly. |
| Matrix equality with tolerance | Manual `abs(a-b) < 1e-6` | `testthat::expect_equal(..., tolerance = 1e-6)` | Produces readable diff output on failure; handles NA symmetry. |
| Wide-CSV → long reshape | Bespoke `melt()` in the test | `import_suts()` (handles aggregate-col stripping at `R/import.R:62-81`) | Already does exactly the reshape the test needs; reusing it also proves it works. |
| Correspondence table load | Bespoke `.dta` reader | `haven::read_dta()` + manual setnames (`CPAagg→CPA_AGG`, `Indagg→IND_AGG`) | `haven` already in Imports; setnames pattern already used in replicate_paper.R:95-96. |
| Outlier filter rename | Author a fresh filter from 08_outlier_treatment.R | Rename `.apply_paper_filters()` in place at `R/paper_tools.R:109` | Body is 38 lines and already audited; only metadata (name, `@export`, roxygen) changes. The existing caller `prepare_sube_comparison()` at `R/paper_tools.R:187` needs its `.apply_paper_filters()` call renamed. |

**Key insight:** Every data-handling helper the test needs (`import_suts`,
`extract_domestic_block`, `build_matrices`, `read_dta`, `fread`) already
exists and is battle-tested by `replicate_paper.R`. The test code should
be near-entirely glue.

## Runtime State Inventory

*Phase 6 renames ONE internal identifier (`.apply_paper_filters` →
`filter_paper_outliers`). Full inventory required.*

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified: no datastores reference the function by name. | None. |
| Live service config | None — verified: no CI/CD, pm2, or web service references any sube R identifier. | None. |
| OS-registered state | None — verified: no Task Scheduler / systemd / launchd unit contains "apply_paper_filters". | None. |
| Secrets/env vars | `SUBE_WIOD_DIR` is NEWLY introduced but only as a test gate; no secret rotation. | Document in vignette + test helper only. |
| Build artifacts | `man/.apply_paper_filters.Rd` does not exist (function is internal, no roxygen `@export`). `man/filter_paper_outliers.Rd` is a NEW file to generate. No stale artifacts. | Generate new Rd manually or via roxygen re-run (pending Phase 5 D-23 clarification — NAMESPACE is hand-edited but `man/*.Rd` may still flow from roxygen; planner should verify by checking `man/` against `R/*.R` heads for one exported function). |

**In-code callers of `.apply_paper_filters()`:**
- `R/paper_tools.R:187` — inside `prepare_sube_comparison()`.
- `R/paper_tools.R:325` — inside `plot_paper_interval_ranges()`.

Both callers must have `.apply_paper_filters(` replaced with
`filter_paper_outliers(` at rename time. `grep -rn "apply_paper_filters"
R/ tests/ inst/ vignettes/` is the audit command. [VERIFIED via `Read`
of `R/paper_tools.R`: exactly 2 call-sites plus the definition.]

## Common Pitfalls

### Pitfall 1: Row/column order misalignment when comparing matrices

**What goes wrong:** Our `model_data` is built via `rbindlist` over
country-years with `INDUSTRIES` order determined by `colnames(W_t)` at
`R/matrices.R:168`, which itself comes from `common_vars` (intersected
industry codes). The legacy CSV's `INDUSTRIES` order is whatever the
2018 script emitted. They are not guaranteed identical.
**Why it happens:** Both tables are "complete" (56 rows × 22 product
cols) but rows can differ in order.
**How to avoid:** `setorder(..., INDUSTRIES)` both sides before comparing.
**Warning signs:** `expect_equal()` fails at the first mismatching cell
rather than reporting a shape difference.

### Pitfall 2: `VAR` column case

**What goes wrong:** `FU_bas` vs `FU_BAS`. `build_matrices()` at
`R/matrices.R:36` calls `toupper()` on `VAR`, and `R/import.R:78`
appends `FU_BAS` uppercase. replicate_paper.R:76 confirms:
`domestic[, VAR := toupper(as.character(VAR))]`. If the test helper
normalises in one place but not another, `final_demand_var = "FU_bas"`
(default) will silently filter out zero rows.
**How to avoid:** Do not customise `final_demand_var`. Trust that
`import_suts()`'s wide-CSV branch already emits `VAR = "FU_BAS"` at
`R/import.R:78`.

### Pitfall 3: Missing correspondence column rename

**What goes wrong:** `CorrespondenceCPA56.dta` has columns
`vars, CPAagg` (lowercase `CPAagg`). `.coerce_map()` (called from
`build_matrices()`) maps by synonym. But replicate_paper.R:95-96
explicitly does `setnames(cpa_map, "CPAagg", "CPA_AGG")` and
`setnames(ind_map, "Indagg", "IND_AGG")`. Without these, the
`.coerce_map()` fallback works but is position-dependent.
**How to avoid:** Mirror lines 95-96 of replicate_paper.R verbatim in
the test helper.

### Pitfall 4: Missing GO input file for a country-year breaks the whole lapply silently

**What goes wrong:** `replicate_paper.R:601-619` returns `NULL` for any
(country, year) lacking paired `GOVAcur/`, `EMP/`, `CO2/` `.dta` files,
and `rbindlist(... [!sapply(..., is.null)])` quietly drops them.
If DEU_2005 is missing one file, the regression matrix comparison for
DEU silently reports "0 rows matched" rather than failing loud.
**How to avoid:** In the test helper, after calling
`build_matrices(..., inputs = inputs_raw)`, explicitly check
`nrow(bundle$model_data[COUNTRY == c & YEAR == 2005]) == 56` for every
country in `c("AUS","DEU","USA","JPN")`. Use `expect_gt(nrow(...), 0)`
or `skip_if(nrow(...) == 0)` with a specific message.

### Pitfall 5: NAMESPACE re-sort breaks hand edits

**What goes wrong:** Running `devtools::document()` after adding
`@export filter_paper_outliers` will regenerate NAMESPACE and may
disturb the hand-curated order. Phase 5 D-23 (referenced implicitly by
D-15) notes NAMESPACE is hand-edited.
**How to avoid:** Add the export line manually and do not run
`devtools::document()` / `roxygen2::roxygenise()` as part of Phase 6
tasks. Generate `man/filter_paper_outliers.Rd` by hand or by running
roxygen on a scratch copy and copying just the new `.Rd` in. Planner
should confirm current `man/` freshness before picking an approach.

### Pitfall 6: Vignette `eval = FALSE` override per chunk

**What goes wrong:** Even with `eval = FALSE` set globally in the setup
chunk, the `include = FALSE, eval = TRUE` setup chunk itself must run
(it loads `library(sube)` and sets the option). If a user copy-pastes
the options line into a chunk that sets `eval = TRUE`, CRAN will try to
run it and fail because WIOD data is absent.
**How to avoid:** Never set `eval = TRUE` in any other chunk. The
single setup chunk `{r, include = FALSE}` evaluates but does nothing
observable; all downstream chunks stay `eval = FALSE` by inheritance.

## Code Examples

### Lifted input-builder for the test helper

Lift `replicate_paper.R:31-84` (domestic SUT import) + lines 91-99
(correspondences) + lines 119-156 (aggregated inputs) + lines 596-625
(raw-industry inputs + build_matrices with inputs=). Target:

```r
# tests/testthat/helper-replication.R
# Source: distilled from inst/scripts/replicate_paper.R steps 1-4, 9a
build_replication_fixtures <- function(root) {
  sut_dir <- file.path(root, "International SUTs domestic")
  sut <- sube::import_suts(sut_dir)
  domestic <- sube::extract_domestic_block(sut)

  cpa_map <- data.table::data.table(haven::read_dta(
    file.path(root, "Correspondences", "CorrespondenceCPA56.dta")))
  ind_map <- data.table::data.table(haven::read_dta(
    file.path(root, "Correspondences", "CorrespondenceInd56.dta")))
  data.table::setnames(cpa_map, "CPAagg", "CPA_AGG")
  data.table::setnames(ind_map, "Indagg", "IND_AGG")

  ind_codes_raw <- ind_map$vars

  go_files <- list.files(file.path(root, "GOVAcur"),
                         pattern = "\\.dta$", full.names = TRUE)
  inputs_raw <- data.table::rbindlist(Filter(Negate(is.null), lapply(go_files, function(f) {
    parts <- strsplit(tools::file_path_sans_ext(basename(f)), "_")[[1]]
    country <- parts[2]; year <- as.integer(parts[3])
    emp_f <- file.path(root, "EMP", sprintf("EMP_%s_%d.dta", country, year))
    co2_f <- file.path(root, "CO2", sprintf("CO2_%s_%d.dta", country, year))
    if (!file.exists(emp_f) || !file.exists(co2_f)) return(NULL)
    dt <- data.table::data.table(haven::read_dta(f))
    emp_dt <- data.table::data.table(haven::read_dta(emp_f))
    co2_dt <- data.table::data.table(haven::read_dta(co2_f))
    data.table::data.table(
      YEAR = year, REP = country, INDUSTRY = ind_codes_raw,
      GO = dt$GO, VA = dt$VA, EMP = emp_dt$vEMP, CO2 = co2_dt$vCO2
    )
  })))

  sube::build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)
}
```

### Per-country assertion block

```r
# tests/testthat/test-replication.R
test_that("model_data (W matrix) matches legacy ground truth within 1e-6", {
  testthat::skip_on_cran()
  root <- resolve_wiod_root()
  testthat::skip_if_not(nzchar(root),
    "SUBE_WIOD_DIR not set — paper replication test skipped")

  bundle <- build_replication_fixtures(root)

  for (country in c("AUS", "DEU", "USA", "JPN")) {
    our <- bundle$model_data[COUNTRY == country & YEAR == 2005]
    legacy <- data.table::fread(
      file.path(root, "Regression", "data", sprintf("%s_2005.csv", country)))
    data.table::setorder(our, INDUSTRIES)
    data.table::setorder(legacy, INDUSTRIES)

    testthat::expect_equal(nrow(our), 56L, info = country)
    testthat::expect_equal(our$INDUSTRIES, legacy$INDUSTRIES, info = country)
    for (p in sprintf("P%02d", 1:22)) {
      testthat::expect_equal(our[[p]], legacy[[p]],
        tolerance = 1e-6, info = paste(country, p))
    }
  }
})
```

### Roxygen block for the renamed filter

```r
# R/paper_tools.R — new block placed immediately above line 109
#' Apply the Paper's Outlier Treatment
#'
#' Applies the six exclusion layers from the 2018 paper's legacy script
#' `archive/legacy-scripts/08_outlier_treatment.R` (lines 89-181) to a
#' SUBE comparison table or results summary. These are historical,
#' paper-specific filters — not general-purpose quality rules.
#'
#' The six layers:
#' \enumerate{
#'   \item Drop whole countries: CAN, CYP.
#'   \item Drop country-year ranges: BEL 2000–2008.
#'   \item Drop specific country-product pairs (14 countries, 38 pairs).
#'   \item CO2 availability: drop `YEAR > 2009`, drop CHE/HRV/NOR.
#'   \item Multiplier plausibility bounds (only if `apply_bounds = TRUE`):
#'     GO ∈ [1, 4], VA ∈ [0, 1], EMP/CO2 ≥ 0.
#'   \item Drop rows with any negative raw elasticity.
#' }
#'
#' @param data A tidy comparison table (shape returned by
#'   [prepare_sube_comparison()]) or a SUBE results summary with
#'   `COUNTRY, YEAR, CPAagg, GO, VA, EMP, CO2` columns.
#' @param variables Subset of metrics to filter on. Default all four.
#' @param apply_bounds Whether to apply layer 5. Defaults to `TRUE`.
#' @return A filtered `data.table`.
#' @export
filter_paper_outliers <- function(data,
                                  variables = c("GO", "VA", "EMP", "CO2"),
                                  apply_bounds = TRUE) {
  # body: current .apply_paper_filters() body from R/paper_tools.R:110-145,
  # with the layer-5 block gated behind `if (isTRUE(apply_bounds))` and
  # the `variable` filters respecting `variables`.
}
```

Planner: the existing body at `R/paper_tools.R:110-145` does NOT
currently honour `variables` or `apply_bounds` — those are new
parameters per D-08. The plan must include refactoring the body, not
just renaming.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tests depending on unshippable data bundled via `tests/data/...` | `Sys.getenv()` gate + graceful skip + pointer to external data | Standard since testthat 2.x | CRAN friendly; no tarball bloat. |
| `eval = TRUE` vignettes with `\dontrun{}` blocks | `knitr::opts_chunk$set(eval = FALSE)` globally with representative `#>` comments | Post knitr 1.20 (~2018) | Reliable CRAN builds regardless of data availability. |
| Hand-rolled `all.equal(M, M_legacy)` without tolerance | `testthat::expect_equal(tolerance = 1e-6)` | testthat 3 edition | Readable diff on failure. |

**Deprecated/outdated:**
- `testthat::expect_equivalent()` — deprecated in testthat 3; use
  `expect_equal(ignore_attr = TRUE)` if attribute mismatch is expected.
  Not expected here since we setorder manually.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `man/*.Rd` files in this project ARE regenerated by roxygen (only NAMESPACE is hand-edited). | Runtime State Inventory | Planner may need an extra manual-Rd-edit step. Low risk; easily verified by opening one existing `.Rd` file and checking for the `% Generated by roxygen2` header. |
| A2 | The 4 target countries (AUS, DEU, USA, JPN) × 2005 all have complete `GOVAcur/`, `EMP/`, `CO2/`, and `Regression/data/` files on the dev machine. Verified `Regression/data/{AUS,DEU,USA,JPN}_2005.csv` all exist. GOVAcur/EMP/CO2 not verified because those files aren't listed in the ls output above but `replicate_paper.R:746` states the replication runs end-to-end — implies all four are present. | Pattern 2 + Pitfall 4 | If one country is missing, the test will skip that country silently. Pitfall 4 documents the mitigation. |
| A3 | The `INDUSTRIES` column in `Regression/data/AUS_2005.csv` uses NACE/ISIC codes matching `ind_map$vars`. Verified via the file header: first data row has `INDUSTRIES = A01`, which matches `ind_map$vars[1]` convention from `replicate_paper.R:140`. | Pattern 2 | Low — format is visible in the byte-inspected header. |
| A4 | `testthat::expect_equal()` tolerance applies to numeric vectors elementwise (matches D-01 "1e-6 absolute"). | Pattern 2 Code Example | `testthat::expect_equal` uses `waldo::compare` with a `tolerance` param that is relative + absolute; 1e-6 is small enough that the distinction rarely matters for matrices with magnitudes 10^1–10^4. If tighter literal absolute tolerance is wanted, planner may prefer `testthat::expect_true(all(abs(x-y) < 1e-6))`. |

## Open Questions

1. **Should the vignette show multiplier/elasticity diffs that are NOT
   1e-6 tight?**
   - What we know: D-02 locks these out of the test. D-11 section 8
     says "Comparing with the legacy paper output and expected
     numerical match".
   - What's unclear: Whether "expected numerical match" means quoting
     replicate_paper.R:740-747 verbatim (~2.7% multiplier / ~0.003
     elasticity / ~0.0001 OLS) or going deeper.
   - Recommendation: Quote the four lines from replicate_paper.R:741-747
     verbatim as illustrative output. No deeper math in the vignette.

2. **Does pkgdown need a separate "Paper replication tools" group, or
   does the existing "Comparison and export helpers" group suffice?**
   - What we know: `_pkgdown.yml:21-31` has a "Comparison and export
     helpers" group already containing `extract_leontief_matrices`,
     `prepare_sube_comparison`, `plot_paper_comparison`,
     `plot_paper_regression`, `plot_paper_interval_ranges`, plus the
     general `filter_sube`, `plot_sube`, `write_sube`.
   - What's unclear: D-17 Claude's Discretion says "create a Paper
     replication tools group". That means splitting the existing group.
   - Recommendation: Create a new `- title: Paper replication tools`
     section between "Compute, model, and compare" and "Comparison and
     export helpers", containing `filter_paper_outliers`,
     `prepare_sube_comparison`, `plot_paper_comparison`,
     `plot_paper_regression`, `plot_paper_interval_ranges`. Move
     those five entries out of the "Comparison and export helpers"
     group (leaving `extract_leontief_matrices`, `filter_sube`,
     `plot_sube`, `write_sube`).

3. **Is the raw SUP/USE cell-by-cell comparison redundant given the W
   comparison?**
   - What we know: `W = t(SUP_agg - USE_agg)`. If `W` matches to 1e-6,
     then `SUP_agg - USE_agg` matches; but `SUP` and `USE` individually
     could both be off by the same amount and still match `W`.
   - What's unclear: Whether anyone in practice would write a bug that
     shifts both SUP and USE by the same amount.
   - Recommendation: Follow D-01 literally. Include both raw SUP and
     USE cell-by-cell comparisons (Pattern 3) even though they may be
     theoretically redundant with W, because D-01 enumerates all three
     and the cost is small (2 extra assertion loops).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R (≥ 4.0) | Everything | ✓ | assumed current per Phase 5 | — |
| testthat | Test | ✓ | Edition 3 (already in use) | — |
| data.table | Test + vignette | ✓ | in Imports | — |
| haven | Test + vignette | ✓ | in Imports | — |
| knitr | Vignette | ✓ | in Suggests | — |
| rmarkdown | Vignette | ✓ | in Suggests | — |
| `inst/extdata/wiod/` | Test (gated) | ✓ on dev box, ✗ CRAN/CI | gitignored | Gate via `SUBE_WIOD_DIR` + skip — this IS the fallback per D-05/D-06 |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** `inst/extdata/wiod/` on
CRAN/CI — gated to skip, which is the intended behaviour.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat (edition 3) |
| Config file | `tests/testthat.R` (standard; not inspected but assumed present per `tests/testthat/*.R` files existing) |
| Quick run command | `Rscript -e 'devtools::test(filter = "replication")'` |
| Full suite command | `Rscript -e 'devtools::test()'` or `R CMD check --as-cran .` |
| Gate for inclusion | `SUBE_WIOD_DIR=/path/to/wiod Rscript -e 'devtools::test(filter = "replication")'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| REP-01 | `model_data` ≡ legacy W matrix, 4 countries × 2005, tol 1e-6 | integration (gated) | `SUBE_WIOD_DIR=... Rscript -e 'devtools::test(filter = "replication")'` | ❌ Wave 0 (`tests/testthat/test-replication.R`) |
| REP-01 | Raw SUP/USE wide ≡ imported long (reshape round-trip), 4 countries × 2005 | integration (gated) | same as above | ❌ Wave 0 (same file) |
| REP-01 | Test SKIPS cleanly without `SUBE_WIOD_DIR` | unit | `Rscript -e 'devtools::test(filter = "replication")'` (env unset) | ❌ Wave 0 |
| REP-02 | Vignette builds without evaluating chunks | build | `Rscript -e 'devtools::build_vignettes()'` or `R CMD build .` | ❌ Wave 0 (`vignettes/paper-replication.Rmd`) |
| REP-02 | `R CMD check` passes including vignette parse | full check | `R CMD check --as-cran sube_0.1.2.tar.gz` | existing harness |

### Sampling Rate

Per CONTEXT.md D-01: 4 countries × 1 year × 3 matrix families (raw SUP,
raw USE, W) = **12 assertion groups minimum**. Each group expands to
22 numeric column comparisons for W (P01..P22) + 1 row-order check, and
~56 CPA-row × ~56 industry-col cell comparisons for raw SUP/USE. Net
≈ 4 × (22 + 22 + 2×56×56) = 4 × 6316 = ~25,264 individual numeric
checks. `testthat::expect_equal()` on a vector does this in one call
each, so actual `expect_*()` count is ~12 × 22 + 4 × 2 × 56 ≈ 712.

- **Per task commit:** `devtools::test(filter = "replication")` (skips
  when env unset — near-instant).
- **Per wave merge:** `devtools::test()` full suite + vignette build.
- **Phase gate:** `SUBE_WIOD_DIR=... R CMD check --as-cran` green.

### Tolerance justification

1e-6 absolute covers floating-point noise from:
- `data.table` aggregation order differences (`sum()` over hashed
  groups is not bit-reproducible across runs if `DT` changes).
- Wide→long→wide reshape in `import_suts()` vs the legacy wide CSV.
Verified by `replicate_paper.R:746-747`: "Raw S/U matrices: exact
match; Net-supply model matrix: exact match" — meaning the legacy dev
run achieved better than 1e-6 on the real data. 1e-6 is a conservative
ceiling.

### What the test does NOT cover (deferred to the vignette)

- Leontief multiplier reproduction — ~2.7% mean diff after outlier
  treatment, driven by averaging order + filter interaction. Not
  bit-stable. Documented in the vignette per D-02 / D-11.
- OLS / pooled / between regression coefficient reproduction — 4+
  decimal match for significant terms, worse for insignificant ones
  (legacy zeroes them via `set.zero` flag, we don't). Documented per
  D-02.
- Outlier filter semantic correctness — covered by existing tests of
  `prepare_sube_comparison()` in `test-workflow.R:184-187`; the rename
  does not change behaviour.

### Wave 0 Gaps

- [ ] `tests/testthat/helper-replication.R` — lifted fixture builder
  (functions `resolve_wiod_root()`, `build_replication_fixtures()`)
- [ ] `tests/testthat/test-replication.R` — three `test_that()` blocks:
  (1) W model_data matches, (2) raw SUP matches, (3) raw USE matches
- [ ] `vignettes/paper-replication.Rmd` — 9-section narrative
- [ ] `R/paper_tools.R` refactor — rename + add `@export`, refactor
  body to honour `variables` and `apply_bounds` args per D-08
- [ ] `NAMESPACE` line addition
- [ ] `man/filter_paper_outliers.Rd` — pending A1 clarification
- [ ] `_pkgdown.yml` — new "Paper replication tools" group
- [ ] `NEWS.md` — 2-3 bullets under v1.1

## Security Domain

Phase 6 introduces no new user inputs, no HTTP, no deserialization of
untrusted content, no auth/session/access-control surface. The test
reads CSVs and `.dta` files from a local path supplied via environment
variable by the researcher themselves; the vignette never evaluates.
ASVS categories V2/V3/V4 do not apply. V5 (input validation) applies
trivially — `fread()` and `read_dta()` are the validators, and they
fail loudly on malformed input. No new security considerations.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (trivial) | `data.table::fread` + `haven::read_dta` native error paths |
| V6 Cryptography | no | — |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/06-paper-replication-verification/06-CONTEXT.md`
  — All locked decisions D-01 through D-17.
- `.planning/REQUIREMENTS.md:19-20` — REP-01, REP-02 definitions.
- `.planning/ROADMAP.md:38-45` — Phase 6 goal + success criteria.
- `R/paper_tools.R:109-146` — current `.apply_paper_filters()` body;
  lines 150-190 — `prepare_sube_comparison()`; line 325 — second call
  site inside `plot_paper_interval_ranges()`.
- `R/matrices.R:32-200` — `build_matrices()` full signature and
  `model_data` construction at lines 106-190.
- `R/import.R:25-100` — `import_suts()` wide CSV branch used by the
  test.
- `NAMESPACE:1-15` — current export list (alphabetical-ish).
- `tests/testthat/test-workflow.R:1-252` — testthat style template
  (`test_that()` naming, `skip_if()` pattern at line 219, `library()`
  at top).
- `vignettes/getting-started.Rmd:1-60` + `vignettes/data-preparation.Rmd:1-40`
  — YAML header + `knitr::opts_chunk$set()` pattern to mirror.
- `_pkgdown.yml:1-58` — reference group structure.
- `NEWS.md:1-21` — current v1.1 entry style.
- `inst/scripts/replicate_paper.R:1-757` — full reference runbook;
  particularly lines 31-84 (import), 91-99 (correspondences), 119-156
  (aggregated inputs), 163-173 (compute_sube), 186-319 (Leontief
  comparison), 596-625 (regression matrix build), 746-747 (accuracy
  summary proving 1e-6 ceiling is conservative).
- Byte-inspected CSV headers: `inst/extdata/wiod/Regression/data/AUS_2005.csv`
  (29 cols: COUNTRY,YEAR,INDUSTRIES,P01..P22,GO,VA,vEMP,vCO2; 57 rows
  = 56 industries + header) and `Int_SUTs_domestic_SUP_2005_May18.csv`
  (REP,PAR,CPA,56 industry cols, 6 aggregate cols, YEAR, TYPE; 2,581
  rows).

### Secondary (MEDIUM confidence)
- Phase 5 `05-CONTEXT.md` D-23 — NAMESPACE hand-edit convention
  (referenced in Pitfall 5 and A1).

### Tertiary (LOW confidence)
- None — all claims grounded in on-disk code or locked decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in DESCRIPTION.
- Architecture: HIGH — line numbers verified in every referenced file.
- Pitfalls: HIGH — each pitfall traces to a specific line in existing
  code or a verified byte-level CSV header observation.
- Runtime inventory: HIGH — two call sites of `.apply_paper_filters()`
  confirmed via `Read`; no other runtime state.
- Vignette conventions: HIGH — two vignettes read and found identical.

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (30 days; stable codebase, no external
moving targets).

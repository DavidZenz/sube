---
phase: 06-paper-replication-verification
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - tests/testthat/helper-replication.R
  - tests/testthat/test-replication.R
autonomous: true
requirements: [REP-01]
threat_model:
  note: "Phase 6 introduces no new user input, HTTP surface, auth, or untrusted deserialization. Scope is local file reads (CSVs + .dta via data.table::fread / haven::read_dta) gated by a researcher-supplied env var SUBE_WIOD_DIR. ASVS V2/V3/V4/V6 not applicable; V5 satisfied by native loader error paths."
  boundaries: []
  threats: []

must_haves:
  truths:
    - "Running SUBE_WIOD_DIR=... Rscript -e 'devtools::test(filter=\"replication\")' produces green (all 4 countries × {SUP, USE, W} assertions pass to 1e-6)"
    - "Running Rscript -e 'devtools::test(filter=\"replication\")' without SUBE_WIOD_DIR produces a clean single SKIP line per test_that block"
    - "Test is auto-skipped on CRAN (skip_on_cran() present in every test_that block)"
  artifacts:
    - path: "tests/testthat/helper-replication.R"
      provides: "resolve_wiod_root() and build_replication_fixtures() helpers"
      min_lines: 40
    - path: "tests/testthat/test-replication.R"
      provides: "Three test_that blocks: model_data W, raw SUP, raw USE"
      min_lines: 60
  key_links:
    - from: "tests/testthat/test-replication.R"
      to: "tests/testthat/helper-replication.R"
      via: "testthat auto-sources helper-*.R files in same dir"
      pattern: "resolve_wiod_root\\(|build_replication_fixtures\\("
    - from: "tests/testthat/helper-replication.R"
      to: "sube::build_matrices + sube::import_suts + sube::extract_domestic_block"
      via: "direct function calls"
      pattern: "sube::(import_suts|extract_domestic_block|build_matrices)"
---

<objective>
Deliver the gated replication test (REP-01): a testthat suite that proves
the `import_suts -> extract_domestic_block -> build_matrices` pipeline
reproduces the paper's raw SUP, raw USE, and `W = t(SUP_agg - USE_agg)`
matrices to within 1e-6 for AUS/DEU/USA/JPN × 2005, and that skips cleanly
on CRAN / when SUBE_WIOD_DIR is unset.

Purpose: Make paper-level numerical reproduction a first-class, verifiable
feature of the package per CONTEXT.md D-01..D-06 and REP-01 SC-1/SC-2.

Output:
- tests/testthat/helper-replication.R (fixture builders)
- tests/testthat/test-replication.R (3 test_that blocks, 4 countries each)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/06-paper-replication-verification/06-CONTEXT.md
@.planning/phases/06-paper-replication-verification/06-RESEARCH.md
@.planning/phases/06-paper-replication-verification/06-VALIDATION.md

@R/import.R
@R/matrices.R
@inst/scripts/replicate_paper.R
@tests/testthat/test-workflow.R

<interfaces>
<!-- Key pipeline contracts the test relies on. Extracted from codebase.
     Executor should use these directly — no codebase exploration needed. -->

From R/import.R (wide-CSV branch, lines 41-83):
```r
# import_suts(sut_dir): reads Int_SUTs_domestic_{SUP,USE}_{year}_May18.csv
# -> returns sube_suts long data.table with columns:
#    REP, PAR, CPA, VAR, VALUE, YEAR, TYPE
# VAR is uppercased (FU_BAS not FU_bas). Aggregate cols (DSUP_bas, IMP,
# SUP_bas, ExpTTM, ReEXP, IntTTM) are stripped pre-melt.
```

From R/matrices.R (build_matrices, lines 68-190):
```r
# build_matrices(domestic, cpa_map, ind_map, inputs = NULL)
# Returns list with:
#   $matrices[[paste(country, year, sep="_")]]$S  (22x22 aggregated supply)
#   $matrices[[paste(country, year, sep="_")]]$U  (22x22 aggregated use)
#   $model_data (ONLY when inputs != NULL) — columns:
#       P01..P22, INDUSTRIES, YEAR, COUNTRY, GO, VA, EMP, CO2
#     where P01..P22 = transpose of W = SUP_agg - USE_agg
# cpa_map / ind_map must have CPA_AGG / IND_AGG columns (setnames from
# CPAagg / Indagg). build_matrices uses default final_demand_var = "FU_bas"
# which is case-insensitively matched via toupper() internally.
```

From R/paper_tools.R (replicate_paper.R lines 31-156 + 596-625 distilled):
```r
# inputs_raw shape required by build_matrices(inputs = ...):
#   data.table with columns YEAR, REP, INDUSTRY (raw 56-level), GO, VA, EMP, CO2
```

From inst/scripts/replicate_paper.R (lines 91-99):
```r
cpa_map <- data.table(haven::read_dta(file.path(root, "Correspondences", "CorrespondenceCPA56.dta")))
ind_map <- data.table(haven::read_dta(file.path(root, "Correspondences", "CorrespondenceInd56.dta")))
setnames(cpa_map, "CPAagg", "CPA_AGG")
setnames(ind_map, "Indagg", "IND_AGG")
```

Ground truth files (root = $SUBE_WIOD_DIR or system.file("extdata","wiod",package="sube")):
- root/Regression/data/{AUS,DEU,USA,JPN}_2005.csv — columns INDUSTRIES, P01..P22, GO, VA, vEMP, vCO2
- root/International SUTs domestic/Int_SUTs_domestic_SUP_2005_May18.csv
- root/International SUTs domestic/Int_SUTs_domestic_USE_2005_May18.csv
- root/GOVAcur/GO_{country}_{year}.dta, root/EMP/EMP_{c}_{y}.dta, root/CO2/CO2_{c}_{y}.dta
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create helper-replication.R (env-var resolver + fixture builder)</name>
  <files>tests/testthat/helper-replication.R</files>
  <read_first>
    - inst/scripts/replicate_paper.R (lines 31-156 and 596-625 — pipeline to lift)
    - R/import.R (lines 41-83 — wide-CSV branch contract)
    - R/matrices.R (lines 68-190 — build_matrices inputs= path producing model_data)
    - tests/testthat/test-workflow.R (lines 1-30, 218-221 — style + skip_if pattern)
  </read_first>
  <action>
Create `tests/testthat/helper-replication.R` with exactly two exported-in-file helpers (testthat auto-sources `helper-*.R`). File contents verbatim-ish:

```r
# tests/testthat/helper-replication.R
# Shared fixtures for the paper-replication test. Lifted from
# inst/scripts/replicate_paper.R steps 1-4 + 9a. Do NOT source this file
# manually — testthat auto-loads helper-*.R.

# Resolve the WIOD root directory. Priority:
#   1) SUBE_WIOD_DIR env var (researcher-set, per CONTEXT.md D-04)
#   2) system.file("extdata", "wiod", package = "sube") local-dev fallback (D-06)
#   3) "" (empty) -> caller should skip_if_not(nzchar(root))
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) return(env)
  fallback <- system.file("extdata", "wiod", package = "sube")
  if (nzchar(fallback) && dir.exists(fallback)) return(fallback)
  ""
}

# Build the bundle the test asserts against. Runs the full pipeline once;
# test_that blocks reuse the returned bundle via a memoised closure in
# the test file. Returns the list from build_matrices(..., inputs = inputs_raw)
# — in particular $model_data.
build_replication_fixtures <- function(root, countries = c("AUS","DEU","USA","JPN"),
                                       year = 2005L) {
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
    cc <- parts[2]; yr <- suppressWarnings(as.integer(parts[3]))
    if (is.na(yr)) return(NULL)
    emp_f <- file.path(root, "EMP", sprintf("EMP_%s_%d.dta", cc, yr))
    co2_f <- file.path(root, "CO2", sprintf("CO2_%s_%d.dta", cc, yr))
    if (!file.exists(emp_f) || !file.exists(co2_f)) return(NULL)
    dt <- data.table::data.table(haven::read_dta(f))
    emp_dt <- data.table::data.table(haven::read_dta(emp_f))
    co2_dt <- data.table::data.table(haven::read_dta(co2_f))
    data.table::data.table(
      YEAR = yr, REP = cc, INDUSTRY = ind_codes_raw,
      GO = dt$GO, VA = dt$VA, EMP = emp_dt$vEMP, CO2 = co2_dt$vCO2
    )
  })))

  sube::build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)
}
```

Preserve exact indentation / 2-space style to match `tests/testthat/test-workflow.R`. No `@export` — these are test helpers. Do NOT wrap in `if (requireNamespace(...))`; the test file handles skipping.
  </action>
  <verify>
    <automated>Rscript -e 'source("tests/testthat/helper-replication.R"); stopifnot(is.function(resolve_wiod_root), is.function(build_replication_fixtures)); cat("OK\n")'</automated>
  </verify>
  <acceptance_criteria>
    - `tests/testthat/helper-replication.R` exists
    - File contains `resolve_wiod_root <- function()`
    - File contains `build_replication_fixtures <- function(root,`
    - File contains `Sys.getenv("SUBE_WIOD_DIR", unset = "")`
    - File contains `system.file("extdata", "wiod", package = "sube")`
    - File contains `setnames(cpa_map, "CPAagg", "CPA_AGG")`
    - File contains `setnames(ind_map, "Indagg", "IND_AGG")`
    - File contains `build_matrices(domestic, cpa_map, ind_map, inputs = inputs_raw)`
    - `Rscript -e 'source("tests/testthat/helper-replication.R")'` exits 0 without parse errors
  </acceptance_criteria>
  <done>Helper file present, both functions defined, sourceable without error, no testthat calls inside helpers.</done>
</task>

<task type="auto">
  <name>Task 2: Create test-replication.R (3 test_that blocks: W, raw SUP, raw USE)</name>
  <files>tests/testthat/test-replication.R</files>
  <read_first>
    - tests/testthat/helper-replication.R (created in Task 1 — function signatures)
    - .planning/phases/06-paper-replication-verification/06-RESEARCH.md (Pattern 2 + Pattern 3 code examples, Pitfall 1 setorder, Pitfall 4 nrow check)
    - R/matrices.R (lines 122-190 — to confirm model_data column order P01..P22, INDUSTRIES, YEAR, COUNTRY, GO, VA, EMP, CO2)
  </read_first>
  <action>
Create `tests/testthat/test-replication.R` with THREE `test_that()` blocks. Every block begins with the same three-line gate:

```r
testthat::skip_on_cran()
root <- resolve_wiod_root()
testthat::skip_if_not(
  nzchar(root),
  "SUBE_WIOD_DIR not set and inst/extdata/wiod/ absent - paper replication test skipped"
)
```

Use a memoised bundle loader at the top of the file (outside any test_that) so the expensive pipeline runs once:

```r
.replication_bundle <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      root <- resolve_wiod_root()
      if (!nzchar(root)) return(NULL)
      cache <<- build_replication_fixtures(root)
    }
    cache
  }
})
```

Then the three blocks:

**Block 1: `test_that("model_data W matrix matches legacy ground truth within 1e-6", { ... })`**
- gate
- `bundle <- .replication_bundle(); testthat::skip_if(is.null(bundle), "fixture build failed")`
- `for (country in c("AUS","DEU","USA","JPN"))`:
  - `our <- bundle$model_data[COUNTRY == country & YEAR == 2005]`
  - `testthat::expect_gt(nrow(our), 0)` with `info = country` (Pitfall 4)
  - `testthat::expect_equal(nrow(our), 56L, info = country)`
  - `legacy <- data.table::fread(file.path(root, "Regression", "data", sprintf("%s_2005.csv", country)))`
  - `data.table::setorder(our, INDUSTRIES); data.table::setorder(legacy, INDUSTRIES)`
  - `testthat::expect_equal(our$INDUSTRIES, legacy$INDUSTRIES, info = country)`
  - Loop `for (p in sprintf("P%02d", 1:22))`: `testthat::expect_equal(our[[p]], legacy[[p]], tolerance = 1e-6, info = paste(country, p))`

**Block 2: `test_that("raw SUP cells match legacy wide CSV within 1e-6", { ... })`**
- gate; `sut <- sube::import_suts(file.path(root, "International SUTs domestic"))`
- For each country in `c("AUS","DEU","USA","JPN")`:
  - `raw_path <- file.path(root, "International SUTs domestic", "Int_SUTs_domestic_SUP_2005_May18.csv")`
  - `raw_wide <- data.table::fread(raw_path); raw_wide <- raw_wide[REP == country & PAR == country]`
  - `our_wide <- data.table::dcast(sut[REP == country & PAR == country & YEAR == 2005 & TYPE == "SUP" & VAR != "FU_BAS"], CPA ~ VAR, value.var = "VALUE", fill = 0)`
  - Drop aggregate cols from legacy (`DSUP_bas`, `IMP`, `SUP_bas`, `ExpTTM`, `ReEXP`, `IntTTM`, `YEAR`, `TYPE`, `REP`, `PAR`) keeping `CPA` + 56 industry cols
  - `data.table::setorder(our_wide, CPA); data.table::setorder(raw_wide, CPA)`
  - `testthat::expect_equal(our_wide$CPA, raw_wide$CPA, info = country)`
  - For each industry col `col` in `intersect(names(our_wide), names(raw_wide))` excluding `CPA`: `expect_equal(our_wide[[col]], raw_wide[[col]], tolerance = 1e-6, info = paste(country, "SUP", col))`

**Block 3: identical to Block 2 but with `TYPE == "USE"` and `Int_SUTs_domestic_USE_2005_May18.csv`.**

Implementation notes:
- The legacy CSVs strip `CPA_` prefix already in `raw_wide$CPA`? Check — `R/import.R:63-68` strips the prefix on OUR side; the legacy CSV must be inspected. Research Pattern 3 says the legacy wide CSV has a `CPA` column; if values start with `CPA_`, strip at test time: `raw_wide[, CPA := sub("^CPA_", "", CPA)]`. Include this transform defensively.
- Ensure the `raw_wide` subset drops the non-industry tail columns. Use `raw_wide <- raw_wide[, setdiff(names(raw_wide), c("REP","PAR","YEAR","TYPE","DSUP_bas","IMP","SUP_bas","ExpTTM","ReEXP","IntTTM")), with = FALSE]` then setcolorder CPA first.
- DO NOT call `compute_sube()` / `estimate_elasticities()` / `filter_paper_outliers()` in this test (D-02).
- DO NOT use `expect_identical` on numeric vectors — use `expect_equal(..., tolerance = 1e-6)` (D-01).
  </action>
  <verify>
    <automated>Rscript -e 'Sys.unsetenv("SUBE_WIOD_DIR"); res <- devtools::test(filter = "replication", reporter = "summary"); q(status = if (as.data.frame(res)$failed |> sum() > 0) 1 else 0)'</automated>
  </verify>
  <acceptance_criteria>
    - `tests/testthat/test-replication.R` exists
    - File contains exactly 3 occurrences of `test_that(` (one per block)
    - File contains `testthat::skip_on_cran()` at least 3 times
    - File contains `testthat::skip_if_not(` at least 3 times with message mentioning `SUBE_WIOD_DIR`
    - File contains `tolerance = 1e-6`
    - File contains `setorder(` (for INDUSTRIES and CPA ordering)
    - File references all four countries: `AUS`, `DEU`, `USA`, `JPN`
    - File references `Int_SUTs_domestic_SUP_2005_May18.csv` and `Int_SUTs_domestic_USE_2005_May18.csv`
    - File references `Regression/data` and `sprintf("%s_2005.csv"`
    - File does NOT reference `compute_sube`, `estimate_elasticities`, or `filter_paper_outliers`
    - Running `Rscript -e 'Sys.unsetenv("SUBE_WIOD_DIR"); devtools::test(filter = "replication")'` produces 0 failures and SKIP output containing "SUBE_WIOD_DIR not set"
    - Running `Rscript -e 'devtools::test()'` full-suite exit 0 (no regression)
  </acceptance_criteria>
  <done>Test file present; ungated run skips cleanly with 0 failures; full suite still green.</done>
</task>

</tasks>

<verification>
Phase-level checks for this plan:

- `Rscript -e 'devtools::test(filter = "replication")'` without SUBE_WIOD_DIR: SKIP output, 0 failures (REP-01 SC-2)
- `Rscript -e 'devtools::test()'`: full suite green (no regression from Phase 5)
- If developer has WIOD data: `SUBE_WIOD_DIR=/path Rscript -e 'devtools::test(filter = "replication")'` passes (REP-01 SC-1) — deferred to manual exec since CI lacks data
</verification>

<success_criteria>
- helper-replication.R + test-replication.R committed
- Ungated run is a clean skip (no failures, no errors) — REP-01 SC-2 met
- Full test suite remains green — regression-free
- When developer runs gated suite, 12 expect_equal loops per block × 3 blocks pass at 1e-6 — REP-01 SC-1 met (verified manually at milestone close)
</success_criteria>

<output>
After completion, create `.planning/phases/06-paper-replication-verification/06-01-SUMMARY.md`
</output>
</content>
</invoke>
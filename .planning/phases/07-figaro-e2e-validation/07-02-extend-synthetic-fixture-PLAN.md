---
phase: 07-figaro-e2e-validation
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv
  - inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
  - tests/testthat/test-figaro.R
autonomous: true
requirements:
  - FIG-E2E-02
tags:
  - testing
  - fixtures
  - figaro

must_haves:
  truths:
    - "The two synthetic FIGARO CSVs under inst/extdata/figaro-sample/ cover 8 real FIGARO A*64 codes across 4 NACE sections and 3 real ISO country codes (DE/FR/IT)"
    - "Synthetic supply values are diagonal-dominant (diag 1000, off-diag 10-80) so Leontief inversion converges"
    - "Combined CSV size is ≤ 50 KB (D-7.5 budget)"
    - "All 46 existing test-figaro.R tests still pass against the extended fixture"
    - "Value-baked assertions at lines 16, 20, 25, 29-31, 88, 102, 118, 119 are updated to match the new fixture without weakening intent"
    - "The fixture preserves at least one B2A3G primary-input row, one FIGW1 row, and one cross-country (REP != PAR) row — per RESEARCH § Extended Synthetic Fixture Design"
  artifacts:
    - path: "inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv"
      provides: "Extended synthetic FIGARO supply flatfile — 3 countries × 8 CPA × 8 industries"
      contains: "CPA_A01"
    - path: "inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv"
      provides: "Extended synthetic FIGARO use flatfile — matching shape + FD + FIGW1 + B2A3G rows"
      contains: "FIGW1"
    - path: "tests/testthat/test-figaro.R"
      provides: "Updated 46-test suite with value-baked assertions recomputed against the extended fixture"
      contains: "A01"
  key_links:
    - from: "tests/testthat/test-figaro.R"
      to: "inst/extdata/figaro-sample/"
      via: "system.file() + read_figaro()"
      pattern: "figaro-sample"
    - from: "inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv"
      to: "read_figaro() CPA column"
      via: "CPA_ prefix stripping in R/import.R:253"
      pattern: "CPA_(A01|A03|C10T12|C13T15|C26|F|G46|G47)"
---

<objective>
Replace the thin 3-CPA × 3-industry × 2-country synthetic FIGARO fixture
with an extended 8-CPA × 8-industry × 3-country fixture using real
FIGARO A*64 codes and real ISO-2 country codes, and update every
value-baked assertion in `test-figaro.R` so the existing 46-test suite
stays green. The extended fixture becomes the input that FIG-E2E-02
(plan 07-03) asserts against.

Purpose: D-7.5 mandates a richer fixture so `build_matrices → compute_sube`
exercises a non-degenerate Leontief inversion on every CRAN/CI build.
The current REP1/REP2 × P01/P02/P03 × I01/I02/I03 fixture is too thin.
The extended version uses domain-real codes so the vignette (plan 07-05)
can copy-paste live examples.

Output: two rewritten CSVs under `inst/extdata/figaro-sample/` and a
refactored `test-figaro.R` whose 46 tests all pass against the new data.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md
@.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md
@.planning/phases/07-figaro-e2e-validation/07-VALIDATION.md

# Source referenced during execution
@R/import.R
@tests/testthat/test-figaro.R
@inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv
@inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
</context>

<interfaces>
<!-- FIGARO flatfile canonical header (verified from on-disk fixture + R/import.R:237) -->
Supply CSV header: `icsupRow,icsupCol,refArea,rowPi,counterpartArea,colPi,obsValue`
Use CSV header:    `icuseRow,icuseCol,refArea,rowPi,counterpartArea,colPi,obsValue`

<!-- read_figaro() transformations (R/import.R:234-258): -->
<!-- - rowPi must start with "CPA_" or the row is dropped (D-19 primary-input filter) -->
<!-- - CPA column in output = substring(rowPi, 5) -> strips the "CPA_" prefix -->
<!-- - VAR column in output = colPi pass-through -->
<!-- - For USE file: rows with colPi in c("P3_S13","P3_S14","P3_S15","P51G","P5M") aggregate to VAR="FU_bas" per (REP, PAR, CPA) -->
<!-- - FIGW1 (rest-of-world-1) is a real country code, preserved in output -->

<!-- Per RESEARCH § Open Item 4: Selected 8 codes across 4 NACE sections -->
CPA codes (used as both product codes and industry codes per D-7.1 equivalence):
  `A01`    (NACE section A)
  `A03`    (NACE section A)
  `C10T12` (NACE section C)
  `C13T15` (NACE section C)
  `C26`    (NACE section C)
  `F`      (NACE section F)
  `G46`    (NACE section G)
  `G47`    (NACE section G)
→ 4 aggregated NACE-section rows (A, C, F, G) after `substr(CPA, 1, 1)` aggregation

Countries (refArea values): `DE`, `FR`, `IT`

FD codes to preserve (use file): `P3_S13`, `P3_S14`, `P3_S15`, `P51G`, `P5M`
Special rows to preserve:
  - at least one `B2A3G` primary-input row (use file; dropped by read_figaro but presence tested at FIG-02/D-19)
  - at least one `FIGW1` row (use file — REP or counterpartArea == "FIGW1")
  - at least one cross-country row (REP != counterpartArea) in supply

<!-- Value plan (RESEARCH § Extended Synthetic Fixture Design, diagonal-dominant): -->
<!-- Supply: diagonal cell = 1000; off-diagonal cell = 10..80 (value varies by position) -->
<!-- Use: diagonal cell = 100; off-diagonal cell = 1..8 -->
<!-- FD: per-code per-country values from {2, 3, 4, 5, 6} (reuses existing fixture's FD scheme) -->

<!-- Size budget: ≤ 50 KB combined (D-7.5) -->
<!-- Strategy (RESEARCH § Open Item 4): domestic supply (REP==PAR) for all 3 countries × 8×8 = 192 rows, -->
<!-- plus one inter-country row per country-pair direction (6 rows), -->
<!-- ≈ 198 supply rows ≈ 12 KB. Use file similar + FD block ≈ 16 KB. Combined ~30 KB. -->

<!-- Existing value-baked assertions to UPDATE (tests/testthat/test-figaro.R): -->
Line 16:    cpa_map$CPA = c("P01","P02","P03") → c("A01","A03","C10T12","C13T15","C26","F","G46","G47")
Line 17:    cpa_map$CPAagg = c("PX","PX","PY") → substr(cpa, 1, 1) i.e. c("A","A","C","C","C","F","G","G")
Line 20:    ind_map$NACE = c("I01","I02","I03") → same 8 real codes as cpa_map$CPA (D-7.1 equivalence)
Line 21:    ind_map$INDagg → same section letters as cpa_map$CPAagg
Line 25:    inputs$REP = c("REP1","REP1","REP2","REP2") → c("DE","DE","DE","DE","FR","FR","FR","FR","IT","IT","IT","IT")
Line 26:    inputs$INDUSTRY = c("IX","IY","IX","IY") → repeat c("A","C","F","G") per REP (4 aggregated industries × 3 countries = 12 rows)
Lines 27-31: inputs GO/VA/EMP/CO2 arrays → resize to length 12, values picked so ratios are sane
Line 88:    `expect_true(all(out$CPA %in% c("P01","P02","P03")))` → `c("A01","A03","C10T12","C13T15","C26","F","G46","G47")`
Line 102:   same expression, same replacement
Line 118:   `expect_equal(nrow(fu_rows), 6L)` → recompute from new fixture: 8 CPAs × 3 REPs = 24L (if every (REP, CPA) pair has FD rows)
Line 119:   `expect_equal(sum(fu_rows$VALUE), 120)` → recompute sum from the chosen FD values
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Write scripts/build_figaro_sample.R (fixture generator) and regenerate both CSVs</name>
  <files>
    scripts/build_figaro_sample.R,
    inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv,
    inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv
  </files>
  <action>
    Per D-7.5 + RESEARCH § Extended Synthetic Fixture Design / Open Item 4.

    Write a committed, reproducible generator script at
    `scripts/build_figaro_sample.R` that assembles both fixture CSVs from a
    single parameter block. This lets the executor re-derive the fixture if
    the value scheme ever needs adjustment, and documents the fixture's
    provenance inside the repo.

    Generator structure:

    ```r
    # scripts/build_figaro_sample.R
    # Regenerates inst/extdata/figaro-sample/flatfile_eu-ic-*_sample.csv
    # per Phase 7 D-7.5. Run from repo root: Rscript scripts/build_figaro_sample.R
    # The output is committed to git; re-running should produce byte-identical CSVs.

    library(data.table)

    # --- Parameters (match 07-02-PLAN interfaces) -----------------------------
    cpa_codes <- c("A01", "A03", "C10T12", "C13T15", "C26", "F", "G46", "G47")
    countries <- c("DE", "FR", "IT")
    fd_codes <- c("P3_S13", "P3_S14", "P3_S15", "P51G", "P5M")
    fd_values <- c(P3_S13 = 2, P3_S14 = 3, P3_S15 = 4, P51G = 5, P5M = 6)

    # --- Helper: canonical row string for rowPi / colPi -----------------------
    cpa_prefix <- function(code) paste0("CPA_", code)

    # --- Supply rows (domestic for all countries + one inter-country per pair) ---
    supply_rows <- list()
    for (rep in countries) {
      for (i in seq_along(cpa_codes)) {
        cpa <- cpa_codes[i]
        for (j in seq_along(cpa_codes)) {
          ind <- cpa_codes[j]
          # Diagonal dominance: diag cell 1000, off-diag 10..80 (cycling by position)
          val <- if (i == j) 1000 else 10 * ((abs(i - j) %% 8) + 1)
          supply_rows[[length(supply_rows) + 1]] <- list(
            icsupRow = paste(rep, cpa_prefix(cpa), sep = "_"),
            icsupCol = paste(rep, ind, sep = "_"),
            refArea = rep, rowPi = cpa_prefix(cpa),
            counterpartArea = rep, colPi = ind,
            obsValue = val
          )
        }
      }
    }
    # Inter-country supply (one row per ordered pair, small values) --- ensures REP != PAR coverage
    for (a_rep in countries) {
      for (a_par in setdiff(countries, a_rep)) {
        supply_rows[[length(supply_rows) + 1]] <- list(
          icsupRow = paste(a_rep, cpa_prefix("A01"), sep = "_"),
          icsupCol = paste(a_par, "A01", sep = "_"),
          refArea = a_rep, rowPi = cpa_prefix("A01"),
          counterpartArea = a_par, colPi = "A01",
          obsValue = 5
        )
      }
    }

    supply_dt <- rbindlist(supply_rows)
    setcolorder(supply_dt,
      c("icsupRow", "icsupCol", "refArea", "rowPi", "counterpartArea", "colPi", "obsValue"))

    # --- Use rows (domestic inter-industry + FD block + B2A3G + FIGW1) --------
    use_rows <- list()
    for (rep in countries) {
      for (i in seq_along(cpa_codes)) {
        cpa <- cpa_codes[i]
        for (j in seq_along(cpa_codes)) {
          ind <- cpa_codes[j]
          # Diagonal dominance (smaller scale than supply): diag 100, off-diag 1..8
          val <- if (i == j) 100 else ((abs(i - j) %% 8) + 1)
          use_rows[[length(use_rows) + 1]] <- list(
            icuseRow = paste(rep, cpa_prefix(cpa), sep = "_"),
            icuseCol = paste(rep, ind, sep = "_"),
            refArea = rep, rowPi = cpa_prefix(cpa),
            counterpartArea = rep, colPi = ind,
            obsValue = val
          )
        }
      }
    }
    # FD block: per (REP, CPA) × each of 5 FD codes, value from fd_values
    for (rep in countries) {
      for (cpa in cpa_codes) {
        for (fd in fd_codes) {
          use_rows[[length(use_rows) + 1]] <- list(
            icuseRow = paste(rep, cpa_prefix(cpa), sep = "_"),
            icuseCol = paste(rep, fd, sep = "_"),
            refArea = rep, rowPi = cpa_prefix(cpa),
            counterpartArea = rep, colPi = fd,
            obsValue = fd_values[[fd]]
          )
        }
      }
    }
    # B2A3G primary-input row (1 per country × 1 CPA, small value — dropped by read_figaro
    # at import per D-19; but presence needed so line 98-99 of test-figaro.R stays meaningful
    # and cannot regress to "vacuously true")
    for (rep in countries) {
      use_rows[[length(use_rows) + 1]] <- list(
        icuseRow = paste(rep, "B2A3G", sep = "_"),
        icuseCol = paste(rep, "A01", sep = "_"),
        refArea = rep, rowPi = "B2A3G",
        counterpartArea = rep, colPi = "A01",
        obsValue = 50
      )
    }
    # FIGW1 row (rest-of-world) — preserved per D-21. Use refArea = "FIGW1" for one row.
    use_rows[[length(use_rows) + 1]] <- list(
      icuseRow = paste("FIGW1", cpa_prefix("A01"), sep = "_"),
      icuseCol = paste("DE", "A01", sep = "_"),
      refArea = "FIGW1", rowPi = cpa_prefix("A01"),
      counterpartArea = "DE", colPi = "A01",
      obsValue = 3
    )

    use_dt <- rbindlist(use_rows)
    setcolorder(use_dt,
      c("icuseRow", "icuseCol", "refArea", "rowPi", "counterpartArea", "colPi", "obsValue"))

    # --- Write CSVs (no quoting, no scientific notation for stable diffs) -----
    out_dir <- file.path("inst", "extdata", "figaro-sample")
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    fwrite(supply_dt, file.path(out_dir, "flatfile_eu-ic-supply_sample.csv"),
           quote = FALSE, scipen = 50)
    fwrite(use_dt,    file.path(out_dir, "flatfile_eu-ic-use_sample.csv"),
           quote = FALSE, scipen = 50)

    cat("Wrote:\n",
        "  supply rows:", nrow(supply_dt), "\n",
        "  use rows:   ", nrow(use_dt),    "\n",
        "  sizes (KB): ",
        round(file.size(file.path(out_dir, "flatfile_eu-ic-supply_sample.csv")) / 1024, 1),
        "+",
        round(file.size(file.path(out_dir, "flatfile_eu-ic-use_sample.csv"))    / 1024, 1),
        "\n")
    ```

    Run the script from repo root:
    `Rscript scripts/build_figaro_sample.R`

    Verify combined file size is ≤ 50 KB. If it exceeds, adjust by dropping
    the inter-country supply rows OR shrinking the off-diagonal value width
    (both CSV sizes are value-digit-count-sensitive).
  </action>
  <verify>
    <automated>Rscript scripts/build_figaro_sample.R && Rscript -e 'sz <- sum(file.size(list.files("inst/extdata/figaro-sample", full.names = TRUE))); stopifnot(sz <= 50 * 1024); cat("combined size:", round(sz/1024, 1), "KB\n")'</automated>
  </verify>
  <done>
    `scripts/build_figaro_sample.R` exists and is idempotent (re-running produces byte-identical CSVs); `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` and `flatfile_eu-ic-use_sample.csv` exist with the new content; combined size ≤ 50 KB; the two files contain the 8 real A*64 codes, 3 ISO-2 countries, one B2A3G primary-input row, one FIGW1 row, and at least 6 cross-country (REP != counterpartArea) supply rows.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Update test-figaro.R value-baked assertions to match extended fixture</name>
  <files>tests/testthat/test-figaro.R</files>
  <behavior>
    - `make_tiny_figaro_maps()` returns cpa_map/ind_map/inputs consistent with the 8 real CPA codes and 3 ISO-2 countries
    - `expect_true(all(out$CPA %in% <code list>))` at lines 88 and 102 uses the new 8-code vector
    - `expect_equal(nrow(fu_rows), ...)` and `expect_equal(sum(fu_rows$VALUE), ...)` at lines 118-119 match the new FD block (3 countries × 8 CPAs = 24 FU_bas rows; sum = 24 × (2+3+4+5+6) = 480)
    - The FIG-04 integration test (line 175-190) runs green end-to-end on the extended fixture (build_matrices + compute_sube succeed with non-singular Leontief inversion)
    - All 46 tests pass (zero failures, zero errors)
  </behavior>
  <action>
    Per D-7.5 + RESEARCH § Existing Test Breakage Analysis.

    Update each value-baked assertion in `tests/testthat/test-figaro.R`.
    Do NOT weaken assertion semantics — recompute expected values from the
    extended fixture, don't replace with shape-only checks.

    Edits:

    1. **Lines 12-33** (`make_tiny_figaro_maps()` helper): rewrite to use the
       8 real CPA codes, section-letter aggregation, and 3 ISO-2 countries.
       Critical: `inputs$INDUSTRY` must match the aggregated INDagg codes
       (section letters `A`, `C`, `F`, `G`) because `compute_sube()` matches
       on the aggregated industry column. Not the raw CPA codes.

       ```r
       make_tiny_figaro_maps <- function() {
         # Matches the extended fixture: 8 real FIGARO A*64 codes, 3 countries,
         # section-letter aggregation (D-7.1 one-liner).
         cpa_codes <- c("A01", "A03", "C10T12", "C13T15", "C26", "F", "G46", "G47")
         section  <- substr(cpa_codes, 1L, 1L)  # A,A,C,C,C,F,G,G

         cpa_map <- data.table::data.table(
           CPA = cpa_codes,
           CPAagg = section
         )
         ind_map <- data.table::data.table(
           NACE = cpa_codes,   # exercises NACE-synonym routing via .coerce_map() (FIG-03)
           INDagg = section
         )
         # inputs covers 3 countries × 4 aggregated industries (A, C, F, G).
         # GO/VA/EMP/CO2 picked so ratios are sane and no metric is zero.
         countries <- c("DE", "FR", "IT")
         agg_inds  <- c("A", "C", "F", "G")
         inputs <- data.table::CJ(YEAR = 2023L, REP = countries, INDUSTRY = agg_inds,
                                  sorted = FALSE)
         inputs[, GO  := seq(100, by = 10,  length.out = nrow(inputs))]
         inputs[, VA  := GO * 0.4]
         inputs[, EMP := GO * 0.1]
         inputs[, CO2 := GO * 0.05]
         list(cpa_map = cpa_map, ind_map = ind_map, inputs = inputs)
       }
       ```

    2. **Line 88** (inside `test_that("read_figaro strips CPA_ prefix ...")`):
       Replace
       ```r
       expect_true(all(out$CPA %in% c("P01", "P02", "P03")))
       ```
       with
       ```r
       expect_true(all(out$CPA %in% c("A01", "A03", "C10T12", "C13T15",
                                     "C26", "F", "G46", "G47")))
       ```

    3. **Line 102** (inside `test_that("read_figaro filters primary-input rows ...")`):
       Same replacement as line 88.

    4. **Lines 118-119** (inside FU_bas aggregation test): recompute from the
       new fixture's FD block (3 countries × 8 CPAs = 24 (REP, CPA) pairs,
       each summing 5 FD codes = 2+3+4+5+6 = 20 per pair, total = 24 × 20 = 480):
       ```r
       fu_rows <- use_rows[VAR == "FU_bas"]
       expect_equal(nrow(fu_rows), 24L)
       expect_equal(sum(fu_rows$VALUE), 480)
       ```
       Also update the inline comment on lines 114-116 to reflect the new shape.

    5. **Line 175-190** (FIG-04 integration test): no assertion edits — the
       test already uses `make_tiny_figaro_maps()` (updated in edit 1) and
       asserts `nrow(result$summary) >= 1`. Confirm it still passes on the
       extended fixture.

    Do NOT modify:
    - Lines 35-51 (canonical columns / shape-only)
    - Lines 53-59 (year validation)
    - Lines 61-81 (path errors — tempdir, not fixture)
    - Lines 122-127 (FIGW1 preservation — fixture still has FIGW1 row)
    - Lines 129-144 (final_demand_vars subset — relative assertion)
    - Lines 146-166 (.coerce_map NACE/NACE_R2 — uses `sube_example_data`, not the fixture)
    - Lines 168-173 (fixture file existence)
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test(filter = "figaro", reporter = testthat::StopReporter())'</automated>
  </verify>
  <done>
    `devtools::test(filter = "figaro")` shows 46 passing tests, 0 failures, 0 errors, 0 skipped; value-baked assertions at lines 88, 102, 118, 119 reference the new code/value vectors; `make_tiny_figaro_maps()` returns maps consistent with the extended fixture; the FIG-04 integration test (line 175-190) exercises the full `build_matrices → compute_sube` chain on the extended fixture without a singular Leontief inversion.
  </done>
</task>

<task type="auto">
  <name>Task 3: Full-suite regression — confirm zero unrelated failures from the fixture swap</name>
  <files>(verification only — no file writes)</files>
  <action>
    Run `Rscript -e 'devtools::test()'` and confirm:

    1. `test-figaro` — 46 green (from task 2)
    2. `test-workflow`, `test-compute`, `test-matrices`, etc. — unchanged counts, zero new failures
    3. Total suite count is ≥ 102 (v1.1 baseline) — fixture swap must not silently drop tests

    If any test outside `test-figaro.R` fails, the fixture extension leaked into
    a path it shouldn't have. Most likely suspect: a test sourcing the fixture
    CSVs directly rather than through `read_figaro()` with a hardcoded row count.
    Grep the codebase: `grep -rn "figaro-sample" R/ tests/` — if any non-helper
    call-site assumes 3 CPAs, update it explicitly in this task.
  </action>
  <verify>
    <automated>Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'</automated>
  </verify>
  <done>
    Full suite (`devtools::test()`) reports zero failures and zero errors across all test files; extended fixture is production-ready for plan 07-03 (FIG-E2E-02 contract block) and plan 07-04 (FIG-E2E-01 gated test) to consume.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A — this plan edits bundled synthetic test data and test-file assertion
values inside the package test suite. No external input, no user-facing
authentication surface, no network I/O. The synthetic fixture is shipped in
`inst/extdata/` and read only by tests and the vignette's copy-pasteable
examples (`eval = FALSE`).

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-02 | N/A | inst/extdata/figaro-sample/*.csv | accept | Synthetic test fixture; no user-supplied data, no PII, no secrets. Diagonal-dominant numeric values chosen to exercise Leontief inversion stability — semantically a test of library arithmetic, not a security-relevant input. |
</threat_model>

<verification>
- `Rscript scripts/build_figaro_sample.R` produces two CSVs, combined size ≤ 50 KB
- `devtools::test(filter = "figaro")` — 46 green
- `devtools::test()` full suite — zero regressions
- Fixture contains: 3 ISO-2 countries, 8 real A*64 codes, 4 NACE sections, ≥1 B2A3G row, ≥1 FIGW1 row, ≥1 cross-country supply row
</verification>

<success_criteria>
- [ ] `scripts/build_figaro_sample.R` exists and is idempotent
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-supply_sample.csv` regenerated, uses real codes
- [ ] `inst/extdata/figaro-sample/flatfile_eu-ic-use_sample.csv` regenerated, includes FD + B2A3G + FIGW1
- [ ] Combined fixture size ≤ 50 KB
- [ ] `test-figaro.R` assertions at lines 16, 17, 20, 21, 25, 27-31, 88, 102, 118, 119 updated with recomputed expected values
- [ ] `make_tiny_figaro_maps()` uses the 8 real codes and 3 ISO-2 countries
- [ ] `devtools::test(filter = "figaro")` — 46 green
- [ ] `devtools::test()` full suite — zero failures
</success_criteria>

<output>
After completion, create `.planning/phases/07-figaro-e2e-validation/07-02-SUMMARY.md`
</output>

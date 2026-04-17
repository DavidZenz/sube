# Phase 11: Data Format Specification - Research

**Researched:** 2026-04-17
**Domain:** R vignette authoring — documentation-only expansion of `vignettes/data-preparation.Rmd`
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Expand existing `vignettes/data-preparation.Rmd` with new sections — do not create a new vignette or standalone reference file
- **D-02:** New sections go **before** existing content — spec first (canonical format, satellite vectors, synonyms, BYOD), then the existing workflow prep sections
- **D-03:** Phase 12 (VIG-02) will integrate this output directly since it's already in data-preparation.Rmd — no copy-paste step needed
- **D-04:** Use tabular summary format for canonical SUT columns: table with Column, Type, Semantics, Example columns — then a code block showing `sube_example_data("sut_data")` output as concrete reference
- **D-05:** Same tabular pattern for satellite vectors (GO, VA, EMP, CO2): table with name, type, what it measures, source — then `sube_example_data("inputs")` code block
- **D-06:** Step-by-step checklist format (not a worked reshape example): (1) identify columns, (2) rename/map to canonical, (3) melt wide→long if needed, (4) verify with `import_suts()`
- **D-07:** BYOD guide covers **both** SUT table preparation and satellite vector preparation (GO/VA/EMP/CO2 inputs)
- **D-08:** Inline synonym table placed directly after the canonical column definitions — not a separate reference section
- **D-09:** Document only what the code accepts today (`.coerce_map()` synonyms) — no aspirational flexibility or extensibility notes

### Claude's Discretion

- Exact wording, prose style, and section headings within the decided structure
- Whether to add cross-references to `?import_suts` or `?read_figaro` help pages
- How to phrase the transition between new spec sections and existing workflow sections

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FMT-01 | User can find a clear definition of each canonical SUT column (REP, PAR, CPA, VAR, VALUE, YEAR, TYPE) with semantics and examples | Column semantics verified from `R/import.R` lines 42-47 and example data; see Canonical Column Contract section |
| FMT-02 | User can find documentation of the satellite vector input contract (GO, VA, EMP, CO2) — what they are, where they come from, that they are researcher-supplied | Verified from `R/compute.R` lines 7-9 and `inst/extdata/sample/inputs.csv`; see Satellite Vector Contract section |
| FMT-03 | User can follow a "bring your own data" guide to reshape non-WIOD/FIGARO supply-use data into the canonical long format | Wide-to-long melting logic verified from `R/import.R` lines 50-83; see BYOD Guide section |
| FMT-04 | User can discover that column names are flexible (e.g. INDUSTRY/NACE/NACE_R2 all accepted) with documented synonyms | Synonym lists verified from `R/utils.R` lines 44-49; see Synonym Flexibility section |
</phase_requirements>

---

## Summary

Phase 11 is a pure documentation task. There is no new R code to write, no new functions to export, and no package-level changes. The entire deliverable is prose inserted into `vignettes/data-preparation.Rmd` before the existing content.

The canonical data contracts are already fully implemented and tested in the package. Research consisted of reading the source files identified in CONTEXT.md to extract the exact, authoritative information that needs to be documented. All claims below are verified directly against the source code and example data files.

**Primary recommendation:** Write the four new vignette sections as a single wave in one plan, following D-02 through D-09 exactly. There are no dependencies between sections and no risk of breaking existing tests.

---

## Canonical Column Contract (FMT-01)

Source: `R/import.R` line 43 and `inst/extdata/sample/sut_data.csv` [VERIFIED: codebase grep]

The seven canonical SUT columns, with semantics derived from how `import_suts()` and `read_figaro()` use each field:

| Column | R type | Semantics | Example value |
|--------|--------|-----------|---------------|
| REP | character | Reporting country — the economy whose supply-use table is being described | `"AAA"` |
| PAR | character | Partner country — the economy supplying or demanding the product. Equal to REP for the domestic block | `"AAA"` |
| CPA | character | Product code — identifies the good or service (CPA/NACE product classification) | `"P1"` |
| VAR | character | Industry or final-demand variable — identifies the column in the SUT (an industry code like `"I1"` or a final-demand code like `"FU_bas"`) | `"I1"`, `"FU_bas"` |
| VALUE | numeric | Cell value in the supply-use table, in the unit of the source data (typically millions of current-price currency units) | `10` |
| YEAR | integer | Reference year of the data | `2020` |
| TYPE | character | Table type: `"SUP"` for supply table, `"USE"` for use table | `"SUP"`, `"USE"` |

Live example output from `sube_example_data("sut_data")` (10 rows, 1 country, 1 year, 2 products, 2 industries + final demand):

```
   REP    PAR    CPA    VAR VALUE  YEAR   TYPE
   AAA    AAA     P1     I1    10  2020    SUP
   AAA    AAA     P1     I2     2  2020    SUP
   AAA    AAA     P2     I1     1  2020    SUP
   AAA    AAA     P2     I2     8  2020    SUP
   AAA    AAA     P1     I1     3  2020    USE
   AAA    AAA     P1     I2     1  2020    USE
   AAA    AAA     P1 FU_bas     6  2020    USE
   AAA    AAA     P2     I1     2  2020    USE
   AAA    AAA     P2     I2     2  2020    USE
   AAA    AAA     P2 FU_bas     5  2020    USE
```

Key observation: each row represents a single cell of the supply-use table. Supply and use tables are stacked in the same data frame, distinguished by TYPE. The domestic block is the subset where `REP == PAR`.

---

## Synonym Flexibility (FMT-04)

Source: `R/utils.R` lines 44-49 [VERIFIED: codebase read]

`.coerce_map()` is the function that accepts synonymous column names for mapping tables. `.standardize_names()` uppercases all column names first, so all synonym matching is case-insensitive in practice.

**Synonym groups (from `.coerce_map()`):**

| Canonical name | Accepted synonyms |
|----------------|-------------------|
| CPA | `CPA`, `CPA56`, `CPA_CODE` |
| CPAAGG | `CPAAGG`, `CPA_AGG`, `PRODUCT`, `PRODUCT_AGG` |
| VARS (industry column in ind_map) | `VARS`, `VAR`, `INDUSTRY`, `IND`, `CODE`, `NACE`, `NACE_R2` |
| INDAGG | `INDAGG`, `IND_AGG`, `INDUSTRY_AGG`, `SECTOR` |

**Scope of synonym resolution:** Synonyms apply to mapping table columns (`cpa_map`, `ind_map`) only — not to the 7 canonical SUT columns themselves. The SUT columns (REP, PAR, CPA, VAR, VALUE, YEAR, TYPE) are matched after uppercasing only. Source: `.standardize_names()` in `R/utils.R` lines 17-21 [VERIFIED: codebase read].

---

## Satellite Vector Contract (FMT-02)

Source: `R/compute.R` lines 7-9, 25-38 and `inst/extdata/sample/inputs.csv` [VERIFIED: codebase read]

The `inputs` table is researcher-supplied. It is not derived from the SUT data by the package; the researcher brings it from national accounts, statistical agencies, or their own calculations. `compute_sube()` requires it as a separate argument.

| Column | R type | What it measures | Required? | Source |
|--------|--------|-----------------|-----------|--------|
| YEAR | integer | Reference year | Yes | matches SUT YEAR values |
| REP | character | Country code | Yes | matches SUT REP values |
| INDUSTRY (or synonym) | character | Industry identifier | Yes | matches VAR codes in the SUT |
| GO | numeric | Gross output — total value of production by industry | Yes | researcher-supplied (e.g. national accounts) |
| VA | numeric | Value added — GDP contribution by industry | Optional | researcher-supplied |
| EMP | numeric | Employment — number of workers or hours by industry | Optional | researcher-supplied |
| CO2 | numeric | CO2 emissions by industry | Optional | researcher-supplied |

The industry identifier column accepts synonyms: `IND`, `INDUSTRY`, `INDUSTRIES`, `INDAGG` (checked in that order, first match wins). Source: `R/compute.R` lines 27-28 [VERIFIED: codebase read].

`GO` is the only metric required. `VA`, `EMP`, `CO2` are computed when present. If a metric listed in the `metrics` argument is absent from `inputs`, `compute_sube()` raises an error.

Live example output from `sube_example_data("inputs")`:

```
   YEAR    REP INDUSTRY    GO    VA   EMP   CO2
   2020    AAA      I01    12     4     3     2
   2020    AAA      I02     9     3     2     1
```

---

## BYOD Guide Structure (FMT-03)

Source: `R/import.R` lines 40-111 [VERIFIED: codebase read]

`import_suts()` supports two CSV formats automatically:

**Long format (already canonical):** File has all 7 columns (REP, PAR, CPA, VAR, VALUE, YEAR, TYPE). The function detects this and uses the file as-is (lines 44-47).

**Wide format:** File has 5 identity columns (REP, PAR, CPA, YEAR, TYPE) and industry codes as column headers. The function melts these to long using `data.table::melt()` (lines 50-83). WIOD-specific aggregate columns (`FU_BAS`, `DSUP_BAS`, etc.) are excluded from the melt or handled specially.

**BYOD checklist steps (per D-06 and D-07):**

*SUT table preparation:*
1. Identify which columns map to REP, PAR, CPA, YEAR, TYPE
2. Rename columns to canonical names (or let `import_suts()` uppercase them)
3. Decide: long format (7 columns including VAR and VALUE) or wide format (5 id columns + industry codes as headers)
4. If wide: ensure aggregate demand columns won't be melted as industries — either remove them or let `import_suts()` handle known WIOD aggregates
5. Verify with `import_suts()` — inspect output with `head()` and `str()`

*Satellite vector preparation:*
1. Identify GO column (gross output by industry, required)
2. Identify VA, EMP, CO2 columns if available (optional)
3. Ensure YEAR and REP columns are present and match values in SUT data
4. Ensure industry column is present (any of: IND, INDUSTRY, INDUSTRIES, INDAGG)
5. One row per (YEAR, REP, INDUSTRY) combination

---

## Architecture Patterns

### Target File Structure

The vignette is a single `.Rmd` file. New sections insert before existing content (D-02). Final structure:

```
vignettes/data-preparation.Rmd
├── [NEW] Canonical SUT format section (FMT-01)
│   ├── Column definition table
│   ├── Inline synonym table (FMT-04)
│   └── sube_example_data("sut_data") code chunk
├── [NEW] Satellite vector contract section (FMT-02)
│   ├── Column definition table
│   └── sube_example_data("inputs") code chunk
├── [NEW] Bring Your Own Data guide section (FMT-03)
│   ├── SUT checklist
│   └── Satellite vector checklist
├── [EXISTING] Supply-use data
├── [EXISTING] Mapping tables
├── [EXISTING] Input metrics
├── [EXISTING] Modeling table
└── [EXISTING] Recommended preparation strategy
```

### Vignette Code Chunk Pattern

Existing vignette uses live `eval = TRUE` code chunks (the file uses `library(sube)` with no gating). All new code chunks referencing `sube_example_data()` should be `eval = TRUE` — the example data is shipped in the package and available without researcher files. [VERIFIED: existing vignette header and chunks]

### Table Syntax

Existing vignette has no markdown tables — it uses plain prose and code chunks only. Phase 11 will introduce the first markdown tables in this vignette. Standard knitr/pandoc-flavored markdown table syntax (pipe tables) is appropriate. [VERIFIED: existing vignette read]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Displaying example data output | Custom table formatting | Live `sube_example_data()` code chunk with `eval = TRUE` |
| Synonym documentation | Manually listing from memory | Copy directly from `R/utils.R` `.coerce_map()` synonym lists |
| Column semantics | Inferring from function names | Read from `R/import.R` usage patterns and `R/compute.R` required-column checks |

---

## Common Pitfalls

### Pitfall 1: Scope creep into aspirational synonyms

**What goes wrong:** Documenting synonyms that do not yet exist in `.coerce_map()` (e.g. suggesting `NACE_R1` is accepted when it is not in the synonym list).
**Why it happens:** Developer intuition about "what should work" rather than what the code actually does.
**How to avoid:** Copy the synonym lists verbatim from `R/utils.R` lines 44-49. D-09 is explicit: document only what the code accepts today.
**Warning signs:** Any synonym not in the four `synonyms <- list(...)` entries in `.coerce_map()`.

### Pitfall 2: Confusing SUT column synonyms with mapping table synonyms

**What goes wrong:** Telling users that `NACE_R2` is a valid name for the `VAR` column in the SUT table.
**Why it happens:** `.coerce_map()` accepts `NACE_R2` as an industry column in the `ind_map`, but this does not extend to the SUT's `VAR` column.
**How to avoid:** The synonym table caption must clarify the scope: synonyms apply to mapping table columns only.
**Warning signs:** Phrasing like "column VAR can also be named NACE_R2 in your SUT file."

### Pitfall 3: Stating GO/VA/EMP/CO2 are derived from SUT data

**What goes wrong:** Implying that `compute_sube()` calculates satellite inputs from the supply-use tables.
**Why it happens:** Reasonable inference from the name "compute_sube".
**How to avoid:** FMT-02 must explicitly state these are researcher-supplied from national accounts or other external sources.
**Warning signs:** Phrases like "the package computes GO from the supply matrix."

### Pitfall 4: Placing new sections after existing content

**What goes wrong:** New spec sections appear below the "Supply-use data" heading instead of above it, violating D-02.
**Why it happens:** Appending is easier than inserting.
**How to avoid:** The plan must explicitly note the insertion point: new content inserts before the `## Supply-use data` heading (line 36 of the current vignette).
**Warning signs:** Draft opens with "Supply-use data" as the first `##` heading.

---

## Code Examples

Verified live examples from installed package:

### Canonical SUT table (sube_example_data)
```r
# Source: inst/extdata/sample/sut_data.csv [VERIFIED: codebase]
sube_example_data("sut_data")
#    REP    PAR    CPA    VAR VALUE  YEAR   TYPE
#    AAA    AAA     P1     I1    10  2020    SUP
#    AAA    AAA     P1     I2     2  2020    SUP
#    AAA    AAA     P2     I1     1  2020    SUP
#    AAA    AAA     P2     I2     8  2020    SUP
#    AAA    AAA     P1     I1     3  2020    USE
#    AAA    AAA     P1     I2     1  2020    USE
#    AAA    AAA     P1 FU_bas     6  2020    USE
#    AAA    AAA     P2     I1     2  2020    USE
#    AAA    AAA     P2     I2     2  2020    USE
#    AAA    AAA     P2 FU_bas     5  2020    USE
```

### Satellite vector inputs (sube_example_data)
```r
# Source: inst/extdata/sample/inputs.csv [VERIFIED: codebase]
sube_example_data("inputs")
#    YEAR    REP INDUSTRY    GO    VA   EMP   CO2
#    2020    AAA      I01    12     4     3     2
#    2020    AAA      I02     9     3     2     1
```

### .coerce_map() synonym lists (verbatim)
```r
# Source: R/utils.R lines 44-49 [VERIFIED: codebase read]
synonyms <- list(
  cpa     = c("CPA", "CPA56", "CPA_CODE"),
  cpa_agg = c("CPAAGG", "CPA_AGG", "PRODUCT", "PRODUCT_AGG"),
  vars    = c("VARS", "VAR", "INDUSTRY", "IND", "CODE", "NACE", "NACE_R2"),
  ind_agg = c("INDAGG", "IND_AGG", "INDUSTRY_AGG", "SECTOR")
)
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat (version from DESCRIPTION) |
| Config file | `tests/testthat/` |
| Quick run command | `Rscript -e "testthat::test_file('tests/testthat/test-workflow.R')"` |
| Full suite command | `Rscript -e "devtools::test()"` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Notes |
|--------|----------|-----------|-------|
| FMT-01 | Canonical column definitions visible in vignette | manual-only | Documentation content; not machine-testable |
| FMT-02 | Satellite vector contract documented | manual-only | Documentation content; not machine-testable |
| FMT-03 | BYOD guide present and accurate | manual-only | Prose accuracy; not machine-testable |
| FMT-04 | Synonym table correct | manual-only | Verified against source; accuracy is human-review |

**Note:** Phase 11 is documentation-only. There is no new R code, no new functions, and no new test surface. All four requirements are satisfied by prose accuracy in the vignette, which is reviewed by reading rather than automated test. The existing test suite (`devtools::test()`) must remain green after the vignette edits — but no new test files are needed.

### Sampling Rate

- **Per task commit:** `Rscript -e "devtools::check(vignettes = FALSE)"` (confirm vignette knits without error)
- **Phase gate:** `Rscript -e "devtools::test()"` full suite green before `/gsd-verify-work`

### Wave 0 Gaps

None — no new test infrastructure needed.

---

## Environment Availability

Phase 11 is a documentation-only change to an `.Rmd` vignette. The only dependency is R with the `sube` package installed.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R | Vignette authoring | Yes | verified (Rscript executed successfully above) | — |
| sube package | `sube_example_data()` code chunks | Yes | installed (example data rendered) | — |
| knitr | Vignette rendering | Yes (part of devtools workflow) | — | — |

No missing dependencies.

---

## Assumptions Log

No assumed claims — all factual claims in this research were verified by direct codebase inspection.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims verified.** No user confirmation needed before planning.

---

## Open Questions

None identified. The phase scope is tightly bounded by D-01 through D-09, and all source material is available in the codebase.

---

## Security Domain

Not applicable. This phase makes no changes to R code, no changes to authentication or data handling, and introduces no new attack surface. Pure documentation edit.

---

## Sources

### Primary (HIGH confidence)
- `R/import.R` lines 42-47 — canonical column list `REP, PAR, CPA, VAR, VALUE, YEAR, TYPE`
- `R/import.R` lines 40-111 — wide/long detection and melt logic used by BYOD guide
- `R/utils.R` lines 17-21 — `.standardize_names()` (uppercase only, no synonym resolution for SUT columns)
- `R/utils.R` lines 44-49 — `.coerce_map()` synonym lists (exact, authoritative)
- `R/compute.R` lines 7-9, 25-38 — satellite vector requirements (YEAR, REP, INDUSTRY, GO mandatory; VA/EMP/CO2 optional)
- `inst/extdata/sample/sut_data.csv` — live example SUT data (10 rows, verified by execution)
- `inst/extdata/sample/inputs.csv` — live example inputs data (2 rows, verified by execution)
- `vignettes/data-preparation.Rmd` — existing vignette (target file, read in full)

---

## Metadata

**Confidence breakdown:**
- Canonical columns: HIGH — read directly from source code and verified by execution
- Synonym lists: HIGH — copied verbatim from `.coerce_map()` source
- Satellite contract: HIGH — read from `compute_sube()` parameter docs and required-column checks
- BYOD logic: HIGH — read from `import_suts()` CSV branch implementation

**Research date:** 2026-04-17
**Valid until:** Stable indefinitely — no external dependencies, all findings from local codebase

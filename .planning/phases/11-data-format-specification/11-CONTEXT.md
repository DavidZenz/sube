# Phase 11: Data Format Specification - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Define authoritative documentation of the canonical long-format SUT contract within the existing `data-preparation.Rmd` vignette. Covers column semantics (FMT-01), satellite vector contract (FMT-02), BYOD guide (FMT-03), and synonym flexibility (FMT-04). No new R code or exported functions — documentation only.

</domain>

<decisions>
## Implementation Decisions

### Document Location
- **D-01:** Expand existing `vignettes/data-preparation.Rmd` with new sections — do not create a new vignette or standalone reference file
- **D-02:** New sections go **before** existing content — spec first (canonical format, satellite vectors, synonyms, BYOD), then the existing workflow prep sections
- **D-03:** Phase 12 (VIG-02) will integrate this output directly since it's already in data-preparation.Rmd — no copy-paste step needed

### Example Depth
- **D-04:** Use tabular summary format for canonical SUT columns: table with Column, Type, Semantics, Example columns — then a code block showing `sube_example_data("sut_data")` output as concrete reference
- **D-05:** Same tabular pattern for satellite vectors (GO, VA, EMP, CO2): table with name, type, what it measures, source — then `sube_example_data("inputs")` code block

### BYOD Guide Scope
- **D-06:** Step-by-step checklist format (not a worked reshape example): (1) identify columns, (2) rename/map to canonical, (3) melt wide→long if needed, (4) verify with `import_suts()`
- **D-07:** BYOD guide covers **both** SUT table preparation and satellite vector preparation (GO/VA/EMP/CO2 inputs)

### Synonym Presentation
- **D-08:** Inline synonym table placed directly after the canonical column definitions — not a separate reference section
- **D-09:** Document only what the code accepts today (`.coerce_map()` synonyms) — no aspirational flexibility or extensibility notes

### Claude's Discretion
- Exact wording, prose style, and section headings within the decided structure
- Whether to add cross-references to `?import_suts` or `?read_figaro` help pages
- How to phrase the transition between new spec sections and existing workflow sections

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing vignette (target file)
- `vignettes/data-preparation.Rmd` — Current content to expand; new sections insert before existing content

### Source code defining the contract
- `R/import.R` lines 42-47 — Canonical column list: `REP, PAR, CPA, VAR, VALUE, YEAR, TYPE`
- `R/import.R` lines 128+ — `read_figaro()` canonical shape documentation
- `R/utils.R` lines 17-21 — `.standardize_names()` implementation (uppercases all columns)
- `R/utils.R` lines 44-49 — `.coerce_map()` synonym lists (CPA, VAR, CPAAGG, INDAGG)

### Example data
- `R/package.R` or `sube_example_data()` — Shipped example objects: `sut_data`, `inputs`, `cpa_map`, `ind_map`, `model_data`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sube_example_data("sut_data")` — shipped example with all 7 canonical columns; use as live proof in vignette
- `sube_example_data("inputs")` — shipped example with GO/VA/EMP/CO2 satellite vectors
- `sube_example_data("cpa_map")` and `sube_example_data("ind_map")` — mapping table examples

### Established Patterns
- `.standardize_names()` just uppercases — no synonym resolution for SUT columns themselves
- `.coerce_map()` handles synonym resolution for mapping table columns only (CPA, VAR families)
- `import_suts()` accepts both wide and long CSV formats, plus WIOD workbooks
- `read_figaro()` handles FIGARO-specific reshaping (CPA prefix strip, FD aggregation)

### Integration Points
- `data-preparation.Rmd` is the target file — all new content goes here
- Existing sections (Supply-use data, Mapping tables, Input metrics, Modeling table) remain after the new spec sections
- pkgdown article grouping (Phase 13) will pick up the expanded vignette automatically

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches within the decided structure.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 11-data-format-specification*
*Context gathered: 2026-04-17*

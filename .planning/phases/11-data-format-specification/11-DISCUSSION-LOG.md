# Phase 11: Data Format Specification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 11-data-format-specification
**Areas discussed:** Document location, Example depth, BYOD guide scope, Synonym presentation

---

## Document Location

| Option | Description | Selected |
|--------|-------------|----------|
| Expand data-preparation.Rmd | Grow existing vignette into authoritative format reference. Phase 12 already plans to integrate Phase 11 output here (VIG-02). | ✓ |
| New vignette: data-format-spec.Rmd | Standalone reference vignette. Keeps data-preparation.Rmd focused on workflow prep. | |
| inst/references/ Rmd file | Non-vignette reference document. Won't appear in pkgdown articles by default. | |

**User's choice:** Expand data-preparation.Rmd
**Notes:** Avoids copy-paste step for Phase 12 (VIG-02) integration.

### Follow-up: Section ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Before — spec first, then workflow | Column definitions and format contract first, then existing prep workflow. Reader learns what the format IS before how to produce it. | ✓ |
| After — workflow first, then spec | Keep existing prep flow at top, spec sections as appendix. | |

**User's choice:** Before — spec first, then workflow

---

## Example Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Tabular summary + shipped data | Table with Column/Type/Semantics/Example, then sube_example_data() code block as concrete reference. | ✓ |
| Full annotated walkthrough | Each column gets own subsection with 3-5 sentences on semantics, edge cases, WIOD/FIGARO mapping. | |
| Minimal inline | Bullet list with column names and one-line descriptions. | |

**User's choice:** Tabular summary + shipped data
**Notes:** Same tabular pattern applies to satellite vectors (GO/VA/EMP/CO2).

### Follow-up: Satellite vector format

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same pattern | Consistent table format for satellite vectors, plus sube_example_data('inputs') code block. | ✓ |
| More narrative | More explanation per vector with typical data sources. | |

**User's choice:** Yes, same pattern

---

## BYOD Guide Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Step-by-step checklist | Numbered steps: identify columns, rename/map, melt if needed, verify with import_suts(). No fake dataset. | ✓ |
| Worked reshape example | Create hypothetical third-party SUT and walk through full reshape in R code. | |
| Both checklist + example | Checklist for quick reference plus worked example. | |

**User's choice:** Step-by-step checklist

### Follow-up: Satellite vector coverage in BYOD

| Option | Description | Selected |
|--------|-------------|----------|
| SUT table only | BYOD focuses on SUT data only. Satellite vectors covered in Input metrics section. | |
| Both SUT + satellites | Include satellite vector preparation alongside SUT reshape. | ✓ |

**User's choice:** Both SUT + satellites

---

## Synonym Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Inline table in the spec | Synonym table right after canonical column definitions. Shows alternative names the package accepts. | ✓ |
| Separate reference section | Synonym table in its own section at end of vignette. | |
| Both inline + ?import_suts help | Table in vignette AND mention in roxygen help page. | |

**User's choice:** Inline table in the spec

### Follow-up: Scope of synonym documentation

| Option | Description | Selected |
|--------|-------------|----------|
| Current code only | Document exactly what .coerce_map() and .standardize_names() handle today. | ✓ |
| Current + extensibility note | Current synonyms plus note about extending via package source. | |

**User's choice:** Current code only

---

## Claude's Discretion

- Exact wording, prose style, and section headings
- Whether to add cross-references to help pages
- Transition phrasing between new and existing sections

## Deferred Ideas

None — discussion stayed within phase scope.

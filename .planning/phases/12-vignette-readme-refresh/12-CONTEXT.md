# Phase 12: Vignette & README Refresh - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Reframe all vignettes and the README so WIOD and FIGARO are presented as example data sources (not "the" data source), integrate Phase 11's format spec into the data-preparation narrative, and ensure the 7 vignettes read coherently in sequence. No new R code or exported functions — prose and documentation only.

</domain>

<decisions>
## Implementation Decisions

### Source-Agnostic Reframing (VIG-01)
- **D-01:** Light-touch approach — add a short framing sentence near the top of each vignette ("this example uses WIOD/FIGARO, but any SUT data in canonical format works"). Keep existing code examples as-is.
- **D-02:** FIGARO vignette stays FIGARO-specific (it's a how-to for that source). Just add a note that other sources follow the same downstream pipeline.
- **D-03:** Paper-replication vignette gets the same light-touch framing note at the top. The vignette is inherently WIOD-specific since it replicates a WIOD-based paper.

### Vignette Reading Order / Narrative Flow (VIG-03)
- **D-04:** Canonical reading order: (1) getting-started, (2) package-design, (3) data-preparation, (4) modeling-and-outputs, (5) paper-replication, (6) figaro-workflow, (7) pipeline-helpers
- **D-05:** getting-started and package-design stay as an intro layer — readers who want theory read #1-#2, practitioners skip to #3
- **D-06:** pipeline-helpers stays last — show full manual workflow first, then convenience shortcuts
- **D-07:** No file renaming — current titles are descriptive enough. pkgdown article grouping (Phase 13) will handle visual ordering.

### README Refresh (DOC-01)
- **D-08:** Light refresh — add a source-agnostic sentence to the intro stating the package works with any SUT data in the canonical format
- **D-09:** Expand the "imports and standardizes supply-use inputs" bullet to mention WIOD workbooks, FIGARO CSVs, and custom supply-use inputs explicitly
- **D-10:** Brief BYOD mention — one sentence pointing readers to the data-preparation vignette for reshaping custom data. No dedicated section.
- **D-11:** Keep existing code example as-is (it uses shipped example data, already source-agnostic)

### Data-Preparation Vignette Integration (VIG-02)
- **D-12:** Light polish on Phase 11's spec sections — add transitions, ensure consistent tone, fix rough edges. Don't rewrite the spec content itself.
- **D-13:** Connect existing sections (Supply-use data, Mapping tables, Input metrics, Modeling table) with transitional sentences that tie back to the canonical format spec
- **D-14:** All code blocks using `sube_example_data()` should be `eval=TRUE` — shipped example data runs on CRAN/CI, keeps vignette internally consistent

### Claude's Discretion
- Exact wording of framing sentences added to each vignette
- How to phrase transitions between Phase 11 spec sections and existing data-prep content
- Whether any prose in existing vignettes needs minor rewording for consistency (beyond the framing sentences)
- Ordering of content within individual vignettes (as long as the overall reading sequence is preserved)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Target files (all will be edited)
- `vignettes/getting-started.Rmd` — Entry point vignette, needs source-agnostic framing sentence
- `vignettes/package-design.Rmd` — Conceptual overview, needs source-agnostic framing sentence
- `vignettes/data-preparation.Rmd` — Primary target: Phase 11 spec integration + transitions + framing
- `vignettes/modeling-and-outputs.Rmd` — Results/outputs vignette, needs source-agnostic framing sentence
- `vignettes/paper-replication.Rmd` — WIOD paper reproduction, needs light framing note (eval=FALSE)
- `vignettes/figaro-workflow.Rmd` — FIGARO how-to, add note about downstream pipeline generality (eval=FALSE)
- `vignettes/pipeline-helpers.Rmd` — Convenience wrappers, needs source-agnostic framing sentence
- `README.md` — Light refresh: source-agnostic intro, expanded import bullet, BYOD mention

### Phase 11 output (already in data-preparation.Rmd)
- `vignettes/data-preparation.Rmd` — Phase 11 added canonical format spec, satellite vector contract, synonym table, and BYOD guide sections before existing content

### Source code defining the contract (for reference)
- `R/import.R` lines 42-47 — Canonical column list
- `R/utils.R` lines 44-49 — `.coerce_map()` synonym lists

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sube_example_data()` — Shipped example objects used throughout vignettes; all eval=TRUE blocks rely on these
- Phase 11's format spec sections — already written in data-preparation.Rmd, ready for integration polish

### Established Patterns
- Vignettes use `knitr::knitr` engine with `collapse = TRUE, comment = "#>"`
- Gated vignettes (paper-replication, figaro-workflow) use `eval = FALSE` — don't change this
- Non-gated vignettes use shipped example data only — safe for CRAN/CI

### Integration Points
- All 7 vignettes and README.md are the target files
- pkgdown article grouping in `_pkgdown.yml` (Phase 13) will use the reading order established here
- No R code changes needed — this is pure documentation work

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

*Phase: 12-vignette-readme-refresh*
*Context gathered: 2026-04-17*

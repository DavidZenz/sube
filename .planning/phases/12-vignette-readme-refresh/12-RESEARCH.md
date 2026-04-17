# Phase 12: Vignette & README Refresh - Research

**Researched:** 2026-04-17
**Domain:** R package documentation — Rmd vignettes, README.md, prose editing
**Confidence:** HIGH

## Summary

Phase 12 is pure documentation work: 7 Rmd vignettes and README.md receive targeted prose edits with no new R code or exported functions. All decisions are locked (D-01 through D-14 in CONTEXT.md). The work divides into three streams: (1) add a one-sentence source-agnostic framing note near the top of six vignettes, (2) add transitional sentences connecting Phase 11's spec sections in data-preparation.Rmd and ensure all its code blocks are `eval=TRUE`, (3) light README refresh with an expanded import bullet and BYOD pointer.

The current state of all 8 target files has been read and audited. No surprises — each file is well-formed Rmd with standard knitr options. The two gated vignettes (paper-replication, figaro-workflow) already use `eval = FALSE` globally and must stay that way. The five non-gated vignettes use `sube_example_data()` and are safe for CRAN/CI.

**Primary recommendation:** Plan as three waves — (W1) framing sentences in the six non-data-prep vignettes, (W2) data-preparation.Rmd integration + eval audit, (W3) README refresh. Each wave is a single commit; wave boundary = `R CMD build .` succeeds.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Source-Agnostic Reframing (VIG-01)**
- D-01: Light-touch approach — add a short framing sentence near the top of each vignette ("this example uses WIOD/FIGARO, but any SUT data in canonical format works"). Keep existing code examples as-is.
- D-02: FIGARO vignette stays FIGARO-specific (it's a how-to for that source). Just add a note that other sources follow the same downstream pipeline.
- D-03: Paper-replication vignette gets the same light-touch framing note at the top. The vignette is inherently WIOD-specific since it replicates a WIOD-based paper.

**Vignette Reading Order / Narrative Flow (VIG-03)**
- D-04: Canonical reading order: (1) getting-started, (2) package-design, (3) data-preparation, (4) modeling-and-outputs, (5) paper-replication, (6) figaro-workflow, (7) pipeline-helpers
- D-05: getting-started and package-design stay as an intro layer — readers who want theory read #1-#2, practitioners skip to #3
- D-06: pipeline-helpers stays last — show full manual workflow first, then convenience shortcuts
- D-07: No file renaming — current titles are descriptive enough. pkgdown article grouping (Phase 13) will handle visual ordering.

**README Refresh (DOC-01)**
- D-08: Light refresh — add a source-agnostic sentence to the intro stating the package works with any SUT data in the canonical format
- D-09: Expand the "imports and standardizes supply-use inputs" bullet to mention WIOD workbooks, FIGARO CSVs, and custom supply-use inputs explicitly
- D-10: Brief BYOD mention — one sentence pointing readers to the data-preparation vignette for reshaping custom data. No dedicated section.
- D-11: Keep existing code example as-is (it uses shipped example data, already source-agnostic)

**Data-Preparation Vignette Integration (VIG-02)**
- D-12: Light polish on Phase 11's spec sections — add transitions, ensure consistent tone, fix rough edges. Don't rewrite the spec content itself.
- D-13: Connect existing sections (Supply-use data, Mapping tables, Input metrics, Modeling table) with transitional sentences that tie back to the canonical format spec
- D-14: All code blocks using `sube_example_data()` should be `eval=TRUE` — shipped example data runs on CRAN/CI, keeps vignette internally consistent

### Claude's Discretion
- Exact wording of framing sentences added to each vignette
- How to phrase transitions between Phase 11 spec sections and existing data-prep content
- Whether any prose in existing vignettes needs minor rewording for consistency (beyond the framing sentences)
- Ordering of content within individual vignettes (as long as the overall reading sequence is preserved)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIG-01 | All vignettes frame WIOD and FIGARO as example data sources, not as "the" data source — source-agnostic language throughout | D-01/D-02/D-03 lock the approach; current vignette text audited — no vignette currently has a framing sentence; each needs one added near the top |
| VIG-02 | Data-preparation vignette expanded with canonical format specification, column definitions, and worked examples | Phase 11 already inserted spec sections; D-12/D-13/D-14 define the polish needed; eval audit required |
| VIG-03 | Narrative flow across all vignettes reviewed and improved for coherent reading order | Reading order locked at D-04; cross-reference links between vignettes are the implementation lever |
| DOC-01 | README refreshed with source-agnostic framing and clear statement that the package works with any SUT data in the canonical format | D-08 through D-11 are precise; current README text audited |
</phase_requirements>

## Current File Audit

This section documents exactly what exists today in each target file, so the planner can write precise "insert after line X" instructions.

### `vignettes/getting-started.Rmd`
- **Opening prose location:** Lines 14-40 (intro block before `## Load sample inputs`)
- **Source references:** Mentions companion paper only; no explicit mention of WIOD or FIGARO as data sources
- **eval status:** All code blocks are `eval=TRUE` (default, no global override)
- **What's needed:** One framing sentence in the intro block (D-01). A cross-reference forward to data-preparation (#3 in reading order) would serve D-05 goal.
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/package-design.Rmd`
- **Opening prose location:** Lines 13-14 (first paragraph before `## Why this package exists`)
- **Source references:** No WIOD or FIGARO mentioned anywhere
- **eval status:** No `library(sube)` loaded, no code blocks execute — no eval concern
- **What's needed:** One framing sentence in the opening paragraph (D-01). Optional cross-reference to getting-started and data-preparation.
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/data-preparation.Rmd`
- **Structure (post-Phase 11):** Opens with 4-family intro → `## Canonical SUT Format` (Phase 11 table + synonym table) → `## Satellite Vector Inputs` (Phase 11 table) → `## Bring Your Own Data` (Phase 11 BYOD guide) → `## Supply-use data` (original) → `## Mapping tables` (original) → `## Input metrics` (original) → `## Modeling table` (original) → `## Recommended preparation strategy` (original)
- **Source references:** No explicit WIOD/FIGARO framing in the intro paragraph
- **eval status:** All `sube_example_data()` blocks appear to be `eval=TRUE` (no `eval=FALSE` seen). D-14 says to confirm/enforce this — all already look compliant. [VERIFIED: file read]
- **What's needed:** (1) Source-agnostic framing sentence in the opening paragraph (D-01/D-12); (2) transitional sentences connecting Phase 11 spec sections (`## Canonical SUT Format`, `## Satellite Vector Inputs`, `## Bring Your Own Data`) to the original sections that follow (D-13); (3) confirm no `eval=FALSE` on `sube_example_data()` blocks (D-14)
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/modeling-and-outputs.Rmd`
- **Opening prose location:** Lines 14-20 (intro before `## Compute the sample workflow`)
- **Source references:** Mentions companion paper only; no WIOD/FIGARO
- **eval status:** All blocks `eval=TRUE` (default)
- **What's needed:** One framing sentence (D-01)
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/paper-replication.Rmd`
- **Opening prose location:** Section 1 "What this vignette replicates" (lines 22-31)
- **Source references:** Explicitly WIOD-centric throughout — "2018 SUBE paper", "WIOD international supply-use tables", "~4 GB WIOD data archive"
- **eval status:** Global `eval = FALSE` set in setup chunk — must not change (D-03)
- **What's needed:** One framing note in Section 1 clarifying this vignette is WIOD-specific but the downstream pipeline (from `build_matrices()` onward) is source-agnostic (D-03)
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/figaro-workflow.Rmd`
- **Opening prose location:** Section 1 "What FIGARO is and what this vignette covers" (lines 21-37)
- **Source references:** Entirely FIGARO-specific by design
- **eval status:** Global `eval = FALSE` set in setup chunk — must not change (D-02)
- **What's needed:** One note at the end of Section 1 (or after the section 7 tip block) stating that once data is in canonical `sube_suts` format, the remainder of the pipeline (`build_matrices()`, `compute_sube()`, etc.) is identical regardless of source (D-02)
- **Confidence:** HIGH [VERIFIED: file read]

### `vignettes/pipeline-helpers.Rmd`
- **Opening prose location:** Section 1 "When to reach for the convenience helpers" (lines 20-33)
- **Source references:** Mentions WIOD-format sample in Section 2 (`source = "wiod"`), FIGARO in Section 4 — both as named examples of `source` parameter values
- **eval status:** Global `eval = TRUE` set in setup chunk; Section 4 block is `{r eval = FALSE}` — correct
- **What's needed:** One framing sentence in Section 1 noting the helpers work with any SUT source, not just WIOD and FIGARO (D-01)
- **Confidence:** HIGH [VERIFIED: file read]

### `README.md`
- **Current intro:** Lines 1-17 — introduces `sube` with companion paper reference; no source-agnostic statement
- **"What the package does" bullet list:** Lines 30-37 — first bullet: "imports and standardizes supply-use inputs" (no mention of WIOD, FIGARO, or custom data)
- **Documentation section:** Lines 104-112 — lists 4 vignettes; missing pipeline-helpers, figaro-workflow, paper-replication
- **BYOD mention:** None currently
- **Code example:** Uses `sube_example_data()` — already source-agnostic per D-11
- **What's needed:** (1) Source-agnostic sentence in the intro after line 10 or 17 (D-08); (2) expand first bullet in "What the package does" to name WIOD workbooks, FIGARO CSVs, and custom supply-use inputs (D-09); (3) one BYOD sentence pointing to data-preparation vignette (D-10); (4) optionally update Documentation section to list all 7 vignettes
- **Confidence:** HIGH [VERIFIED: file read]

## Standard Stack

### Core (documentation tools)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| knitr | installed | Rmd rendering engine | Already in use: `%\VignetteEngine{knitr::knitr}` |
| R Markdown | installed | Vignette format | All vignettes are `.Rmd` |

No new packages required. This phase adds no dependencies. [VERIFIED: file read]

### Established Patterns
- Vignette setup chunk: `knitr::opts_chunk$set(collapse = TRUE, comment = "#>")` — standard, do not change [VERIFIED: file read]
- Gated vignettes add `eval = FALSE` to the global setup chunk — paper-replication and figaro-workflow both do this [VERIFIED: file read]
- Non-gated vignettes load `library(sube)` in setup chunk and use `sube_example_data()` for all live examples [VERIFIED: file read]

## Architecture Patterns

### Prose Edit Pattern: Framing Sentence Placement
**What:** Insert one sentence immediately after the opening paragraph of each vignette (before the first `##` heading), following existing intro prose.
**When to use:** VIG-01 edits for getting-started, package-design, modeling-and-outputs, pipeline-helpers.
**Template:** "The examples below use [WIOD/FIGARO/shipped sample] data, but any SUT data in the canonical long format works the same way — see the [data-preparation vignette](data-preparation.html) for details."

### Prose Edit Pattern: Gated Vignette Note
**What:** Insert a brief note within Section 1 of gated vignettes (paper-replication, figaro-workflow) that separates source-specific import steps from the source-agnostic downstream pipeline.
**When to use:** D-02 and D-03 edits.
**Template for paper-replication:** "This vignette is specific to WIOD data. The pipeline from `build_matrices()` onward is identical for any SUT source in canonical format."
**Template for figaro-workflow:** "This vignette covers FIGARO-specific import. Once data is in canonical `sube_suts` format, the downstream pipeline — `build_matrices()`, `compute_sube()`, and `estimate_elasticities()` — works the same for any SUT source."

### Prose Edit Pattern: Transition Sentences in data-preparation.Rmd
**What:** Add 1-2 sentences at the end of each Phase 11 spec section that bridges forward to the concrete examples in the original sections.
**When to use:** D-13 — connecting spec sections to the `## Supply-use data`, `## Mapping tables`, `## Input metrics`, `## Modeling table` sections.
**Example bridge from `## Bring Your Own Data` to `## Supply-use data`:** "The remaining sections walk through the shipped example objects in detail, illustrating each data family in the preparation sequence." (Note: this sentence already exists at line 107 — confirm it's adequate or strengthen it.)

### README Edit Pattern
**What:** Three targeted inline edits — no section additions, no structural change.
**Locations:**
1. After the first sentence of the first paragraph (or after the companion paper block) — add source-agnostic sentence (D-08)
2. First bullet of "What the package does" — expand to name WIOD, FIGARO, and custom data (D-09)
3. At end of "What the package does" list or after the workflow section — one-sentence BYOD pointer (D-10)

### Cross-Reference Pattern
**What:** Use relative HTML links within vignette prose, matching the pkgdown article link format.
**Standard form:** `[vignette title](vignette-slug.html)`
**Examples already in use:** `[Pipeline Helpers vignette](pipeline-helpers.html)` (figaro-workflow.Rmd line 42), `[run_sube_pipeline()](../reference/run_sube_pipeline.html)` (paper-replication.Rmd line 33)
**Guidance:** Any cross-references added for narrative flow (VIG-03) should use this form.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Vignette rendering | Manual HTML | `R CMD build .` + `knitr` — standard R package build |
| Reading order enforcement | Custom index | pkgdown article grouping (Phase 13) handles visual ordering per D-07 |
| Eval gating | Custom mechanisms | Standard knitr `eval = FALSE` chunk option — already in use |

## Common Pitfalls

### Pitfall 1: Breaking eval=FALSE in gated vignettes
**What goes wrong:** Adding `library(sube)` call or changing setup chunk options in paper-replication or figaro-workflow causes CRAN/CI build failure when WIOD/FIGARO data is unavailable.
**Why it happens:** The gated vignettes set `eval = FALSE` globally to prevent execution without external data. Any prose edit near the setup chunk risks accidental modification.
**How to avoid:** Never modify the setup chunk (`{r, include = FALSE}`) in paper-replication.Rmd or figaro-workflow.Rmd. Edits are prose-only, in numbered sections only.
**Warning signs:** `R CMD build .` or `R CMD check` fails with "object not found" or data-download errors.

### Pitfall 2: eval=TRUE on a sube_example_data() block that was inadvertently set to FALSE
**What goes wrong:** If any `sube_example_data()` block in data-preparation.Rmd has `eval = FALSE`, the vignette shows code but no output — breaking D-14 and making format spec less illustrative.
**Why it happens:** Could be a leftover from Phase 11 edits, or a copy-paste of gated vignette chunk options.
**How to avoid:** Audit all code chunks in data-preparation.Rmd explicitly. Chunks using `sube_example_data()` must not have `eval = FALSE`.
**Warning signs:** Vignette renders with no output under code blocks.

### Pitfall 3: Framing sentence placed inside a section heading context
**What goes wrong:** Inserting a framing sentence after a `##` heading instead of before the first heading — the sentence ends up in the wrong section visually and tonally.
**Why it happens:** Some vignettes open directly with a heading; editors may miss the pre-heading intro block.
**How to avoid:** All framing sentences go in the pre-heading intro paragraph (before the first `##`). If there is no pre-heading paragraph, add a brief one. Do not insert sentences inside numbered sections.

### Pitfall 4: README Documentation section omits newer vignettes
**What goes wrong:** The README Documentation section lists only 4 vignettes (getting-started, data-preparation, modeling-and-outputs, package-design), omitting pipeline-helpers, figaro-workflow, and paper-replication. A BYOD edit may draw attention to this gap without fixing it.
**Why it happens:** The 3 newer vignettes (added in v1.1/v1.2) were not added to the README Documentation section.
**How to avoid:** When making D-10 BYOD edits, also update the Documentation section to list all 7 vignettes. This is within discretion scope.

### Pitfall 5: Cross-references using wrong slug format
**What goes wrong:** Link to `vignette("pipeline-helpers", package = "sube")` in Rmd prose rather than `[title](pipeline-helpers.html)` — the R-style reference works only in the R console, not in rendered HTML from pkgdown.
**Why it happens:** Vignette cross-references can be written two ways; the HTML form is required for pkgdown articles.
**How to avoid:** Match the form already used in figaro-workflow.Rmd line 42: `[Pipeline Helpers vignette](pipeline-helpers.html)`.

## Code Examples

No new R code. All code in vignettes stays unchanged (D-01, D-12, D-14).

### Verified knitr setup pattern (do not change)
```r
# Source: file read of all 7 vignettes
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
```

### Verified eval=FALSE pattern for gated vignettes
```r
# Source: paper-replication.Rmd lines 10-13, figaro-workflow.Rmd lines 10-12
knitr::opts_chunk$set(
  collapse = TRUE, comment = "#>",
  eval = FALSE
)
```

### Verified cross-reference link format
```md
<!-- Source: figaro-workflow.Rmd line 42, paper-replication.Rmd line 33 -->
[Pipeline Helpers vignette](pipeline-helpers.html)
[`run_sube_pipeline()`](../reference/run_sube_pipeline.html)
```

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — this phase edits Rmd and Markdown files only; no new packages, tools, or services required).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat |
| Config file | tests/testthat/ |
| Quick run command | `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'` |
| Full suite command | `R -q -e 'testthat::test_dir("tests/testthat")'` |
| Build check | `R CMD build . && R CMD check sube_0.1.2.tar.gz --no-manual` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| VIG-01 | Framing sentences present in all non-gated vignettes | Manual review | Visual inspection during PR | No automated prose test exists or is needed |
| VIG-02 | data-preparation.Rmd spec sections integrated, all eval=TRUE | Build check | `R CMD build .` — vignette must build without errors | Phase gate |
| VIG-03 | Reading order cross-references coherent | Manual review | Visual inspection | Links verified by `R CMD check` (broken links flagged) |
| DOC-01 | README source-agnostic sentence present, BYOD pointer present | Manual review | Visual inspection during PR | |

### Sampling Rate
- **Per task commit:** `R -q -e 'testthat::test_file("tests/testthat/test-workflow.R")'`
- **Per wave merge:** `R CMD build . && R CMD check sube_0.1.2.tar.gz --no-manual`
- **Phase gate:** Full suite green + `R CMD build .` succeeds before `/gsd-verify-work`

### Wave 0 Gaps
None — no new test infrastructure needed. This phase is documentation-only; the existing test suite and `R CMD build .` are sufficient validators.

## Security Domain

Step 2.5 SKIPPED — security_enforcement not in config, but this phase edits only Markdown/Rmd prose with no authentication, data handling, or external calls. ASVS categories V2/V3/V4/V5/V6 are all inapplicable.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All 7 vignettes currently lack a source-agnostic framing sentence — none was found in the file read | Current File Audit | Low — if one exists, the task is to verify/improve wording rather than add from scratch |
| A2 | The transition sentence at data-preparation.Rmd line 107 ("The remaining sections walk through…") was written by Phase 11 and may already serve as adequate bridging prose for D-13 | Architecture Patterns | Low — if adequate, D-13 tasks may be lighter than anticipated |
| A3 | `R CMD check` will flag broken Rmd cross-reference links as NOTEs or WARNINGs | Validation Architecture | Low — even if not flagged, manual verification during PR catches broken links |

## Open Questions (RESOLVED)

1. **Documentation section in README: update to list all 7 vignettes?**
   - What we know: README Documentation section currently lists 4 vignettes; 3 newer vignettes (pipeline-helpers, figaro-workflow, paper-replication) are absent
   - What's unclear: Whether updating this list is explicitly required or within Claude's discretion
   - Recommendation: Treat as within-discretion housekeeping — update the list when making D-10 edits; costs one extra line, improves discoverability
   - RESOLVED: Task 3 updates Documentation section to list all 7 vignettes in canonical order.

2. **Transition sentence at data-preparation.Rmd line 107**
   - What we know: "The remaining sections walk through the shipped example objects in detail, illustrating each data family in the preparation sequence." already bridges Phase 11 BYOD section to original sections
   - What's unclear: Whether this is sufficient for D-13 or whether each original section also needs an opening line referencing the spec above
   - Recommendation: Per D-13, add 1-sentence openers to each of `## Supply-use data`, `## Mapping tables`, `## Input metrics` that echo back to the canonical spec (e.g., "The `sut_data` example shows the 7-column canonical format described above."). This is light and explicit.
   - RESOLVED: Task 2 adds 1-sentence openers to each of the four original sections (Supply-use data, Mapping tables, Input metrics, Modeling table) that echo back to the spec above.

## Sources

### Primary (HIGH confidence)
- File read: `vignettes/getting-started.Rmd` — current content verified
- File read: `vignettes/package-design.Rmd` — current content verified
- File read: `vignettes/data-preparation.Rmd` — Phase 11 output verified, eval status checked
- File read: `vignettes/modeling-and-outputs.Rmd` — current content verified
- File read: `vignettes/paper-replication.Rmd` — eval=FALSE gate verified
- File read: `vignettes/figaro-workflow.Rmd` — eval=FALSE gate verified
- File read: `vignettes/pipeline-helpers.Rmd` — eval=TRUE confirmed, Section 4 gated correctly
- File read: `README.md` — current bullet list and Documentation section verified
- File read: `R/import.R` lines 42-47 — canonical column list: REP, PAR, CPA, VAR, VALUE, YEAR, TYPE
- File read: `R/utils.R` lines 44-49 — synonym lists for mapping table columns
- File read: `.planning/phases/12-vignette-readme-refresh/12-CONTEXT.md` — decisions D-01..D-14 verified

### Secondary (MEDIUM confidence)
- `AGENTS.md` — project conventions: snake_case, short imperative commits, `R CMD build .` as release check

## Metadata

**Confidence breakdown:**
- Current file audit: HIGH — all 8 files read directly
- Edit locations: HIGH — precise line-level knowledge of each file's structure
- Validation approach: HIGH — established R package build/check workflow
- Prose wording (framing sentences): LOW — Claude's discretion per CONTEXT.md; exact wording is implementation-time decision

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (stable; file contents won't change until Phase 12 implementation begins)

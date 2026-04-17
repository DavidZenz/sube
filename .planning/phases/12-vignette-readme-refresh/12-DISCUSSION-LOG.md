# Phase 12: Vignette & README Refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 12-vignette-readme-refresh
**Areas discussed:** Source-agnostic reframing strategy, Vignette reading order & narrative flow, README scope and content, Data-prep vignette integration

---

## Source-Agnostic Reframing Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Light touch | Add framing sentence near top of each vignette, keep code examples as-is | ✓ |
| Moderate rewrite | Reframe paragraphs throughout, adjust prose but don't restructure | |
| Structural rewrite | Reorganize vignettes to lead with source-agnostic concepts first | |

**User's choice:** Light touch
**Notes:** Minimal intervention — a framing sentence is enough since code examples already use shipped data.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep FIGARO-specific | It's a how-to for FIGARO users, just add note about downstream pipeline | ✓ |
| Add agnostic framing | Open with source-agnostic context, then FIGARO specifics | |

**User's choice:** Keep FIGARO-specific
**Notes:** FIGARO vignette's purpose is diluted by source-agnostic framing.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same light touch | Brief framing note at top of paper-replication vignette | ✓ |
| Skip it entirely | No framing note needed for inherently WIOD-specific vignette | |

**User's choice:** Yes, same light touch
**Notes:** Even the WIOD-specific replication vignette gets a brief framing note.

---

## Vignette Reading Order & Narrative Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Keep both as intro layer | getting-started #1, package-design #2, then target sequence follows | ✓ |
| Merge into getting-started | Fold package-design into getting-started | |
| Drop package-design | Remove it, let workflow vignettes speak for themselves | |

**User's choice:** Keep both as intro layer
**Notes:** Theory readers get #1-#2, practitioners skip to #3.

| Option | Description | Selected |
|--------|-------------|----------|
| After (last) | Show full manual workflow first, then convenience shortcuts | ✓ |
| Before replication | Show easy path first, then deep-dive workflows | |

**User's choice:** After (last)
**Notes:** Pipeline helpers are convenience wrappers — show the full workflow before the shortcut.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep at #4 | After data-prep, before deep-dive workflows | ✓ |
| Move after pipeline-helpers | Treat as reference material at the end | |

**User's choice:** Keep at #4
**Notes:** Natural flow: data-prep → what the package produces → specific workflows.

| Option | Description | Selected |
|--------|-------------|----------|
| No renaming | Current titles are descriptive, pkgdown handles visual ordering | ✓ |
| Prefix with numbers | 01-getting-started.Rmd etc. | |
| You decide | Claude's discretion on title adjustments | |

**User's choice:** No renaming
**Notes:** Phase 13 (pkgdown) will handle article ordering visually.

---

## README Scope and Content

| Option | Description | Selected |
|--------|-------------|----------|
| Light refresh | Source-agnostic sentence, mention FIGARO in feature list, keep code example | ✓ |
| Moderate refresh | Rewrite intro, add second code example, mention BYOD | |
| Full rewrite | Restructure all README sections | |

**User's choice:** Light refresh
**Notes:** README already uses shipped example data in code — just needs prose framing.

| Option | Description | Selected |
|--------|-------------|----------|
| Brief mention | One sentence pointing to data-prep vignette for BYOD | ✓ |
| No mention | README stays focused on package workflow | |
| Dedicated section | "Supported data sources" section | |

**User's choice:** Brief mention
**Notes:** Points readers to the right place without duplicating content.

| Option | Description | Selected |
|--------|-------------|----------|
| Expand slightly | "imports WIOD workbooks, FIGARO CSVs, and custom supply-use inputs" | ✓ |
| Keep as-is | "imports and standardizes supply-use inputs" is agnostic enough | |
| You decide | Claude's discretion | |

**User's choice:** Expand slightly
**Notes:** Explicitly naming all three source types in the feature list.

---

## Data-Prep Vignette Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Light polish | Add transitions, consistent tone, fix rough edges. Don't rewrite spec. | ✓ |
| Full narrative rewrite | Rewrite Phase 11 sections as tutorial prose | |
| You decide | Claude's discretion based on actual content | |

**User's choice:** Light polish
**Notes:** Phase 11's spec structure was deliberate — just smooth the edges.

| Option | Description | Selected |
|--------|-------------|----------|
| Connect with transitions | Keep existing sections, add transitional sentences | ✓ |
| Rewrite for consistency | Rewrite existing sections to match new spec style | |
| Leave untouched | No integration prose | |

**User's choice:** Connect with transitions
**Notes:** "Now that you know the column contract, here's how to prepare each input family."

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, eval=TRUE | Phase 11 code blocks use shipped data, safe for CRAN/CI | ✓ |
| You decide | Claude's discretion | |

**User's choice:** Yes, eval=TRUE
**Notes:** Keeps vignette internally consistent — all shipped-data blocks evaluate.

---

## Claude's Discretion

- Exact wording of framing sentences in each vignette
- Transition phrasing between Phase 11 spec and existing data-prep content
- Minor prose adjustments for consistency

## Deferred Ideas

None — discussion stayed within phase scope.

---
phase: 12-vignette-readme-refresh
reviewed: 2026-04-18T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - vignettes/getting-started.Rmd
  - vignettes/package-design.Rmd
  - vignettes/data-preparation.Rmd
  - vignettes/modeling-and-outputs.Rmd
  - vignettes/paper-replication.Rmd
  - vignettes/figaro-workflow.Rmd
  - vignettes/pipeline-helpers.Rmd
  - README.md
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: advisory
---

# Phase 12: Code Review Report

**Reviewed:** 2026-04-18
**Depth:** standard
**Files Reviewed:** 8
**Status:** advisory

## Summary

Phase 12 is a prose-only documentation pass that adds source-agnostic framing
to six vignettes, polishes the `data-preparation.Rmd` integration, and
refreshes the README. All 8 in-scope files were reviewed.

Checked and confirmed:

- **Cross-reference link targets are valid.** All new `.html` links
  (`data-preparation.html`, `modeling-and-outputs.html`, `pipeline-helpers.html`)
  match actual vignette slugs in `vignettes/` and the pkgdown `docs/articles/`
  layout.
- **Gated vignettes still gated.** `paper-replication.Rmd` and
  `figaro-workflow.Rmd` both retain `eval = FALSE` at the chunk-options level
  (lines 12 and 12, respectively). No chunk-level overrides were introduced.
- **Function names are accurate.** Every function referenced in the new prose
  exists in `R/`: `import_suts`, `read_figaro`, `build_matrices`,
  `compute_sube`, `estimate_elasticities`, `extract_domestic_block`,
  `sube_example_data`, `run_sube_pipeline`, `batch_sube`.
- **`run_sube_pipeline(source = "figaro", ...)` is valid.** `R/pipeline.R:246`
  declares `source = c("wiod", "figaro")`, so the tip in
  `figaro-workflow.Rmd:45-48` is correct.
- **Section-number citations in `paper-replication.Rmd` are correct.** The new
  paragraph at lines 27-30 claims WIOD-specific content is in sections 3
  (import) and 4 (correspondence tables); the actual headings are `# 3.
  Importing the domestic block` and `# 4. Aggregation via correspondence
  tables`. Match.
- **Canonical vignette-reading order in README is internally consistent.** The
  Documentation section lists all 7 vignettes, matching the files in
  `vignettes/` one-for-one.
- **Source-agnostic framing is consistent across files.** WIOD and FIGARO are
  named as shipped importers everywhere; no vignette contradicts the
  source-agnostic tone by re-asserting WIOD-only framing for the downstream
  pipeline.
- **No factual claims about the package API are wrong.** The data-preparation
  section-echo transitions accurately reference the Canonical SUT Format,
  Satellite Vector Inputs, and mapping synonym sections above.

One advisory item below relates to a cross-reference that points readers to the
wrong vignette for the content advertised. It is not a broken link — the
target exists — but the framing misdirects a reader looking for the manual
workflow.

## Info

### IN-01: `pipeline-helpers.Rmd` cross-reference points to wrong vignette for "manual workflow"

**File:** `vignettes/pipeline-helpers.Rmd:23-27`

**Issue:** The new paragraph says:

> The manual workflow is covered in detail in the
> [modeling-and-outputs vignette](modeling-and-outputs.html); see the
> [data-preparation vignette](data-preparation.html) for input contracts
> and the canonical format.

However, `modeling-and-outputs.Rmd` explicitly scopes itself to "the tidy
result layer, filtering, plots, and export" (line 14) and only demonstrates
`build_matrices()` + `extract_domestic_block()` starting from already-loaded
sample data. It does not walk through the full four-step manual chain
(`import_suts()` / `read_figaro()` → `extract_domestic_block()` →
`build_matrices()` → `compute_sube()`) that the surrounding paragraph
describes.

The vignette that actually walks through the four-step manual workflow
end-to-end is `getting-started.Rmd` (sections "Load sample inputs", "Build
matrices", "Compute Leontief benchmark results", "Estimate SUBE models",
"Compare Leontief and SUBE outputs" — lines 48-108).

A reader who clicks the "manual workflow" link expecting the hand-rolled
four-step chain will land on a compute-layer/plots vignette and not find
what was promised.

**Fix:** Point the "manual workflow" xref at `getting-started.html` and keep
`modeling-and-outputs.html` as a separate, correctly-scoped pointer. For
example:

```markdown
The manual workflow is covered end-to-end in the
[getting-started vignette](getting-started.html); see the
[modeling-and-outputs vignette](modeling-and-outputs.html) for the tidy
result layer, filtering, plots, and export, and the
[data-preparation vignette](data-preparation.html) for input contracts
and the canonical format.
```

Severity rationale: info, not warning. The link itself works, the target is
an existing useful vignette, and a reader will still get value from the
landing page. The issue is precision of framing, not a bug or broken
reference.

---

_Reviewed: 2026-04-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

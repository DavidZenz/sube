# Phase 2 Research: Comparison Layer Stabilization

**Phase:** 2
**Date:** 2026-04-08
**Status:** Complete

## Objective

Research what must be true to plan Phase 2 well for the package's public comparison layer built on Leontief extraction, model-output alignment, paper-style plotting, and export helpers.

## Repo Facts

- The comparison API already exists in `R/paper_tools.R` and is exported through documented helpers rather than hidden scripts.
- `R/filter_plot_export.R` provides a second public surface for generic tidy-result filtering, plotting, and export.
- `README.md`, `vignettes/modeling-and-outputs.Rmd`, and `vignettes/getting-started.Rmd` already present comparison usage, which means Phase 2 is primarily about reliability and contract clarity rather than feature discovery.
- `tests/testthat/test-workflow.R` currently gives comparison helpers only smoke coverage; it proves the path works on sample data but does not pin many edge behaviors or alternate formats.

## Implementation Considerations

### 1. Output shape matters more than new functionality

The highest risk is not missing helpers; it is ambiguous or weakly tested output shape. `extract_leontief_matrices()` supports `list`, `long`, and `wide` forms, while `prepare_sube_comparison()` mixes Leontief and model outputs into a shared table. Phase 2 should make these shapes explicit enough that researchers can build on them without inspecting source.

### 2. Comparison preparation has the densest contract surface

`prepare_sube_comparison()` controls measure selection, variable filtering, year aggregation, CPA grouping, and optional paper-style exclusions. That function is the hub connecting Phase 1 compute outputs to plotting and export helpers. It therefore deserves the strongest normalization and test attention in this phase.

### 3. Plotting and export should fail predictably

The plotting helpers are already package-level conveniences, but they depend on column normalization, non-empty subsets, and in some cases interval calculations. `write_sube()` also needs predictable single-file vs directory semantics across CSV, RDS, and DTA. Phase 2 should ensure these utilities either return stable objects or fail explicitly instead of relying on accidental input shape success.

### 4. Examples should stay bounded to the package workflow

The package already has enough public docs for the comparison layer. Phase 2 should refine the modeling/output vignette and workflow tests rather than expanding into a broad docs rewrite. That keeps the phase focused and leaves cross-surface consistency work to Phase 3.

## Recommended Plan Shape

Use three plans:
1. Normalize extraction and comparison-table contracts
2. Harden plotting and export behavior
3. Extend tests and examples to cover the stabilized comparison workflow

This matches the roadmap, separates source ownership reasonably well, and gives execution a clean Wave 1 then Wave 2 structure.

## Risks and Watchouts

- Tightening comparison-table or export contracts may require updating vignette snippets and smoke tests in the same phase.
- Paper-filter logic is intentionally opinionated; the phase should stabilize that behavior, not silently broaden it.
- Plot helpers returning nested lists of `ggplot` objects can be easy to use incorrectly; tests should pin the list shape where public examples rely on it.

## Validation Architecture

Phase 2 can stay within the same `testthat` infrastructure used by Phase 1:
- framework: `testthat`
- quick checks: targeted workflow test file while iterating
- full checks: repository `testthat` suite before phase completion
- example validation: vignette snippets should remain runnable from shipped data without external setup

## Research Conclusion

Phase 2 should treat the comparison layer as an existing public product surface that needs contract hardening, not reinvention. The best plan shape is to stabilize extraction/comparison tables first, then plotting/export behavior, then lock the whole story in with tests and examples.

## RESEARCH COMPLETE

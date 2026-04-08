# Phase 3 Research: Documentation Alignment

**Phase:** 3
**Date:** 2026-04-08
**Status:** Complete

## Objective

Research what must be true to plan Phase 3 well for a package whose code contracts are now stable but whose public documentation surfaces still drift in framing, grouping, and discoverability.

## Repo Facts

- The public workflow is already spread across `README.md`, four vignettes, pkgdown configuration, package-level roxygen text, and release notes.
- Phase 1 and Phase 2 clarified the actual package contracts around core workflow reproducibility and the comparison layer, so documentation can now align to a firmer source of truth.
- The package-level reference text in `R/package.R` and `man/sube-package.Rd` is narrower than the current README/vignette story because it still emphasizes tidy outputs more than the stabilized comparison layer.
- `NEWS.md` still frames the “next scope” in terms that Phase 2 has already delivered, which can confuse the public release narrative.

## Implementation Considerations

### 1. The main risk is narrative drift, not missing docs

The repository already has multiple useful documentation surfaces. Phase 3 should focus on making them agree rather than creating more pages. The leverage is in tightening sequencing, wording, and grouping so users can infer the workflow from any entry point.

### 2. pkgdown grouping is part of the product story

`_pkgdown.yml` is not just navigation; it defines how the package is conceptually organized on the website. That makes it a first-class target for DOC-01 and DOC-02. If article names and reference groups diverge from README and vignette framing, users will perceive the package as less coherent even if the code is fine.

### 3. Example-data guidance should bridge to real data

The shipped sample data is now the validated baseline. Phase 3 should use that fact more deliberately to satisfy MIG-02: docs should make it obvious what users can learn from sample objects before attempting their own research inputs.

### 4. Keep paper context separate from operational guidance

The paper is an important part of the package motivation, but it should not crowd out the practical package-first workflow. Phase 3 should preserve the paper link while making operational documentation more direct and discoverable.

## Recommended Plan Shape

Use three plans:
1. Reconcile README and vignette framing
2. Align pkgdown and package/reference grouping
3. Tighten example-data and input-contract guidance for new users

This mirrors the roadmap and keeps execution scoped to narrative alignment, site structure, and guidance clarity.

## Risks and Watchouts

- Over-editing narrative docs could spill into release-note or migration work that belongs to Phase 4.
- Changing pkgdown grouping without keeping vignette titles and README phrasing in sync would only move the inconsistency elsewhere.
- Example guidance should remain package-native and sample-driven, not drift back into script-era assumptions.

## Validation Architecture

Phase 3 remains primarily documentation work, but it can still use lightweight automated verification:
- framework: `testthat` for regression protection on touched examples when needed
- quick checks: targeted `tests/testthat/test-workflow.R` after doc examples are adjusted if they mirror tested paths
- full checks: repository `testthat` suite before phase completion
- manual checks: inspect pkgdown config/article groupings and ensure edited prose describes the same workflow sequence across surfaces

## Research Conclusion

Phase 3 should make the current package story internally consistent rather than broader. The best plan shape is to align README/vignettes first, then pkgdown and reference framing, then tighten the example-data and input-guidance bridge for new users.

## RESEARCH COMPLETE

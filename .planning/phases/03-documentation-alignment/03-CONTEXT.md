# Phase 3: Documentation Alignment - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Source:** Orchestrator synthesis from brownfield repo state

<domain>
## Phase Boundary

Phase 3 covers the public documentation surfaces that explain the package-first workflow: `README.md`, package vignettes, pkgdown navigation and grouping, package-level reference framing, and release-note-facing workflow descriptions. The goal is to make those surfaces describe the same product story and the same function groupings after the Phase 1 and Phase 2 contract hardening work.

This phase does not redesign the computational API or add new comparison functionality. It aligns how existing package behavior is explained and discovered.
</domain>

<decisions>
## Implementation Decisions

### Workflow scope
- Treat the package-first public workflow as the canonical documentation story.
- Keep Phase 3 centered on `README.md`, `_pkgdown.yml`, vignettes, `R/package.R`, and generated reference pages that shape how users discover the package surface.
- Use the shipped sample-data workflow as the baseline documentation path for new users.

### Alignment strategy
- Prefer one coherent workflow sequence across docs: import or load data, build matrices, compute results, estimate models, compare outputs, export artifacts.
- Distinguish clearly between core package workflow documentation and paper-context interpretation.
- Make function grouping and example-data expectations discoverable without requiring users to inspect tests or source files.

### Repo-specific constraints
- Follow the current package layout and exported API rather than the stale script-oriented `AGENTS.md` description.
- Keep Phase 3 scoped to documentation and site alignment rather than release engineering or legacy-wrapper execution.
- Preserve the existing package tone and sample-data-driven examples where possible.

### the agent's Discretion
- Whether alignment is best achieved by editing existing docs, tweaking pkgdown grouping, or lightly refreshing package-level reference text.
- Exact split between README, vignettes, and pkgdown edits, as long as the public workflow and function categories converge.
- Whether `NEWS.md` needs a narrow documentation-facing refresh as part of the alignment story.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Public documentation surfaces
- `README.md` — primary entry point and quickstart story
- `_pkgdown.yml` — website article/navigation/reference grouping
- `vignettes/getting-started.Rmd` — end-to-end sample workflow
- `vignettes/data-preparation.Rmd` — input contract guidance
- `vignettes/modeling-and-outputs.Rmd` — modeling, comparison, and export workflow
- `vignettes/package-design.Rmd` — paper-context and package-design framing
- `R/package.R` — package-level overview text
- `NEWS.md` — release-facing narrative of current scope

### Reference outputs
- `man/sube-package.Rd` — package-level reference landing text
- `man/import_suts.Rd` — data-preparation reference framing
- `man/paper_tools.Rd` — comparison-layer reference framing
- `man/filter_plot_write.Rd` — output helper reference framing

### Planning context
- `.planning/PROJECT.md` — project framing and constraints
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, MIG-02
- `.planning/ROADMAP.md` — Phase 3 goal and success criteria
- `.planning/STATE.md` — current project state
- `.planning/phases/02-comparison-layer-stabilization/02-VERIFICATION.md` — latest validated comparison-surface contract
</canonical_refs>

<specifics>
## Specific Ideas

- Reconcile the README quickstart, getting-started vignette, and package-design framing so they describe the same package-first workflow and paper relationship.
- Align pkgdown article and reference groups with the actual function clusters already present in the codebase.
- Tighten input-contract and example-data guidance so users can move from shipped samples to their own data with less ambiguity.
- Refresh package-level reference text where it still under-describes the comparison/output workflow.
</specifics>

<deferred>
## Deferred Ideas

- Tarball checks, CI assumptions, and release-command validation belong to Phase 4.
- Legacy wrapper execution and migration-path verification belong to Phase 4.
- New convenience wrappers or broader UX helpers remain future expansion work.
</deferred>

---
*Phase: 03-documentation-alignment*
*Context gathered: 2026-04-08 via direct repo synthesis*

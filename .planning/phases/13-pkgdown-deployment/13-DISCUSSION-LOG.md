# Phase 13: pkgdown Deployment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-18
**Phase:** 13-pkgdown-deployment
**Areas discussed:** Deploy workflow shape, Article order & grouping, Reference section taxonomy, Deploy gating & verification

---

## Deploy Workflow Shape

### Q1: Which deployment pattern for the pkgdown GHA workflow?

| Option | Description | Selected |
|--------|-------------|----------|
| Modern r-lib pattern | r-lib/actions + actions/configure-pages + upload-pages-artifact + deploy-pages; no gh-pages branch | ✓ |
| Keep JamesIves → gh-pages | Existing custom workflow pushing built site to gh-pages branch | |
| Hybrid: keep shape, update actions | Keep gh-pages flow but upgrade action versions | |

**User's choice:** Modern r-lib pattern
**Notes:** Recommended default. Uses GitHub's first-party Pages deployment; no branch to maintain.

### Q2: Deploy triggers — which branches/events?

| Option | Description | Selected |
|--------|-------------|----------|
| Push to master only | branches: [main, master] + workflow_dispatch | ✓ |
| Push to master + tags | Add tag triggers for release-time rebuilds | |
| Push to master + PRs (preview build) | Also build on PRs as smoke test | |

**User's choice:** Push to master only
**Notes:** Deploy stays minimal; PR smoke build is handled separately (see Q5 of Gating area).

### Q3: Cross-platform / R version matrix for pkgdown build?

| Option | Description | Selected |
|--------|-------------|----------|
| Ubuntu + R release only | Single fast job | ✓ |
| Ubuntu + R release + R devel | Adds R-devel forward-compat check | |

**User's choice:** Ubuntu + R release only
**Notes:** R-CMD-check workflow already runs the full OS/R matrix; pkgdown only needs to build once.

### Q4: Workflow permissions declaration style?

| Option | Description | Selected |
|--------|-------------|----------|
| Match chosen deploy pattern | Claude sets minimal perms for the pattern (contents:read, pages:write, id-token:write) | ✓ |
| You decide | Defer to Claude during implementation | |

**User's choice:** Match chosen deploy pattern
**Notes:** Standard minimal set for actions/deploy-pages.

---

## Article Order & Grouping

### Q1: _pkgdown.yml article order — realign to Phase 12 D-04?

| Option | Description | Selected |
|--------|-------------|----------|
| Realign exactly to Phase 12 D-04 | getting-started → package-design → data-preparation → modeling-and-outputs → paper-replication → figaro-workflow → pipeline-helpers | ✓ |
| Keep current order | Current _pkgdown.yml ordering | |
| Realign but keep pipeline-helpers earlier | Deviates from D-06 | |

**User's choice:** Realign exactly to Phase 12 D-04
**Notes:** Honors the narrative order locked during Phase 12.

### Q2: How to group the 7 articles in the pkgdown sidebar?

| Option | Description | Selected |
|--------|-------------|----------|
| Consolidated narrative groups | 3 groups: Getting started / Workflow / Data sources in practice | ✓ |
| Flat — one group per article (current) | 7 single-article groups | |
| Two-tier: Core workflow / Examples | Two groups | |

**User's choice:** Consolidated narrative groups
**Notes:** Reduces sidebar noise; matches the narrative arc of the documentation.

### Q3: navbar 'Get started' entry — which article is the landing?

| Option | Description | Selected |
|--------|-------------|----------|
| getting-started.Rmd | Keep current behavior | ✓ |
| Auto from first article | Remove explicit binding; infer from ordering | |

**User's choice:** getting-started.Rmd
**Notes:** Matches filename and role as entry vignette.

### Q4: Additional navbar entries?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current navbar | left: reference, articles, paper, news; right: search, github | ✓ |
| Add 'Changelog' shortcut | Short alias for news/index.html | |
| You decide | Defer to Claude | |

**User's choice:** Keep current navbar
**Notes:** Existing structure already covers the docs surface.

---

## Reference Section Taxonomy

### Q1: Reference section structure — keep 4 groups or split?

| Option | Description | Selected |
|--------|-------------|----------|
| Split into 6 groups | Data import / Matrix building / Compute & models / Pipeline helpers / Paper replication / Output & export | ✓ |
| Keep current 4 groups | Existing taxonomy | |
| Consolidate to 3 groups | Data & matrices / Modeling & compute / Outputs & replication | |

**User's choice:** Split into 6 groups
**Notes:** Mirrors the function taxonomy in PROJECT.md's pkgdown groups list. Surfaces pipeline helpers as a distinct surface.

### Q2: Should reference groups include short descriptions (desc: field)?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, one-line desc per group | Each group gets a one-sentence description | ✓ |
| No descriptions | Titles only | |

**User's choice:** Yes, one-line desc per group
**Notes:** Improves scannability and aligns with Phase 12's source-agnostic narrative.

### Q3: Ordering within each reference group?

| Option | Description | Selected |
|--------|-------------|----------|
| Pipeline flow order | Functions ordered by call sequence | ✓ |
| Alphabetical | Simpler to maintain | |
| You decide | Defer to Claude | |

**User's choice:** Pipeline flow order
**Notes:** Preserves the 'what do I call first' cue for users reading the reference.

### Q4: Should S3 print methods or internal helpers surface in reference?

| Option | Description | Selected |
|--------|-------------|----------|
| Exported only | Only NAMESPACE exports appear in reference | ✓ |
| You decide | Defer to Claude | |

**User's choice:** Exported only
**Notes:** Matches package-first philosophy.

---

## Deploy Gating & Verification

### Q1: Pre-merge smoke check — should PRs build pkgdown (no deploy)?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, PR smoke build only | pkgdown::build_site() on pull_request, no artifact upload | ✓ |
| No — deploy workflow runs only on push | Minimal triggers | |
| PR preview with artifact upload | Heavier, gives reviewers a downloadable preview | |

**User's choice:** Yes, PR smoke build only
**Notes:** Catches broken vignettes before merge; no artifact overhead.

### Q2: First-deploy verification — how do we validate the initial deploy?

| Option | Description | Selected |
|--------|-------------|----------|
| Trigger workflow_dispatch after merging, verify site live | Manual post-merge dispatch + live check | ✓ |
| Local pkgdown::build_site() dry-run first | Build locally before pushing | |
| Both local dry-run + workflow_dispatch check | Most thorough | |

**User's choice:** Trigger workflow_dispatch after merging, verify site live
**Notes:** Document verification steps in VERIFICATION.md.

### Q3: What to do about the existing pkgdown.yaml workflow?

| Option | Description | Selected |
|--------|-------------|----------|
| Replace in place | Overwrite .github/workflows/pkgdown.yaml, keep filename | ✓ |
| New file, delete old | Fresh filename like pkgdown-pages.yaml | |

**User's choice:** Replace in place
**Notes:** Git history shows the evolution of the workflow.

### Q4: GitHub Pages repo setting — who confirms it's enabled?

| Option | Description | Selected |
|--------|-------------|----------|
| User confirms manually | Document Settings → Pages → Source: GitHub Actions prerequisite | ✓ |
| Defer to first-run failure | Push workflow; fix setting after deploy-pages fails | |

**User's choice:** User confirms manually
**Notes:** One-time manual prerequisite; document in VERIFICATION.md.

---

## Claude's Discretion

- Exact YAML formatting, step names, and comments in the workflow file
- Exact one-sentence `desc:` text for each reference group
- Whether to pin a specific pkgdown version or use `any::pkgdown`
- Caching strategy for R packages (inherit r-lib/actions defaults)
- Whether PR smoke-build is a separate workflow file or a conditional job

## Deferred Ideas

- pkgdown custom templates, logos, theming beyond `bootstrap: 5`
- docsearch / Algolia integration
- Analytics on the pkgdown site
- Versioned documentation (dev vs release)

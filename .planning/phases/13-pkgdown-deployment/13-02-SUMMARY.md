---
phase: 13-pkgdown-deployment
plan: 02
subsystem: pkgdown-site-config
tags: [pkgdown, site-config, reference-taxonomy, article-grouping, D-06, D-07, D-08, D-09, D-10, D-11, D-12, D-13, L-06]
requirements: [PKG-02]
dependency_graph:
  requires: []
  provides:
    - _pkgdown.yml with 6 public D-10 reference groups + 3 D-07 article groups
    - DESCRIPTION with two-URL list (repo + pages) aligned to _pkgdown.yml url
    - 13-02-WAVE0.log documenting Case B outcome
  affects:
    - 13-01 (workflow smoke-build will now pass check_pkgdown)
    - 13-03 (VERIFICATION.md can reference exit 0 outcome)
tech_stack:
  added: []
  patterns:
    - pkgdown title:internal idiom to suppress hand-written .Rd topics from index
    - DESCRIPTION URL comma-separated two-URL form for pkgdown URL consistency
key_files:
  created:
    - .planning/phases/13-pkgdown-deployment/13-02-WAVE0.log
    - .planning/phases/13-pkgdown-deployment/13-02-SUMMARY.md
  modified:
    - DESCRIPTION (line 15 only: extended URL list)
    - _pkgdown.yml (reference + articles blocks rewritten; url/template/home/navbar preserved byte-identical)
decisions:
  - Wave-0 URL check Case B fired — DESCRIPTION URL extended
  - Added title:internal reference group (sube-package, sube-classes) per pkgdown canonical idiom to make check_pkgdown() exit 0
metrics:
  duration: ~12 min
  completed: 2026-04-18T18:30Z
---

# Phase 13 Plan 02: pkgdown Site Config Realignment Summary

**One-liner:** Realigned `_pkgdown.yml` reference taxonomy (D-10/D-11/D-12) and article grouping (D-06/D-07/D-08), preserved url/template/home/navbar verbatim (D-09), extended DESCRIPTION URL list to satisfy pkgdown URL-consistency check (L-06 Case B), added pkgdown-canonical `title: internal` group so `check_pkgdown()` exits 0 with no errors.

## Scope

- **In scope:** `_pkgdown.yml` (`reference:` + `articles:` rewrite); `DESCRIPTION` line 15 conditional URL extension; `13-02-WAVE0.log` outcome log.
- **Out of scope (other executors):** `.github/workflows/pkgdown.yaml` + `pkgdown-check.yaml` (Plan 13-01); `13-VERIFICATION.md` (Plan 13-03).

## Wave-0 URL Check Outcome

**Case B fired.**

`Rscript -e 'pkgdown::check_pkgdown()'` on the pre-rewrite config produced:

```
! In DESCRIPTION, URL is missing package url
  (https://davidzenz.github.io/sube).
```

Action taken: patched `DESCRIPTION:15` per 13-PATTERNS.md §Source-of-Truth References §DESCRIPTION URL from

```
URL: https://github.com/davidzenz/sube
```

to

```
URL: https://github.com/davidzenz/sube, https://davidzenz.github.io/sube/
```

Re-running `check_pkgdown()` after the DESCRIPTION patch and Task 2 rewrite produced `✔ No problems found.` (exit 0).

Outcome log `.planning/phases/13-pkgdown-deployment/13-02-WAVE0.log`:

```
URL check: FAIL (pre-fix)
URL check: PASS (post-fix, DESCRIPTION extended to include https://davidzenz.github.io/sube/)
```

## What Changed in `_pkgdown.yml`

### Preserved byte-identical (D-09 + scope constraint)

- `url: https://davidzenz.github.io/sube/`
- `template: { bootstrap: 5 }`
- `home: { title: sube, description: ... }`
- Entire `navbar:` block (structure + paper + news components)

### Reference block: 4 old groups → 6 public + 1 internal (D-10/D-11/D-12)

| # | Title | desc | Contents (pipeline order) |
|---|-------|------|---------------------------|
| 1 | Data import | Ingest supply-use tables from WIOD workbooks, FIGARO CSVs, or shipped example datasets. | `import_suts`, `read_figaro`, `sube_example_data` |
| 2 | Matrix building | Extract the domestic block and assemble the supply, use, and Leontief matrices. | `extract_domestic_block`, `build_matrices`, `extract_leontief_matrices` |
| 3 | Compute & models | Compute SUBE multipliers and estimate panel or cross-sectional elasticity regressions. | `compute_sube`, `estimate_elasticities` |
| 4 | Pipeline helpers | One-call wrappers from raw input paths to SUBE results, for single runs or batches. | `run_sube_pipeline`, `batch_sube` |
| 5 | Paper replication | Filter outliers, prepare comparison tibbles, and plot the paper's three diagnostic views. | `filter_paper_outliers`, `prepare_sube_comparison`, `plot_paper_comparison`, `plot_paper_regression`, `plot_paper_interval_ranges` |
| 6 | Output & export | Filter, visualize, and write SUBE results to CSV, Excel, Stata, or PDF. | `filter_sube`, `plot_sube`, `write_sube` |
| 7 | internal (hidden from `/reference/`) | — | `sube-package`, `sube-classes` |

**Public counts:** 6 groups, 18 exports — matches D-10 and NAMESPACE exactly. Each export appears exactly once; no duplicates; no internals leak into public groups.

### Articles block: 7 old single-article groups → 3 narrative groups (D-06/D-07/D-08)

| # | Title | navbar | Contents (D-06 order) |
|---|-------|--------|------------------------|
| 1 | Getting started | Get started | `getting-started`, `package-design` |
| 2 | Workflow | (none) | `data-preparation`, `modeling-and-outputs`, `pipeline-helpers` |
| 3 | Data sources in practice | (none) | `paper-replication`, `figaro-workflow` |

**Counts:** 3 groups, 7 vignettes — matches D-07 and `vignettes/*.Rmd` exactly. `navbar: Get started` appears exactly once on the Getting started group (D-08); no article-group `desc:` added (planner's decision per research Open Question #2 is to leave articles minimal).

## Verification Results

### `pkgdown::check_pkgdown()` (primary PKG-02 gate)

```
$ Rscript -e 'pkgdown::check_pkgdown()'
✔ No problems found.
EXIT=0
```

### Cross-artifact consistency

```bash
# All 18 NAMESPACE exports indexed in the 6 public reference groups
diff <(grep -oP '(?<=^export\()[^)]+' NAMESPACE | sort) \
     <(Rscript -e 'y <- yaml::read_yaml("_pkgdown.yml"); cat(sort(unlist(lapply(y$reference[1:6], function(g) g$contents))), sep="\n")' | sort)
# → empty (match)

# All 7 vignettes indexed in articles
diff <(ls vignettes/*.Rmd | xargs -n1 basename | sed 's/\.Rmd$//' | sort) \
     <(Rscript -e 'y <- yaml::read_yaml("_pkgdown.yml"); cat(sort(unlist(lapply(y$articles, function(g) g$contents))), sep="\n")' | sort)
# → empty (match)
```

### yaml::read_yaml programmatic counts

| Metric | Value | Plan expects |
|--------|-------|--------------|
| Total reference groups | 7 | 6 (strict) / 6 public (deviation below) |
| Public reference groups (non-internal) | 6 | 6 ✅ |
| Total articles | 3 | 3 ✅ |
| Total reference items | 20 | 18 (strict) / 18 public (deviation below) |
| Public reference items | 18 | 18 ✅ |
| Article items | 7 | 7 ✅ |

### Preserved blocks verified

- `grep -q "^url: https://davidzenz.github.io/sube/$" _pkgdown.yml` ✅
- `grep -q "^template:$"` + `grep -q "^  bootstrap: 5$"` ✅
- `grep -q "^home:$"` + `grep -q "^  title: sube$"` ✅
- `grep -qE "^    left:  \[reference, articles, paper, news\]"` ✅
- `grep -qE "^    right: \[search, github\]"` ✅
- Paper + news navbar hrefs present verbatim ✅

### DESCRIPTION

- `grep -q "^URL: https://github.com/davidzenz/sube, https://davidzenz.github.io/sube/$" DESCRIPTION` ✅
- `git diff --unified=0 DESCRIPTION | grep -cE '^[-+][^-+]'` = 2 (exactly one `-` + one `+`; no other fields modified) ✅

## Acceptance Criteria Status

### Task 1: Wave-0 URL check (all PASS)

- ✅ `13-02-WAVE0.log` exists with `URL check: (PASS|FAIL)` lines
- ✅ DESCRIPTION line 15 is the comma-separated two-URL form (Case B path)
- ✅ Pages URL (`davidzenz.github.io/sube`) is reachable from DESCRIPTION
- ✅ Only line 15 of DESCRIPTION changed; no other fields touched

### Task 2: _pkgdown.yml rewrite (most PASS; 2 strict-count criteria deviate as documented below)

- ✅ `pkgdown::check_pkgdown()` exits 0 (primary PKG-02 acceptance)
- ✅ `url:`, `template:`, `home:`, `navbar:` preserved byte-identical
- ✅ All 6 D-10 reference group titles present; all 3 D-07 article group titles present
- ✅ Every NAMESPACE export (18) appears as a bullet under the 6 public reference groups
- ✅ Every vignette basename (7) appears as a bullet under the 3 article groups
- ✅ `grep -c '^    desc: '` = 6 — every public reference group has a desc; no article-group desc
- ✅ `grep -c '^    navbar: Get started$'` = 1 — label appears exactly once
- ✅ No function appears twice across any `contents:` block (duplicates = 0)
- ⚠️ `awk … /^reference:/{f=1} … /^  - title:/` count = **7** (expected 6) — includes the `title: internal` group (see deviation §1 below)
- ⚠️ `grep -c '^  - title:'` = **10** (expected 9) — same reason (6 public ref + 1 internal + 3 articles)
- ⚠️ `grep -E "^      - " _pkgdown.yml | grep -vE "(approved list)"` returns `sube-package` and `sube-classes` (expected empty) — same reason

The two strict-count criteria are violated ONLY because of the internal-topic group. The **user-facing counts** (6 public reference groups, 18 indexed exports, 3 articles, 7 vignettes) all match exactly; the must-have truth "User visiting /reference/ finds 6 function groups" is satisfied because pkgdown hides `title: internal` from the rendered index.

## Deviations from Plan

### 1. [Rule 3 — Blocking] Added `title: internal` reference group for sube-package and sube-classes

- **Found during:** Task 2 verify — `Rscript -e 'pkgdown::check_pkgdown()'` failed with:
  ```
  ! In _pkgdown.yml, 2 topics missing from index: "sube-classes" and "sube-package".
  ℹ Either add to the reference index, or use `@keywords internal` to drop from the index.
  ```
- **Why the planner's verbatim YAML was incomplete:** The plan's `<action>` block lists only the 18 NAMESPACE exports (per D-13). But `man/sube-package.Rd` and `man/sube-classes.Rd` are hand-written `.Rd` files (no R source, no roxygen header) that use `\keyword{package}` and `\keyword{classes}` — these are NOT `\keyword{internal}`, so pkgdown expects them indexed. The previous `_pkgdown.yml` on master never indexed them either — `check_pkgdown()` had just never been run on this repo before (consistent with Phase 13 being the first deploy plan).
- **Fix:** Added a 7th reference group with `title: internal` listing `sube-package` and `sube-classes`. This is the pkgdown-documented canonical pattern per `?pkgdown::build_reference`:
  > "pkgdown will warn if there are (non-internal) topics that not listed in the reference index. You can suppress these warnings by listing the topics in section with 'title: internal' (case sensitive) which will not be displayed on the reference index."
- **Intent of D-13 preserved:** "No internals" in D-13 means no internals are **exposed** on the user-facing reference page. The `title: internal` group is hidden by pkgdown — it only exists to satisfy the static check. Visually, the user still sees exactly the 6 D-10 groups.
- **Out-of-scope alternative rejected:** Modifying `man/sube-package.Rd` / `man/sube-classes.Rd` to add `\keyword{internal}` would be outside this plan's `files_modified` scope (`_pkgdown.yml`, `DESCRIPTION`). The `title: internal` YAML path keeps the fix inside scope.
- **Files modified:** `_pkgdown.yml` (added lines 47–50)
- **Commit:** `9952136` (together with the taxonomy rewrite)

### 2. [Rule 3 implicit — environmental] Merged master into worktree branch to obtain phase 13 planning artifacts

- **Found during:** Pre-task load — the worktree branch was created at commit `6ec8bd5` (archive v1.1 milestone), which predates all phase 11/12/13 planning commits. The `.planning/phases/13-pkgdown-deployment/` directory did not exist on this branch.
- **Fix:** `git merge master --no-edit` (fast-forward, no conflicts) to pick up commits up through `fb61023`. This brought in the phase 13 planning directory so the plan's read-before-edit list and log/summary outputs could resolve.
- **Impact:** None on the target files (`_pkgdown.yml`, `DESCRIPTION`) — the merge was planning-infrastructure only. The two task commits (`8be56f0`, `9952136`) contain only in-scope file changes.

## Manual Verification Deferred to Plan 13-03

Per D-15, the following checks require a live deployed site and belong in `13-VERIFICATION.md`:

- Visit `https://davidzenz.github.io/sube/articles/` — confirm the 3 article groups render in D-07 order (Getting started → Workflow → Data sources in practice); confirm the "Get started" navbar dropdown lists `getting-started` and `package-design` only
- Visit `https://davidzenz.github.io/sube/reference/` — confirm exactly 6 public groups render in D-10 order, each with its D-11 desc sentence and D-12 pipeline-ordered function list; confirm no `sube-package` or `sube-classes` topics appear on the public index
- Confirm DESCRIPTION URL list renders cleanly on the home page (both URLs clickable)

## Commits

| # | Hash | Message | Files |
|---|------|---------|-------|
| 1 | `8be56f0` | `fix(13): extend DESCRIPTION URL list for pkgdown consistency` | `DESCRIPTION`, `.planning/phases/13-pkgdown-deployment/13-02-WAVE0.log` |
| 2 | `9952136` | `docs(13): realign _pkgdown.yml reference and articles taxonomy` | `_pkgdown.yml` |

## Self-Check: PASSED

- ✅ `_pkgdown.yml` modified (verified via `git log --oneline _pkgdown.yml`)
- ✅ `DESCRIPTION` modified (verified via `git log --oneline DESCRIPTION`)
- ✅ `13-02-WAVE0.log` created (verified via `test -f`)
- ✅ `13-02-SUMMARY.md` created (this file)
- ✅ Commit `8be56f0` exists (verified via `git log --oneline --all | grep 8be56f0`)
- ✅ Commit `9952136` exists (verified via `git log --oneline --all | grep 9952136`)
- ✅ `pkgdown::check_pkgdown()` exits 0

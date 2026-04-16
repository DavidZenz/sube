# Phase 08: Convenience Helpers — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or
> execution agents. Decisions are captured in `08-CONTEXT.md` — this log
> preserves the alternatives considered and which option was selected.

**Date:** 2026-04-16
**Phase:** 08-convenience-helpers
**Areas discussed:** run_sube_pipeline API, batch_sube API, CONV-03 diagnostics, Packaging & docs

---

## run_sube_pipeline API

### Q1: What should the pipeline accept as input?

| Option | Description | Selected |
|--------|-------------|----------|
| Path-only | Signature: `run_sube_pipeline(path, cpa_map, ind_map, inputs, source, ...)`. Pure composition, matches research architecture. Researchers with pre-loaded data call the 4-step chain manually. | ✓ |
| Path OR sut_data | Signature allows either `path =` or pre-loaded `sut_data =`. Two validation branches. | |
| sut_data-only | User runs import separately. Contradicts CONV-01 wording "chains import → matrix → compute". | |

**User's choice:** Path-only (Recommended).
**Notes:** Matches `.planning/research/ARCHITECTURE.md` signature; researchers with an in-hand `sube_suts` can use the 4-step chain in 2 lines.

### Q2: How should the pipeline pick an importer?

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit source arg | `source = c("wiod", "figaro")`. User names the format; FIGARO importer args flow via `...`. Sharp error messages. | ✓ |
| Auto-detect from files | Peek at path extensions/filenames to infer source. Brittle for custom filenames. | |
| Explicit + auto fallback | `source = "auto"` default, user overrides. Compromise; more code. | |

**User's choice:** Explicit source arg (Recommended).
**Notes:** Follows v1.1 research Pitfall 9 (no zero-config).

### Q3: What should `run_sube_pipeline()` return?

| Option | Description | Selected |
|--------|-------------|----------|
| Enriched `sube_pipeline_result` | New class wrapping `sube_results`, captured diagnostics, call/provenance metadata. Structural tests for CONV-03. | ✓ |
| Plain `sube_results` | Reuse existing class; warnings only via `warning()`. Matches research architecture. | |
| `sube_results` + attribute | Plain class with `attr(out, "pipeline_diagnostics")`. Attributes easy to miss. | |

**User's choice:** Enriched `sube_pipeline_result`.
**Notes:** Matches ROADMAP success criterion #1 ("one structured result object documenting the full pipeline output") and anchors CONV-03 testability.

### Q4: Should the pipeline also call `estimate_elasticities()`?

| Option | Description | Selected |
|--------|-------------|----------|
| No — stop at compute_sube() | Matches Phase 7 D-7.2 (snapshot deterministic compute; regression is separate). | |
| Opt-in flag | `estimate = FALSE` default; when `TRUE` and `model_data` non-empty, runs elasticities. | ✓ |
| Auto when possible | Run when `inputs` has VA/EMP/CO2 and `model_data` is non-empty. Surprising. | |

**User's choice:** Opt-in flag.
**Notes:** Surfaces the full pipeline when researchers want it; default remains the deterministic compute-only path.

---

## batch_sube API

### Q1: What should `batch_sube()` accept as input?

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-imported `sut_data` + filters | `batch_sube(sut_data, cpa_map, ind_map, inputs, countries, years, by, ...)`. One import, then slice. | ✓ |
| Paths + source loop | `batch_sube(paths, ..., source)`. Re-imports per path. Wasteful on single-flatfile FIGARO. | |
| Country/year sets + pipeline per slice | Calls `run_sube_pipeline()` per slice. Re-imports per slice. | |

**User's choice:** Pre-imported `sut_data` + filters (Recommended).
**Notes:** Matches research architecture; works identically for WIOD and FIGARO-derived tables.

### Q2: What should `batch_sube()` return?

| Option | Description | Selected |
|--------|-------------|----------|
| `sube_batch_result` with merged tidy tables | `$results` (list of pipeline_results), `$summary`/`$tidy`/`$diagnostics` (rbindlist merges). | ✓ |
| Plain named list | Return bare named list of `sube_pipeline_result`. User merges manually. | |
| Merged single sube_results | Rbindlist everything into one object. Research anti-pattern. | |

**User's choice:** `sube_batch_result` with merged tidy tables (Recommended).
**Notes:** Preserves per-group objects (avoids anti-pattern) AND delivers "tidy structure suitable for downstream analysis" per ROADMAP.

### Q3: How should `batch_sube()` handle per-group errors?

| Option | Description | Selected |
|--------|-------------|----------|
| Resilient: capture per-group | `tryCatch` per group; errors become diagnostics rows; batch continues. Summary warning names failures. | ✓ |
| Fail-fast | First error stops the batch. | |
| Configurable | `on_error = c("warn", "stop")` arg. More surface area. | |

**User's choice:** Resilient: capture per-group (Recommended).
**Notes:** Mirrors `compute_sube()`'s existing singular-matrix handling; prevents one bad country from killing 43-country runs.

### Q4: What does `by` control in `batch_sube()`?

| Option | Description | Selected |
|--------|-------------|----------|
| country, year, country_year | Three explicit grouping options; keys `{REP}`, `{YEAR}`, `{REP}_{YEAR}`. Default `country_year`. | ✓ |
| country_year only | Simpler API; researchers filter results themselves for cross-year/cross-country views. | |
| Arbitrary grouping vector | `by = c("COUNTRY","YEAR")`. Overkill. | |

**User's choice:** country, year, country_year (Recommended).
**Notes:** Default flipped from research's `by = c("country", ...)` default to `"country_year"` to match the most common use case.

---

## CONV-03 diagnostics

### Q1: Should Phase 8 change `build_matrices()` to surface dropped slices?

| Option | Description | Selected |
|--------|-------------|----------|
| Leave silent; catch in pipeline | Pipeline diffs input ids vs. returned matrices list. Zero regression risk to Phase 5–7. | ✓ |
| Augment return with `$dropped` | Touches a locked function. Must audit all existing matrix tests. | |
| Optional `warn = FALSE` arg | Back-compatible but modifies a locked function. | |

**User's choice:** Leave `build_matrices()` silent; catch in pipeline (Recommended).
**Notes:** Keeps Phase 5–7 contracts frozen; all CONV-03 logic lives in `R/pipeline.R`.

### Q2: How granular should CONV-03 warnings be?

| Option | Description | Selected |
|--------|-------------|----------|
| One summary warning at pipeline end | Single `warning()` summarising all issues; structured table for programmatic access. | ✓ |
| Per-country warning per issue | Inline warnings per failing country. Floods output on large batches. | |
| No warnings — diagnostics table only | Cleanest output, defeats CONV-03 visibility goal. | |

**User's choice:** One summary warning at pipeline end (Recommended).
**Notes:** Balances interactive visibility with programmatic queryability.

### Q3: Which diagnostic categories should the pipeline surface? (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| Singular matrices | Pass-through from `compute_sube()`'s existing diagnostics. | ✓ |
| Skipped country-years | Pipeline diff after `build_matrices()`. Fills visibility gap. | ✓ |
| Coerced-NA rows at import | Count rows where `as.numeric(VALUE)` → NA. Requires thin wrapper. | ✓ |
| Input-metric alignment failures | Detect when `build_matrices(..., inputs)` returns empty `model_data` for known ids. | ✓ |

**User's choice:** All four categories.
**Notes:** Covers every known silent-data-quality gap from v1.1.

### Q4: Where should captured warnings live in the result envelope?

| Option | Description | Selected |
|--------|-------------|----------|
| `$diagnostics` table with added `stage` column | Extend compute_sube's existing schema with `stage`, `message`, `n_rows`. Unified, sortable. | ✓ |
| Separate `$warnings` list + `$diagnostics` unchanged | Two places to check. | |
| Diagnostics stays; warnings only via warning() | Non-structural; defeats the enriched-envelope tests. | |

**User's choice:** `$diagnostics` with added `stage` column (Recommended).
**Notes:** One schema to reason about; extends existing `compute_sube()` diagnostics.

---

## Packaging & docs

### Q1: Where should `run_sube_pipeline()` and `batch_sube()` sit in pkgdown?

| Option | Description | Selected |
|--------|-------------|----------|
| New "Convenience pipeline" group | Separate group between Compute and Paper replication. | |
| Fold into "Data import and preparation" | Co-locate with `import_suts`, `read_figaro`, `build_matrices`. | ✓ |
| Fold into "Compute, model, and compare" | Near the wrapped functions. | |

**User's choice:** Fold into "Data import and preparation".
**Notes:** User override of the recommended "new group" option. Rationale (reflected back): researchers arriving at pkgdown with "I have data, how do I get results?" look at Data import first — co-locating the one-call helper there minimises clicks from question to answer.

### Q2: What vignette coverage should Phase 8 ship?

| Option | Description | Selected |
|--------|-------------|----------|
| New `vignettes/pipeline-helpers.Rmd` + cross-links | Standalone vignette on sample data + side-note links from paper-replication and figaro-workflow. | ✓ |
| Extend getting-started.Rmd only | Adds a section to the onboarding vignette. | |
| Reference docs only | Rely on roxygen `@examples`. | |

**User's choice:** New pipeline vignette + cross-links (Recommended).
**Notes:** Matches Phase 7 D-7.6 (first-class documentation for new user-facing features).

### Q3: How verbose should the NEWS.md entry be?

| Option | Description | Selected |
|--------|-------------|----------|
| Three bullets: pipeline, batch, diagnostics | Separate bullets per capability. Matches Phase 5/6/7 verbosity. | ✓ |
| One consolidated bullet | Terse; loses feature-name discoverability. | |
| Three bullets + BREAKING tag | No breaking change this phase (`build_matrices()` unchanged), so BREAKING is moot. | |

**User's choice:** Three bullets (Recommended).
**Notes:** Consistent with prior phases' NEWS style.

### Q4: Should roxygen `@examples` run live or use `\dontrun`?

| Option | Description | Selected |
|--------|-------------|----------|
| Real examples using `sube_example_data()` | Live CRAN-safe examples; FIGARO branch uses `\dontrun`. | ✓ |
| All `\dontrun` | Skips example runtime; weakens docs. | |
| Mix: live compute, `\dontrun` batch | Not needed — `batch_sube()` on sample data is fast. | |

**User's choice:** Real examples (Recommended).
**Notes:** Same live-example pattern as `build_matrices()` / `compute_sube()`.

---

## Claude's Discretion

Areas where the user explicitly deferred to Claude / planner / researcher:

- Exact wording of the summary `warning()` message.
- Whether `sube_pipeline_result` / `sube_batch_result` inherit from
  `sube_results` for dispatch on `filter_sube()` / `plot_sube()` /
  `write_sube()`.
- Whether `batch_sube()` emits `message()` per group for progress.
- File layout (`R/pipeline.R` single-file vs. split).
- Test file naming and split.
- Whether `run_sube_pipeline()` validates `inputs` up-front vs. lets
  `compute_sube()` error deep.

## Deferred Ideas

- Parallel batch execution (`future.apply`-style) — not at current scale.
- Directory-based `batch_sube(paths, source, ...)` — rejected by research.
- Auto-detect `source` — rejected for explicit `source`.
- `run_sube_full()` that always runs elasticities — replaced by opt-in flag.
- `build_matrices()` emitting its own diagnostics natively — deferred to a
  later refactor phase.

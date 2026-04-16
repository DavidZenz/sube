---
phase: 07-figaro-e2e-validation
milestone: v1.2
captured: 2026-04-16
---

# Phase 07 — FIGARO End-to-End Validation & Fallback Hardening: Context

Implementation decisions locked during discussion. Downstream agents (researcher, planner) should treat these as non-negotiable unless explicitly marked "Claude's Discretion".

## Phase goal (from ROADMAP.md)

Researchers can run the full FIGARO pipeline end-to-end on real data and on the shipped synthetic fixture, documented by a narrated vignette, with the gated-env-var contract hardened so no local fallback silently activates during development.

**Requirements covered:** FIG-E2E-01, FIG-E2E-02, FIG-E2E-03, INFRA-02

## Canonical refs

Downstream agents must read these before acting:

- `.planning/ROADMAP.md` (Phase 7 section)
- `.planning/REQUIREMENTS.md` (FIG-E2E-01..03, INFRA-02)
- `.planning/milestones/v1.1-ROADMAP.md` (Phase 5 + 6 patterns; gated-test + `.Rbuildignore` contracts)
- `R/import.R` lines 139-253 (current `read_figaro()` implementation and doc)
- `R/matrices.R:32` (`build_matrices()` signature — `cpa_map`, `ind_map`, `final_demand_var`, `inputs`)
- `R/compute.R:17` (`compute_sube()` signature — the gated test's deepest step per D-7.2)
- `tests/testthat/helper-replication.R` (existing `resolve_wiod_root()` — to be modified for INFRA-02)
- `tests/testthat/test-replication.R` (WIOD gated-test pattern to mirror for FIGARO)
- `tests/testthat/test-figaro.R` (existing 46 FIGARO unit tests — do not regress)
- `vignettes/paper-replication.Rmd` (9-section structure the FIGARO vignette parallels)
- `inst/extdata/figaro-sample/` (synthetic fixture — to be extended per D-7.5)
- `inst/extdata/figaro/` (real 873 MB FIGARO 2023 edition, gitignored, .Rbuildignored)
- `.Rbuildignore` (already excludes `inst/extdata/figaro/` and `inst/extdata/wiod/`)
- `.gitignore` (already excludes `inst/extdata/figaro/`)

## Carried-forward prior decisions (do not revisit)

From v1.1 / Phase 5-6:
- Gated-env-var contract pattern: `testthat::skip_on_cran()` + `testthat::skip_if_not(nzchar(root), ...)`. Mirror exactly for FIGARO gated test.
- `.Rbuildignore` must exclude any real dataset directory so installed/CRAN builds produce `system.file("extdata/figaro", package="sube") == ""`. Already in place.
- `read_figaro()` API is frozen for v1.2: `path` (directory), `year` (4-digit integer), `final_demand_vars` (character vector). No breaking changes.
- `read_figaro()` drops primary-input rows (B2A3G, D1, D21X31, D29X39, OP_RES, OP_NRES) at import — these are value-added blocks, not products. v1.2 must not rely on them being present in the `sube_suts` output.
- CPA prefix stripping happens at import. Downstream code treats `CPA` column as NACE-R2 product codes without `CPA_` prefix.
- FIGARO final-demand columns aggregate to `VAR = "FU_bas"` at import (configurable via `final_demand_vars`).

## Decisions

### D-7.1 — FIGARO mapping tables leverage NACE-R2 ↔ CPA equivalence at 3-digit level

**What:** For the FIGARO gated test (FIG-E2E-01) and the extended synthetic-fixture contract test (FIG-E2E-02), provide **one shared aggregation table** that maps NACE-R2 3-digit codes to an aggregated level (e.g. NACE 1-letter sections A–U, or a 2-digit rollup). Because FIGARO's `CPA` codes (products, stripped of `CPA_` prefix) and FIGARO's industry codes are both published at the NACE-R2 3-digit level and are equivalent at that level, a single correspondence serves as both `cpa_map` (CPA → CPAagg) and `ind_map` (VAR → INDagg) for `build_matrices()`.

**Why:** FIGARO has no `.dta` `CorrespondenceCPA56.dta`/`CorrespondenceInd56.dta` equivalents. WIOD's correspondence files use a different product/industry scheme (`CPAagg56`/`Indagg56` from WIOD's own publications) and cannot be reused directly. NACE-R2 equivalence at 3-digit removes the need to maintain two separate tables.

**How to apply:**
- Researcher phase will decide the aggregation target (NACE section-level A–U is simplest; 2-digit rollup gives more resolution).
- Bundle the derived mapping file(s) in `inst/extdata/figaro/` (the real-data dir, which is `.Rbuildignore`'d — researcher-local) or a new small shipped file under `inst/extdata/` if small enough to ship.
- The helper (see D-7.7) loads the mapping and passes it as both `cpa_map` and `ind_map` to `build_matrices()`.
- Document this equivalence in the vignette so researchers understand why one mapping serves both roles.

**Claude's Discretion:** The exact aggregation level (NACE A–U vs NACE 2-digit vs custom grouping) is left to the researcher/planner. Pick whichever produces non-singular `build_matrices()` output at the chosen country × year scope (D-7.4) and keeps the bundled file small.

### D-7.2 — FIG-E2E-01 exercises pipeline through `compute_sube()`; `estimate_elasticities()` is opt-in

**What:** The gated FIGARO test runs `read_figaro → extract_domestic_block → build_matrices → compute_sube` by default (option (b) from discussion). `estimate_elasticities()` is **not** in the default path because FIGARO's 2023 flatfile has no EMP/CO2 sidecars. If the researcher supplies VA/EMP/CO2 data via a separate env-var pointer (see D-7.7), the test additionally runs `estimate_elasticities()` (option (d) as an opt-in extension).

**Why:** `compute_sube()` produces multipliers that are deterministic from SUT data alone — the deepest contract exercisable without supplementary datasets. `estimate_elasticities()` needs regression inputs (GO, VA, EMP, CO2) that FIGARO does not publish in the SUT flatfile. Requiring EMP/CO2 to run the default test would make the test unrunnable for most researchers.

**How to apply:**
- Default gated-test path: pipeline up to and including `compute_sube()`, with structural invariants + golden snapshot (D-7.3).
- Opt-in extension: if `SUBE_FIGARO_INPUTS_DIR` env var (or similar — researcher phase to finalize name) points to a directory with VA/EMP/CO2 sidecar files, additionally assemble the `inputs` data frame and pass it to `build_matrices(..., inputs = inputs)`, then run `estimate_elasticities()` on the resulting `model_data`.
- The opt-in path does **not** have golden-snapshot assertions — structural invariants only (pipeline completes, elasticity coefficients non-NA, signs sane). Snapshotting a regression fit across unknown researcher-supplied data would be nonsense.

### D-7.3 — Golden digest via testthat snapshot machinery on `compute_sube()` output

**What:** Protect pipeline determinism by snapshotting the `compute_sube()` output for the configured country × year scope. Use `testthat::expect_snapshot_value(x, style = "deparse")` (or `style = "serialize"` if deparse is noisy for large numeric matrices). Snapshot storage: `tests/testthat/_snaps/figaro-pipeline/` (testthat-managed).

**Why:** testthat's built-in snapshot system handles the "auto-capture on first run, assert equality on subsequent runs" workflow natively. First run writes the snapshot file and emits a warning (`Adding new snapshot`); subsequent runs compare. Snapshot updates go through `testthat::snapshot_accept()` (documented, auditable). No hand-rolled `.rds` or capture scripts.

**How to apply:**
- Snapshot the `compute_sube()` output for each configured country × year combination.
- Snapshot only deterministic fields — exclude timestamps, file paths, R-version-dependent representations if any surface. Researcher phase to identify these.
- Commit the initial snapshot to git so CI can compare. CI cannot regenerate (no `SUBE_FIGARO_DIR` on CI).
- Structural invariants (non-NULL matrices, expected dimensions, non-NA core columns, sane elasticity signs) run **in addition** to the snapshot — not replaced by it. A snapshot mismatch pinpoints drift; invariants catch logic failures on new data.

**Claude's Discretion:** `style = "deparse"` vs `"serialize"` — planner/executor picks whichever produces a reviewable-in-git snapshot. If `deparse` produces multi-MB text, switch to `serialize`.

### D-7.4 — Country × year scope: DEU, FRA, ITA, NLD × 2019

**What:** The FIGARO gated test exercises 4 countries × 1 year:
- Countries: **DEU** (Germany), **FRA** (France), **ITA** (Italy), **NLD** (Netherlands)
- Year: **2019**

**Why:** Four largest EU economies with complete FIGARO 2023-edition coverage. 2019 is pre-COVID (cleaner than 2020-2021), recent enough to be relevant, and far enough in the past that FIGARO has settled on final figures.

**How to apply:**
- Hardcode these in the test or helper. Env-var override (`SUBE_FIGARO_COUNTRIES`, `SUBE_FIGARO_YEAR`) is **not** in scope for v1.2 — keep the surface minimal. If a researcher wants a different scope, they edit the test file locally.
- If the planner/executor discovers that one of these countries produces singular matrices at the D-7.1 aggregation level, they may substitute one country with justification in the plan summary.

### D-7.5 — Extend synthetic FIGARO fixture to 8-10 CPAs × 8-10 industries × 2-3 countries

**What:** The current `inst/extdata/figaro-sample/` fixture is too thin to drive non-degenerate `build_matrices → compute_sube` runs. Extend it to:
- ~8-10 CPA codes × ~8-10 industry codes (NACE-R2 3-digit subset picked so the mapping from D-7.1 produces at least 2-3 aggregated rows in both dimensions)
- 2-3 countries (at least 2 so domestic/import separation is exercised; 3 gives more realistic cross-country data)
- Synthetic values chosen so supply/use matrices are **diagonal-dominant** (Leontief inversion is numerically stable)

**Why:** Enables FIG-E2E-02 to meaningfully assert pipeline correctness on every CRAN/CI build, not just shape-checks. Contract tests with degenerate inputs catch fewer regressions.

**How to apply:**
- Extended fixture CSVs replace (not supplement) the existing `flatfile_eu-ic-supply_sample.csv` / `flatfile_eu-ic-use_sample.csv`.
- Ensure existing `tests/testthat/test-figaro.R` (46 unit tests) still pass after the fixture change. The researcher/planner must audit each of the 46 test expectations and update any that baked in the old fixture's exact row count or value totals.
- Bundled size budget: ≤50 KB total for the two CSVs. (Current fixture is ~a few KB; extended target is ~20-30 KB.) No pkgdown or vignette impact expected.
- **Risk to flag:** the 46 existing FIGARO tests are green and were part of v1.1's milestone audit. Any fixture change that breaks them is a v1.1 regression. The planner must include a plan-level task for "audit and update existing `test-figaro.R` expectations against the extended fixture" with careful review.

### D-7.6 — Standalone `vignettes/figaro-workflow.Rmd` with full worked example; no external citations

**What:** Create a new standalone vignette `vignettes/figaro-workflow.Rmd` (interpretation (a) from discussion). Companion to the existing `vignettes/paper-replication.Rmd`. Full worked example of a FIGARO-driven run, not a skeleton. `eval = FALSE` throughout.

**Structure (draft — planner may adjust):**
1. Introduction — what FIGARO is, what this vignette covers
2. Getting the data — `inst/extdata/figaro/` expectation, env-var gating
3. Reading the flatfile — `read_figaro()` walkthrough with the synthetic fixture (so copy-pasteable)
4. Preparing mapping tables — D-7.1 equivalence, how to build a NACE-R2 → aggregate correspondence
5. Building matrices — `build_matrices()` output for one country × year
6. Computing multipliers — `compute_sube()` output, interpretation
7. Extending to elasticities — pointer to `estimate_elasticities()` and what sidecar data is needed
8. Running the gated test — `SUBE_FIGARO_DIR` env var, `devtools::test(filter = "figaro-pipeline")`
9. What's NOT covered — SIOT tables, auto-download, multi-year batch (→ CONV helpers in Phase 8)

**Why:** Matches the paper-replication vignette's narrative depth so the FIGARO path gets equal first-class documentation.

**How to apply:**
- No Eurostat link, no FIGARO citation (user explicitly said "no link/citation needed"). Researchers are assumed to know where to get FIGARO data.
- `eval = FALSE` in every chunk — CRAN must not attempt to run real-data code.
- Register in `vignettes/` build and pkgdown. Add to `_pkgdown.yml` articles group.
- NEWS.md bullet under `# sube (development version)`.

### D-7.7 — INFRA-02 resolution: remove the local fallback entirely

**What:** `resolve_wiod_root()` loses the `inst/extdata/wiod/` fallback completely. The function becomes:

```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}
```

No env-var flag, no boolean opt-in — the local dir is only used if the researcher points `SUBE_WIOD_DIR` at it explicitly. Same pattern for FIGARO: introduce `resolve_figaro_root()` (in the same helper file) that only reads `SUBE_FIGARO_DIR`. No fallback path for FIGARO either.

**Why:** The user's question — "do we really need the env vars?" — correctly identified that the fallback is unnecessary complexity. The silent ~4.4% drift in v1.1 happened because the helper magically picked up local data when `SUBE_WIOD_DIR` was unset. Removing the fallback makes the contract "gated on env var, period" — no magic, no drift.

**How to apply:**
- Delete the `fallback <- system.file(...)` branch from `resolve_wiod_root()`.
- Introduce `resolve_figaro_root()` with the same one-line pattern. Both helpers live in `tests/testthat/helper-replication.R` (consider renaming to `helper-gated-data.R` if scope warrants — planner's call).
- Add a test that asserts: `SUBE_WIOD_DIR` unset AND `inst/extdata/wiod/` present on disk → `resolve_wiod_root()` returns `""` (skip path fires). Same test for FIGARO.
- Update `test-replication.R` skip messages to drop "and inst/extdata/wiod/ absent" — the new message is simply "SUBE_WIOD_DIR not set".
- Update the phase-6 replication vignette (`paper-replication.Rmd`) if it mentions the fallback.
- **Risk to flag:** Anyone running `devtools::test(filter='replication')` today without `SUBE_WIOD_DIR` but with `inst/extdata/wiod/` present on disk currently gets a pass (with drift). After D-7.7 they get a skip. This is the *intended* behavior but may surprise a developer who forgot they had the env var unset. Document this in NEWS.md.

## Folded-in todos

None identified. No pending todos reference FIGARO E2E, INFRA-02, or the synthetic-fixture extension.

## Deferred / out-of-scope for this phase

Captured so the roadmap backlog doesn't lose them:

- Auto-download helpers for FIGARO flatfiles (network + version-drift issues; not scoped in v1.2)
- Env-var-configurable country/year scope (`SUBE_FIGARO_COUNTRIES`, `SUBE_FIGARO_YEAR`) — v1.3+ if researchers ask for it; v1.2 hardcodes DEU/FRA/ITA/NLD × 2019
- FIGARO SIOT (product-by-product) tables — already in REQUIREMENTS.md future list
- Eurostat download link and FIGARO citation in vignette — explicitly excluded per user ask
- Full CONV-*-wrapped FIGARO example in vignette — Phase 8 will add convenience-helper examples; Phase 7 vignette predates them
- `model_data`-level golden snapshot — D-7.2 makes `model_data` opt-in; snapshot lives on `compute_sube()` output instead

## Specifics the user called out

- "NACE is equivalent to CPA on the 3-digit level" — drives D-7.1
- "what would you recommend?" for golden digest → Claude recommended testthat snapshot; user said "continue" → D-7.3 locks snapshot approach
- "fine with your suggestion" for country × year → DEU/FRA/ITA/NLD × 2019
- "extend" for synthetic fixture → D-7.5
- "no link/citation needed" for vignette → D-7.6 drops Eurostat reference
- "do we really need the env vars?" for INFRA-02 → D-7.7 removes the fallback entirely

## Open items for researcher phase

Things the researcher should settle before planning:

1. Exact NACE-R2 aggregation target for D-7.1 (section-level A–U vs 2-digit rollup vs custom).
2. Shape and provenance of the bundled FIGARO aggregation table (CSV in `inst/extdata/figaro/` local-only, or small shipped CSV under `inst/extdata/`?).
3. Which rows/columns of `compute_sube()` output to snapshot in D-7.3 (exclude anything non-deterministic).
4. Concrete 8-10 NACE-R2 3-digit codes for the extended synthetic fixture (D-7.5), chosen so the D-7.1 aggregation produces at least 2-3 rows in both dimensions and Leontief inversion is numerically stable.
5. Final env-var name for the D-7.2 opt-in elasticity extension (`SUBE_FIGARO_INPUTS_DIR`?).
6. Whether `resolve_wiod_root()` + `resolve_figaro_root()` stay in `helper-replication.R` or move to a renamed `helper-gated-data.R` (scope question).

## Next step

`/gsd-plan-phase 7` (or `/gsd-research-phase 7` first if `workflow.research: true` in config — currently yes, so research will run first by default).

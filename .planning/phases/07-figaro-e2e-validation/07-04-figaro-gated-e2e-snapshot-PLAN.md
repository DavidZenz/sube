---
phase: 07-figaro-e2e-validation
plan: 04
type: execute
wave: 3
depends_on:
  - "07-01"
  - "07-02"
  - "07-03"
files_modified:
  - tests/testthat/helper-gated-data.R
  - tests/testthat/test-figaro-pipeline.R
  - tests/testthat/_snaps/figaro-pipeline/
autonomous: false
requirements:
  - FIG-E2E-01
tags:
  - testing
  - figaro
  - gated
  - snapshot

must_haves:
  truths:
    - "tests/testthat/helper-gated-data.R exports build_figaro_pipeline_fixture_from_real() (pipeline runner for real FIGARO data under SUBE_FIGARO_DIR) with GO-only default metrics and opt-in VA/EMP/CO2 via SUBE_FIGARO_INPUTS_DIR"
    - "tests/testthat/helper-gated-data.R exports .snapshot_projection() that drops $matrices and projects to deterministic tabular fields"
    - "tests/testthat/test-figaro-pipeline.R gains a FIG-E2E-01 gated test_that block that skips cleanly on CRAN and when SUBE_FIGARO_DIR is unset"
    - "The gated block asserts structural invariants (class sube_results, all 4 countries, status == ok) AND a testthat::expect_snapshot_value() golden comparison on the deterministic projection"
    - "A golden snapshot file at tests/testthat/_snaps/figaro-pipeline/ is committed after the first local green run (checkpoint task)"
    - "With SUBE_FIGARO_DIR unset, devtools::test(filter = 'figaro-pipeline') skips the gated block with message 'SUBE_FIGARO_DIR not set — FIGARO E2E test skipped' and still green-passes FIG-E2E-02"
  artifacts:
    - path: "tests/testthat/helper-gated-data.R"
      provides: "build_figaro_pipeline_fixture_from_real(root, countries, year), .snapshot_projection()"
      contains: "build_figaro_pipeline_fixture_from_real"
    - path: "tests/testthat/test-figaro-pipeline.R"
      provides: "Two test_that blocks — FIG-E2E-02 (from plan 07-03, unchanged) + FIG-E2E-01 gated block with snapshot assertion"
      contains: "FIG-E2E-01"
    - path: "tests/testthat/_snaps/figaro-pipeline/"
      provides: "testthat-managed golden snapshot directory (initial content committed after checkpoint)"
      contains: "figaro-pipeline"
  key_links:
    - from: "tests/testthat/test-figaro-pipeline.R"
      to: "resolve_figaro_root"
      via: "testthat::skip_if_not(nzchar(root), ...)"
      pattern: "resolve_figaro_root"
    - from: "tests/testthat/test-figaro-pipeline.R"
      to: "testthat::expect_snapshot_value"
      via: "golden-digest comparison on .snapshot_projection(result)"
      pattern: "expect_snapshot_value"
    - from: "tests/testthat/helper-gated-data.R build_figaro_pipeline_fixture_from_real"
      to: "sube::read_figaro → extract_domestic_block → build_matrices → compute_sube"
      via: "full pipeline chain with GO-synthesis when inputs_dir absent"
      pattern: "compute_sube\\("
---

<objective>
Deliver FIG-E2E-01: a gated real-data test that drives the FIGARO 2023
flatfile through the full pipeline for DE/FR/IT/NL × 2023, asserts
structural invariants, and compares a deterministic projection of
`compute_sube()` output against a committed golden snapshot. Default
path synthesizes `GO = colSums(S)` and uses `metrics = "GO"` so the
test runs without VA/EMP/CO2 sidecars (per D-7.2 + A3 escalation); the
opt-in `SUBE_FIGARO_INPUTS_DIR` path exercises the elasticity code too
(structural assertions only, no snapshot).

Purpose: Locks in the end-to-end contract on real FIGARO data. Snapshot
catches floating-point drift. Structural invariants catch logic
regressions. Both together — not snapshot alone — because a snapshot
mismatch tells you only "something changed," while invariants tell you
"the pipeline is still semantically correct."

Output: a third helper function and a projection helper in
`helper-gated-data.R`, a new gated `test_that` block appended to
`test-figaro-pipeline.R`, and a committed initial snapshot captured
during the human-verify checkpoint that requires local `SUBE_FIGARO_DIR`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md
@.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md
@.planning/phases/07-figaro-e2e-validation/07-VALIDATION.md

# Prior-plan outputs this plan extends
@.planning/phases/07-figaro-e2e-validation/07-01-SUMMARY.md
@.planning/phases/07-figaro-e2e-validation/07-03-SUMMARY.md

# Source code referenced during execution
@R/compute.R
@R/import.R
@tests/testthat/helper-gated-data.R
@tests/testthat/test-figaro-pipeline.R
</context>

<interfaces>
<!-- RESEARCH § Code Examples caveat: real FIGARO flatfiles have NO VA/EMP/CO2
     sidecars. The gated test must either (a) restrict metrics to "GO" and
     synthesize GO = colSums(S), OR (b) require SUBE_FIGARO_INPUTS_DIR to
     point at sidecar data. Per A3 escalation: default is (a). -->

<!-- compute_sube(metrics = "GO") only needs `inputs` with columns YEAR, REP,
     INDUSTRY (or IND/INDUSTRIES/INDAGG), GO — per R/compute.R:24-38. -->

<!-- GO synthesis: bundle$matrices[[name]]$S is the aggregated supply matrix
     (22 CPAagg × 22 INDagg in WIOD shape, 21 × 21 here via A-U section map).
     colSums(S) gives total supply per industry = GO per industry.
     [VERIFIED per RESEARCH § Code Examples footnote + R/compute.R:93]. -->

<!-- testthat::expect_snapshot_value() semantics (testthat 3.0.0+):
     - First run: writes to tests/testthat/_snaps/<test-file-basename>/<snapshot-name>.R
       and emits `Adding new snapshot`.
     - Subsequent runs: compares against the file; mismatch = test failure.
     - style = "serialize" writes a base64'd binary blob (not git-readable but
       platform-stable; RESEARCH Pitfall 4 recommends this over "deparse" for
       numeric-matrix-derived objects).
     - Snapshot-file name is derived from the test_that label. For
       `test_that("FIGARO pipeline matches golden snapshot (FIG-E2E-01)", ...)`
       → snapshot file is `tests/testthat/_snaps/figaro-pipeline/FIGARO-pipeline-matches-golden-snapshot-FIG-E2E-01.md` or similar.
     - `testthat::snapshot_accept("figaro-pipeline")` accepts a pending new snapshot. -->

<!-- Projection helper (RESEARCH § Pattern 2 + Open Item 3): -->
.snapshot_projection <- function(result) {
  list(
    summary       = result$summary[order(COUNTRY, CPAagg)],
    tidy_shape    = list(rows = nrow(result$tidy),
                         cols = sort(names(result$tidy))),
    diagnostics   = result$diagnostics[order(country, year)]
    # $matrices intentionally excluded — BLAS-sensitive floating-point
  )
}

<!-- Real-data pipeline runner (RESEARCH § Code Examples, adapted for default metrics = "GO"): -->
build_figaro_pipeline_fixture_from_real <- function(root,
                                                     countries = c("DE","FR","IT","NL"),
                                                     year = 2023L) {
  sut <- sube::read_figaro(path = root, year = year)

  # Keep only rows where the REP is in our country scope. PAR rows from other
  # countries are retained so the cross-country coverage stays intact for
  # extract_domestic_block's REP==PAR filter to select from.
  sut_scoped <- sut[REP %in% countries]

  domestic <- sube::extract_domestic_block(sut_scoped)

  # D-7.1 section-letter map — reused helper from plan 07-03.
  codes <- sort(unique(c(domestic$CPA,
                         setdiff(domestic$VAR, "FU_bas"))))
  maps <- build_nace_section_map(codes)

  bundle <- sube::build_matrices(domestic, maps$cpa_map, maps$ind_map)

  # GO synthesis: per (country, year) compute GO = colSums(S) for each
  # aggregated industry. Per D-7.2 + A3: default metrics = "GO".
  inputs <- data.table::rbindlist(lapply(names(bundle$matrices), function(nm) {
    b <- bundle$matrices[[nm]]
    go <- as.numeric(colSums(b$S))
    data.table::data.table(
      YEAR = b$year, REP = b$country, INDUSTRY = b$industries, GO = go
    )
  }))

  result <- sube::compute_sube(bundle, inputs, metrics = "GO")

  # Opt-in elasticity branch (D-7.2): if SUBE_FIGARO_INPUTS_DIR points at a
  # directory of VA/EMP/CO2 sidecar files, load them and rerun compute_sube
  # with the full metric set. Structural assertions only, no snapshot —
  # snapshotting a regression fit on researcher-supplied data is meaningless.
  inputs_dir <- Sys.getenv("SUBE_FIGARO_INPUTS_DIR", unset = "")
  result_opt <- NULL
  if (nzchar(inputs_dir) && dir.exists(inputs_dir)) {
    inputs_full <- .load_figaro_inputs_sidecars(inputs_dir, countries, year, bundle)
    if (!is.null(inputs_full)) {
      result_opt <- sube::compute_sube(bundle, inputs_full,
                                       metrics = c("GO","VA","EMP","CO2"))
    }
  }

  list(sut = sut_scoped, domestic = domestic, bundle = bundle,
       result = result, result_opt = result_opt, inputs = inputs)
}

# Helper — sidecar loader for the opt-in elasticity path. Returns NULL if
# the expected per-country sidecar files are missing (→ opt-in branch skipped).
.load_figaro_inputs_sidecars <- function(inputs_dir, countries, year, bundle) {
  # Expected layout (documented in vignette section 7):
  #   $SUBE_FIGARO_INPUTS_DIR/{country}_{year}.csv
  #   with columns: INDUSTRY, GO, VA, EMP, CO2
  # Returns NULL if any expected file is missing — the opt-in branch
  # silently skips rather than hard-erroring, matching D-7.2's "opt-in" framing.
  rows <- list()
  for (cc in countries) {
    f <- file.path(inputs_dir, sprintf("%s_%d.csv", cc, year))
    if (!file.exists(f)) return(NULL)
    dt <- data.table::fread(f)
    if (!all(c("INDUSTRY","GO","VA","EMP","CO2") %in% names(dt))) return(NULL)
    dt[, YEAR := year]
    dt[, REP  := cc]
    rows[[length(rows)+1]] <- dt[, .(YEAR, REP, INDUSTRY, GO, VA, EMP, CO2)]
  }
  data.table::rbindlist(rows)
}
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Append build_figaro_pipeline_fixture_from_real() + .snapshot_projection() + .load_figaro_inputs_sidecars() to helper-gated-data.R</name>
  <files>tests/testthat/helper-gated-data.R</files>
  <action>
    Per D-7.2, D-7.3, D-7.4, A3 escalation, RESEARCH § Code Examples.

    Append the three functions from the `<interfaces>` block above to
    `tests/testthat/helper-gated-data.R`, AFTER the plan-07-03 functions
    (`build_nace_section_map`, `build_figaro_pipeline_fixture_from_synthetic`),
    BEFORE end of file.

    Design notes preserved in code comments:
    - **Default metrics = "GO"** (A3 escalation, D-7.2): FIGARO has no EMP/CO2
      sidecars. Synthesize `GO = colSums(S)` (per industry, per country-year
      matrix) so `compute_sube()` doesn't hard-error on missing metric columns.
    - **Opt-in SUBE_FIGARO_INPUTS_DIR** (D-7.2, Open Item 5): If the env var
      points at a valid directory with `{country}_{year}.csv` sidecar files
      containing INDUSTRY/GO/VA/EMP/CO2, additionally run `compute_sube()`
      with the full metric set and store as `result_opt`. If any sidecar file
      is missing or malformed, silently skip the opt-in branch (return NULL
      from `.load_figaro_inputs_sidecars()`) — matches D-7.2's "opt-in, not
      required" framing. Do NOT hard-error.
    - **.snapshot_projection()** (D-7.3, RESEARCH § Pattern 2): projects to
      deterministic tabular fields only. `$matrices` is excluded because
      dense 21×21 `L` matrices are BLAS-sensitive and trigger false diffs
      (Pitfall 4). The `$summary` table's GO column is derived from
      `colSums(L)` (R/compute.R:93) so any drift in `L` surfaces at
      user-visible precision — the invariant that matters.
    - **Sidecar-loader file format** is documented inline (the vignette
      mentions it too, plan 07-05 section 7).
  </action>
  <verify>
    <automated>Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); stopifnot(exists("build_figaro_pipeline_fixture_from_real"), exists(".snapshot_projection"), exists(".load_figaro_inputs_sidecars"))'</automated>
  </verify>
  <done>
    All three functions exist in `helper-gated-data.R`; the file sources cleanly under `devtools::load_all()`; function signatures match the `<interfaces>` block.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Append the FIG-E2E-01 gated test_that block to test-figaro-pipeline.R (with memoised closure + snapshot)</name>
  <files>tests/testthat/test-figaro-pipeline.R</files>
  <behavior>
    - With `SUBE_FIGARO_DIR` unset → test_that block skips cleanly with exact message `"SUBE_FIGARO_DIR not set — FIGARO E2E test skipped"`
    - With `SUBE_FIGARO_DIR` set to a valid FIGARO root → block asserts structural invariants (class sube_results, 4 countries present {DE, FR, IT, NL}, all diagnostics status == "ok") AND `expect_snapshot_value` on `.snapshot_projection(result)` with `style = "serialize"`
    - On CRAN (`skip_on_cran()` at top of block) → block skips unconditionally
    - Opt-in branch: with both `SUBE_FIGARO_DIR` AND `SUBE_FIGARO_INPUTS_DIR` set and valid → `result_opt` is non-NULL; assert `inherits(result_opt, "sube_results")` and `all(result_opt$diagnostics$status == "ok")`; NO snapshot on this branch
  </behavior>
  <action>
    Per RESEARCH § Pattern 1 (gated test skeleton) + D-7.3 (snapshot) + D-7.4
    (country scope DE/FR/IT/NL × 2023) + D-7.2 (opt-in elasticity branch).

    Append the following content to `tests/testthat/test-figaro-pipeline.R`
    AFTER the existing FIG-E2E-02 test_that block.

    ```r
    # ---- FIG-E2E-01: gated real-data test + golden snapshot ------------------

    # Memoised fixture builder — runs the real-data pipeline at most once per
    # test-file invocation so both test_that blocks below can reuse the
    # bundle without paying the full-pipeline cost twice.
    .figaro_real_bundle <- local({
      cache <- NULL
      function() {
        if (is.null(cache)) {
          root <- resolve_figaro_root()
          if (!nzchar(root)) return(NULL)
          cache <<- build_figaro_pipeline_fixture_from_real(
            root,
            countries = c("DE", "FR", "IT", "NL"),
            year = 2023L
          )
        }
        cache
      }
    })

    test_that("FIGARO pipeline matches golden snapshot on real data (FIG-E2E-01)", {
      testthat::skip_on_cran()
      root <- resolve_figaro_root()
      testthat::skip_if_not(
        nzchar(root),
        "SUBE_FIGARO_DIR not set — FIGARO E2E test skipped"
      )

      bundle <- .figaro_real_bundle()
      testthat::skip_if(is.null(bundle), "FIGARO pipeline fixture build failed")

      # Structural invariants — catch logic regressions on real data
      expect_s3_class(bundle$result, "sube_results")
      expect_gt(nrow(bundle$result$summary), 0L)
      expect_setequal(unique(bundle$result$summary$COUNTRY),
                      c("DE", "FR", "IT", "NL"))
      expect_true(all(bundle$result$diagnostics$status == "ok"))

      # Golden snapshot on deterministic projection — catches floating-point
      # drift or aggregation bugs that survive the structural checks.
      testthat::expect_snapshot_value(
        .snapshot_projection(bundle$result),
        style = "serialize"
      )
    })

    test_that("FIGARO elasticity opt-in path runs when SUBE_FIGARO_INPUTS_DIR is set (FIG-E2E-01 opt-in)", {
      testthat::skip_on_cran()
      root <- resolve_figaro_root()
      testthat::skip_if_not(
        nzchar(root),
        "SUBE_FIGARO_DIR not set — FIGARO E2E opt-in elasticity test skipped"
      )
      inputs_dir <- Sys.getenv("SUBE_FIGARO_INPUTS_DIR", unset = "")
      testthat::skip_if_not(
        nzchar(inputs_dir) && dir.exists(inputs_dir),
        "SUBE_FIGARO_INPUTS_DIR not set — opt-in elasticity branch skipped"
      )

      bundle <- .figaro_real_bundle()
      testthat::skip_if(is.null(bundle), "FIGARO pipeline fixture build failed")
      testthat::skip_if(is.null(bundle$result_opt),
                        "SUBE_FIGARO_INPUTS_DIR present but sidecar files missing/malformed")

      # Structural invariants only — no snapshot on regression-flavored output
      expect_s3_class(bundle$result_opt, "sube_results")
      expect_true(all(bundle$result_opt$diagnostics$status == "ok"))
      expect_true(all(c("GOe","VAe","EMPe","CO2e") %in%
                     names(bundle$result_opt$summary)))
    })
    ```

    The test file now has three `test_that` blocks total: the FIG-E2E-02
    block from plan 07-03, plus these two new gated blocks.
  </action>
  <verify>
    <automated>Rscript -e 'Sys.unsetenv("SUBE_FIGARO_DIR"); Sys.unsetenv("SUBE_FIGARO_INPUTS_DIR"); res <- as.data.frame(devtools::test(filter = "figaro-pipeline")); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L); cat("skipped (expected, env unset):", sum(res$skipped), "passed:", sum(res$passed), "\n"); stopifnot(sum(res$skipped) >= 2L)'</automated>
  </verify>
  <done>
    `tests/testthat/test-figaro-pipeline.R` contains three `test_that` blocks (1 synthetic-ungated + 2 real-gated); with env unset, `devtools::test(filter = "figaro-pipeline")` reports FIG-E2E-02 passing + both gated blocks skipping with the expected messages; zero failures, zero errors.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Human verification — capture the initial golden snapshot with real SUBE_FIGARO_DIR</name>
  <what-built>
    `test-figaro-pipeline.R` FIG-E2E-01 block + `.snapshot_projection()` + `build_figaro_pipeline_fixture_from_real()`.
    The automated CI-safe branches (FIG-E2E-02 + gated skips with env unset) are confirmed green from Task 2. This checkpoint captures and commits the initial golden snapshot that future CI runs will compare against — a one-time operation requiring the researcher's local FIGARO 2023 flatfile.
  </what-built>
  <how-to-verify>
    On the researcher's local machine (where `/home/zenz/R/sube/inst/extdata/figaro/` contains `flatfile_eu-ic-supply_25ed_2023.csv` and `flatfile_eu-ic-use_25ed_2023.csv`):

    1. **Set the env var and run the gated test:**
       ```bash
       SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/ \
         Rscript -e 'devtools::test(filter = "figaro-pipeline")'
       ```

    2. **Expected first-run output:** testthat emits `Adding new snapshot` for the FIG-E2E-01 block, completes the full pipeline (~60-120 s for 4 countries × 2023 real data), and reports:
       - FIG-E2E-02 synthetic: PASS
       - FIG-E2E-01 gated (snapshot): PASS with `Adding new snapshot` warning
       - FIG-E2E-01 opt-in (no SUBE_FIGARO_INPUTS_DIR): SKIP with message "SUBE_FIGARO_INPUTS_DIR not set — opt-in elasticity branch skipped"

    3. **Inspect the newly-written snapshot:**
       ```bash
       ls tests/testthat/_snaps/figaro-pipeline/
       cat tests/testthat/_snaps/figaro-pipeline/<whatever-name>.md
       ```
       Confirm the file exists and contains base64-serialized content (style = "serialize" is opaque binary — correct).

    4. **Inspect structural sanity of the projected result** (optional but recommended — load the serialized value back):
       ```r
       Sys.setenv(SUBE_FIGARO_DIR = "/home/zenz/R/sube/inst/extdata/figaro/")
       devtools::load_all()
       source("tests/testthat/helper-gated-data.R")
       b <- build_figaro_pipeline_fixture_from_real(resolve_figaro_root())
       proj <- .snapshot_projection(b$result)
       str(proj, max.level = 2)
       # summary should have ≥ 4 × 21 = 84 rows (4 countries × 21 sections)
       # diagnostics should have 4 rows, all status = "ok"
       ```
       Expected: `nrow(proj$summary) >= 84`, all `proj$diagnostics$status == "ok"`, no NAs in `proj$summary$GO`.

    5. **Second-run sanity** — rerun the gated test (env still set):
       ```bash
       SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/ \
         Rscript -e 'devtools::test(filter = "figaro-pipeline")'
       ```
       Expected: snapshot comparison PASSES silently (no `Adding new snapshot` warning). If it FAILS with a snapshot diff, that indicates the projection helper or pipeline is non-deterministic — investigate before accepting.

    6. **Commit the snapshot** (only after all above green):
       ```bash
       git add tests/testthat/_snaps/figaro-pipeline/
       git status  # confirm only the new snap dir is added
       ```
  </how-to-verify>
  <resume-signal>
    Reply `approved` once the snapshot is captured, second-run is clean, and `tests/testthat/_snaps/figaro-pipeline/` is staged for commit.

    If the snapshot fails on second run, reply `non-deterministic — investigate` and stop; the projection helper needs rework before the snapshot ships.
  </resume-signal>
</task>

<task type="auto">
  <name>Task 4: Full-suite regression + CRAN-safe skip verification</name>
  <files>(verification only — no file writes)</files>
  <action>
    Run two smoke tests to confirm the gated test ships correctly:

    1. **Env-unset run** (CI-equivalent):
       ```bash
       env -u SUBE_FIGARO_DIR -u SUBE_FIGARO_INPUTS_DIR \
         Rscript -e 'devtools::test()'
       ```
       Expected: full suite green, with the two new FIG-E2E-01 gated blocks
       skipping. Zero failures, zero errors.

    2. **Env-set run** (local researcher equivalent):
       ```bash
       SUBE_FIGARO_DIR=/home/zenz/R/sube/inst/extdata/figaro/ \
         Rscript -e 'devtools::test(filter = "figaro-pipeline")'
       ```
       Expected: all three blocks run, snapshot matches (from Task 3),
       opt-in branch skips (no inputs dir). Zero failures.

    If either run fails, investigate before marking plan complete. Do NOT
    accept a flaky snapshot.
  </action>
  <verify>
    <automated>env -u SUBE_FIGARO_DIR -u SUBE_FIGARO_INPUTS_DIR Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L); cat("failed:", sum(res$failed), "skipped:", sum(res$skipped), "passed:", sum(res$passed), "\n")'</automated>
  </verify>
  <done>
    Env-unset `devtools::test()` is fully green with ≥ 2 additional gated skips (FIG-E2E-01 snapshot + opt-in); env-set run exercises the gated pipeline + passes the committed snapshot; the snapshot directory is committed to git.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A in the attacker-sense — but note that this plan introduces a test-time
read of `$SUBE_FIGARO_DIR` file content. The trust assumption is that the
researcher's local FIGARO flatfile is authentic Eurostat data, not attacker-
supplied. Since the test auto-skips unless the env var is set explicitly
(D-7.7 contract), there is no default-path attack surface.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-04 | N/A | tests/testthat/test-figaro-pipeline.R (gated block) | accept | Test infrastructure consuming researcher-local data. The env-var gate (D-7.7) ensures the test cannot run with attacker-controlled paths unless the attacker has already compromised the developer's shell environment — outside the package's threat scope. |
| T-07-05 | N/A | tests/testthat/_snaps/figaro-pipeline/ | accept | Golden snapshot is binary-serialized output of `compute_sube()` on trusted local data. Not user-facing content; not executed — only compared against. |
</threat_model>

<verification>
- Task 1: all three helpers exist and load
- Task 2 automated: env-unset run shows both gated blocks SKIP with correct messages; 0 failures
- Task 3 checkpoint: researcher captures snapshot locally, second run compares clean, stages directory for commit
- Task 4: env-unset full suite green; env-set filtered run green with matching snapshot
</verification>

<success_criteria>
- [ ] `build_figaro_pipeline_fixture_from_real()` exists in helper-gated-data.R with GO-synthesis default and opt-in sidecar branch
- [ ] `.snapshot_projection()` exists in helper-gated-data.R and excludes `$matrices`
- [ ] `.load_figaro_inputs_sidecars()` exists and silently returns NULL for missing/malformed sidecars
- [ ] `test-figaro-pipeline.R` has three `test_that` blocks (FIG-E2E-02 synthetic + FIG-E2E-01 snapshot + FIG-E2E-01 opt-in)
- [ ] Gated blocks skip cleanly with env unset, message reads `SUBE_FIGARO_DIR not set — FIGARO E2E test skipped`
- [ ] `tests/testthat/_snaps/figaro-pipeline/` exists and is committed to git (captured during human-verify checkpoint)
- [ ] Second-run with env set passes snapshot comparison silently (no `Adding new snapshot`)
- [ ] `devtools::test()` full suite zero failures in both env-set and env-unset scenarios
</success_criteria>

<output>
After completion, create `.planning/phases/07-figaro-e2e-validation/07-04-SUMMARY.md`
</output>

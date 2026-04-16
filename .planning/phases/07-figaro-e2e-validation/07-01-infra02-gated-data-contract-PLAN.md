---
phase: 07-figaro-e2e-validation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - tests/testthat/helper-replication.R
  - tests/testthat/helper-gated-data.R
  - tests/testthat/test-gated-data-contract.R
  - tests/testthat/test-replication.R
autonomous: true
requirements:
  - INFRA-02
tags:
  - testing
  - infrastructure
  - gated-data

must_haves:
  truths:
    - "tests/testthat/helper-replication.R no longer exists; its content lives in tests/testthat/helper-gated-data.R"
    - "resolve_wiod_root() returns \"\" when SUBE_WIOD_DIR is unset, even if inst/extdata/wiod/ is present on disk"
    - "resolve_figaro_root() exists with identical env-var-only semantics reading SUBE_FIGARO_DIR"
    - "test-gated-data-contract.R green-passes guarded-skip, fallback-ignored, and opt-in-path assertions for both resolvers"
    - "test-replication.R skip messages no longer mention `inst/extdata/wiod/` absence — they read `SUBE_WIOD_DIR not set`"
    - "Full test suite (devtools::test()) still green post-rename — zero regressions"
  artifacts:
    - path: "tests/testthat/helper-gated-data.R"
      provides: "resolve_wiod_root(), resolve_figaro_root(), build_replication_fixtures() (unchanged from prior helper-replication.R apart from resolver edits)"
      contains: "resolve_figaro_root"
    - path: "tests/testthat/test-gated-data-contract.R"
      provides: "INFRA-02 contract tests for both resolvers"
      contains: "resolve_figaro_root"
  key_links:
    - from: "tests/testthat/test-replication.R"
      to: "resolve_wiod_root"
      via: "helper auto-load (testthat)"
      pattern: "resolve_wiod_root\\(\\)"
    - from: "tests/testthat/test-gated-data-contract.R"
      to: "resolve_wiod_root / resolve_figaro_root"
      via: "helper auto-load"
      pattern: "resolve_(wiod|figaro)_root"
---

<objective>
Close the INFRA-02 silent-fallback gap. Replace `resolve_wiod_root()`'s
`inst/extdata/wiod/` fallback with a one-line env-var-only contract, add
a parallel `resolve_figaro_root()` reading `SUBE_FIGARO_DIR`, rename the
helper file to reflect its widened scope, and ship a new contract test
that asserts both resolvers return `""` when the env var is unset even
in the presence of a local data directory.

Purpose: The v1.1 audit flagged a ~4.4% WIOD multiplier drift caused by
the helper magically picking up `inst/extdata/wiod/` when `SUBE_WIOD_DIR`
was unset. D-7.7 eliminates that behavior. This plan delivers the
refactor + regression test + skip-message cleanup in one atomic change.

Output: renamed `helper-gated-data.R`, new `test-gated-data-contract.R`,
updated skip messages in `test-replication.R`, zero regressions in the
existing 102-test suite.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/07-figaro-e2e-validation/07-CONTEXT.md
@.planning/phases/07-figaro-e2e-validation/07-RESEARCH.md
@.planning/phases/07-figaro-e2e-validation/07-VALIDATION.md

# Source code the executor modifies
@tests/testthat/helper-replication.R
@tests/testthat/test-replication.R
</context>

<interfaces>
<!-- Current resolver shape (tests/testthat/helper-replication.R:10-16) -->
<!-- Executor replaces the multi-branch version with the one-liner per D-7.7. -->

Current (helper-replication.R:10-16):
```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) return(env)
  fallback <- system.file("extdata", "wiod", package = "sube")
  if (nzchar(fallback) && dir.exists(fallback)) return(fallback)
  ""
}
```

Target (helper-gated-data.R, per D-7.7 + RESEARCH Pattern 3):
```r
resolve_wiod_root <- function() {
  env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}

resolve_figaro_root <- function() {
  env <- Sys.getenv("SUBE_FIGARO_DIR", unset = "")
  if (nzchar(env) && dir.exists(env)) env else ""
}
```

Existing skip-message lines (tests/testthat/test-replication.R:32, 65-66, 106-107):
```r
"SUBE_WIOD_DIR not set and inst/extdata/wiod/ absent - paper replication test skipped"
```
→ Replace every occurrence with:
```r
"SUBE_WIOD_DIR not set - paper replication test skipped"
```

testthat helper auto-loading semantics:
- testthat scans `tests/testthat/` at test-file load time for any file matching
  `helper-*.R` and sources it before the first `test_that()` call.
- Renaming `helper-replication.R` → `helper-gated-data.R` has zero runtime
  impact beyond the file-name change. Use `git mv` (or Bash `git mv`) so the
  rename is tracked as a rename in git history (findable via `git log --follow`).
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Rename helper file and replace resolve_wiod_root() with env-var-only one-liner; add resolve_figaro_root()</name>
  <files>
    tests/testthat/helper-replication.R (deleted via `git mv`),
    tests/testthat/helper-gated-data.R (created via `git mv` + content edit)
  </files>
  <action>
    Per D-7.7 and RESEARCH § Pattern 3 / INFRA-02 Implementation.

    Step 1: `git mv tests/testthat/helper-replication.R tests/testthat/helper-gated-data.R` so the rename is tracked.

    Step 2: In `helper-gated-data.R`, replace the top-of-file comment and `resolve_wiod_root()` body (lines 1-16 of the current file) with the new content below. Keep `build_replication_fixtures()` (lines 22-57) untouched.

    New file header + resolvers (replaces lines 1-16):
    ```r
    # tests/testthat/helper-gated-data.R
    # Shared fixtures and env-var resolvers for the gated data tests
    # (paper-replication + FIGARO E2E). Renamed from helper-replication.R
    # in Phase 7 (INFRA-02 / D-7.7). Do NOT source this file manually --
    # testthat auto-loads helper-*.R.

    # Resolve the WIOD root directory.
    # D-7.7: env-var-only contract. No fallback to inst/extdata/wiod/.
    # Returns "" when SUBE_WIOD_DIR is unset or points at a missing dir;
    # callers should skip_if_not(nzchar(root)).
    resolve_wiod_root <- function() {
      env <- Sys.getenv("SUBE_WIOD_DIR", unset = "")
      if (nzchar(env) && dir.exists(env)) env else ""
    }

    # Resolve the FIGARO root directory. Parallel contract to
    # resolve_wiod_root(): env-var-only, no fallback. Gates the FIG-E2E-01
    # test introduced in 07-04-*.
    resolve_figaro_root <- function() {
      env <- Sys.getenv("SUBE_FIGARO_DIR", unset = "")
      if (nzchar(env) && dir.exists(env)) env else ""
    }
    ```

    Do NOT modify `build_replication_fixtures()` in this task — it is consumed
    by `test-replication.R` and must keep its current signature/behavior.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::load_all(quiet = TRUE); source("tests/testthat/helper-gated-data.R"); stopifnot(exists("resolve_wiod_root"), exists("resolve_figaro_root"), exists("build_replication_fixtures")); Sys.unsetenv("SUBE_WIOD_DIR"); Sys.unsetenv("SUBE_FIGARO_DIR"); stopifnot(resolve_wiod_root() == "", resolve_figaro_root() == "")'</automated>
  </verify>
  <done>
    `helper-replication.R` is deleted (via `git mv`); `helper-gated-data.R` exists and defines both resolvers + `build_replication_fixtures()`; both resolvers return `""` with env unset regardless of any local `inst/extdata/wiod/` or `inst/extdata/figaro/` presence; `devtools::load_all()` succeeds without errors.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update test-replication.R skip messages to drop fallback mention</name>
  <files>tests/testthat/test-replication.R</files>
  <action>
    Per D-7.7 + RESEARCH § "Skip-message updates".

    Replace the skip-message string at lines 31-33, 64-66, and 105-107 of
    `tests/testthat/test-replication.R`. Three occurrences, same replacement:

    Before (at each occurrence):
    ```r
    testthat::skip_if_not(
      nzchar(root),
      "SUBE_WIOD_DIR not set and inst/extdata/wiod/ absent - paper replication test skipped"
    )
    ```

    After:
    ```r
    testthat::skip_if_not(
      nzchar(root),
      "SUBE_WIOD_DIR not set - paper replication test skipped"
    )
    ```

    No other changes in this file — the `resolve_wiod_root()` call signature
    is unchanged; only the message text shortens.
  </action>
  <verify>
    <automated>Rscript -e 'txt <- readLines("tests/testthat/test-replication.R"); stopifnot(!any(grepl("inst/extdata/wiod/ absent", txt))); stopifnot(sum(grepl("SUBE_WIOD_DIR not set - paper replication test skipped", txt)) == 3L)'</automated>
  </verify>
  <done>
    All three skip-message occurrences in `test-replication.R` read `"SUBE_WIOD_DIR not set - paper replication test skipped"`; no occurrence mentions `inst/extdata/wiod/` absence; `devtools::test(filter = "replication")` exits cleanly (skips 3/3 tests) with `SUBE_WIOD_DIR` unset.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Add tests/testthat/test-gated-data-contract.R covering INFRA-02 for both resolvers</name>
  <files>tests/testthat/test-gated-data-contract.R</files>
  <behavior>
    - `resolve_wiod_root()` with `SUBE_WIOD_DIR` unset → returns `""` (guarded-skip path)
    - `resolve_wiod_root()` with `SUBE_WIOD_DIR` unset AND `inst/extdata/wiod/` present on disk → still returns `""` (fallback is gone; this is the D-7.7 regression guard)
    - `resolve_wiod_root()` with `SUBE_WIOD_DIR` set to a valid existing directory → returns the directory path (opt-in path)
    - `resolve_wiod_root()` with `SUBE_WIOD_DIR` set to a nonexistent directory → returns `""`
    - Parallel four assertions for `resolve_figaro_root()` / `SUBE_FIGARO_DIR`
  </behavior>
  <action>
    Per D-7.7 + RESEARCH § "New test file: test-gated-data-contract.R".

    Create `tests/testthat/test-gated-data-contract.R` with the shape below.
    Use base-R `Sys.setenv()` + `withr::defer()` via `on.exit()`-style envelope
    (withr is NOT in Suggests per RESEARCH Note near line 547 — avoid adding a
    new dependency for this one phase). Use a local helper `with_env()` that
    saves/restores via `Sys.getenv(..., unset = NA)` + `Sys.setenv()` /
    `Sys.unsetenv()`.

    ```r
    # tests/testthat/test-gated-data-contract.R
    # INFRA-02: assert the env-var-only contract for resolve_wiod_root()
    # and resolve_figaro_root(). D-7.7 removed the inst/extdata/{wiod,figaro}/
    # fallback; this test guards against reintroducing it.
    library(testthat)

    # Local env-var scoping helper (avoids adding withr to Suggests).
    with_env <- function(key, value, code) {
      old <- Sys.getenv(key, unset = NA)
      if (is.null(value)) {
        Sys.unsetenv(key)
      } else {
        Sys.setenv(setNames(list(value), key))
      }
      on.exit(
        if (is.na(old)) Sys.unsetenv(key) else Sys.setenv(setNames(list(old), key)),
        add = TRUE
      )
      force(code)
    }

    # ---- resolve_wiod_root --------------------------------------------------

    test_that("resolve_wiod_root returns empty when SUBE_WIOD_DIR is unset (INFRA-02)", {
      with_env("SUBE_WIOD_DIR", NULL, {
        expect_identical(resolve_wiod_root(), "")
      })
    })

    test_that("resolve_wiod_root ignores inst/extdata/wiod/ fallback when env unset (D-7.7 regression guard)", {
      fallback <- system.file("extdata", "wiod", package = "sube")
      skip_if_not(nzchar(fallback) && dir.exists(fallback),
                  "fallback path absent on this install; D-7.7 still holds vacuously")
      with_env("SUBE_WIOD_DIR", NULL, {
        expect_identical(resolve_wiod_root(), "")
      })
    })

    test_that("resolve_wiod_root returns env path when SUBE_WIOD_DIR points at valid dir", {
      tmp <- tempfile("sube-wiod-test-")
      dir.create(tmp)
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
      with_env("SUBE_WIOD_DIR", tmp, {
        expect_identical(resolve_wiod_root(), tmp)
      })
    })

    test_that("resolve_wiod_root returns empty when SUBE_WIOD_DIR points at nonexistent dir", {
      with_env("SUBE_WIOD_DIR", "/this/path/does/not/exist/ever", {
        expect_identical(resolve_wiod_root(), "")
      })
    })

    # ---- resolve_figaro_root -----------------------------------------------

    test_that("resolve_figaro_root returns empty when SUBE_FIGARO_DIR is unset (INFRA-02)", {
      with_env("SUBE_FIGARO_DIR", NULL, {
        expect_identical(resolve_figaro_root(), "")
      })
    })

    test_that("resolve_figaro_root ignores inst/extdata/figaro/ fallback when env unset (D-7.7 regression guard)", {
      fallback <- system.file("extdata", "figaro", package = "sube")
      skip_if_not(nzchar(fallback) && dir.exists(fallback),
                  "fallback path absent on this install; D-7.7 still holds vacuously")
      with_env("SUBE_FIGARO_DIR", NULL, {
        expect_identical(resolve_figaro_root(), "")
      })
    })

    test_that("resolve_figaro_root returns env path when SUBE_FIGARO_DIR points at valid dir", {
      tmp <- tempfile("sube-figaro-test-")
      dir.create(tmp)
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
      with_env("SUBE_FIGARO_DIR", tmp, {
        expect_identical(resolve_figaro_root(), tmp)
      })
    })

    test_that("resolve_figaro_root returns empty when SUBE_FIGARO_DIR points at nonexistent dir", {
      with_env("SUBE_FIGARO_DIR", "/this/path/does/not/exist/ever", {
        expect_identical(resolve_figaro_root(), "")
      })
    })
    ```

    Do NOT add `withr` to `DESCRIPTION` Suggests — the base-R `with_env()`
    helper keeps the dependency footprint flat.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test(filter = "gated-data-contract", reporter = testthat::StopReporter())'</automated>
  </verify>
  <done>
    `test-gated-data-contract.R` exists; `devtools::test(filter = "gated-data-contract")` reports 8 `test_that()` blocks, all green (or with `skip()` where fallback dir absent); zero failures, zero warnings.
  </done>
</task>

<task type="auto">
  <name>Task 4: Run full test suite + devtools::check() as non-blocking smoke test; zero regressions</name>
  <files>(verification only — no file writes)</files>
  <action>
    Confirm the rename + resolver refactor did not regress the 102-test baseline.

    1. `Rscript -e 'devtools::test()'` → expect all tests pass. The gated-test
       skip count is now deterministic: WIOD + FIGARO each skip cleanly when
       their env vars are unset.
    2. `Rscript -e 'devtools::check(cran = FALSE, vignettes = FALSE)'` →
       expect Status: OK or Status: 1 NOTE (acceptable — tarball checks are
       covered in Phase 9). Must NOT introduce new WARNINGs or ERRORs.

    If any failure: inspect output, fix, rerun. Do NOT proceed to 07-02+ until
    this is green.
  </action>
  <verify>
    <automated>Rscript -e 'res <- as.data.frame(devtools::test()); stopifnot(sum(res$failed) == 0L, sum(res$error) == 0L)'</automated>
  </verify>
  <done>
    `devtools::test()` full suite reports zero failures and zero errors;
    `devtools::check(cran = FALSE, vignettes = FALSE)` reports no new WARNINGs
    or ERRORs relative to v1.1 baseline; resolver+rename refactor is verified
    clean for downstream plans to build on.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A — this plan modifies test-helper R code and a single test file inside the
package test suite. There is no external input, no user-facing authentication
surface, no network I/O, and no code path reachable at package load time (test
helpers are sourced only by testthat during `devtools::test()`).

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-01 | N/A | tests/testthat/helper-gated-data.R | accept | Test infrastructure and local-data gating; no user-facing attack surface. The D-7.7 change *tightens* the local-data contract (removes silent-fallback), reducing data-provenance ambiguity. |
</threat_model>

<verification>
- `devtools::test(filter = "gated-data-contract")` — 8 blocks green
- `devtools::test(filter = "replication")` — skips cleanly with env unset; 3 tests skipped with new shorter message
- `devtools::test()` — full suite zero failures
- `git log --follow tests/testthat/helper-gated-data.R` shows the rename from `helper-replication.R`
</verification>

<success_criteria>
- [ ] `tests/testthat/helper-replication.R` no longer exists
- [ ] `tests/testthat/helper-gated-data.R` exists with both resolvers + `build_replication_fixtures()`
- [ ] `resolve_wiod_root()` body is the D-7.7 one-liner; no `system.file()` fallback branch
- [ ] `resolve_figaro_root()` exists with identical one-liner shape reading `SUBE_FIGARO_DIR`
- [ ] `test-replication.R` skip messages drop the `inst/extdata/wiod/ absent` phrase (3 occurrences updated)
- [ ] `test-gated-data-contract.R` exists with 8 passing tests covering both resolvers × 4 branches each
- [ ] `devtools::test()` full-suite zero failures
</success_criteria>

<output>
After completion, create `.planning/phases/07-figaro-e2e-validation/07-01-SUMMARY.md`
</output>

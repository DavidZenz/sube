# Phase 9: Test Infrastructure Tech Debt - Research

**Researched:** 2026-04-17
**Domain:** R subprocess library-path threading; `R CMD check` environment isolation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Fix the subprocess by threading `.libPaths()` into the `Rscript` call via
  `R_LIBS` environment variable so the child process finds sube in the check-time
  temporary library. Do NOT use `skip_on_cran()` or any skip-based workaround.
- **D-02:** The fix must work cross-platform (Linux, macOS, Windows). No fallback to a
  documented skip if platform issues arise — invest the effort to make `R_LIBS`
  threading robust everywhere.
- **D-03:** Document the resolution in four places: (1) inline comment at the test site
  explaining the `.libPaths()` threading, (2) PROJECT.md Key Decisions entry, (3)
  NEWS.md bullet, (4) DESCRIPTION Note field mentioning that the legacy wrapper test
  requires `.libPaths()` threading.
- **D-04:** Verification requires both `devtools::test()` (all tests green, no
  regressions) AND `R CMD check --as-cran` on the built tarball (subprocess test
  passes). Both must succeed.

### Claude's Discretion

- Exact mechanism for passing `.libPaths()` to the subprocess (e.g., `R_LIBS` env var
  in `system2()` call, `callr::r()`, or wrapping the Rscript invocation)
- Whether to refactor the `system2()` call in-place or extract a helper for subprocess
  library threading

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID       | Description                                                                                                                                                         | Research Support                                                                                           |
|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| INFRA-01 | `tests/testthat/test-workflow.R:218` passes cleanly under `R CMD check --as-cran` by threading `R_LIBS`/`.libPaths()` into the subprocess; `devtools::test()` stays 102/102 green | Threading pattern verified via `system2()` `env` param and `callr::rscript()` `libpath` param (see below) |
</phase_requirements>

---

## Summary

The test at `tests/testthat/test-workflow.R:218` spawns a child `Rscript` process via
`system2()` to execute `inst/scripts/run_legacy_pipeline.R`, which calls
`library(sube)`. Under normal `devtools::test()` runs the package is loaded in the
parent R session and `.libPaths()` includes the development source tree, so the child
inherits a workable library path through OS environment variables. Under `R CMD check
--as-cran` the harness installs the package into a *temporary* library directory and
sets `R_LIBS` to point there; however, the child `Rscript` launched via `system2()`
does NOT automatically inherit that temporary path — it starts with the default library
search list from the user's profile, which does not contain the check-time temp dir.
The result is `Error in library(sube) : there is no package called 'sube'`.

The fix is mechanically simple: before calling `system2()`, construct the `R_LIBS`
value from the parent process's `paste(.libPaths(), collapse = .Platform$path.sep)`
and pass it through `system2()`'s `env` argument as `"R_LIBS=<value>"`. The child
`Rscript` then initialises its library search list from `R_LIBS` and finds `sube` in
the check-time temporary directory. This is fully cross-platform: `.Platform$path.sep`
is `":"` on Unix/macOS and `";"` on Windows — both are the correct `R_LIBS` separator
for their OS.

An alternative mechanism is `callr::rscript()`, which has `libpath = .libPaths()`
built into its signature and automatically injects it as `R_LIBS` before launching the
subprocess. However, `callr` is not a declared `Suggests` dependency of sube; using
it would require adding a dependency. The `system2()` + `env` approach requires no new
dependencies and is equally correct — this makes it the preferred mechanism.

**Primary recommendation:** In-place modification of the `system2()` call at
`test-workflow.R:240-245`: add `env = paste0("R_LIBS=", paste(.libPaths(), collapse =
.Platform$path.sep))`. No new files, no new dependencies.

---

## Standard Stack

### Core

| Library   | Version | Purpose                             | Why Standard                              |
|-----------|---------|-------------------------------------|-------------------------------------------|
| base R    | 4.3.0   | `system2()` subprocess invocation   | Already used at the call site             |
| testthat  | 3.2+    | Test framework; `test_that()` blocks | Project-wide standard (`Config/testthat/edition: 3`) |

### Supporting

| Library | Version | Purpose                                       | When to Use                              |
|---------|---------|-----------------------------------------------|------------------------------------------|
| callr   | 3.7.6   | High-level subprocess with automatic libpath  | If `system2()` approach proves fragile in edge cases — but adds a `Suggests` dep |

`callr` is installed on this machine (v3.7.6) [VERIFIED: `Rscript -e "packageVersion('callr')"`], but it is not currently in DESCRIPTION and adding it solely for this fix creates unnecessary coupling. The `system2()` approach is preferred.

**Version verification:** [VERIFIED: `R --version` → R 4.3.0; `callr` → 3.7.6]

---

## Architecture Patterns

### Pattern 1: Thread `.libPaths()` through `system2()` `env` argument

**What:** Construct `R_LIBS` from the parent process's `.libPaths()` and pass it as a
name=value string in the `env` parameter of `system2()`.

**When to use:** Any time a test spawns a child R process that needs to load the
package under test.

**Example (in-place fix for `test-workflow.R:240-245`):**

```r
# Source: base R docs for system2(); verified via ?system2 in R 4.3.0
# R CMD check sets R_LIBS to a temp dir; child Rscript does NOT inherit
# it automatically. Pass .libPaths() explicitly so the subprocess finds
# the package in the check-time temporary library.
r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)

status <- system2(
  Sys.which("Rscript"),
  c(script_path, sut_path, cpa_map_path, ind_map_path, inputs_path, output_dir),
  stdout = TRUE,
  stderr = TRUE,
  env    = paste0("R_LIBS=", r_libs)
)
```

**Why it works:** `system2()` `env` takes a character vector of `"NAME=VALUE"` strings
that are *set* in the child process environment before execution. R (all platforms)
reads `R_LIBS` at startup to build the initial `.libPaths()` for the child session.
[VERIFIED: `?system2` in R 4.3.0 — "character vector of name=value strings to set
environment variables."]

**Cross-platform note:** `.Platform$path.sep` is `":"` on Linux/macOS and `";"` on
Windows. Both are the platform-correct separator for `R_LIBS`. [VERIFIED: R docs for
`.Platform`]

### Pattern 2: `callr::rscript()` alternative (not recommended for this phase)

```r
# callr::rscript() has libpath = .libPaths() by default — no manual env threading
# Requires adding callr to DESCRIPTION Suggests.
callr::rscript(
  script_path,
  cmdargs = c(sut_path, cpa_map_path, ind_map_path, inputs_path, output_dir),
  stdout  = TRUE,
  stderr  = TRUE
)
```

D-01 says use `R_LIBS` threading; the `system2()` approach fulfils this without
adding a dependency.

### Anti-Patterns to Avoid

- **`skip_on_cran()` / `skip_if()` on the outer test:** Explicitly prohibited by D-01.
  The test must run and pass, not be skipped.
- **Hard-coding a library path:** Never use an absolute path; always derive from
  `.libPaths()` at runtime so the test is portable across machines and CI environments.
- **Setting `R_LIBS_USER` instead of `R_LIBS`:** `R_LIBS_USER` is also consulted by R
  at startup, but `R_LIBS` takes precedence and is what `R CMD check` itself sets.
  Using `R_LIBS` is the correct and conventional choice.

---

## Don't Hand-Roll

| Problem                        | Don't Build                                        | Use Instead                                | Why                                               |
|--------------------------------|----------------------------------------------------|--------------------------------------------|---------------------------------------------------|
| Library path construction      | Custom path-separator logic with `if (.Platform...)` | `.Platform$path.sep` (built-in)           | Already cross-platform                            |
| Subprocess env var injection   | Temporary `.Renviron` files                        | `system2()` `env` parameter               | Clean, no temp file cleanup, no race conditions   |
| Child process R session setup  | `--args` flags passed to Rscript                  | `R_LIBS` env var                           | R reads `R_LIBS` before user code runs            |

---

## Common Pitfalls

### Pitfall 1: `R_LIBS` vs `R_LIBS_USER` vs `R_LIBS_SITE`

**What goes wrong:** Developer uses `R_LIBS_USER` thinking it is equivalent to
`R_LIBS`. Under `R CMD check`, `R_LIBS` is explicitly set by the harness; it takes
precedence over `R_LIBS_USER`. Setting `R_LIBS_USER` instead of `R_LIBS` may work on
some machines but fail on others depending on how `R CMD check` configures the
environment.

**Why it happens:** Confusing the three `R_LIBS*` env vars.

**How to avoid:** Always use `R_LIBS` when you want to ensure the temp check lib is at
the front of the search path. [VERIFIED: `?Startup` in R docs — startup sequence
specifies `R_LIBS` evaluated before `R_LIBS_USER`]

**Warning signs:** Test passes locally (`devtools::test()`) but fails under `R CMD
check --as-cran` tarball.

### Pitfall 2: `env` in `system2()` *sets*, it does not *append*

**What goes wrong:** Passing only `"R_LIBS=<new path>"` via `env` replaces the child's
entire library path with only the check-time paths. If sube's dependencies are in a
different library that was previously on the path via `R_LIBS_USER`, they become
invisible to the child.

**Why it happens:** `system2()` `env` sets variables to exactly the provided values; it
does not merge with the existing environment.

**How to avoid:** Use `paste(.libPaths(), collapse = .Platform$path.sep)` which
captures ALL currently-visible libraries, including the user library and system
libraries. This ensures `data.table`, `ggplot2`, etc. are all reachable by the child.
[VERIFIED: confirmed by running `.libPaths()` output in test environment]

**Warning signs:** Child process exits with a missing *dependency* of sube (not sube
itself), e.g., `Error in library(data.table)`.

### Pitfall 3: `system2()` with `stdout=TRUE, stderr=TRUE` treats non-zero exit as attribute, not error

**What goes wrong:** Developer expects `system2()` to throw an R error on subprocess
failure. It does not — it returns the captured output and sets `attr(result, "status")`
to the exit code. The existing `expect_null(attr(status, "status"))` assertion is the
correct check.

**Why it happens:** `system2()` behaviour differs from `callr::rscript()` (which throws
on non-zero exit by default).

**How to avoid:** Keep the existing `expect_null(attr(status, "status"))` assertion
unchanged. The fix only adds the `env` parameter to the `system2()` call.

---

## Code Examples

### Exact diff — the only code change required

```r
# BEFORE (test-workflow.R lines 240-245):
status <- system2(
  Sys.which("Rscript"),
  c(script_path, sut_path, cpa_map_path, ind_map_path, inputs_path, output_dir),
  stdout = TRUE,
  stderr = TRUE
)

# AFTER:
# Thread .libPaths() into child Rscript via R_LIBS so R CMD check's
# temporary library directory is visible to the subprocess. Without this,
# library(sube) fails in the child because R CMD check isolates the
# installed package in a temp dir that is not on the default search path.
r_libs <- paste(.libPaths(), collapse = .Platform$path.sep)

status <- system2(
  Sys.which("Rscript"),
  c(script_path, sut_path, cpa_map_path, ind_map_path, inputs_path, output_dir),
  stdout = TRUE,
  stderr = TRUE,
  env    = paste0("R_LIBS=", r_libs)
)
```

[VERIFIED: `system2()` `env` parameter confirmed via `?system2` in R 4.3.0;
`.Platform$path.sep` confirmed cross-platform via R documentation]

---

## State of the Art

| Old Approach          | Current Approach                        | When Changed       | Impact                                   |
|-----------------------|-----------------------------------------|--------------------|------------------------------------------|
| No env threading      | `system2(..., env = paste0("R_LIBS=…"))` | Phase 9 (this work) | Subprocess finds package under check    |

**Deprecated/outdated:**
- `skip_on_cran()`: Explicitly prohibited by D-01.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The subprocess failure root cause is `R CMD check` not propagating `R_LIBS` to `system2()` child | Summary | If the failure has another cause, the fix may not resolve it — but this is the canonical explanation for this class of problem [ASSUMED based on training knowledge; directly testable by running `R CMD check` on a tarball] |
| A2 | DESCRIPTION `Note:` field is a valid optional field for the R package metadata format | Documentation section | If CRAN rejects a `Note:` field, D-03 item (4) needs an alternative placement [ASSUMED — not tested in this session] |

**Note on A1:** The CONTEXT.md (D-01) already confirms the root cause via the
discussion phase — this is recorded here for traceability only.

---

## Open Questions

1. **`callr` vs in-place `system2` fix**
   - What we know: Both approaches solve the problem. `callr` is already installed
     on this machine.
   - What's unclear: This is left to Claude's Discretion per CONTEXT.md.
   - Recommendation: Use in-place `system2()` + `env` — no new dependency, single
     line change, no refactor required.

2. **DESCRIPTION `Note:` field validity**
   - What we know: The DESCRIPTION file does not currently have a `Note` field.
     `R CMD check` does not mandate or prohibit it.
   - What's unclear: Whether `R CMD check --as-cran` emits a NOTE for unrecognised
     DESCRIPTION fields.
   - Recommendation: Use a comment-style note in the `Description:` paragraph or
     omit the DESCRIPTION item if it generates spurious `R CMD check` output.
     Planner should clarify with a conservative approach (add to Description text or
     omit).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R          | All test execution | ✓ | 4.3.0 | — |
| Rscript    | Subprocess invocation (existing test) | ✓ | 4.3.0 | — |
| devtools   | `devtools::test()` (D-04) | ✓ | (in user lib) | — |
| callr      | Alternative mechanism (Claude's Discretion) | ✓ | 3.7.6 | Use `system2()` instead |

[VERIFIED: all availability checks run via Bash in this session]

---

## Validation Architecture

### Test Framework

| Property         | Value                                          |
|------------------|------------------------------------------------|
| Framework        | testthat 3 (`Config/testthat/edition: 3`)     |
| Config file      | `tests/testthat.R` (standard)                  |
| Quick run command | `devtools::test(filter = "workflow")`         |
| Full suite command | `devtools::test()` (all 58 test blocks)     |

### Phase Requirements → Test Map

| Req ID   | Behavior                                             | Test Type    | Automated Command                              | File Exists? |
|----------|------------------------------------------------------|--------------|------------------------------------------------|--------------|
| INFRA-01 | Legacy wrapper subprocess passes under `R CMD check` | integration  | `devtools::test(filter = "workflow")` (quick check); `R CMD check --as-cran` on tarball (gate) | ✅ `test-workflow.R:218` |

### Sampling Rate

- **Per task commit:** `devtools::test(filter = "workflow")`
- **Per wave merge:** `devtools::test()` (full suite — 58 test blocks across 6 files)
- **Phase gate:** `R CMD check --as-cran` on the built tarball exits zero failures from `test-workflow.R`

### Wave 0 Gaps

None — existing test infrastructure covers the requirement. The test block already
exists at `test-workflow.R:218`; the fix modifies the `system2()` call within it.

---

## Security Domain

> `security_enforcement` not explicitly set to `false` in config.json — section included.

### Applicable ASVS Categories

| ASVS Category         | Applies | Standard Control                                       |
|-----------------------|---------|--------------------------------------------------------|
| V2 Authentication     | no      | —                                                      |
| V3 Session Management | no      | —                                                      |
| V4 Access Control     | no      | —                                                      |
| V5 Input Validation   | no      | Test inputs are controlled `tempfile()` paths          |
| V6 Cryptography       | no      | —                                                      |

### Known Threat Patterns

This phase is a test infrastructure fix with no user-facing surface and no network
access. The subprocess receives only local temporary file paths constructed from
`tempfile()` — no user-supplied input. No ASVS controls apply.

The `R_LIBS` env var carries only file system paths from `.libPaths()`. There is no
injection risk in a test-only context.

---

## Project Constraints (from CLAUDE.md)

No project-level `CLAUDE.md` was found at `/home/zenz/R/sube/CLAUDE.md`. Global
`~/.claude/CLAUDE.md` references RTK (token proxy tool) — not relevant to R package
development conventions. No directives to extract.

---

## Sources

### Primary (HIGH confidence)

- `?system2` in R 4.3.0 — `env` parameter signature and semantics confirmed in-session
- `?Startup` in R — `R_LIBS`, `R_LIBS_USER`, `R_LIBS_SITE` startup order
- `.planning/phases/09-test-infrastructure-tech-debt/09-CONTEXT.md` — locked decisions (D-01 through D-04)
- `tests/testthat/test-workflow.R` — exact call site (lines 218–251) read in-session
- `inst/scripts/run_legacy_pipeline.R` — confirmed: script is correct, problem is in test invocation
- Bash probes — R version (4.3.0), `.libPaths()`, `.Platform$path.sep`, callr version (3.7.6) all verified

### Secondary (MEDIUM confidence)

- `callr::rscript()` signature: `libpath = .libPaths()` default — confirmed via
  `print(args(callr::rscript))` in-session

### Tertiary (LOW confidence)

- DESCRIPTION `Note:` field behaviour under `R CMD check --as-cran` — not verified
  in-session; see Open Questions item 2 [ASSUMED]

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependencies; base R `system2()` mechanics verified
- Architecture: HIGH — fix pattern confirmed via R docs and live probes
- Pitfalls: HIGH — all three pitfalls verified via R documentation and live probes
- DESCRIPTION `Note:` field: LOW — not tested; see Open Questions

**Research date:** 2026-04-17
**Valid until:** 2027-04-17 (base R API is stable; no fast-moving dependencies)

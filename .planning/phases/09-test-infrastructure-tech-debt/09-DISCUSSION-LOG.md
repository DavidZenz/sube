# Phase 9: Test Infrastructure Tech Debt - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 09-test-infrastructure-tech-debt
**Areas discussed:** Resolution strategy, Documentation scope, Regression safety

---

## Resolution Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Fix the subprocess (Recommended) | Thread .libPaths() into the Rscript call via R_LIBS env var so the child process finds sube | ✓ |
| Skip under R CMD check | Detect R CMD check context and skip_on_cran(). Document rationale. | |
| You decide | Let Claude pick the best approach based on research | |

**User's choice:** Fix the subprocess
**Notes:** None

### Follow-up: Fallback strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, skip as fallback | If fix doesn't work cross-platform, fall back to skip_on_cran() | |
| No, must fix | The fix must work everywhere. Invest more effort. | ✓ |

**User's choice:** No, must fix
**Notes:** No skip fallback under any circumstances

---

## Documentation Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Three places is sufficient | Inline comment, PROJECT.md, NEWS.md | |
| Add DESCRIPTION note | Also mention in DESCRIPTION's Note field | ✓ |

**User's choice:** Add DESCRIPTION note (four documentation touchpoints total)
**Notes:** None

---

## Regression Safety

| Option | Description | Selected |
|--------|-------------|----------|
| devtools::test() + R CMD check | Both must pass green | ✓ |
| devtools::test() only | Skip full R CMD check | |
| You decide | Let Claude determine verification scope | |

**User's choice:** devtools::test() + R CMD check
**Notes:** None

## Claude's Discretion

- Exact mechanism for passing .libPaths() to the subprocess
- Whether to refactor system2() in-place or extract a helper

## Deferred Ideas

None

---
phase: 4
slug: release-ci-and-migration-readiness
status: passed
score: 3/3
verified: 2026-04-08
---

# Phase 4 Verification

## Result

Phase 4 passed verification. The repo now has one coherent maintainer release path across local commands, GitHub Actions, and package-facing documentation, while preserving a working legacy wrapper as a compatibility bridge for script-era users.

## Evidence

- GitHub Actions now mirrors the documented maintainer flow and has stronger execution controls and platform coverage
- The legacy wrapper creates its output directory, writes the expected CSV outputs, and is covered by a regression test in both source and installed-package contexts
- `AGENTS.md`, `README.md`, and `NEWS.md` no longer describe a stale script-first repository or contradictory release process
- `.planning/` is excluded from source builds, so the tarball-based release check is clean

## Commands

- `R -q -e 'testthat::test_dir("tests/testthat")'`
- `R CMD build .`
- `R CMD check sube_0.1.2.tar.gz --no-manual`

## Notes

`gh` was still unavailable on `PATH` in this shell, so GitHub Actions hardening was verified through workflow-file inspection and local release-path parity rather than live Actions inspection.

# Plan 04-01 Summary

## Outcome

Aligned the local release workflow and GitHub Actions around the same package-first check path, then hardened the CI workflow so maintainers get clearer and broader signal from routine checks.

## Delivered

- Expanded `.github/workflows/R-CMD-check.yaml` with manual dispatch, concurrency control, explicit permissions, clearer job naming, a wider OS matrix, and an explicit `testthat` step
- Updated `README.md` so local maintainer commands mirror the CI flow: test suite, tarball build, then `R CMD check --no-manual`
- Added `.Rbuildignore` coverage for `.planning/` so the release tarball no longer carries local planning artifacts into package checks

## Files

- `.github/workflows/R-CMD-check.yaml`
- `README.md`
- `.Rbuildignore`

## Verification

- `R -q -e 'testthat::test_dir("tests/testthat")'`
- `R CMD build .`
- `R CMD check sube_0.1.2.tar.gz --no-manual`

## Status

Complete

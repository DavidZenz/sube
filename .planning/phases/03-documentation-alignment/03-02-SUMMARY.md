# Plan 03-02 Summary

## Outcome

Aligned pkgdown and package/reference framing with the actual workflow categories already documented in the README and vignettes. The website and package-level help now better expose data preparation, compute/model steps, and comparison/export helpers as coherent groups.

## Delivered

- Updated `_pkgdown.yml` article and reference group titles
- Broadened package-level reference framing in `R/package.R` and `man/sube-package.Rd`
- Tightened selected man-page titles and descriptions for discoverability and consistency

## Files

- `_pkgdown.yml`
- `R/package.R`
- `man/sube-package.Rd`
- `man/import_suts.Rd`
- `man/paper_tools.Rd`

## Verification

- `R -q -e 'testthat::test_dir("tests/testthat")'`

## Status

Complete

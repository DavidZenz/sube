## Test environments

- local Debian GNU/Linux 10, R 4.3.0

## R CMD check results

- `R CMD check` run on the built source tarball.
- No errors.
- No warnings expected in the release artifact.

## Notes

- The package contains small shipped example data so all examples and
  vignettes can run without external downloads.
- Historical paper scripts are retained locally in an ignored `archive/`
  directory and are not part of the package bundle.


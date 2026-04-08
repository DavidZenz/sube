# Plan 04-03 Summary

## Outcome

Removed the last stale script-era guidance and made the repo’s release, CI, and migration story consistent across contributor instructions, release notes, and public docs.

## Delivered

- Rewrote `AGENTS.md` to match the actual package structure, package workflow, and release commands in this repo
- Updated `NEWS.md` so the current release notes describe the stabilized comparison workflow, package-first docs alignment, and the hardened release path
- Refined `README.md` and the Phase 4 planning state so maintainers now see one coherent package-first maintenance path

## Files

- `AGENTS.md`
- `NEWS.md`
- `README.md`
- `.planning/PROJECT.md`

## Verification

- `R CMD check sube_0.1.2.tar.gz --no-manual`

## Status

Complete

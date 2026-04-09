# Phase 5: FIGARO SUT Ingestion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 05-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09
**Phase:** 05-figaro-sut-ingestion
**Areas discussed:** Format verification, File layout, CPA prefix, Year determination, Year semantics, Domestic block, Input API, Test fixture, Performance guardrails

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Format verification | Download + inspect real FIGARO CSV before coding, or code from docs | ✓ |
| Domestic block semantics | Return full inter-country vs. always domestic block | ✓ |
| Year determination strategy | Explicit arg vs. filename inference vs. hybrid | ✓ |
| Synthetic fixture scope | How rich the test CSV should be | ✓ |

**User's choice:** All four areas selected.

---

## Format Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Download + inspect locally | User shares real FIGARO CSV layout with Claude before coding | ✓ |
| Code from documented schema | Write parser against docs, verify at fixture test time | |
| Defer format work | Block phase on user action | |

**User's choice:** Download + inspect locally. User revealed files already exist at `inst/extdata/figaro/` (gitignored).

**Finding:** Real FIGARO flat files are LONG format with pre-split dimension columns (`refArea`, `counterpartArea`, `rowPi`, `colPi`, `obsValue`). Research assumption of wide CSVs with compound labels was incorrect. Pitfall #1 (compound label parsing) is largely eliminated.

---

## File Layout

| Option | Description | Selected |
|--------|-------------|----------|
| New R/figaro.R | Isolate FIGARO parsing in its own file with helpers | |
| Extend R/import.R | Add read_figaro() alongside import_suts() | ✓ |

**User's choice:** Extend R/import.R.

**Notes:** Research originally recommended a separate file anticipating heavy parsing helpers, but D-01 eliminated most of that work, so the function stays co-located with `import_suts()`.

---

## Data Source

| Option | Description | Selected |
|--------|-------------|----------|
| I already have a FIGARO file locally | User points to existing local file | ✓ |
| I need to download one first | Claude provides Eurostat landing page reference | |
| Use domain inference, no real file | Proceed without live verification | |

**User's choice:** Already have local files. Path: `inst/extdata/figaro/` containing `flatfile_eu-ic-supply_25ed_2023.csv` and `flatfile_eu-ic-use_25ed_2023.csv`.

---

## CPA Prefix Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Strip CPA_ prefix | Store CPA as 'A01' to match colPi style | ✓ |
| Keep prefix as-is | Store CPA as 'CPA_A01' | |
| Store both (CPA + CPA_raw) | Schema drift | |

**User's choice:** Strip CPA_ prefix. Keeps CPA and VAR lexically comparable and avoids forcing mapping tables to carry the prefix.

---

## Year Determination

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit year= argument required | Caller must pass year; hard error if missing | ✓ |
| Infer from filename, error if missing | Parse 4-digit year from filename | |
| Hybrid: infer with explicit override | Default inference, optional override | |

**User's choice:** Explicit year= argument required. Directly mitigates Pitfall #11 (silent NA_integer year).

---

## Year Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Release/edition year | 2023 in filename = publication year | |
| Reference/data year | 2023 in filename = observation year | ✓ |
| Unsure — need to check FIGARO docs | Defer to planner research | |

**User's choice:** Reference/data year. Simplifies documentation; caller passes the year that appears in the filename.

---

## Domestic Block Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Full inter-country table | Matches import_suts symmetry; caller runs extract_domestic_block() | ✓ |
| Always domestic block | Filter REP == PAR internally | |
| Default full, optional domestic_only = TRUE | Optional argument | |

**User's choice:** Full inter-country. Preserves FIGARO's multi-regional value and matches `import_suts()` behavior exactly.

---

## Input API

| Option | Description | Selected |
|--------|-------------|----------|
| Single file path only | One file, TYPE inferred or passed explicitly | |
| Directory with auto-pair SUP + USE | Scan dir for supply/use files | ✓ |
| Either (file or directory) | Like import_suts(), most flexible | |

**User's choice:** Directory with auto-pair. Matches `import_suts()` directory behavior and reflects the one-supply-one-use-per-release reality.

---

## Test Fixture

| Option | Description | Selected |
|--------|-------------|----------|
| 2 countries × 3 CPA × 3 NACE, SUP + USE | ~36 rows per file, exercises inter-country + SUP/USE | ✓ |
| Single country, minimal rows (domestic only) | ~9 rows × 2 types | |
| Slice of the real file | First N rows from real file | |

**User's choice:** 2 countries × 3 CPA × 3 NACE. Smallest fixture that validates REP/PAR splitting, domestic vs cross-country rows, and build_matrices integration.

---

## Performance Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Document expectations, no code guardrail | fread handles 400 MB; document memory in @details | ✓ |
| Add countries= / years= pre-filter arguments | Caller can subset during load | |
| Load in chunks + rbindlist | Read in N-row batches | |

**User's choice:** Document expectations, no code guardrail. fread on 400 MB uses ~3–5 GB peak — tolerable on research laptops.

---

## Claude's Discretion

- Exact error message wording for missing/invalid `year`, ambiguous directory contents
- Whether to emit a `message()` summary on successful load (row count, country count)
- Whether `.parse_figaro_row()` / `.parse_figaro_col()` exist as internal helpers or inline
- pkgdown reference group placement
- Exact NEWS.md wording for the new function

## Deferred Ideas

- Chunked / streaming reader for extreme file sizes
- Country / year pre-filter arguments in `read_figaro()`
- Single-file input mode without paired supply/use sibling
- `type =` override argument
- FIGARO SIOT (product-by-product) tables — out of scope per REQUIREMENTS.md
- Auto-downloading FIGARO data from Eurostat — out of scope per REQUIREMENTS.md
- Shipping real FIGARO data in the package tarball — out of scope

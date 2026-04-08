# Domain Pitfalls

**Domain:** R econometrics package — adding FIGARO ingestion, paper replication, and convenience wrappers to existing `sube`
**Researched:** 2026-04-08
**Confidence:** MEDIUM — based on codebase analysis + FIGARO/WIOD domain knowledge; web verification unavailable

---

## Critical Pitfalls

Mistakes that cause rewrites, broken existing tests, or irreproducible numerical results.

---

### Pitfall 1: FIGARO column layout does not match what `import_suts()` expects

**What goes wrong:** FIGARO industry-by-industry SUTs are distributed as wide CSV files where rows are origin country-industry pairs and columns are destination country-industry pairs. The WIOD importer in `import_suts()` pivots wide Excel sheets with `REP`, `PAR`, `CPA` row keys and industry code column headers. FIGARO has no such column structure — it uses composite row/column labels like `AT_01` (country underscore NACE code). A naive `import_figaro_suts()` that calls the same `melt()` path will silently produce wrong `REP`, `PAR`, `CPA`, `VAR` assignments.

**Why it happens:** The two data formats look superficially similar (both are wide numeric tables), but the key decomposition is fundamentally different. FIGARO encodes all four dimensions (reporting country, partner country, product/industry, transaction type) into a single composite label rather than splitting them across axes and sheet names.

**Consequences:** The `build_matrices()` step will receive a long table where `REP`, `PAR`, `CPA`, and `VAR` are systematically wrong. `build_matrices()` filters on `REP == PAR` inside `extract_domestic_block()` — if REP/PAR are not parsed correctly, the domestic block is empty or incorrect. `compute_sube()` then silently runs on wrong data. No existing test catches this because tests run on WIOD-format CSV fixtures.

**Prevention:**
- Write `import_figaro_suts()` as a separate, self-contained function — do not try to extend `import_suts()` with a format-detection branch.
- Parse FIGARO row/column labels into constituent country, industry, and transaction fields before melting.
- Add a dedicated test fixture (small synthetic FIGARO-shaped CSV) and verify `REP`, `PAR`, `CPA`, `VAR` for known values in that fixture.
- Assert that the FIGARO importer produces a `sube_suts` class object that passes the same `REP == PAR` domestic block logic for at least one known domestic diagonal entry.

**Detection:** The domestic block is suspiciously small or empty after `extract_domestic_block()`. `REP` and `PAR` contain composite strings rather than ISO country codes.

**Phase:** FIGARO ingestion phase. Needs dedicated schema mapping work before any code is written.

---

### Pitfall 2: Floating-point aggregation order breaks exact paper replication

**What goes wrong:** The paper's legacy scripts and the package accumulate values using different aggregation orders. `data.table` `sum()` with `by =` groups in a different key order than, for example, `tapply()` or `aggregate()` in a legacy R script. IEEE 754 double arithmetic is not associative: `(a + b) + c != a + (b + c)` when values differ by many orders of magnitude (common in SUT data spanning millions of euros across 56 industries). A replication run that prints `max(abs(pkg_value - paper_value)) = 3e-10` is actually a failure if the paper asserts an exact threshold.

**Why it happens:** The existing `compute_sube()` uses `sum(as.numeric(VALUE), na.rm = TRUE)` in `build_matrices()` which respects `data.table`'s internal key order. Legacy scripts may have sorted data differently, looped over rows in file order, or used `colSums()` on a matrix in a different industry order. When aggregating 56 industries to 22 products, intermediate rounding accumulates.

**Consequences:** Replication appears to "nearly" match but differs at the 10th–14th significant digit. If the acceptance criterion is `all.equal(pkg, paper, tolerance = .Machine$double.eps^0.5)` this passes; if it is bitwise identity or tolerance `1e-8`, it fails intermittently depending on platform. The team may spend days diagnosing a structural bug that is actually a summation order discrepancy.

**Prevention:**
- Define the tolerance threshold for "exact match" before coding, and document it in the replication test. `1e-6` relative tolerance is appropriate for SUT multipliers.
- Sort input rows to a canonical key order (YEAR, REP, CPA, VAR) before any aggregation in `build_matrices()`.
- Run the replication test on both Linux and macOS (different BLAS/LAPACK can shift matrix inversion results).
- If the legacy script uses matrix inversion via `solve()`, ensure `compute_sube()`'s `.safe_solve()` uses the same factorization path. `solve(A)` and `solve(A, b)` follow different code paths in some BLAS implementations.

**Detection:** `max(abs(pkg - paper))` is not zero but less than `1e-8`. Values diverge more for countries with more industries or more years.

**Phase:** Paper replication phase.

---

### Pitfall 3: One-call pipeline swallows intermediate errors silently

**What goes wrong:** A pipeline function like `run_sube_pipeline(path, cpa_map, ind_map, inputs)` that chains `import_suts() -> extract_domestic_block() -> build_matrices() -> compute_sube()` in a single call will return a `sube_results` object even when intermediate steps partially fail. `build_matrices()` silently drops rows where `CPAagg` or `INDagg` is `NA` after the merge. `compute_sube()` skips singular matrices and logs them in `$diagnostics` rather than stopping. A user calling the pipeline gets a result object and plots, but some countries or years are silently missing.

**Why it happens:** Each step was designed defensively for interactive use where the user inspects intermediate objects. Chaining them hides the inspection opportunity. The `$diagnostics` field exists precisely to surface these issues, but a pipeline user who does not read the docs will not check it.

**Consequences:** Published analysis is missing data silently. Worse, when run with FIGARO data where mapping coverage is lower (FIGARO uses NACE Rev 2 codes, mapping tables may not cover all entries), the silent-drop rate is higher.

**Prevention:**
- The pipeline function should aggregate all diagnostics from each step and emit a summary warning if any country-year was skipped or any mapping produced NAs.
- Add a `verbose` parameter (default `TRUE`) that prints a coverage report: rows imported, rows surviving domestic block filter, unique country-year pairs in matrices, country-years with ok/failed compute status.
- Write a test that passes deliberately incomplete mapping tables through the pipeline and asserts that a warning is raised, not silent success.
- Do not suppress warnings inside the pipeline — the existing `suppressWarnings()` pattern in tests should not leak into the pipeline function itself.

**Detection:** `nrow(result$diagnostics[status != "ok"])` is nonzero but the user never sees it.

**Phase:** One-call pipeline phase. Also relevant when testing with FIGARO data (lower mapping coverage risk).

---

### Pitfall 4: FIGARO uses NACE Rev 2 industry codes; existing CPA/VAR synonyms do not cover them

**What goes wrong:** `utils.R`'s `.coerce_map()` recognises a fixed synonym list for the `vars` (industry) slot: `c("VARS", "VAR", "INDUSTRY", "IND", "CODE")`. FIGARO industry codes follow the pattern `A01`, `C10`, `G46` (NACE Rev 2 two-letter section plus two-digit code). If a FIGARO-derived `ind_map` uses column name `NACE` or `NACE_R2`, `.coerce_map()` falls back to positional matching (`names(data)[2]`), which is fragile — it silently uses whatever the second column happens to be.

**Why it happens:** The synonym list was built for WIOD-style inputs. It is a reasonable design for the WIOD case but is not extensible by callers.

**Consequences:** Mapping silently uses the wrong column. `build_matrices()` produces an `INDagg` column of all `NA`, which means `aggregated` after filtering `!is.na(INDagg)` is empty. `matrices` list is empty. `compute_sube()` returns empty results. The error message will be "No matrices to compute" at best, or an empty `$diagnostics` table at worst.

**Prevention:**
- Extend the `vars` synonym list in `.coerce_map()` to include `NACE`, `NACE_R2`, `NACE2`, `ACTIVITY` before writing the FIGARO importer.
- Alternatively, document that `ind_map` must contain a column named `VAR` or `IND` and validate explicitly in `import_figaro_suts()` rather than relying on synonym matching.
- Add a test that constructs a FIGARO-style `ind_map` with a `NACE` column and verifies it routes correctly through `build_matrices()`.

**Detection:** `nrow(bundle$aggregated)` is 0 after `build_matrices()`. `bundle$matrices` is an empty list.

**Phase:** FIGARO ingestion phase.

---

### Pitfall 5: Batch processing accumulates large objects in a list and exhausts memory

**What goes wrong:** A batch function that collects `sube_results` objects for many countries and years into a named list holds all matrices, tidy data, and coefficient matrices in RAM simultaneously. A single `sube_results` object for one country-year is small, but 44 countries times 20 years times the matrix storage in `$matrices` (coefficient_matrices for each country-year) scales to several GB for FIGARO's 64-sector coverage.

**Why it happens:** `compute_sube()` stores full `A` and `L` matrices in `coefficient_matrices[[name]]`. For FIGARO with 64 industries and 64 products, each `A` and `L` is 64x64 doubles = 32 KB. For 44 countries x 20 years = 880 country-year pairs, that is 880 x 2 x 32 KB = ~56 MB for matrices alone — manageable. But the `$tidy` and `$summary` tables also accumulate, and if the batch function naively `rbindlist()`s all results into a growing object, peak memory is 2x the final object size during the bind.

**Why it is more dangerous than it appears:** FIGARO can have more than 64 sectors in some releases (up to 64 NACE activities) but the real risk is if users pass full WIOD multi-country files: the WIOD 2016 release has 43 countries and 56 sectors, and if matrices are stored for all country-years, the coefficient matrix list alone is large. More critically, naive batch implementations that `lapply()` and then `rbindlist()` everything will hold two copies of the data in memory during the bind.

**Prevention:**
- Design the batch function to return only the summary and tidy tables by default, with `keep_matrices = FALSE` as the default. Users who need matrices should request them explicitly.
- Process in chunks: write intermediate results to disk (using `write_sube()` which already exists) and return a path or a lightweight index, not the full object list.
- Document memory expectations in the function's `@details` section with a rough formula.

**Detection:** R session hits memory limit mid-batch with "cannot allocate vector of size X MB".

**Phase:** Batch processing phase. Also relevant if one-call pipeline is designed to loop internally.

---

## Moderate Pitfalls

---

### Pitfall 6: FIGARO year parsing fails because FIGARO filenames use a different naming pattern

**What goes wrong:** `utils.R`'s `.parse_year_from_name()` has two strategies: match `intsutYY` (WIOD pattern like `intsut10.xlsx` for 2010) and then fall back to any four-digit year in the filename. FIGARO filenames use patterns like `eu-27-suts-2019-industry-by-industry.csv` or `figaro_sut_2020_i_by_i.xlsx`. The four-digit fallback catches these correctly — but only if the year appears as an isolated four-digit sequence. If the filename contains a version tag like `v2023-rev1` before the actual data year, `.parse_year_from_name()` returns `2023` instead of the actual data year.

**Prevention:**
- Add a FIGARO-specific year pattern to `.parse_year_from_name()` or accept an explicit `year` argument in `import_figaro_suts()` that overrides filename inference.
- Document the filename convention expected by the importer and emit a warning when year is `NA_integer_` after parsing.

**Phase:** FIGARO ingestion phase.

---

### Pitfall 7: `extract_domestic_block()` applied to FIGARO data loses inter-country flows that FIGARO is designed to capture

**What goes wrong:** FIGARO is an inter-country SUT — its primary value is the off-diagonal country blocks showing inter-country flows. Applying `extract_domestic_block()` (which keeps only `REP == PAR`) is correct for the WIOD workflow but may surprise FIGARO users who expected to use the inter-country structure. If `import_figaro_suts()` produces data where `PAR` is always equal to `REP` (by design of the domestic extraction inside the importer), this is fine; but if it returns the full inter-country table, the downstream API is unclear about when to call `extract_domestic_block()`.

**Prevention:**
- Decide at the API design stage whether `import_figaro_suts()` returns the full inter-country table (like `import_suts()`) or always returns the domestic block. Document this explicitly in the function's `@details` section.
- If returning the full inter-country table, the vignette must show the `extract_domestic_block()` call, and the function must warn if the caller passes the full table directly to `build_matrices()`.

**Phase:** FIGARO ingestion phase.

---

### Pitfall 8: Replication comparison uses `prepare_sube_comparison()` filters that were tuned for WIOD, not for a general verification

**What goes wrong:** `.apply_paper_filters()` hard-codes a list of country-CPA exclusions and year/metric exclusions specific to the WIOD 2016 paper (e.g., `CAN` and `CYP` excluded, `BEL` restricted to post-2008, `CO2` restricted to pre-2010). Paper replication verification must reproduce these exact exclusions. If the replication test calls `prepare_sube_comparison(apply_paper_filters = TRUE)` on data that includes or excludes different country-years than the original, the comparison table will not match the paper's tables even when the underlying computation is correct.

**Prevention:**
- The replication test must use the exact WIOD country-year coverage from the paper — not all available WIOD years.
- Log which filters were applied and how many rows they removed when running replication verification.
- Do not conflate the paper-replication path with any FIGARO-specific comparison. The filter list in `.apply_paper_filters()` should not be modified to accommodate FIGARO data.

**Phase:** Paper replication phase.

---

### Pitfall 9: A one-call pipeline that constructs mapping tables internally cannot be tested without real data

**What goes wrong:** If the pipeline function bundles default or auto-detected mapping tables (e.g., inferring CPA groupings from column names), it is difficult to test without a real-size WIOD or FIGARO file. The existing architecture separates mapping tables from data for exactly this reason — `cpa_map` and `ind_map` are explicit arguments. A pipeline that tries to be "zero-config" by shipping built-in maps will need to update those maps when classifications change, creating a maintenance burden inside the package.

**Prevention:**
- Keep the pipeline function's signature consistent with the existing step-by-step API: `run_sube_pipeline(path, cpa_map, ind_map, inputs, ...)`. Do not bundle default maps in the function.
- The convenience is in the chaining, not in removing the mapping arguments. Document this clearly.

**Phase:** One-call pipeline phase.

---

## Minor Pitfalls

---

### Pitfall 10: Batch function modifies data.table objects by reference inside the loop

**What goes wrong:** `data.table` operations that use `:=` modify objects by reference. If the batch function passes the same `inputs` data.table into `compute_sube()` for each iteration, and `compute_sube()` internally calls `setnames()` or `:=` on a copy that is not actually a copy, the `inputs` object will be silently mutated. The second iteration then operates on a modified version. The existing `compute_sube()` calls `.standardize_names()` which calls `setDT()` on the input — this modifies in place if the input is already a data.table.

**Prevention:**
- Pass `data.table::copy(inputs)` into each batch iteration, or ensure `compute_sube()` works on a `data.table::copy()` of its inputs internally.
- The existing code does `inputs <- .standardize_names(inputs)` at the top of `compute_sube()` which reassigns the local `inputs` variable, so the external object is not mutated — but verify this assumption does not break if the batch function stores references rather than values.

**Phase:** Batch processing phase.

---

### Pitfall 11: `import_suts()` year parsing returns `NA_integer_` silently for FIGARO files

**What goes wrong:** When FIGARO files do not contain a recognizable year pattern, `YEAR` is `NA_integer_` in the output. This propagates through `build_matrices()` which groups by `YEAR`, creating a matrix key `"AT_NA"`. `compute_sube()` will process this bundle without error, but downstream joins on `YEAR` will silently miss or double-count rows.

**Prevention:**
- `import_figaro_suts()` should accept an explicit `year` argument and validate that year is a four-digit integer before returning. Emit a `stop()` if year cannot be determined and no explicit `year` is provided.

**Phase:** FIGARO ingestion phase.

---

### Pitfall 12: Adding new exported functions without corresponding `@export` + pkgdown reference group entries causes documentation gaps

**What goes wrong:** The project has a `pkgdown` site and documented reference groups. New functions like `import_figaro_suts()`, `run_sube_pipeline()`, and `sube_batch()` that are exported but not added to `_pkgdown.yml` reference groups will appear in the "Unlisted" section of the pkgdown site. The NEWS entry may also be absent if the developer forgets to update it alongside the new function.

**Prevention:**
- After each new export, update `_pkgdown.yml` reference groups and `NEWS.md` before the PR is merged.
- The existing GitHub Actions `R-CMD-check` workflow does not check pkgdown completeness — add a local pre-commit reminder or a vignette that cross-references the new functions.

**Phase:** Any phase that adds new exported functions.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| FIGARO ingestion | Column layout mismatch with `import_suts()` path (Pitfall 1) | Separate importer function, synthetic test fixture |
| FIGARO ingestion | NACE synonym not in `.coerce_map()` (Pitfall 4) | Extend synonym list before writing importer |
| FIGARO ingestion | Year parsing returns NA (Pitfall 11) | Explicit `year` argument with validation |
| FIGARO ingestion | Domestic block semantics unclear (Pitfall 7) | Decide and document at API design time |
| Paper replication | Floating-point aggregation order (Pitfall 2) | Define tolerance before coding; canonical sort order |
| Paper replication | Wrong filter coverage invalidates comparison (Pitfall 8) | Use exact WIOD coverage; log filter steps |
| One-call pipeline | Silent drops not surfaced (Pitfall 3) | Diagnostic summary warning; verbose mode |
| One-call pipeline | Zero-config default maps temptation (Pitfall 9) | Keep mapping args explicit |
| Batch processing | Memory accumulation (Pitfall 5) | `keep_matrices = FALSE` default; chunk-and-write |
| Batch processing | data.table reference mutation (Pitfall 10) | `copy()` inside each iteration |
| All new functions | pkgdown reference group and NEWS gaps (Pitfall 12) | Checklist item before each PR merge |

---

## Sources

- Codebase analysis: `R/import.R`, `R/utils.R`, `R/matrices.R`, `R/compute.R`, `R/paper_tools.R`, `R/models.R`, `tests/testthat/test-workflow.R` (read 2026-04-08)
- Project context: `.planning/PROJECT.md` (read 2026-04-08)
- Domain knowledge: FIGARO EU supply-use tables structure, WIOD 2016 release format, IEEE 754 floating-point arithmetic in R — training knowledge, confidence MEDIUM; web verification was unavailable
- Paper reference: `inst/references/paper.md` — Stehrer, Rueda-Cantuche, Amores, Zenz, "Wrapping input-output multipliers in confidence intervals" (read 2026-04-08)

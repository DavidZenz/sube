---
phase: 08-convenience-helpers
plan: 03
type: execute
wave: 3
depends_on:
  - 01
  - 02
files_modified:
  - man/run_sube_pipeline.Rd
  - man/batch_sube.Rd
  - _pkgdown.yml
  - NEWS.md
  - vignettes/pipeline-helpers.Rmd
  - vignettes/paper-replication.Rmd
  - vignettes/figaro-workflow.Rmd
autonomous: true
requirements:
  - CONV-01
  - CONV-02
  - CONV-03
tags:
  - r-package
  - documentation
  - pkgdown
  - vignettes
must_haves:
  truths:
    - "`man/run_sube_pipeline.Rd` and `man/batch_sube.Rd` exist and are regenerated from the roxygen blocks written in Plans 01+02."
    - "`_pkgdown.yml` reference group 'Data import and preparation' lists `run_sube_pipeline` and `batch_sube` AFTER `build_matrices` (per D-8.13 exact order)."
    - "`_pkgdown.yml` articles section contains a new 'Pipeline Helpers' group immediately after 'Modeling, Comparison, and Outputs' and before 'Package Design and Paper Context' (per D-8.14)."
    - "`NEWS.md` top section (development version) contains 3 new bullets: one for `run_sube_pipeline()`, one for `batch_sube()`, one for the unified diagnostics layer (per D-8.15)."
    - "`vignettes/pipeline-helpers.Rmd` exists, knits under `R CMD check --no-manual`, contains sections for (1) when to reach for helpers, (2) `run_sube_pipeline()` on sample data, (3) inspecting `$results`/`$diagnostics`/`$call`, (4) FIGARO path (`eval = FALSE`), (5) `batch_sube()` over 2 years, (6) `estimate = TRUE`, (7) diagnostic category tour (per D-8.14)."
    - "`vignettes/paper-replication.Rmd` and `vignettes/figaro-workflow.Rmd` each contain a one-line cross-link pointing at `run_sube_pipeline()` (per D-8.14)."
    - "pkgdown reference and articles render correctly — `pkgdown::build_site(preview = FALSE)` completes without error (manual verification optional; automated check via `devtools::check(args = '--no-manual')`)."
  artifacts:
    - path: "vignettes/pipeline-helpers.Rmd"
      provides: "Researcher-facing narrative for CONV-01 + CONV-02 + CONV-03"
      contains: "run_sube_pipeline"
      min_lines: 120
    - path: "man/run_sube_pipeline.Rd"
      provides: "roxygen-generated help for CONV-01"
      contains: "\\name{run_sube_pipeline}"
    - path: "man/batch_sube.Rd"
      provides: "roxygen-generated help for CONV-02"
      contains: "\\name{batch_sube}"
    - path: "_pkgdown.yml"
      provides: "Reference section D-8.13 + articles section D-8.14 updates"
      contains: "pipeline-helpers"
    - path: "NEWS.md"
      provides: "3 v1.2 bullets under development version"
      contains: "run_sube_pipeline"
  key_links:
    - from: "vignettes/pipeline-helpers.Rmd"
      to: "R/pipeline.R::run_sube_pipeline"
      via: "live code chunk using sube_example_data paths"
      pattern: "run_sube_pipeline\\("
    - from: "_pkgdown.yml"
      to: "man/run_sube_pipeline.Rd + man/batch_sube.Rd"
      via: "reference group 'Data import and preparation' listing"
      pattern: "- run_sube_pipeline"
---

<objective>
Package the Phase 8 behavior into the public surface: regenerate the `.Rd` files from Plans 01+02's roxygen blocks, update pkgdown reference and articles per D-8.13/D-8.14, ship the new `pipeline-helpers` vignette, add cross-links to the existing FIGARO + paper-replication vignettes, and write the three NEWS.md bullets per D-8.15.

Purpose: Close CONV-01 / CONV-02 / CONV-03 on the packaging side — the code surface was completed in Plans 01+02; this plan makes it discoverable and narrates it.

Output: Two new man files, one new vignette, three touched docs files (pkgdown, NEWS, both existing vignettes), all regressions green, and `R CMD check --no-manual` exits clean.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/08-convenience-helpers/08-CONTEXT.md
@.planning/phases/08-convenience-helpers/08-RESEARCH.md
@.planning/phases/08-convenience-helpers/08-01-pipeline-core-PLAN.md
@.planning/phases/08-convenience-helpers/08-02-batch-sube-PLAN.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Regenerate .Rd man pages from roxygen via devtools::document() and verify they contain all required sections</name>
  <files>man/run_sube_pipeline.Rd, man/batch_sube.Rd</files>
  <read_first>
    - R/pipeline.R (written by Plans 01 + 02 — must contain the full roxygen blocks for both functions)
    - man/build_matrices.Rd (reference for .Rd structure style — one sibling in the same pkgdown group)
    - man/compute_sube.Rd (reference for @examples + @details style)
    - DESCRIPTION lines 15–22 (RoxygenNote: 7.3.3)
  </read_first>
  <action>
1) Run `Rscript -e "devtools::document()"` from the repo root. This reads the roxygen blocks in `R/pipeline.R` (created in Plans 01+02) and regenerates:
   - `man/run_sube_pipeline.Rd`
   - `man/batch_sube.Rd`
   - Potentially updates `NAMESPACE` (should be a no-op since Plans 01+02 hand-edited the two `export()` lines; devtools::document() will confirm them from `@export` tags).

2) If `devtools::document()` reorders or rewrites NAMESPACE, verify the final NAMESPACE still contains both export lines:

   ```
   export(batch_sube)
   export(run_sube_pipeline)
   ```

3) Verify each `.Rd` file opens correctly (`Rscript -e "tools::Rd2txt('man/run_sube_pipeline.Rd')"` should render without error).

4) Do NOT hand-edit the `.Rd` files. If something is missing (e.g. `\examples{}` block), fix the roxygen in `R/pipeline.R` and re-run `devtools::document()`.

5) If Plans 01 or 02's `@examples` block is absent or the `@param` lines are incomplete, open `R/pipeline.R` and ADD the missing tags, then regenerate. The target state (verified by acceptance criteria): both `.Rd` files contain `\name{}`, `\title{}`, `\usage{}`, `\arguments{}`, `\value{}`, `\details{}`, `\examples{}`, `\seealso{}`.
  </action>
  <verify>
    <automated>test -f man/run_sube_pipeline.Rd && test -f man/batch_sube.Rd</automated>
    <automated>grep -q "\\\\name{run_sube_pipeline}" man/run_sube_pipeline.Rd</automated>
    <automated>grep -q "\\\\name{batch_sube}" man/batch_sube.Rd</automated>
    <automated>grep -q "\\\\examples{" man/run_sube_pipeline.Rd</automated>
    <automated>grep -q "\\\\examples{" man/batch_sube.Rd</automated>
    <automated>grep -q "\\\\seealso{" man/run_sube_pipeline.Rd</automated>
    <automated>grep -q "\\\\seealso{" man/batch_sube.Rd</automated>
    <automated>grep -q "^export(run_sube_pipeline)$" NAMESPACE</automated>
    <automated>grep -q "^export(batch_sube)$" NAMESPACE</automated>
    <automated>Rscript -e "tools::Rd2txt('man/run_sube_pipeline.Rd', out = tempfile())"</automated>
    <automated>Rscript -e "tools::Rd2txt('man/batch_sube.Rd', out = tempfile())"</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `man/run_sube_pipeline.Rd` and `man/batch_sube.Rd` both exist.
    - Each `.Rd` file contains the literal strings: `\name{...}`, `\title{}`, `\usage{}`, `\arguments{}`, `\value{}`, `\details{}`, `\examples{}`, `\seealso{}`.
    - `tools::Rd2txt()` renders both files without error.
    - NAMESPACE still has exactly one `export(run_sube_pipeline)` and one `export(batch_sube)` line (verify counts: `grep -c "^export(run_sube_pipeline)$" NAMESPACE == 1` and `grep -c "^export(batch_sube)$" NAMESPACE == 1`).
    - `devtools::test()` still green — no regressions.
  </acceptance_criteria>
  <done>Both man pages regenerated from roxygen; NAMESPACE stable; Rd2txt rendering clean; tests still green.</done>
</task>

<task type="auto">
  <name>Task 2: Update _pkgdown.yml reference (D-8.13) and articles (D-8.14) sections; update NEWS.md with three v1.2 bullets (D-8.15)</name>
  <files>_pkgdown.yml, NEWS.md</files>
  <read_first>
    - _pkgdown.yml (current full file — 68 lines)
    - NEWS.md (current full file — must see the `# sube (development version)` header and existing v1.2 bullets to append under)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.13, D-8.14, D-8.15 — exact YAML and bullet specs)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §4 "pkgdown Article Ordering (D-8.14)" — exact YAML insertion point
  </read_first>
  <action>
1) **_pkgdown.yml — reference section (D-8.13)**: open `_pkgdown.yml`, find the `Data import and preparation` group (lines 11–17 currently ending at `- build_matrices`), and add two new entries in the exact order specified. The final group must read EXACTLY:

   ```yaml
     - title: Data import and preparation
       contents:
         - import_suts
         - read_figaro
         - extract_domestic_block
         - sube_example_data
         - build_matrices
         - run_sube_pipeline
         - batch_sube
   ```

2) **_pkgdown.yml — articles section (D-8.14)**: find the existing articles block (currently ending at `- figaro-workflow`). Insert a NEW group titled `Pipeline Helpers` immediately AFTER the `Modeling, Comparison, and Outputs` group and BEFORE `Package Design and Paper Context`. The new block:

   ```yaml
     - title: Pipeline Helpers
       contents:
         - pipeline-helpers
   ```

   The final articles block (full snippet, verify order) MUST be:

   ```yaml
   articles:
     - title: Workflow Start Here
       navbar: Get started
       contents:
         - getting-started
     - title: Inputs and Preparation
       contents:
         - data-preparation
     - title: Modeling, Comparison, and Outputs
       contents:
         - modeling-and-outputs
     - title: Pipeline Helpers
       contents:
         - pipeline-helpers
     - title: Package Design and Paper Context
       contents:
         - package-design
     - title: Paper replication
       contents:
         - paper-replication
     - title: FIGARO workflow
       contents:
         - figaro-workflow
   ```

3) **NEWS.md (D-8.15)**: open `NEWS.md`. Under the existing `# sube (development version)` header (line 1), append three new bullets BEFORE the first existing bullet (which is currently the INFRA-02 bullet). Insert these three bullets (exact text, preserve markdown):

   ```
   - Added `run_sube_pipeline()`, a one-call wrapper that chains
     `import_suts()` or `read_figaro()` → `extract_domestic_block()` →
     `build_matrices()` → `compute_sube()` (with opt-in
     `estimate_elasticities()`) for a single SUT path. Returns a structured
     `sube_pipeline_result` object carrying `$results`, `$models`,
     `$diagnostics`, and `$call` provenance. See
     `vignette("pipeline-helpers")`.
   - Added `batch_sube()`, which loops the convenience pipeline over a
     pre-imported `sube_suts` table grouped by country, year, or
     country-year (default `by = "country_year"`), returning per-group
     results alongside merged tidy `$summary`, `$tidy`, and `$diagnostics`
     tables suitable for downstream analysis. Per-group errors never abort
     the batch. See `vignette("pipeline-helpers")`.
   - Added the unified pipeline diagnostics layer: `run_sube_pipeline()`
     and `batch_sube()` surface four categories of silent data-quality
     issues — coerced-NA rows at import, country-years dropped by
     correspondence-map alignment, singular matrix branches from
     `compute_sube()`, and input-metric misalignments from
     `build_matrices()` model-data — through a unified `$diagnostics`
     `data.table` and a single summary `warning()` per run.
   ```

4) Do NOT touch the existing v1.2 INFRA-02 / FIGARO bullets or the older version sections; only append above them under the development-version header.
  </action>
  <verify>
    <automated>grep -q "      - run_sube_pipeline$" _pkgdown.yml</automated>
    <automated>grep -q "      - batch_sube$" _pkgdown.yml</automated>
    <automated>grep -q "  - title: Pipeline Helpers" _pkgdown.yml</automated>
    <automated>grep -q "      - pipeline-helpers$" _pkgdown.yml</automated>
    <automated>grep -q "Added \`run_sube_pipeline()\`" NEWS.md</automated>
    <automated>grep -q "Added \`batch_sube()\`" NEWS.md</automated>
    <automated>grep -q "unified pipeline diagnostics layer" NEWS.md</automated>
    <automated>Rscript -e "yaml::read_yaml('_pkgdown.yml')"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^      - run_sube_pipeline$" _pkgdown.yml` prints `1`.
    - `grep -c "^      - batch_sube$" _pkgdown.yml` prints `1`.
    - `grep -c "  - title: Pipeline Helpers$" _pkgdown.yml` prints `1`.
    - `grep -c "^      - pipeline-helpers$" _pkgdown.yml` prints `1`.
    - `_pkgdown.yml` parses cleanly as YAML: `yaml::read_yaml('_pkgdown.yml')` returns a non-null list (acceptance automated).
    - NEWS.md contains exactly 3 new bullets under the development-version header that mention `run_sube_pipeline()`, `batch_sube()`, and "unified pipeline diagnostics layer" respectively.
    - No existing NEWS entries (INFRA-02, FIGARO, read_figaro, etc.) are altered.
    - Order in pkgdown articles verified: `grep -n "  - title:" _pkgdown.yml` places `Pipeline Helpers` at position 4 (after `Modeling, Comparison, and Outputs` position 3, before `Package Design and Paper Context` position 5).
  </acceptance_criteria>
  <done>_pkgdown.yml reference + articles sections updated per D-8.13/D-8.14 exactly; NEWS.md has 3 new v1.2 bullets per D-8.15.</done>
</task>

<task type="auto">
  <name>Task 3: Create vignettes/pipeline-helpers.Rmd (live, eval=TRUE where sube_example_data drives chunks; eval=FALSE for FIGARO-path illustration); add one-line cross-link notes to paper-replication.Rmd and figaro-workflow.Rmd</name>
  <files>vignettes/pipeline-helpers.Rmd, vignettes/paper-replication.Rmd, vignettes/figaro-workflow.Rmd</files>
  <read_first>
    - vignettes/paper-replication.Rmd lines 1–40 (YAML front matter + knitr opts style)
    - vignettes/figaro-workflow.Rmd lines 1–40 (same; eval = FALSE at file level)
    - vignettes/getting-started.Rmd lines 1–30 (pattern for eval = TRUE live vignettes using sube_example_data)
    - R/pipeline.R (post-Plans 01+02 — must know the exact @examples block contents for consistency)
    - .planning/phases/08-convenience-helpers/08-CONTEXT.md (D-8.14 — the 7-section structure, cross-link wording)
    - .planning/phases/08-convenience-helpers/08-RESEARCH.md §4 "`@examples` Runnable Budget" (sample data dimensions, batch trick)
  </read_first>
  <action>
1) Create `vignettes/pipeline-helpers.Rmd`. Full contents (exact; preserve markdown formatting):

   ```markdown
   ---
   title: "Pipeline Helpers — One Call from Path to Multipliers"
   vignette: >
     %\VignetteIndexEntry{Pipeline Helpers — One Call from Path to Multipliers}
     %\VignetteEngine{knitr::knitr}
     %\VignetteEncoding{UTF-8}
   ---

   ```{r, include = FALSE}
   knitr::opts_chunk$set(
     collapse = TRUE, comment = "#>",
     eval = TRUE
   )
   library(sube)
   library(data.table)
   ```

   # 1. When to reach for the convenience helpers

   The four-step SUBE chain — `import_suts()` / `read_figaro()` →
   `extract_domestic_block()` → `build_matrices()` → `compute_sube()` — gives you
   full control over every stage. If you already have the intermediate objects in
   hand, call the four steps directly; it is two extra lines.

   Reach for the convenience helpers in two cases:

   1. You have a SUT file (or directory) on disk and want multipliers back in one
      call: use `run_sube_pipeline()`.
   2. You have a pre-imported `sube_suts` table and want to sweep across many
      country-year slices, collecting tidy merged outputs: use `batch_sube()`.

   Both helpers surface the same structured diagnostics contract so silent
   data-quality issues (dropped rows, misaligned inputs, singular branches) never
   disappear from the console.

   # 2. `run_sube_pipeline()` on sample data

   The package ships a tiny WIOD-format sample under
   `system.file("extdata", "sample", package = "sube")`. Feed its `sut_data.csv`
   straight into `run_sube_pipeline()`:

   ```{r}
   sut_path <- system.file("extdata", "sample", "sut_data.csv", package = "sube")

   result <- run_sube_pipeline(
     path    = sut_path,
     cpa_map = sube_example_data("cpa_map"),
     ind_map = sube_example_data("ind_map"),
     inputs  = sube_example_data("inputs"),
     source  = "wiod"
   )

   class(result)
   names(result)
   ```

   # 3. Inspecting `$results`, `$diagnostics`, and `$call`

   The compute output lives under `$results`:

   ```{r}
   result$results$summary
   ```

   The unified diagnostics table has a 6-column schema — `country`, `year`,
   `stage`, `status`, `message`, `n_rows`:

   ```{r}
   result$diagnostics
   ```

   When every status is `"ok"` no warning is emitted. Provenance about the call
   itself lives under `$call`:

   ```{r}
   result$call[c("source", "path", "n_countries", "n_years", "estimate",
                 "package_version")]
   ```

   # 4. Switching to the FIGARO path

   The same helper imports FIGARO flatfiles when `source = "figaro"`. Because
   FIGARO data is ~400 MB per flatfile, the block below is illustrative
   (`eval = FALSE`):

   ```{r eval = FALSE}
   figaro_dir <- Sys.getenv("SUBE_FIGARO_DIR")   # user-provided
   run_sube_pipeline(
     path    = figaro_dir,
     cpa_map = my_cpa_map,     # user-supplied correspondence
     ind_map = my_ind_map,
     inputs  = my_inputs,      # industry-level GO/VA/EMP/CO2
     source  = "figaro",
     year    = 2023L
   )
   ```

   See `vignette("figaro-workflow")` for the full FIGARO narrative including the
   env-var gate (`SUBE_FIGARO_DIR`) and map-table construction.

   # 5. `batch_sube()` across groups

   The sample data has one country (AAA) and one year (2020). To illustrate
   multi-group batching, duplicate the sample into a second year:

   ```{r}
   sut <- sube_example_data("sut_data")
   sut2 <- data.table::copy(sut); sut2[, YEAR := 2021L]
   sut_multi <- rbind(sut, sut2)
   class(sut_multi) <- c("sube_suts", class(sut_multi))

   inp <- sube_example_data("inputs")
   inp2 <- data.table::copy(inp); inp2[, YEAR := 2021L]
   inp_multi <- rbind(inp, inp2)

   batch <- batch_sube(
     sut_data = sut_multi,
     cpa_map  = sube_example_data("cpa_map"),
     ind_map  = sube_example_data("ind_map"),
     inputs   = inp_multi
   )

   names(batch$results)
   batch$summary
   batch$diagnostics
   ```

   Per-group results are preserved under `batch$results`; merged tables under
   `$summary`, `$tidy`, and `$diagnostics` (with a `group_key` column naming
   each batch key) are ready for downstream analysis.

   # 6. Turning on `estimate = TRUE`

   When you also want elasticities from `estimate_elasticities()`, pass
   `estimate = TRUE`. The sample data is tiny so the regression may return
   `NULL`; on production-sized inputs a `sube_models` object is attached:

   ```{r}
   result_est <- run_sube_pipeline(
     path     = sut_path,
     cpa_map  = sube_example_data("cpa_map"),
     ind_map  = sube_example_data("ind_map"),
     inputs   = sube_example_data("inputs"),
     source   = "wiod",
     estimate = TRUE
   )
   class(result_est$models)   # "sube_models" when model_data is non-empty, else NULL
   ```

   # 7. Reading the diagnostic warnings

   The `$diagnostics` table categorises silent issues into four statuses:

   - **`coerced_na`** (`stage = "import"`) — rows whose `VALUE` became `NA`
     during `as.numeric()` coercion at import. Pipeline-level aggregate; count
     lives in `n_rows`.
   - **`skipped_alignment`** (`stage = "build"`) — country-years present in
     the SUT input but dropped by `build_matrices()` because the CPA or
     industry correspondence left no aligned rows.
   - **`inputs_misaligned`** (`stage = "build"`) — country-years present in
     both the SUT data and the `inputs` table but absent from
     `build_matrices()`'s `$model_data`. Typical cause: industry codes in
     `inputs` that do not match the matrix industries.
   - **`singular_supply` / `singular_go` / `singular_leontief`**
     (`stage = "compute"`) — `compute_sube()` could not invert the relevant
     matrix for this country-year. Pass-through from the compute stage's
     existing diagnostics.

   When any row has `status != "ok"`, a single `warning()` summarises counts
   per category. Query the structured table for programmatic follow-up; read
   the warning for a fast interactive heads-up.
   ```

2) **Update `vignettes/paper-replication.Rmd`** — add a one-line cross-link near the top of section 1 (immediately after the opening paragraph about what the vignette replicates). Insert the following blockquote right after line 29 (after the gated-test paragraph ends — before the `# 2. Obtaining the WIOD data` header):

   ```markdown

   > **Tip.** For a one-call equivalent of the full chain — import through
   > multipliers in a single function — see
   > [`run_sube_pipeline()`](../reference/run_sube_pipeline.html) and the
   > [Pipeline Helpers vignette](pipeline-helpers.html).

   ```

3) **Update `vignettes/figaro-workflow.Rmd`** — add the same cross-link near the top, immediately after the numbered list of steps in section 1 (after line 37 — after `7. Executing the gated integration test locally` block and before section 2). Insert:

   ```markdown

   > **Tip.** For a one-call equivalent that chains `read_figaro()` through
   > `compute_sube()`, see
   > [`run_sube_pipeline(source = "figaro", ...)`](../reference/run_sube_pipeline.html)
   > and the [Pipeline Helpers vignette](pipeline-helpers.html).

   ```

4) Verify the new vignette builds under knitr by running `Rscript -e "devtools::build_vignettes()"`. This exercises the `eval = TRUE` chunks (sections 2, 3, 5, 6) against the installed package.
  </action>
  <verify>
    <automated>test -f vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "VignetteIndexEntry{Pipeline Helpers" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "run_sube_pipeline" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "batch_sube" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "coerced_na" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "skipped_alignment" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "inputs_misaligned" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "singular_leontief" vignettes/pipeline-helpers.Rmd</automated>
    <automated>grep -q "Pipeline Helpers vignette" vignettes/paper-replication.Rmd</automated>
    <automated>grep -q "Pipeline Helpers vignette" vignettes/figaro-workflow.Rmd</automated>
    <automated>Rscript -e "devtools::build_vignettes()"</automated>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
  </verify>
  <acceptance_criteria>
    - `vignettes/pipeline-helpers.Rmd` exists with at least 120 lines.
    - All 7 section headers present: `grep -c "^# [1-7]\\." vignettes/pipeline-helpers.Rmd` returns `7`.
    - File lists all 4 diagnostic categories by name in section 7 (grep for `coerced_na`, `skipped_alignment`, `inputs_misaligned`, `singular_leontief`).
    - `eval = TRUE` set at top via `knitr::opts_chunk$set`; only the FIGARO illustration block has `eval = FALSE`: `grep -c 'eval = FALSE' vignettes/pipeline-helpers.Rmd` returns `1`.
    - `vignettes/paper-replication.Rmd` and `vignettes/figaro-workflow.Rmd` each contain the literal string `Pipeline Helpers vignette`.
    - `devtools::build_vignettes()` succeeds (exits 0) — `eval = TRUE` chunks run without error against the installed package.
    - `devtools::test()` still green — no regressions.
  </acceptance_criteria>
  <done>pipeline-helpers.Rmd shipped with 7 sections, 6 live chunks, 1 eval=FALSE FIGARO illustration, and a diagnostic-category tour. Both existing vignettes carry a one-line tip cross-link. Vignette builds clean under devtools::build_vignettes(). No test regressions.</done>
</task>

<task type="auto">
  <name>Task 4: Final regression sweep — run full test suite and R CMD check --no-manual --no-vignettes to verify no downstream breakage from pkgdown/NEWS/vignette changes</name>
  <files>.planning/phases/08-convenience-helpers/08-VALIDATION.md</files>
  <read_first>
    - .planning/phases/08-convenience-helpers/08-VALIDATION.md (current state — Per-Task Verification Map table is empty; fill it now)
    - All three Phase 8 plan files (08-01, 08-02, 08-03 — to know the task IDs to enter)
  </read_first>
  <action>
1) Run the full regression gauntlet. Each must exit 0 (or non-zero is the body of this task — treat any failure as a blocker to fix in the relevant Plan 01/02/03 file):

   - `Rscript -e "devtools::test(stop_on_failure = TRUE)"` — full testthat suite.
   - `Rscript -e "devtools::document()"` — no drift between roxygen and .Rd (should be no-op if Task 1 ran cleanly).
   - `Rscript -e "devtools::check(args = c('--no-manual', '--no-vignettes'), error_on = 'warning')"` — CRAN-style check minus the PDF manual (no LaTeX needed in CI) and minus vignettes (already verified in Task 3 via build_vignettes).
   - `Rscript -e "yaml::read_yaml('_pkgdown.yml')"` — YAML sanity.

   Any WARNING or ERROR from `devtools::check` must be diagnosed and fixed in the originating plan's R code / roxygen / NEWS / YAML before this task completes.

2) Update `.planning/phases/08-convenience-helpers/08-VALIDATION.md` — populate the Per-Task Verification Map with the actual task IDs from this phase. Replace the entire Per-Task Verification Map section with the following rows (keep the surrounding context unchanged):

   ```markdown
   ## Per-Task Verification Map

   | Task ID  | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
   |----------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
   | 8-01-01  | 01   | 1    | CONV-01, CONV-03 | T-8.1-01 | data.table::copy of inputs before .standardize_names | unit | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅       | ⬜ pending |
   | 8-01-02  | 01   | 1    | CONV-03 | T-8.1-01 | diagnostic detections read-only on sut/inputs | unit + integration (figaro fixture) | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ⬜ pending |
   | 8-01-03  | 01   | 1    | CONV-01, CONV-03 | — | N/A | unit + integration | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ⬜ pending |
   | 8-02-01  | 02   | 2    | CONV-02 | T-8.2-01 | data.table::copy guards on cpa_map/ind_map/inputs | unit | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ⬜ pending |
   | 8-02-02  | 02   | 2    | CONV-02, CONV-03 | T-8.2-01 | tryCatch isolation per group | unit + resilience | `Rscript -e "devtools::test(filter = 'pipeline')"` | ✅ | ⬜ pending |
   | 8-03-01  | 03   | 3    | CONV-01, CONV-02 | — | N/A | doc build | `Rscript -e "devtools::document()"` | ✅ | ⬜ pending |
   | 8-03-02  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | config | `Rscript -e "yaml::read_yaml('_pkgdown.yml')"` | ✅ | ⬜ pending |
   | 8-03-03  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | vignette build | `Rscript -e "devtools::build_vignettes()"` | ✅ | ⬜ pending |
   | 8-03-04  | 03   | 3    | CONV-01, CONV-02, CONV-03 | — | N/A | full CRAN check | `Rscript -e "devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')"` | ✅ | ⬜ pending |
   ```

3) Flip the frontmatter field in `.planning/phases/08-convenience-helpers/08-VALIDATION.md` from `nyquist_compliant: false` to `nyquist_compliant: true` and from `wave_0_complete: false` to `wave_0_complete: true` (Wave 0 gap was the missing `tests/testthat/test-pipeline.R`; it now exists with ≥ 25 test_that blocks after Plans 01+02+03).
  </action>
  <verify>
    <automated>Rscript -e "devtools::test(stop_on_failure = TRUE)"</automated>
    <automated>Rscript -e "devtools::document()"</automated>
    <automated>Rscript -e "devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')"</automated>
    <automated>grep -q "^nyquist_compliant: true$" .planning/phases/08-convenience-helpers/08-VALIDATION.md</automated>
    <automated>grep -q "^wave_0_complete: true$" .planning/phases/08-convenience-helpers/08-VALIDATION.md</automated>
    <automated>grep -q "8-01-01" .planning/phases/08-convenience-helpers/08-VALIDATION.md</automated>
    <automated>grep -q "8-03-04" .planning/phases/08-convenience-helpers/08-VALIDATION.md</automated>
  </verify>
  <acceptance_criteria>
    - `devtools::test()` exits 0 with 0 failures.
    - `devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')` exits 0 (no ERROR, no WARNING — NOTEs are acceptable if they are the same set present on master before this phase).
    - 08-VALIDATION.md `nyquist_compliant` is `true`.
    - 08-VALIDATION.md Per-Task Verification Map has all 9 task IDs (8-01-01, 8-01-02, 8-01-03, 8-02-01, 8-02-02, 8-03-01, 8-03-02, 8-03-03, 8-03-04).
    - `devtools::build_vignettes()` still succeeds (already verified in Task 3, re-run allowed if needed).
    - YAML check passes.
  </acceptance_criteria>
  <done>Full regression sweep green; R CMD check --no-manual --no-vignettes clean; validation map populated with concrete task IDs; nyquist flag flipped to true.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

N/A for this plan — it is pure documentation/packaging. All code-facing threats live in Plans 01 and 02.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8.3-01 | All | Documentation surface | accept | Pure text/YAML/Rd changes; no new attack surface. ASVS L1 N/A. |
</threat_model>

<verification>
- `Rscript -e "devtools::document()"` — no-op after roxygen blocks already ship.
- `Rscript -e "devtools::build_vignettes()"` — vignette builds clean.
- `Rscript -e "devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')"` — 0 ERROR, 0 WARNING.
- `Rscript -e "yaml::read_yaml('_pkgdown.yml')"` — valid YAML.
- NEWS.md has exactly 3 new bullets; paper-replication + figaro-workflow vignettes each have one cross-link line.
</verification>

<success_criteria>
1. `man/run_sube_pipeline.Rd` + `man/batch_sube.Rd` exist and render cleanly (CONV-01 + CONV-02 help surface).
2. `_pkgdown.yml` reference group 'Data import and preparation' lists both new functions in the specified order (D-8.13).
3. `_pkgdown.yml` articles section has a new 'Pipeline Helpers' group between 'Modeling, Comparison, and Outputs' and 'Package Design and Paper Context' (D-8.14).
4. `NEWS.md` development-version section has 3 new bullets (D-8.15), none of the existing v1.2 bullets disturbed.
5. `vignettes/pipeline-helpers.Rmd` ships with 7 sections, live `eval = TRUE` chunks on `sube_example_data()`, FIGARO illustration `eval = FALSE`, and a full diagnostic-category tour.
6. Existing FIGARO + paper-replication vignettes each carry one cross-link tip.
7. `devtools::check(args = c('--no-manual','--no-vignettes'), error_on = 'warning')` exits 0.
8. `.planning/phases/08-convenience-helpers/08-VALIDATION.md` Per-Task Verification Map populated; `nyquist_compliant: true` + `wave_0_complete: true`.
9. No regressions in the 5 pre-existing test files.
</success_criteria>

<output>
After completion, create `.planning/phases/08-convenience-helpers/08-03-SUMMARY.md`.
</output>

# tests/testthat/test-gated-data-contract.R
# INFRA-02: assert the env-var-only contract for resolve_wiod_root()
# and resolve_figaro_root(). D-7.7 removed the inst/extdata/{wiod,figaro}/
# fallback; this test guards against reintroducing it.
library(testthat)

# Local env-var scoping helper (avoids adding withr to Suggests).
with_env <- function(key, value, code) {
  old <- Sys.getenv(key, unset = NA)
  if (is.null(value)) {
    Sys.unsetenv(key)
  } else {
    Sys.setenv(setNames(list(value), key))
  }
  on.exit(
    if (is.na(old)) Sys.unsetenv(key) else Sys.setenv(setNames(list(old), key)),
    add = TRUE
  )
  force(code)
}

# ---- resolve_wiod_root --------------------------------------------------

test_that("resolve_wiod_root returns empty when SUBE_WIOD_DIR is unset (INFRA-02)", {
  with_env("SUBE_WIOD_DIR", NULL, {
    expect_identical(resolve_wiod_root(), "")
  })
})

test_that("resolve_wiod_root ignores inst/extdata/wiod/ fallback when env unset (D-7.7 regression guard)", {
  fallback <- system.file("extdata", "wiod", package = "sube")
  skip_if_not(nzchar(fallback) && dir.exists(fallback),
              "fallback path absent on this install; D-7.7 still holds vacuously")
  with_env("SUBE_WIOD_DIR", NULL, {
    expect_identical(resolve_wiod_root(), "")
  })
})

test_that("resolve_wiod_root returns env path when SUBE_WIOD_DIR points at valid dir", {
  tmp <- tempfile("sube-wiod-test-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  with_env("SUBE_WIOD_DIR", tmp, {
    expect_identical(resolve_wiod_root(), tmp)
  })
})

test_that("resolve_wiod_root returns empty when SUBE_WIOD_DIR points at nonexistent dir", {
  with_env("SUBE_WIOD_DIR", "/this/path/does/not/exist/ever", {
    expect_identical(resolve_wiod_root(), "")
  })
})

# ---- resolve_figaro_root -----------------------------------------------

test_that("resolve_figaro_root returns empty when SUBE_FIGARO_DIR is unset (INFRA-02)", {
  with_env("SUBE_FIGARO_DIR", NULL, {
    expect_identical(resolve_figaro_root(), "")
  })
})

test_that("resolve_figaro_root ignores inst/extdata/figaro/ fallback when env unset (D-7.7 regression guard)", {
  fallback <- system.file("extdata", "figaro", package = "sube")
  skip_if_not(nzchar(fallback) && dir.exists(fallback),
              "fallback path absent on this install; D-7.7 still holds vacuously")
  with_env("SUBE_FIGARO_DIR", NULL, {
    expect_identical(resolve_figaro_root(), "")
  })
})

test_that("resolve_figaro_root returns env path when SUBE_FIGARO_DIR points at valid dir", {
  tmp <- tempfile("sube-figaro-test-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  with_env("SUBE_FIGARO_DIR", tmp, {
    expect_identical(resolve_figaro_root(), tmp)
  })
})

test_that("resolve_figaro_root returns empty when SUBE_FIGARO_DIR points at nonexistent dir", {
  with_env("SUBE_FIGARO_DIR", "/this/path/does/not/exist/ever", {
    expect_identical(resolve_figaro_root(), "")
  })
})

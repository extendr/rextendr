library(testthat)
library(rextendr)

# no need to run tests if cargo isn't installed.
cargo_available <- system2("cargo") == 0L
not_cran <- identical(Sys.getenv("NOT_CRAN"), "true")

if (cargo_available && not_cran) {
  test_env <- formals(rextendr::rust_source)

  toolchain <- Sys.getenv("REXTENDR_TOOLCHAIN")
  if (!is.null(toolchain) && nzchar(toolchain)) {
    test_env$toolchain <- toolchain
    message(paste0(">> {rextendr}: Using toolchain from 'REXTENDR_TOOLCHAIN': ", toolchain))
  }

  patch <- Sys.getenv("REXTENDR_PATCH_CRATES_IO")
  if (!is.null(patch) && nzchar(patch)) {
    test_env$patch.crates_io <- strsplit(patch, ";")[[1]]
    message(paste0(">> {rextendr}: Using cargo patch from 'REXTENDR_PATCH_CRATES_IO': ", patch))
  } else {
    test_env$patch.crates_io <- eval(test_env$patch.crates_io)
  }

  test_check("rextendr")
}
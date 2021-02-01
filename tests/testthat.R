library(testthat)
library(rextendr)

# no need to run tests if cargo isn't installed.
cargo_available <- system2("cargo") == 0L
not_cran <- identical(Sys.getenv("NOT_CRAN"), "true")

if (cargo_available && not_cran) {
  # This retrieves exrepssions that represent
  # default arguments of rust_source,
  # which are used for reference
  test_env <- formals(rextendr::rust_source)

  # Toolchain is a string, so can be read as is
  toolchain <- Sys.getenv("REXTENDR_TOOLCHAIN")
  if (!is.null(toolchain) && nzchar(toolchain)) {
    test_env$toolchain <- toolchain
    message(paste0(">> {rextendr}: Using toolchain from 'REXTENDR_TOOLCHAIN': ", toolchain))
  }

  # Patch is represented as vector of character.
  # In environment variable different crates are separated using ';'
  # E.g., "extendr-api = { git = \"https://github.com/extendr/extendr\" };extendr-macros = { git = \"https://github.com/extendr/extendr\" }"
  patch <- Sys.getenv("REXTENDR_PATCH_CRATES_IO")
  if (!is.null(patch) && nzchar(patch)) {
    test_env$patch.crates_io <- strsplit(patch, ";")[[1]]
    message(paste0(">> {rextendr}: Using cargo patch from 'REXTENDR_PATCH_CRATES_IO': ", patch))
  } else {
    # Patch should be evaluated because it can be represented as a vector
    test_env$patch.crates_io <- eval(test_env$patch.crates_io)
  }

  test_check("rextendr")
}
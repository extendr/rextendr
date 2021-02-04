library(testthat)
library(rextendr)

# no need to run tests if cargo isn't installed.
cargo_available <- system2("cargo") == 0L
not_cran <- identical(Sys.getenv("NOT_CRAN"), "true")

if (cargo_available && not_cran) {
  test_check("rextendr")
}

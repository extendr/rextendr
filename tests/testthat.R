library(testthat)
library(rextendr)

# no need to run tests if cargo isn't installed.
result <- system2("cargo")
if (result == 0L) {
  test_check("rextendr")
}

test_that("Feature 'ndarray' is enabled when no extra dependencies are specified", {
  skip_if_cargo_unavailable()
  skip_on_R42_win()
  skip_on_cran()

  input <- file.path("../data/ndarray_example.rs")
  rust_source(
    file = input,
    features = "ndarray"
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Feature 'ndarray' is enabled when 'extendr-api' has features enabled", {
  skip_if_cargo_unavailable()
  skip_on_R42_win()
  skip_on_cran()

  input <- file.path("../data/ndarray_example.rs")
  rust_source(
    file = input,
    features = "ndarray",
    extendr_deps = list(`extendr-api` = list(version = "*", features = array("serde")))
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Enable multiple features simultaneously", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  rust_function("fn test_multiple_features() {}", features = c("ndarray", "serde", "graphics"))
  expect_no_error(test_multiple_features())
})

test_that("Passing integers to `features` results in error", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(rust_function("fn test() {}", features = 1:10))
})

test_that("Passing list to `features` results in error", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(rust_function("fn test() {}", features = list()))
})

test_that("Feature 'ndarray' is enabled when no extra dependencies are specified", {
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
  rust_function("fn test_multiple_features() {}", features = c("ndarray", "serde", "graphics"))
  expect_no_error(test_multiple_features())
})

test_that("Passing integers to `features` results in error", {
  expect_error(rust_function("fn test() {}", features = 1:10))
})

test_that("Passing list to `features` results in error", {
  expect_error(rust_function("fn test() {}", features = list()))
})

test_that("Enabling experimental feature raises warning", {
  expect_warning(
    rust_function(
      "fn test_either(_x : Either<Integers, Doubles>) {}",
      features = "either",
      # either works only with `use_try_from = TRUE`
      extendr_fn_options = list(use_try_from = TRUE),
      # manually override dependency to avoid setting `use_dev_extendr = TRUE`
      patch.crates_io = list("extendr-api" = list(git = "https://github.com/extendr/extendr"))
    )
  )
})

test_that("Enabling experimental feature does not raise warning if `use_dev_extendr` is `TRUE`", {
  expect_no_warning(
    rust_function(
      "fn test_either(_x : Either<Integers, Doubles>) {}",
      features = "either",
      # either works only with `use_try_from = TRUE`
      extendr_fn_options = list(use_try_from = TRUE),
      use_dev_extendr = TRUE
    )
  )
})

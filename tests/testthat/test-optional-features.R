test_that("Feature 'ndarray' is enabled when no extra dependencies are specified", {
  input <- file.path("../data/either_example.rs")
  rust_source(
    file = input,
    features = "ndarray"
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Feature 'ndarray' is enabled when dependency is explicitly set", {
  input <- file.path("../data/either_example.rs")
  rust_source(
    file = input,
    features = "ndarray",
    dependencies = list(ndarray = "*")
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Feature 'ndarray' is enabled when dependency is explicitly set to a complex value", {
  input <- file.path("../data/either_example.rs")
  rust_source(
    file = input,
    features = "ndarray",
    dependencies = list(ndarray = list(version = "*"))
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Feature 'ndarray' is enabled when other dependencies are specified", {
  input <- file.path("../data/either_example.rs")
  rust_source(
    file = input,
    features = "ndarray",
    dependencies = list(either = list(version = "*"))
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

test_that("Feature 'ndarray' is enabled when 'extendr-api' has features enabled", {
  input <- file.path("../data/either_example.rs")
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

test_that("'features' accepts only pre-defined values", {
  expect_error(rust_function("fn test_two_features() {}", features = "not-a-feature"))
})

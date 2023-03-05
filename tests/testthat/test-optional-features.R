test_that("Feature 'either' is enabled when no extra dependencies are passed", {
  input <- file.path("../data/either_example.rs")
  rextendr::rust_source(
    file = input,
    features = "ndarray"
  )

  data <- matrix(runif(100L), 25)
  expected_sum <- sum(data)
  actual_sum <- matrix_sum(data)

  expect_equal(actual_sum, expected_sum)
})

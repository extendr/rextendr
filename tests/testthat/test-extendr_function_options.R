test_that("`extendr` code is compiled with `either` feature and `use_try_from` enabled", {
  rust_function(
    "fn type_aware_sum(input : Either<Integers, Doubles>) -> Either<Rint, Rfloat> {
      match input {
        Either::Left(left) => Either::Left(left.iter().sum()),
        Either::Right(right) => Either::Right(right.iter().sum())
      }
    }",
    extendr_fn_options = list("use_try_from" = TRUE),
    features = "either",
    use_dev_extendr = TRUE,
    quiet = TRUE # Suppresses warnings while the feature is still experimental
  )

  int_sum <- type_aware_sum(1:5)

  expect_type(int_sum, "integer")
  expect_equal(int_sum, 15L)

  dbl_sum <- type_aware_sum(c(1, 2, 3, 4, 5))

  expect_type(dbl_sum, "double")
  expect_equal(dbl_sum, 15)
})

test_that("`r_name` option renames R function", {
  rust_function(
    "fn func() -> &'static str {\"Modified Name\"}",
    extendr_fn_options = list("r_name" = "not_original_name")
  )

  expect_equal(not_original_name(), "Modified Name")
})

test_that("`rust_source()` errors if `extendr_fn_options` contains `NULL` value", {
  expect_error(rust_function("fn func() {}", extendr_fn_options = list("use_try_from" = NULL)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains value of the wrong type", {
  expect_error(rust_function("fn func() {}", extendr_fn_options = list("use_try_from" = 42L)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains option with an invalid name", {
  expect_error(rust_function("fn func() {}", extendr_fn_options = list("use try from" = TRUE)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains two invalid options", {
  expect_error(
    rust_function("fn func() {}", extendr_fn_options = list("use try from" = TRUE, "r_name" = NULL))
  )
})

test_that("`rust_source()` warns if `extendr_fn_options` contains an unkwon option", {
  expect_warning( # Unknown option
    expect_error( # Failed compilation because of the unknonw option
      rust_function("fn func() {}", extendr_fn_options = list("unknown_option" = 42L))
    )
  )
})

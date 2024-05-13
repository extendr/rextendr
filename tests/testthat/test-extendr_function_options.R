test_that("`extendr` code is compiled with `either` feature", {
  skip_if_cargo_unavailable()

  rust_function(
    "fn type_aware_sum(input : Either<Integers, Doubles>) -> Either<Rint, Rfloat> {
      match input {
        Either::Left(left) => Either::Left(left.iter().sum()),
        Either::Right(right) => Either::Right(right.iter().sum())
      }
    }",
    features = "either",
  )

  int_sum <- type_aware_sum(1:5)

  expect_type(int_sum, "integer")
  expect_equal(int_sum, 15L)

  dbl_sum <- type_aware_sum(c(1, 2, 3, 4, 5))

  expect_type(dbl_sum, "double")
  expect_equal(dbl_sum, 15)
})

test_that("`r_name` option renames R function", {
  skip_if_cargo_unavailable()

  rust_function(
    "fn func() -> &'static str {\"Modified Name\"}",
    extendr_fn_options = list("r_name" = "not_original_name")
  )

  expect_equal(not_original_name(), "Modified Name")
})

test_that("`rust_source()` errors if `extendr_fn_options` contains `NULL` value", {
  expect_rextendr_error(rust_function("fn func() {}", extendr_fn_options = list("use_rng" = NULL)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains value of the wrong type", {
  skip_if_cargo_unavailable()

  # due to the use of purrr here, the error that is emitted is on of class `mutate_error`
  # we cannot expect `rextendr_error` from this function.
  expect_error(rust_function("fn func() {}", extendr_fn_options = list("use_rng" = 42L)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains option with an invalid name", {
  skip_if_cargo_unavailable()

  expect_rextendr_error(rust_function("fn func() {}", extendr_fn_options = list("use try from" = TRUE)))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains two invalid options", {
  skip_if_cargo_unavailable()

  expect_rextendr_error(
    rust_function("fn func() {}", extendr_fn_options = list("use try from" = TRUE, "r_name" = NULL))
  )
})

test_that("`rust_source()` warns if `extendr_fn_options` contains an unknown option", {
  skip_if_cargo_unavailable()

  expect_warning( # Unknown option
    expect_rextendr_error( # Failed compilation because of the unknonw option
      rust_function("fn func() {}", extendr_fn_options = list("unknown_option" = 42L))
    )
  )
})

test_that(
  "`rust_source()` does not warn if `extendr_fn_options` contains an unknown option and `use_dev_extendr` is `TRUE`",
  {
    skip_if_cargo_unavailable()
    skip_if_opted_out_of_dev_tests()

    expect_rextendr_error( # Failed compilation because of the unknonw option
      rust_function(
        code = "fn func() {}",
        extendr_fn_options = list("unknown_option" = 42L),
        use_dev_extendr = TRUE
      )
    )
  }
)


test_that(
  "`rust_function()` does not emit any messages when `quiet = TRUE`",
  {
    skip_if_cargo_unavailable()

    expect_no_message(rust_function(code = "fn func() {}", quiet = TRUE))
  }
)

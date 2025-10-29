test_that("`extendr` code is compiled with `either` feature", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  rust_function(
    "fn type_aware_sum(input : Either<Integers, Doubles>) -> Either<Rint, Rfloat> {
      match input {
        Either::Left(left) => Either::Left(left.iter().sum()),
        Either::Right(right) => Either::Right(right.iter().sum())
      }
    }",
    features = "either",
    use_dev_extendr = TRUE
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
  skip_on_cran()

  rust_function(
    "fn func() -> &'static str {\"Modified Name\"}",
    extendr_fn_options = list("r_name" = "not_original_name")
  )

  expect_equal(not_original_name(), "Modified Name")
})

test_that("`rust_source()` errors if `extendr_fn_options` contains `NULL` value", {
  expect_rextendr_error(rust_function(
    "fn func() {}",
    extendr_fn_options = list("use_rng" = NULL)
  ))
  skip_on_cran()
})

test_that("`rust_source()` errors if `extendr_fn_options` contains value of the wrong type", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(rust_function(
    "fn func() {}",
    extendr_fn_options = list("use_rng" = 42L)
  ))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains option with an invalid name", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(rust_function(
    "fn func() {}",
    extendr_fn_options = list("use try from" = TRUE)
  ))
})

test_that("`rust_source()` errors if `extendr_fn_options` contains two invalid options", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(
    rust_function(
      "fn func() {}",
      extendr_fn_options = list("use try from" = TRUE, "r_name" = NULL)
    )
  )
})

test_that("`rust_function()` errors if `extendr_fn_options` contains an option not in dev or release", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(
    # Failed compilation because of the unknonw option
    rust_function(
      "fn func() {}",
      extendr_fn_options = list("unknown_option" = 42L),
      use_dev_extendr = TRUE
    )
  )
})

# nolint start: line_length_linter
test_that("`rust_function()` errors if `extendr_fn_options` contains an option in dev but `use_dev_extendr` is `FALSE`", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_rextendr_error(
    # Failed compilation because of the unknonw option
    rust_function(
      "fn func() {}",
      extendr_fn_options = list("invisible" = 42L),
      use_dev_extendr = FALSE
    )
  )
})
# nolint end

test_that("`rust_function()` does not emit any messages when `quiet = TRUE`", {
  skip_if_cargo_unavailable()
  skip_on_cran()

  expect_no_message(rust_function(code = "fn func() {}", quiet = TRUE))
})

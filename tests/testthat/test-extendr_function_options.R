test_that("TODO", {
  rust_function(
    "fn type_aware_sum(input : either::Either<Integers, Doubles>) -> either::Either<Rint, Rfloat> {
      match input {
        either::Either::Left(left) => either::Either::Left(left.iter().sum()),
        either::Either::Right(right) => either::Either::Right(right.iter().sum())
      }
    }",
    extendr_fn_options = list("use_try_from" = TRUE),
    features = "either",
    use_dev_extendr = TRUE,
    quiet = TRUE, # Suppresses warnings while the feature is still experimental
    dependencies = list(either = "*") # Crates associated with experimental features are not references automatically
  )

  int_sum <- type_aware_sum(1:5)

  expect_type(int_sum, "integer")
  expect_equal(int_sum, 15L)

  dbl_sum <- type_aware_sum(c(1, 2, 3, 4, 5))

  expect_type(dbl_sum, "double")
  expect_equal(dbl_sum, 15)
})

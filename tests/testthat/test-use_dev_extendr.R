test_that("`use_dev_extendr = TRUE` works together with `features`", {
  skip_if_cargo_unavailable()
  skip_if_opted_out_of_dev_tests()
  skip_on_cran()

  rust_function(
    "fn uses_either() -> Either<Rint, Rfloat> { Either::Left(Rint::from(42i32)) }",
    features = "either",
    use_dev_extendr = TRUE,
    quiet = TRUE # Suppresses warnings while the feature is still experimental
  )

  expect_equal(42L, uses_either())
})

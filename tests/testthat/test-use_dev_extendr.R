test_that("`use_dev_extendr = TRUE` works together with `features`", {
  rust_function(
    "fn uses_either() -> Either<Rint, Rfloat> { Either::Left(Rint::from(42i32)) }",
    features = "either",
    use_dev_extendr = TRUE,
    quiet = TRUE # Suppresses warnings while the feature is still experimental
  )

  expect_equal(42L, uses_either())
})

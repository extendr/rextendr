test_that("Running `document` after adding multiple files", {
  skip_on_cran()

  path <- local_package("testPackage")
  rextendr::use_extendr()
  expect_error(rextendr::document(), NA)

  file.create(glue("{path}src/rust/src/a.rs"))
  file.create(glue("{path}src/rust/src/b.rs"))

  expect_error(rextendr::document(), NA)
})

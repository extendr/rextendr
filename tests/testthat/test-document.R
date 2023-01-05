test_that("Running `document` after adding multiple files", {
  skip_on_cran()

  path <- local_package("testPackage")
  rextendr::use_extendr()
  expect_error(rextendr::document(), NA)

  file.create(file.path(path, "src/rust/src/a.rs"))
  file.create(file.path(path, "src/rust/src/b.rs"))

  expect_error(rextendr::document(), NA)
})

test_that("Warn if using older rextendr", {
  path <- local_package("futurepkg")
  use_extendr()
  desc::desc_set(`Config/rextendr/version` = "999.999")

  expect_message(document(quiet = FALSE), "Installed rextendr is older than the version used with this package")
})

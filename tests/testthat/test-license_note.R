test_that("LICENSE.note is generated properly", {
  skip_on_cran()
  skip_if_not_installed("RcppTOML")
  skip_if_cargo_bin(c("metadata", "--help"))

  local_package("testPackage")
  rextendr::use_extendr()
  write_license_note()

  expect_snapshot(cat_file("LICENSE.note"))
  expect_rextendr_error(write_license_note(), NA)
  expect_rextendr_error(write_license_note(force = FALSE), "LICENSE.note already exists.")
})

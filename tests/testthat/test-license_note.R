test_that("LICENSE.note is generated properly", {
  skip_if_not_installed("usethis")
  skip_if_cargo_unavailable(c("license", "--help"))

  local_package("testPackage")

  # try running write_license_note() when there is nothing present
  dir.create(file.path("src", "rust"), recursive = TRUE)
  expect_error(write_license_note())

  # create license note for extendr package
  use_extendr()
  write_license_note()
  expect_snapshot(cat_file("LICENSE.note"))
  expect_error(write_license_note(path = NULL))
  expect_error(write_license_note(force = "yup"))
})

test_that("create_extendr_package() creates an extendr package project correctly", {

  skip_if_not_installed("usethis")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  dir <- local_temp_dir("testCreateExtendrPackage")

  scrubbed_string <- normalizePath(dir, winslash = "/")

  expect_snapshot(
    rextendr:::create_extendr_package(
      path = dir,
      roxygen = TRUE,
      check_name = TRUE,
      edition = "2021"
    ),
    transform = function(lines) {
      stringi::stri_replace_all_fixed(lines, scrubbed_string, "TEMPORARY_PACKAGE_PATH")
    }
  )

  expect_snapshot(cat_file("INDEX"))

})

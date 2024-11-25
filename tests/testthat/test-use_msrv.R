test_that("use_msrv() modifies the MSRV in the DESCRIPTION", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)
  expect_no_error(use_msrv("1.70", path))

  d <- desc::desc("DESCRIPTION")

  expect_identical(
    "Cargo (Rust's package manager), rustc >= 1.70",
    d$get_field("SystemRequirements")
  )

  expect_error(use_msrv("adksfghu", path))

  expect_error(use_msrv("1.70", path = "../doesntexist"))

  # when overwrite is FALSE and SystemRequirements is already set
  expect_message(
    use_msrv("1.65", overwrite = FALSE),
    "The SystemRequirements field in the "
  )
})

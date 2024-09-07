test_that("use_msrv() modifies the MSRV in the DESCRIPTION", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)
  use_msrv("1.70", path)

  d <- desc::desc("DESCRIPTION")

  expect_identical(
    "Cargo (Rust's package manager), rustc >= 1.70",
    d$get_field("SystemRequirements")
  )
})

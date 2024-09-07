test_that("use_msrv() modifies the MSRV in the DESCRIPTION", {
  skip_if_not_installed("usethis")

  path <- withr::local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)
  use_msrv("1.70")

  expect_snapshot(cat(readLines("DESCRIPTION"), sep = "\n"))
})
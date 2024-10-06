test_that("read_cargo_metadata() returns crate or workspace metadata", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  out <- read_cargo_metadata(path)

  expect_type(out, "list")
})

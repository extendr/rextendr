test_that("find_extendr_crate() returns path to Rust crate", {
  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  expect_error(find_extendr_crate(), class = "rextendr_error")

  use_extendr(path, quiet = TRUE)

  rust_folder <- find_extendr_crate()

  expect_true(dir.exists(rust_folder))
})

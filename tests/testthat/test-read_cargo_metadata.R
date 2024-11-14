test_that("read_cargo_metadata() returns crate or workspace metadata", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  out <- read_cargo_metadata(path)

  expect_type(out, "list")

  expect_equal(
    out[["packages"]][["name"]],
    "testpkg"
  )

  expect_equal(
    out[["packages"]][["version"]],
    "0.1.0"
  )

  expect_equal(
    out[["packages"]][["dependencies"]][[1]][["name"]],
    "extendr-api"
  )

  expect_equal(
    out[["workspace_root"]],
    normalizePath(
      file.path(path, "src", "rust"),
      winslash = "\\",
      mustWork = FALSE
    )
  )
})

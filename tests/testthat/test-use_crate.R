test_that("use_crate() adds dependency to package or workspace", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  use_crate(
    "serde",
    features = "derive",
    git = "https://github.com/serde-rs/serde",
    version = "1.0.1"
  )

  metadata <- read_cargo_metadata(path)

  dependency <- metadata[["packages"]][["dependencies"]][[1]]
  dependency <- dependency[dependency[["name"]] == "serde", ]

  expect_equal(dependency[["name"]], "serde")

  expect_equal(dependency[["features"]], "derive")

  expect_equal(dependency[["source"]], "git+https://github.com/serde-rs/serde")

  expect_equal(dependency[["req"]], "^1.0.1")
})

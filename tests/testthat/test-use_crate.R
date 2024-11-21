test_that("use_crate() adds dependency to package or workspace", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  use_crate(
    "serde",
    features = "derive",
    version = "1.0.1",
    path = path
  )

  metadata <- read_cargo_metadata(path, echo = FALSE)

  dependency <- metadata[["packages"]][["dependencies"]][[1]]
  dependency <- dependency[dependency[["name"]] == "serde", ]

  expect_equal(dependency[["name"]], "serde")
  expect_equal(dependency[["features"]][[1]], "derive")
  expect_equal(dependency[["req"]], "^1.0.1")

})

test_that("use_crate() errors when user passes git and version arguments", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  fn <- function() {
    use_crate(
      "serde",
      git = "https://github.com/serde-rs/serde",
      version = "1.0.1"
    )
  }

  expect_error(fn(), class = "rextendr_error")
})

test_that("use_crate(optional = TRUE) adds optional dependency", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  use_crate(
    "serde",
    optional = TRUE,
    path = path
  )

  metadata <- read_cargo_metadata(path)

  dependency <- metadata[["packages"]][["dependencies"]][[1]]
  dependency <- dependency[dependency[["name"]] == "serde", ]

  expect_identical(dependency[["optional"]], TRUE)
})

test_that("use_crate(git = <url>) adds dependency with git source", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")

  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)

  use_extendr(path, quiet = TRUE)

  use_crate(
    "serde",
    git = "https://github.com/serde-rs/serde",
    path = path
  )

  metadata <- read_cargo_metadata(path)

  dependency <- metadata[["packages"]][["dependencies"]][[1]]
  dependency <- dependency[dependency[["name"]] == "serde", ]

  expect_equal(dependency[["source"]], "git+https://github.com/serde-rs/serde")
})

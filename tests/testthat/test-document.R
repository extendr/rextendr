test_that("Running `document` after adding multiple files", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()
  withr::local_options(lifecycle_verbosity = "quiet")

  path <- local_package("testPackage")
  use_extendr()
  expect_rextendr_error(rextendr::document(), NA)

  file.create(file.path(path, "src/rust/src/a.rs"))
  file.create(file.path(path, "src/rust/src/b.rs"))

  expect_rextendr_error(rextendr::document(), NA)
})

test_that("Warn if using older rextendr", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()
  withr::local_options(lifecycle_verbosity = "quiet")

  path <- local_package("futurepkg")
  use_extendr()
  desc::desc_set(`Config/rextendr/version` = "999.999")

  expect_message(
    document(quiet = FALSE),
    "Installed rextendr is older than the version used with this package"
  )
})

test_that("Update the Config/rextendr/version field in DESCRIPTION file", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()
  withr::local_options(lifecycle_verbosity = "quiet")

  path <- local_package("oldpkg")
  use_extendr()
  desc::desc_set(`Config/rextendr/version` = "0.1")

  expect_message(
    document(quiet = FALSE),
    "Setting `Config/rextendr/version` to"
  )

  version_in_desc <- stringi::stri_trim_both(desc::desc_get(
    "Config/rextendr/version",
    path
  )[[1]])
  expect_equal(version_in_desc, as.character(packageVersion("rextendr")))
})

test_that("document() warns if NAMESPACE file is malformed", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()
  withr::local_options(lifecycle_verbosity = "quiet")

  path <- local_package("testPackage")
  r"(exportPattern("^[[:alpha:]]+"))" |> brio::write_lines("NAMESPACE")
  use_extendr()
  expect_warning(
    rextendr::document(),
    "The 'NAMESPACE' file does not contain the expected `useDynLib` directive."
  )
})

test_that("document() is deprecated", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()

  path <- local_package("testPackage")
  use_extendr()
  expect_warning(document(), class = "lifecycle_warning_deprecated")
})

test_that("register_extendr() is deprecated", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()

  path <- local_package("testPackage")
  use_extendr()
  expect_warning(register_extendr(), class = "lifecycle_warning_deprecated")
})

test_that("devtools::document() builds lib", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()

  path <- local_package("testPackage")
  use_extendr()
  devtools::document()

  lib_file <- file.path(
    path,
    "src",
    paste0("testPackage", .Platform$dynlib.ext)
  )

  expect_true(file.exists(lib_file))
})

test_that("devtools::document() generates wrappers", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()

  path <- local_package("testPackage")
  use_extendr()
  devtools::document()
  expect_snapshot(cat_file("R/extendr-wrappers.R"))
})

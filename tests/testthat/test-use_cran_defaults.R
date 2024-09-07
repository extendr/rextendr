test_that("use_cran_defaults() modifies and creates files correctly", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  expect_snapshot(use_extendr())
  expect_snapshot(use_cran_defaults())

  expect_snapshot(cat_file("src", "Makevars"))
  expect_snapshot(cat_file("src", "Makevars.win"))
  expect_snapshot(cat_file("configure"))
  expect_snapshot(cat_file("configure.win"))
  expect_snapshot(cat_file("tools", "msrv.R"))
})

test_that("use_cran_defaults() quiet if quiet=TRUE", {
  skip_if_not_installed("usethis")

  path <- local_package("quiet")
  expect_snapshot({
    use_extendr(quiet = TRUE)
    use_cran_defaults(quiet = TRUE)
  })
})


test_that("vendor_pkgs() vendors dependencies", {
  mask_version_strings <- function(snapshot_lines) {
    stringi::stri_replace_all_regex(
      snapshot_lines,
      "\\d+\\.\\d+\\.\\d+",
      "*.*.*"
    )
  }

  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  use_extendr(path, quiet = TRUE)
  use_cran_defaults(path, quiet = TRUE, overwrite = TRUE)

  package_versions <- vendor_pkgs(path, quiet = TRUE)
  expect_snapshot(cat_file("src", "rust", "vendor-config.toml"))
  expect_snapshot(package_versions, transform = mask_version_strings)
  expect_true(file.exists(file.path("src", "rust", "vendor.tar.xz")))
})

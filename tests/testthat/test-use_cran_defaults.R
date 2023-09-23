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
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  use_extendr(path, quiet = TRUE)
  use_cran_defaults(path, quiet = TRUE)

  expect_snapshot(vendor_pkgs(path))
  expect_snapshot(cat_file("src", "rust", "vendor-config.toml"))

})

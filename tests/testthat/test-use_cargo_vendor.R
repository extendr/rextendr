test_that("use_cargo_vendor() sets up extendr files correctly", {
  skip_if_not_installed("usethis")
  local_edition(3)

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  use_extendr(path)
  use_cargo_vendor(path, overwrite = TRUE)

  expect_snapshot(cat_file("src", "Makevars"))
  expect_snapshot(cat_file("src", "Makevars.win"))
  expect_snapshot(cat_file(".gitignore"))
  expect_snapshot(cat_file(".Rbuildignore"))
  expect_snapshot(cat_file("src", "rust", "vendor-config.toml"))
})

test_that("vendor_pkgs() creates a compressed file", {
  skip_if_not_installed("usethis")
  skip_if_cargo_bin(c("vendor"))
  local_edition(3)

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  use_extendr(path)
  use_cargo_vendor(path, overwrite = TRUE)
  vendor_pkgs(path)
  # checking for a hash of a compressed file since we cannot compare contents
  expect_snapshot(cat(rlang::hash_file(file.path(path, "src", "rust", "vendor.tar.xz"))))
})

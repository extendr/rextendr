test_that("update_extendr() overwrites all scaffolding files", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)
  expect_true(update_extendr(revendor = FALSE, quiet = TRUE))

  expect_true(file.exists(file.path("src", "entrypoint.c")))
  expect_true(file.exists(file.path("src", "Makevars.in")))
  expect_true(file.exists(file.path("src", "Makevars.win.in")))
  expect_true(file.exists("cleanup"))
  expect_true(file.exists("cleanup.win"))
  expect_true(file.exists(file.path("src", "rust", "document.rs")))
  expect_true(file.exists(file.path("tools", "msrv.R")))
  expect_true(file.exists(file.path("tools", "config.R")))
  expect_true(file.exists("configure"))
  expect_true(file.exists("configure.win"))
})

test_that("update_extendr() substitutes crate_name and lib_name correctly", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)
  update_extendr(
    crate_name = "mycrate",
    lib_name = "mylib",
    revendor = FALSE,
    quiet = TRUE
  )

  makevars <- brio::read_file(file.path("src", "Makevars.in"))
  expect_true(grepl("mylib", makevars))

  configure <- brio::read_file("configure")
  expect_true(grepl("mylib", configure))
})

test_that("update_extendr() revendor = FALSE leaves vendor files untouched", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)

  src_rust <- file.path("src", "rust")
  brio::write_lines("dummy", file.path(src_rust, "vendor.tar.xz"))
  brio::write_lines("dummy", file.path(src_rust, "vendor-config.toml"))

  update_extendr(revendor = FALSE, quiet = TRUE)

  expect_true(file.exists(file.path(src_rust, "vendor.tar.xz")))
  expect_true(file.exists(file.path(src_rust, "vendor-config.toml")))
})

test_that("update_extendr() revendor = TRUE clears and recreates vendor files", {
  skip_if_not_installed("usethis")
  skip_on_cran()
  skip_if_cargo_unavailable(c("vendor", "--help"))

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)

  src_rust <- file.path("src", "rust")
  brio::write_lines("stale", file.path(src_rust, "vendor.tar.xz"))

  update_extendr(revendor = TRUE, quiet = TRUE)

  expect_true(file.exists(file.path(src_rust, "vendor.tar.xz")))
  expect_false(identical(
    brio::read_file(file.path(src_rust, "vendor.tar.xz")),
    "stale\n"
  ))
})

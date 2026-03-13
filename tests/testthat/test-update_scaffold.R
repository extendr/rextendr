test_that("update_scaffold() rewrites scaffolding files", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  withr::local_options(
    rextendr.extendr_deps = list(`extendr-api` = "*")
  )

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)
  expect_true(update_scaffold(quiet = TRUE))

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

test_that("update_scaffold() removes dependency-related files and folders", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  withr::local_options(
    rextendr.extendr_deps = list(`extendr-api` = "*")
  )

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)

  src_dir <- file.path("src", "rust")
  dir.create(file.path(src_dir, "vendor"), recursive = TRUE)
  dir.create(file.path(src_dir, "target"), recursive = TRUE)
  dir.create(file.path("src", ".cargo"), recursive = TRUE)
  file.create(file.path(src_dir, "vendor.tar.xz"))
  file.create(file.path(src_dir, "vendor-config.toml"))

  update_scaffold(quiet = TRUE)

  expect_false(dir.exists(file.path(src_dir, "vendor")))
  expect_false(dir.exists(file.path(src_dir, "target")))
  expect_false(dir.exists(file.path("src", ".cargo")))
  expect_false(file.exists(file.path(src_dir, "vendor.tar.xz")))
  expect_false(file.exists(file.path(src_dir, "vendor-config.toml")))
})

test_that("update_scaffold() substitutes crate_name and lib_name correctly", {
  skip_if_not_installed("usethis")
  skip_on_cran()

  withr::local_options(
    rextendr.extendr_deps = list(`extendr-api` = "*")
  )

  path <- local_package("testpkg")
  use_extendr(quiet = TRUE)
  update_scaffold(crate_name = "mycrate", lib_name = "mylib", quiet = TRUE)

  makevars <- brio::read_file(file.path("src", "Makevars.in"))
  expect_true(grepl("mylib", makevars))

  makevars_win <- brio::read_file(file.path("src", "Makevars.win.in"))
  expect_true(grepl("mylib", makevars_win))
})

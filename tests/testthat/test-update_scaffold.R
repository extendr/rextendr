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

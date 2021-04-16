test_that("use_extendr() sets up extendr files correctly", {
  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  expect_snapshot(use_extendr())

  # directory structure
  expect_true(dir.exists("src"))
  expect_true(dir.exists(file.path("src", "rust")))
  expect_true(dir.exists(file.path("src", "rust", "src")))

  # extendr files
  expect_true(file.exists(file.path("R", "extendr-wrappers.R")))
  expect_true(file.exists(file.path("src", "Makevars")))
  expect_true(file.exists(file.path("src", "Makevars.win")))
  expect_true(file.exists(file.path("src", "entrypoint.c")))
  expect_true(file.exists(file.path("src", "rust", "Cargo.toml")))
  expect_true(file.exists(file.path("src", "rust", "src", "lib.rs")))
})

test_that("use_extendr() does not set up packages with pre-existing src", {
  path <- local_package("testpkg.src")
  dir.create("src")
  withr::local_options(usethis.quiet = FALSE)
  expect_message(
    created <- use_extendr(),
    "already present in package source. No action taken."
  )

  expect_false(created)
})


test_that("use_extendr() does not set up packages with pre-existing wrappers", {
  path <- local_package("testpkg.wrap")
  usethis::use_r("extendr-wrappers", open = FALSE)
  withr::local_options(usethis.quiet = FALSE)
  expect_message(
    created <- use_extendr(),
    "already present in package source. No action taken."
  )

  expect_false(created)
})

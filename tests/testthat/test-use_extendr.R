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
  cat_file <- function(...) {
    cat(brio::read_file(file.path(...)))
  }

  expect_snapshot(cat_file("R", "extendr-wrappers.R"))
  expect_snapshot(cat_file("src", "Makevars"))
  expect_snapshot(cat_file("src", "Makevars.win"))
  expect_snapshot(cat_file("src", "entrypoint.c"))
  expect_snapshot(cat_file("src", "rust", "Cargo.toml"))
  expect_snapshot(cat_file("src", "rust", "src", "lib.rs"))
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

test_that("use_rextendr_template() works when usethis not available", {
  path <- local_package("testpkg.wrap")
  mockr::with_mock(
    # mock that usethis installed
    is_installed = function(...) TRUE,
    use_extendr(),
    .env = "rextendr"
  )

  files <- c(
    file.path("R", "extendr-wrappers.R"),
    file.path("src", "Makevars"),
    file.path("src", "Makevars.win"),
    file.path("src", "entrypoint.c"),
    file.path("src", "rust", "Cargo.toml"),
    file.path("src", "rust", "src", "lib.rs")
  )

  usethis_generated_templates <- purrr::map(files, brio::read_lines)

  unlink("src", recursive = TRUE)
  unlink(file.path("R", "extendr-wrappers.R"))

  mockr::with_mock(
    # mock that usethis not installed
    is_installed = function(...) FALSE,
    use_extendr(),
    .env = "rextendr"
  )

  rextendr_generated_templates <- purrr::map(files, brio::read_lines)

  expect_identical(usethis_generated_templates, rextendr_generated_templates)
})

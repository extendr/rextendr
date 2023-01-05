test_that("use_extendr() sets up extendr files correctly", {
  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  expect_snapshot(use_extendr())

  # directory structure
  expect_true(dir.exists("src"))
  expect_true(dir.exists(file.path("src", "rust")))
  expect_true(dir.exists(file.path("src", "rust", "src")))

  expect_snapshot(cat_file("R", "extendr-wrappers.R"))
  expect_snapshot(cat_file("src", "Makevars"))
  expect_snapshot(cat_file("src", "Makevars.win"))
  expect_snapshot(cat_file("src", "Makevars.ucrt"))
  expect_snapshot(cat_file("src", "entrypoint.c"))
  expect_snapshot(cat_file("src", "testpkg-win.def"))
  expect_snapshot(cat_file("src", "rust", "Cargo.toml"))
  expect_snapshot(cat_file("src", "rust", "src", "lib.rs"))
})

test_that("use_extendr() quiet if quiet=TRUE", {
    path <- local_package("quiet")
    expect_snapshot(use_extendr(quiet = TRUE))
  }
)

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
    { use_extendr() },
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
    { use_extendr() },
    .env = "rextendr"
  )

  rextendr_generated_templates <- purrr::map(files, brio::read_lines)

  expect_identical(usethis_generated_templates, rextendr_generated_templates)
})

# Check that {rextendr} works in packages containing dots in their names.
# The check is performed by compiling the sample package and checking that
# `hello_world()` template function is available and works.
test_that("use_extendr() handles R packages with dots in the name", {
  path <- local_package("a.b.c")
  use_extendr()
  document()
  document()
  expect_equal(hello_world(), "Hello world!")
})

# Specify crate name and library names explicitly
test_that("use_extendr() handles R package name, crate name and library name separately", {
  path <- local_package("testPackage")
  use_extendr(crate_name = "crate_name", lib_name = "lib_name")
  document()
  document()
  expect_equal(hello_world(), "Hello world!")
})

# Pass unsupported values to `crate_name` and `lib_name` and expect errors.
test_that("use_extendr() does not allow invalid rust names", {
  path <- local_package("testPackage")
  expect_rextendr_error(use_extendr(crate_name = "22unsupported"))
  expect_rextendr_error(use_extendr(lib_name = "@unsupported"))
})

test_that("R/ folder is created when not present", {
  path <- local_temp_dir("my.pkg")
  usethis::proj_set(path, force = TRUE)
  usethis::use_description()

  expect_false(dir.exists("R/"))

  # expect no error
  expect_error(use_extendr(), regexp = NA)
})

test_that("Warn if using older rextendr", {
  path <- local_package("futurepkg")
  use_extendr()
  desc::desc_set(`Config/rextendr/version` = "999.999")

  expect_message(document(quiet = FALSE), "Installed rextendr is older than the version used with this package")
})

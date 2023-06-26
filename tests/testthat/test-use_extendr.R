test_that("use_extendr() sets up extendr files correctly", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  # capture setup messages
  withr::local_options(usethis.quiet = FALSE)
  expect_snapshot(use_extendr())

  # DESCRITION file
  version_in_desc <- stringi::stri_trim_both(desc::desc_get("Config/rextendr/version", path)[[1]])
  expect_equal(version_in_desc, as.character(packageVersion("rextendr")))

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
  skip_if_not_installed("usethis")

  path <- local_package("quiet")
  expect_snapshot(use_extendr(quiet = TRUE))
})

test_that("use_extendr() skip pre-existing files in non-interactive sessions", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg.wrap")
  use_extendr(quiet = FALSE)
  withr::local_options(usethis.quiet = FALSE)
  expect_snapshot(use_extendr())
})

test_that("use_rextendr_template() works when usethis not available", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg.wrap")

  mockr::with_mock(
    # mock that usethis installed
    is_installed = function(...) TRUE,
    {
      use_rextendr_template(
        "_gitignore",
        save_as = file.path("installed")
      )
    },
    .env = "rextendr"
  )

  mockr::with_mock(
    # mock that usethis not installed
    is_installed = function(...) FALSE,
    {
      use_rextendr_template(
        "_gitignore",
        save_as = file.path("not_installed")
      )
    },
    .env = "rextendr"
  )

  expect_identical(brio::read_file(file.path("installed")), brio::read_file(file.path("not_installed")))
})

# Check that {rextendr} works in packages containing dots in their names.
# The check is performed by compiling the sample package and checking that
# `hello_world()` template function is available and works.
test_that("use_extendr() handles R packages with dots in the name", {
  skip_if_not_installed("usethis")

  path <- local_package("a.b.c")
  use_extendr()
  document()
  document()
  expect_equal(hello_world(), "Hello world!")
})

# Specify crate name and library names explicitly
test_that("use_extendr() handles R package name, crate name and library name separately", {
  skip_if_not_installed("usethis")

  path <- local_package("testPackage")
  use_extendr(crate_name = "crate_name", lib_name = "lib_name")
  document()
  document()
  expect_equal(hello_world(), "Hello world!")
})

# Pass unsupported values to `crate_name` and `lib_name` and expect errors.
test_that("use_extendr() does not allow invalid rust names", {
  skip_if_not_installed("usethis")

  path <- local_package("testPackage")
  expect_rextendr_error(use_extendr(crate_name = "22unsupported"))
  expect_rextendr_error(use_extendr(lib_name = "@unsupported"))
})

test_that("R/ folder is created when not present", {
  skip_if_not_installed("usethis")

  path <- local_temp_dir("my.pkg")
  usethis::proj_set(path, force = TRUE)
  usethis::use_description()

  expect_false(dir.exists("R/"))

  # expect no error
  expect_rextendr_error(use_extendr(), regexp = NA)
})

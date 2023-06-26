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

test_that("use_extendr() does not set up packages with pre-existing src", {
  skip_if_not_installed("usethis")

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
  skip_if_not_installed("usethis")

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
  skip_if_not_installed("usethis")

  path <- local_package("testpkg.wrap")
  # mock that usethis installed
  with_mocked_bindings(
    {
      use_extendr()
    },
    is_installed = function(...) TRUE
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

  # mock that usethis not installed
  with_mocked_bindings(
    {
      use_extendr()
    },
    is_installed = function(...) FALSE
  )

  rextendr_generated_templates <- purrr::map(files, brio::read_lines)

  expect_identical(usethis_generated_templates, rextendr_generated_templates)
})

# Check that {rextendr} works in packages containing dots in their names.
# The check is performed by compiling the sample package and checking that
# `hello_world()` template function is available and works.
test_that("use_extendr() handles R packages with dots in the name", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_bin()

  path <- local_package("a.b.c")
  use_extendr()
  document()
  devtools::load_all()
  expect_equal(hello_world(), "Hello world!")
})

# Specify crate name and library names explicitly
test_that("use_extendr() handles R package name, crate name and library name separately", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_bin()

  path <- local_package("testPackage")
  use_extendr(crate_name = "crate_name", lib_name = "lib_name")
  document()
  devtools::load_all()
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

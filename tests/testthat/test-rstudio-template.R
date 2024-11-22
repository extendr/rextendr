test_that("RStudio template generation is correct", {
  pkg_name <- "extendrtest"
  tmp <- file.path(tempdir(), pkg_name)

  pkg <- create_extendr_package(
    tmp,
    roxygen = TRUE,
    check_name = FALSE,
    crate_name = pkg_name,
    lib_name = pkg_name,
    edition = "2021"
  )

  expected_files <- c(
    "configure", "configure.win", "DESCRIPTION",
    "extendrtest.Rproj", "NAMESPACE", "R/extendr-wrappers.R",
    "src/entrypoint.c", "src/extendrtest-win.def",
    "src/Makevars.in", "src/Makevars.ucrt", "src/Makevars.win.in",
    "src/rust/Cargo.toml", "src/rust/src/lib.rs", "tools/msrv.R"
  )

  for (file in expected_files) {
    expect_true(file.exists(file.path(tmp, file)))
  }
})

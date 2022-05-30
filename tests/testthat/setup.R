old_test_settings <- options(
  usethis.quiet = TRUE
)

# Ensure inst/libgcc_mock exists
pkgbuild::compile_dll(force = TRUE, quiet = TRUE)

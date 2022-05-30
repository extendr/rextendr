old_test_settings <- options(
  usethis.quiet = TRUE
)

# Ensure inst/libgcc_mock exists (Note that `quiet = TRUE` seems mandatory here,
# otherwise it crashes probably because of broken pipe?)
pkgbuild::compile_dll(force = TRUE, quiet = TRUE)

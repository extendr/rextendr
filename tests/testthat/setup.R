withr::local_options(usethis.quiet = TRUE, .local_envir = teardown_env())

# Ensure inst/libgcc_mock exists (Note that `quiet = TRUE` seems mandatory here,
# otherwise it crashes probably because of broken pipe?)
pkgbuild::compile_dll(force = TRUE, quiet = TRUE)

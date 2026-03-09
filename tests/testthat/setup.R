withr::local_options(
  usethis.quiet = TRUE,
  .local_envir = teardown_env()
)

# use git version of extendr-api for CI and tests
options(
  "rextendr.extendr_deps" = list(
    `extendr-api` = list(git = "https://github.com/extendr/extendr")
  )
)

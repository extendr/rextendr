withr::local_options(
  usethis.quiet = TRUE,
  .local_envir = teardown_env()
)

# use "*" as version for CI and tests
options(
  "rextendr.extendr_deps" = list(
    `extendr-api` = "*"
  )
)

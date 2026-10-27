test_that("`try_exec_cmd()` returns `NA` when command is not available", {
  expect_true(is.na(try_exec_cmd("invalidcmdname")))
})

test_that("`try_exec_cmd()` returns stdout when command is available", {
  echo <- "This is an echo"
  expect_equal(try_exec_cmd("echo", echo), echo)
})

test_that("`replace_na()` respects type", {
  x <- 1:5
  x[2] <- NA
  expect_error(replace_na(x, "L"))
})

test_that("`replace_na()` replaces with the correct value", {
  x <- 1:5
  x[2] <- NA_integer_
  expect_identical(replace_na(x, -99L), c(1L, -99L, 3L, 4L, 5L))
})

test_that("`local_quiet_cli()` suppresses cli output in the calling function", {
  f <- function(quiet) {
    local_quiet_cli(quiet)
    cli::cli_alert_info("hello")
  }
  expect_message(f(quiet = FALSE))
  expect_no_message(f(quiet = TRUE))
})

test_that("`local_quiet_cli()` suppresses cli output in functions called by the calling function", {
  g <- function() cli::cli_alert_info("hello")
  f <- function(quiet) {
    local_quiet_cli(quiet)
    g()
  }
  expect_message(f(quiet = FALSE))
  expect_no_message(f(quiet = TRUE))
})

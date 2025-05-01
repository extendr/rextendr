test_that("`cargo_command_available()` returns TRUE when `try_exec_cmd()` returns not `NA`", {
  local_mocked_bindings(try_exec_cmd = function(...) {
    "output"
  })
  expect_true(cargo_command_available())
})

test_that("`cargo_command_available()` returns FALSE when `try_exec_cmd()` returns `NA`", {
  local_mocked_bindings(try_exec_cmd = function(...) {
    NA_character_
  })
  expect_false(cargo_command_available())
})

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

test_that("is_vscode() returns FALSE when VSCode environment variables are not set", {
  withr::with_envvar(
    c(
      VSCODE_PID = "",
      VSCODE_CWD = "",
      VSCODE_IPC_HOOK_CLI = "",
      TERM_PROGRAM = ""
    ),
    {
      expect_false(is_vscode())
    }
  )
})

test_that("is_vscode() returns TRUE when VSCode environment variables are set", {
  withr::with_envvar(
    c(
      VSCODE_PID = "",
      VSCODE_CWD = "",
      VSCODE_IPC_HOOK_CLI = "",
      TERM_PROGRAM = "vscode"
    ),
    {
      expect_true(is_vscode())
    }
  )
})
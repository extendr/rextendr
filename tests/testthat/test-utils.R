test_that("`cargo_command_available()` returns TRUE when `try_exec_cmd()` returns not `NA`", {
  mockr::local_mock(try_exec_cmd = function(...) {
    "output"
  })
  expect_true(cargo_command_available())
})

test_that("`cargo_command_available()` returns FALSE when `try_exec_cmd()` returns `NA`", {
  mockr::local_mock(try_exec_cmd = function(...) {
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

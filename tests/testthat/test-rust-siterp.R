test_that("`cargo` or `rustup` are not found", {
  mockr::local_mock(try_exec_cmd = function(...) {
    NA_character_
  })
  expect_snapshot(rust_sitrep())
})

test_that("`rust_eval()` works", {
  expect_equal(rust_eval("2 + 2"), 4)
  expect_visible(rust_eval("2 + 2"))

  expect_equal(rust_eval("let _ = 2 + 2;"), NULL)
  expect_invisible(rust_eval("let _ = 2 + 2;"))
})

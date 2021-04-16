test_that("Multiple rust functions with the same name", {
  rust_src_1 <- "
  #[extendr]
  fn rust_fn_1() -> i32 { 1i32 }

  #[extendr]
  fn rust_fn_2() -> i32 { 2i32 }
  "

  rust_src_2 <- "
  #[extendr]
  fn rust_fn_2() -> i32 { 20i32 }

  #[extendr]
  fn rust_fn_3() -> i32 { 30i32 }
  "

  rust_source(
    code = rust_src_1,
    quiet = FALSE # ,
    # toolchain = rust_source_defaults[["toolchain"]],
    # patch.crates_io = rust_source_defaults[["patch.crates_io"]]
  )

  # At this point:
  # fn1 -> 1
  # fn2 -> 2
  # fn3 -> (not exported)

  expect_equal(rust_fn_1(), 1L)
  expect_equal(rust_fn_2(), 2L)

  rust_source(
    code = rust_src_2,
    quiet = FALSE # ,
    # toolchain = rust_source_defaults[["toolchain"]],
    # patch.crates_io = rust_source_defaults[["patch.crates_io"]]
  )

  # At this point:
  # fn1 -> 1 (unchanged)
  # fn2 -> 20 (changed)
  # fn3 -> 30 (new function)

  expect_equal(rust_fn_1(), 1L)
  expect_equal(rust_fn_2(), 20L)
  expect_equal(rust_fn_3(), 30L)
})

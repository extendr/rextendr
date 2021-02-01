test_that("Testing the source", {

  rust_src <- "
    #[extendr]
    fn hello() -> &'static str {
        \"Hello, this string was created by Rust.\"
    }

    #[extendr]
    fn add_and_multiply(a: i32, b: i32, c: i32) -> i32 {
      c * (a + b)
    }

    #[extendr]
    fn add(a: i64, b: i64) -> i64 {
        a + b
    }

    #[extendr]
    fn say_nothing() {

    }
    "

  rust_source(
    code = rust_src,
    quiet = FALSE,
    cache_build = TRUE,
    toolchain = test_env[["toolchain"]],
    patch.crates_io = test_env[["patch.crates_io"]]
  )

  # call `hello()` function from R
  #> [1] "Hello, this string was created by Rust."
  expect_equal(hello(), "Hello, this string was created by Rust.")

  # call `add()` function from R
  expect_equal(add(14, 23), 37)
  #> [1] 37
  expect_equal(add(17, 42), 17 + 42)

  # This function takes no arguments and invisibly return NULL
  expect_null(say_nothing())

})

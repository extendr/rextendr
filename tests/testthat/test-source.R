test_that("`rust_source()` works", {
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
    cache_build = TRUE # ,
  )

  # call `hello()` function from R
  # > [1] "Hello, this string was created by Rust."
  expect_equal(hello(), "Hello, this string was created by Rust.")

  # call `add()` function from R
  expect_equal(add(14, 23), 37)
  # > [1] 37
  expect_equal(add(17, 42), 17 + 42)

  # This function takes no arguments and invisibly return NULL
  expect_null(say_nothing())
})


test_that("`options` override `toolchain` value in `rust_source`", {
  withr::local_options(rextendr.toolchain = "Non-existent-toolchain")
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})

test_that("`options` override `patch.crates_io` value in `rust_source`", {
  withr::local_options(rextendr.patch.crates_io = list(`extendr-api` = "-1"))
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})


test_that("`options` override `rextendr.extendr_deps` value in `rust_source`", {
  withr::local_options(rextendr.extendr_deps = list(`extendr-api` = "-1"))
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})

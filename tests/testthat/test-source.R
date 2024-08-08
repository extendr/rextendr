test_that("`rust_source()` works", {
  skip_if_cargo_unavailable()

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
  skip_if_cargo_unavailable()

  withr::local_options(rextendr.toolchain = "Non-existent-toolchain")
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})

test_that("`options` override `patch.crates_io` value in `rust_source`", {
  skip_if_cargo_unavailable()

  withr::local_options(rextendr.patch.crates_io = list(`extendr-api` = "-1"))
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})


test_that("`options` override `rextendr.extendr_deps` value in `rust_source`", {
  skip_if_cargo_unavailable()

  withr::local_options(rextendr.extendr_deps = list(`extendr-api` = "-1"))
  expect_rextendr_error(rust_function("fn rust_test() {}"), "Rust code could not be compiled successfully. Aborting.")
})

test_that("`rust_source` works even when the PATH is not set correctly, which mainly happens on macOS", {
  skip_on_os("windows") # On Windows, we have no concern as the only installation method is the official installer
  skip_on_os("linux") # On Linux, `cargo` might be on somewhere like `/usr/bin`, which is hard to eliminate
  skip_on_cran()
  skip_if_cargo_unavailable()

  # Construct PATH without ~/.cargo/bin
  local_path <- Sys.getenv("PATH")
  local_path <- stringi::stri_split_fixed(local_path, ":")[[1]]
  local_path <- stringi::stri_subset_fixed(local_path, ".cargo/bin", negate = TRUE)
  local_path <- glue_collapse(local_path, sep = ":")

  withr::local_envvar(PATH = local_path)

  # confirm cargo is not found
  expect_equal(Sys.which("cargo"), c(cargo = ""))

  # confirm `rust_function()` succeeds with a warning
  warn_msg <- "Can't find cargo on the PATH. Please review your Rust installation and PATH setups."
  expect_error(
    expect_warning(rust_function("fn rust_test() {}"), warn_msg),
    NULL
  )
})

# https://github.com/extendr/rextendr/issues/234
test_that("`rust_code()` can compile code from rust file", {
  skip_if_cargo_unavailable()

  input <- file.path("../data/rust_source.rs")
  expect_no_error(rust_source(input, module_name = "test_module"))
  expect_equal(test_method(), 42L)
})

# https://github.com/extendr/rextendr/issues/234
test_that("`rust_code()` can compile code from rust file multiple times", {
  skip_if_cargo_unavailable()

  input <- file.path("../data/rust_source.rs")
  expect_no_error(rust_source(input, module_name = "test_module"))
  expect_no_error(rust_source(input, module_name = "test_module"))
  expect_no_error(rust_source(input, module_name = "test_module"))
  expect_equal(test_method(), 42L)
})

# https://github.com/extendr/rextendr/issues/234
test_that("`rust_code()` can compile code from rust files with identical names", {
  skip_if_cargo_unavailable()

  input_1 <- file.path("../data/inner_1/rust_source.rs")
  input_2 <- file.path("../data/inner_2/rust_source.rs")

  expect_no_error(rust_source(input_1, module_name = "test_module"))
  expect_no_error(rust_source(input_2, module_name = "test_module"))

  expect_equal(test_method_1(), 1L)
  expect_equal(test_method_2(), 2L)
})

# https://github.com/extendr/rextendr/issues/264
test_that("`rust_source()` should not raise internal error for code without extendr attrs", {
  skip_if_cargo_unavailable()

  expect_no_error(rust_source(code = "fn test() {}"))
})

# https://github.com/extendr/rextendr/issues/356
test_that("`rust_function()` supports `r#` prefix in rust function names", {
  skip_if_cargo_unavailable()

  rust_fn_src <- "
    fn r#true() -> &'static str {
        \"Specially-named function has been called\"
    }
    "

  rust_function(
    code = rust_fn_src
  )

  expect_equal(true(), "Specially-named function has been called")
})

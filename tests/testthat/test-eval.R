test_that("`rust_eval()` works", {
  skip_if_cargo_unavailable()

  expect_equal(rust_eval("2 + 2"), 4)
  expect_visible(rust_eval("2 + 2"))

  expect_equal(rust_eval("let _ = 2 + 2;"), NULL)
  expect_invisible(rust_eval("let _ = 2 + 2;"))
})

# Test if multiple Rust chunks can be compiled and then executed
# in the order of compilation.
#
# Generate `n` integers (1..n) and then compile Rust chunks that
# return `n` as `i32`.
# Collect all deferred handles first, then execute them in
# the order of compilation.
# Returned integer values should be identical to the input sequence.
test_that("multiple `rust_eval_deferred()` work correctly", {
  skip_if_cargo_unavailable()

  provided_values <- seq_len(5)
  deferred_handles <- map(
    provided_values,
    ~ rust_eval_deferred(glue::glue("{.x}i32"))
  )

  obtained_values <- map_int(deferred_handles, ~ (.x)())

  testthat::expect_equal(
    obtained_values,
    provided_values
  )
})


# Test if multiple Rust chunks can be compiled and then executed
# in the reverse order. This ensures that the order of compilation and
# execution do not affect each other.
#
# Generate `n` integers (1..n) and then compile Rust chunks that
# return `n` as `i32`.
# Collect all deferred handles first, then execute them in
# the reverse order.
# Returned integer values should be identical to the reversed input sequence.
test_that("multiple `rust_eval_deferred()` work correctly in reverse order", {
  skip_if_cargo_unavailable()

  provided_values <- seq_len(5)

  deferred_handles <- map(
    provided_values,
    ~ rust_eval_deferred(glue::glue("{.x}i32"))
  )

  deferred_handles <- rev(deferred_handles)

  obtained_values <- map_int(deferred_handles, ~ (.x)())

  testthat::expect_equal(
    obtained_values,
    rev(provided_values)
  )
})

# Test if the same Rust chunk can be executed multiple times.
#
# After compilation, the Rust chunk can be executed only once, after which
# all associated resources are freed.
# First, compile a simple Rust expression returning an `i32` value.
# Second, execute it once and compare returned value to expected value.
# Third, attempt to execute the same compiled piece of code and
# observe an error.
test_that("`rust_eval_deferred()` disallows multiple executions of the same chunk", {
  skip_if_cargo_unavailable()

  handle <- rust_eval_deferred("5i32 + 6i32")

  testthat::expect_equal(handle(), 5L + 6L)
  testthat::expect_error(
    handle(),
    "The Rust code fragment is no longer available for execution."
  )
})

# Test if `rust_eval_deferred()` correctly cleans up environment.
#
# Create a simple Rust code chunk and compile it.
# Use attributes to get the name of the Rust (and R wrapper) function and
# the path to the dynamically compiled dll.
# Test if the wrapper is in the environement and the dll is loaded.
# Execute code chunk and verify result.
# Test if the wrapper has been removed and dll unloaded.
test_that("`rust_eval_deferred()` environment cleanup", {
  skip_if_cargo_unavailable()

  handle <- rust_eval_deferred("42i32")
  fn_name <- attr(handle, "function_name")
  dll_path <- attr(handle, "dll_path")

  testthat::expect_true(exists(fn_name))
  dlls <- keep(getLoadedDLLs(), ~ .x[["path"]] == dll_path)
  testthat::expect_length(dlls, 1L)

  testthat::expect_equal(handle(), 42L)

  testthat::expect_false(exists(fn_name))
  dlls <- keep(getLoadedDLLs(), ~ .x[["path"]] == dll_path)
  testthat::expect_length(dlls, 0L)
})


# Test that wrapper function names are unique even for identical Rust source
#
# Use the same string to compile two Rust chunks.
# Compare wrapper function names and dll paths (should be unequal).
# Execute both chunks and test results (should be equal).
test_that("`rust_eval_deferred()` generates unique function names", {
  skip_if_cargo_unavailable()

  rust_code <- "42f64"

  handle_1 <- rust_eval_deferred(rust_code)
  handle_2 <- rust_eval_deferred(rust_code)

  testthat::expect_false(
    attr(handle_1, "function_name") == attr(handle_2, "function_name")
  )

  testthat::expect_false(
    attr(handle_1, "dll_path") == attr(handle_2, "dll_path")
  )

  testthat::expect_equal(handle_1(), handle_2())
})

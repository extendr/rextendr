test_that("`rust_eval()` works", {
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
# Collect all deferred handles first, and then execute them in
# the the order of compilation.
# Returned integer values should be identical to the input sequence.
test_that("multiple `rust_eval_deferred()` work correctly", {
  provided_values <- seq_len(5)
  deferred_handles <- purrr::map(
    provided_values,
    ~rust_eval_deferred(glue::glue("{.x}i32"))
  )

  obtained_values <- purrr::map_int(deferred_handles, ~(.x)())

  testthat::expect_equal(
    obtained_values,
    provided_values
  )
})


# Test if multiple Rust chunks can be compiled and then executed
# in the reverse order. This ensures that the order of compilation and
# execution does not matter.
#
# Generate `n` integers (1..n) and then compile Rust chunks that
# return `n` as `i32`.
# Collect all deferred handles first, and then execute them in
# the the reverse order.
# Returned integer values should be identical to the reversed input sequence.
test_that("multiple `rust_eval_deferred()` work correctly in reverse order", {
  provided_values <- seq_len(5)

  deferred_handles <- purrr::map(
    provided_values,
     ~rust_eval_deferred(glue::glue("{.x}i32"))
  )

  deferred_handles <- rev(deferred_handles)

  obtained_values <- purrr::map_int(deferred_handles, ~(.x)())

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
  handle <- rust_eval_deferred("5i32 + 6i32")

  testthat::expect_equal(handle(), 5L + 6L)
  testthat::expect_error(
    handle(),
    "The Rust code fragment is no longer available for execution."
  )

})
# implementation of actual tests will require updated extendr-api, extendr-macros, libR-sys
# on crates.io.

test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})

test_that("rextendr::clean() removes cargo target directory & binaries", {
  skip_if_not_installed("usethis")
  skip_if_not_installed("devtools")
  skip_on_cran()
  skip_if_cargo_unavailable()
  skip_on_R42_win()

  path <- local_package("testpkg")
  use_extendr()
  document()

  expect_equal(length(dir("src", pattern = "testpkg\\..*")), 1)
  expect_true(dir.exists(file.path("src", "rust", "target")))

  # clean once
  clean()

  # we expect an error the second time
  expect_error(clean())

  expect_error(clean(1L))
  expect_error(clean(echo = NULL))
  expect_equal(length(dir("src", pattern = "testpkg\\..*")), 0)
  expect_false(dir.exists(file.path("src", "rust", "target")))
})

test_that("`use_extendr()` works correctly when path is specified explicitly", {
  skip_if_not_installed("usethis")
  local_temp_dir("temp_dir")
  usethis::create_package("testpkg")

  use_extendr(path = "testpkg")
  succeed()
})

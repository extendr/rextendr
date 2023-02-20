# Test if `pretty_rel_path` determines relative paths correctly.
# Edge cases include initiating the search from a directory outside of
# package directory (an ancestor/parent in the hierarchy), and
# from a non-existent/invalid directory (such as `NA` or `""`),
# in which case `pretty_rel_path` should return absolute path of itr
# first argument.
test_that("`pretty_rel_path()` works", {
  pkg_root <- local_package("testpkg")
  use_extendr()

  # Find relative path from package root, trivial case
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      pkg_root
    ),
    "R/extendr-wrappers.R"
  )

  # Find relative path starting from a subdirectory of package
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      file.path(pkg_root, "src", "rust", "src", "lib.rs")
    ),
    "R/extendr-wrappers.R"
  )

  # Find relative path starting outside of package directory.
  # This should return the absolute path of the file (not relative).
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      file.path(pkg_root, "..")
    ),
    normalizePath(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      winslash = "/"
    )
  )

  # Find relative path providing no input for the package directory.
  # This should return the absolute path of the file (not relative).
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      ""
    ),
    normalizePath(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      winslash = "/"
    )
  )

  # Same as the one above, but providing NA_character_
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      NA_character_
    ),
    normalizePath(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      winslash = "/"
    )
  )

  # Same as the one above, but providing empty character vector
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      character(0)
    ),
    normalizePath(
      file.path(pkg_root, "R", "extendr-wrappers.R"),
      winslash = "/"
    )
  )

  # Test path to non-existent file
  expect_equal(
    pretty_rel_path(
      file.path(pkg_root, "A", "B", "C", "D.F"),
      pkg_root
    ),
    "A/B/C/D.F"
  )
})

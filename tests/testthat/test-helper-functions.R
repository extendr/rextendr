
# Test if `pretty_rel_path` determines relative paths correctly.
# Edge cases include initiating the search from a directory outside of
# package directory (an ancestor/parent in the hierarchy), and
# from a non-exstenst/invalid directory (such as `NA` or `""`),
# in which case `pretty_rel_path` should return absolute path of itr
# first argument.
test_that("`pretty_rel_path()` works", {
  tempdir <- tempdir()
  pkg_root <- file.path(tempdir, "testpkg")
  dir.create(pkg_root, recursive = TRUE)
  pkg_root <- normalizePath(pkg_root, winslash = "/")
  sink(nullfile())
  tryCatch(
    devtools::create(pkg_root),
    finally = sink()
  )
  rextendr::use_extendr(pkg_root, quiet = TRUE)

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


# Verifies that `rextendr::get_file_info()` returns the same as base R
# `file.info()` for files and directories.
test_that("`get_file_info()` and `file.info()` outputs are equivalent", {
  n_test_files <- 3L
  n_test_dirs <- 2L
  # Creates 10 temp files in 10 *different* temp directories,
  # each file prefixed with its index (1 to 10)
  temp_files <- purrr::map_chr(
    seq_len(n_test_files),
    ~ tempfile(pattern = as.character(.x))
  )

  # Creates 2 temporary directories
  temp_dirs <- purrr::map_chr(
    seq_len(n_test_dirs),
    ~ tempdir()
  )

  # Test both files & directories
  temp_paths <- c(temp_files, temp_dirs)

  # Gets file info using base R. This returns a `data.frame`,
  # where rownames contain (absolute) paths.
  base_info <- file.info(temp_paths, extra_cols = FALSE)

  # Gets file info using rextendr function. This returns a `tibble`,
  # similar to base R, but file paths are now recorded in column `path`.
  rextendr_info <- get_file_info(temp_paths)

  expect_equal(rownames(base_info), rextendr_info[["path"]])
  expect_equal(base_info[["size"]], rextendr_info[["size"]])
  expect_equal(base_info[["isdir"]], rextendr_info[["isdir"]])
  expect_equal(base_info[["mode"]], rextendr_info[["mode"]])
  expect_equal(base_info[["mtime"]], rextendr_info[["mtime"]])
  expect_equal(base_info[["ctime"]], rextendr_info[["ctime"]])
  expect_equal(base_info[["atime"]], rextendr_info[["atime"]])

  # A file that does not exist has `NA` in all columns.
  na_info <- get_file_info("non_existent.file")

  expect_equal(na_info[["path"]], "non_existent.file")
  expect_true(is.na(na_info[["size"]]))
  expect_true(is.na(na_info[["isdir"]]))
  expect_true(is.na(na_info[["mode"]]))
  expect_true(is.na(na_info[["mtime"]]))
  expect_true(is.na(na_info[["ctime"]]))
  expect_true(is.na(na_info[["atime"]]))
})


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
  # Creates 3 temp files in 3 *different* temp directories,
  # each file prefixed with its index (1 to 3)
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

test_that("find_newer_files_than() works", {
  old_file <- tempfile()
  new_file1 <- tempfile()
  new_file2 <- tempfile()
  brio::write_file("", old_file)
  Sys.sleep(0.01)
  brio::write_file("", new_file1)
  brio::write_file("", new_file2)

  # files are older than reference
  expect_equal(find_newer_files_than(old_file, new_file1), character(0))
  # files are newer than reference
  expect_equal(find_newer_files_than(new_file1, old_file), new_file1)
  # multiple files
  expect_equal(find_newer_files_than(c(new_file1, new_file2), old_file), c(new_file1, new_file2))
  # no files
  expect_equal(find_newer_files_than(character(0), old_file), character(0))
  expect_equal(find_newer_files_than(NA_character_, old_file), character(0))
  # invalid cases
  expect_error(find_newer_files_than(old_file, character(0)))
  expect_error(find_newer_files_than(old_file, "/no/such/files"))
})

# Verifies that `ui_*` assemble correct ansi strings.
# Each output of the `ui_*` is compared to the output
# of {cli}.
test_that("`ui_*` generate correct ansi strings", {
  # `*_rxr` is generated by {rextendr}.
  # `*_cli` is generated by {cli}.
  # Simplified version of the generated message:
  # x This is an error in `package::function()`.
  msg_danger <- "This is an error in {.fun package::function}."
  danger_rxr <- ui_x(msg_danger)
  danger_cli <- cli::cli_format_method(
    cli::cli_alert_danger(msg_danger)
  )

  # i Index out of bounds at `1`, `2`, `3`, `4`, and `5`,
  msg_info <- "Index out of bounds at {.val {1:5}}."
  info_rxr <- ui_i(msg_info)
  info_cli <- cli::cli_format_method(
    cli::cli_alert_info(
      msg_info
    )
  )

  # ! File path/to/file.ext already exists.
  msg_warning <- "File {.file path/to/file.ext} already exists."
  warning_rxr <- ui_w(msg_warning)
  warning_cli <- cli::cli_format_method(
    cli::cli_alert_warning(msg_warning)
  )

  # v Successfully updated pkg! Press [Y] to continue.
  msg_success <- "Successfully udpated {.pkg {.emph a.package}}! Press {.key Y} to continue."
  success_rxr <- ui_v(msg_success)
  success_cli <- cli::cli_format_method(
    cli::cli_alert_success(msg_success)
  )

  # ? Are you sure file DESCRIPTION exists?
  msg_question <- "Are you sure file {.path DESCRIPTION} exists?"
  question_rxr <- ui_q(msg_question)
  question_cli <- cli::cli_format_method(
    cli::cli_alert(
      cli::cli_format_method(
        cli::cli_text(cli::col_yellow("?"), " ", msg_question)
      )
    )
  )

  expect_equal(danger_rxr, danger_cli)
  expect_equal(info_rxr, info_cli)
  expect_equal(warning_rxr, warning_cli)
  expect_equal(success_rxr, success_cli)
  expect_equal(question_rxr, question_cli)
})

# Checks if a complex multiline error message is
# correctly formatted with `ui_throw()` and other
# `ui_*` funtions.
test_that("`ui_throw()` formats error messages", {
  # Gathers multiple (ansi-styled) output lines
  # used as a template for comparison.
  expected <- c(
    "Something bad has happened!",
    cli::cli_format_method(
      cli::cli_alert_danger(
        "This bad thing happened."
      )
    ),
    cli::cli_format_method(
      cli::cli_alert_danger(
        "That bad thing happened."
      )
    ),
    cli::cli_format_method(
      cli::cli_alert_warning(
        "{.file File} does not exist."
      )
    ),
    cli::cli_format_method(
      cli::cli_alert_info(
        "Ensure {.val {21 + 21}} == {.val {21 * 2}}."
      )
    )
  )

  expected <- paste(expected, collapse = "\n")

  expect_error(
    # Expresion we test
    object = ui_throw(
      "Something bad has happened!",
      c(
        ui_x("This bad thing happened."),
        ui_x("That bad thing happened."),
        ui_w("{.file File} does not exist."),
        ui_i("Ensure {.val {21 + 21}} == {.val {21 * 2}}.")
      )
    ),
    # (Sub)string equal to the desired output
    regexp = expected,
    # Compare as plain text, do not treat `regexp` as pattern
    fixed = TRUE
  )
})
# Ensures that `write_file()` wrapper around `brio::write_lines()`
# writes file correctly and produces a meaningful message displayed to user.
test_that("`write_file()` does the same as `brio::write_lines()`", {
  # The initial text fragment is split into several lines.
  text <- stringi::stri_split_lines1(
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et
    dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea 
    commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat 
    nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit 
    anim id est laborum."
  )

  # Creating two temp files for {rextendr} and {brio}.
  temp_file_rxr <- tempfile(pattern = "rxr_")
  temp_file_brio <- tempfile(pattern = "brio_")

  # Explicitly removing temporary files
  on.exit(
    {
      unlink(temp_file_rxr)
      unlink(temp_file_brio)
    },
    add = TRUE
  )

  # Writing using {brio} and {rextendr}
  brio::write_lines(text, temp_file_brio)
  # `write_file()` produces a {cli} message, so it is captured here
  ui_message <- cli::cli_format_method(write_file(text, temp_file_rxr))

  # Verifies file content
  expect_equal(readLines(temp_file_rxr), readLines(temp_file_brio))
  # Obtaines 'relative path' that is displayed to the user.
  rel_path <- pretty_rel_path(temp_file_rxr, ".")
  # Verifies displayed message
  expect_equal(
    ui_message,
    cli::cli_format_method(
      cli::cli_alert_success("Writing file {.file {rel_path}}.")
    )
  )
})

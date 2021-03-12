# Converts any path to path, relative to the package root
# E.g., outer_root/some_folder/code/packages/my_package/src/rust/src/lib.rs
# becomes src/rust/src/lib.rs.
# Used for pretty printing.
pretty_rel_path <- function(path, search_from = ".") {
  fs::path_rel(path, start = rprojroot::find_package_root_file(path = search_from))
}

get_library_path <- function(path = ".") {
  # Constructs path to the library file (e.g., package_name.dll)
  pkg <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- pkg$get("Package")
  fs::path(
    glue::glue(
      "src",
      "{pkg_name}{.Platform$dynlib.ext}",
      .sep = .Platform$file.sep
    )
  )
}

get_rust_files <- function(path = ".") {
  # Enumerates all Rust files, changes to which should trigger re-compilation.

  src_root <- rprojroot::find_package_root_file("src", path = path)
  if (!fs::dir_exists(src_root)) {
    # No source code found
    cli::cli_alert_warning("{.file src} directory is missing. Are you sure the package is set up to use Rust?")
    return(fs::path())
  }

  # Recursively enumerating files wihtin pkg_root/src

  # This handles Cargo.toml files,
  cargo_toml_paths <- fs::dir_ls(
    path = src_root,
    recurse = TRUE,
    glob = "*Cargo.toml"
  )

  # This handles *rs files
  rust_src_paths <- fs::dir_ls(
    path = src_root,
    recurse = TRUE,
    glob = "*.rs"
  )

  result <- fs::fs_path(c(cargo_toml_paths, rust_src_paths))
  result
}

needs_compilation <- function(path = ".") {
  library_path <- get_library_path(path)

  # This will likely never happen.
  # Shortcut: missing library file requires compilation in any case.
  if (!fs::file_exists(library_path)) {
    library_path_rel <- pretty_rel_path(library_path, path)
    cli::cli_alert_info("No library found at {.file {library_path_rel}}, recompilation is required.")
    return(TRUE)
  }

  rust_files <- get_rust_files(path)

  # Shortcut: no rust sources found, nothing to track.
  if (length(rust_files) == 0L) {
    return(FALSE)
  }

  # Obtains detailed info of each source file and library file.
  # This includes 'last modification time'.
  # Stored as tibbles
  rust_info <- fs::file_info(rust_files)
  library_info <- fs::file_info(library_path)

  # Leaves files, which were modified *after* the library
  modified_files_info <- dplyr::filter(
    rust_info,
    .data$modification_time > library_info[["modification_time"]][1]
  )

  # Shortcut: no files have been modified since last compilation.
  if (nrow(modified_files_info) == 0L) {
    return(FALSE)
  }

  # Takes relative to the project root paths of all modified files and walks it,
  # informing user of each modification.
  # This perhaps should have an `isFALSE(quiet)` check, but right now rextendr rocelts
  # do not support `quiet` arg.
  purrr::walk(
    pretty_rel_path(modified_files_info[["path"]], search_from = path),
    ~ cli::cli_alert_info("File {.file {.x}} has been modified since last compilation.")
  )

  TRUE
}

touch_makevars <- function(path = ".") {
  # Build system does not track modfications to source files other than
  # C/C++/Fortran and Makevars.
  # If Makevars is 'touched', next time recompilation will be triggered
  # (mtime of Makevars will be > mtime of the library file).

  src_root <- rprojroot::find_package_root_file("src", path = path)
  makevars_path <- fs::path(src_root, "Makevars")
  makevars_win_path <- fs::path(src_root, "Makevars.win")

  has_been_touched <- FALSE

  # 'Touching' only if files exist.
  # Otherwise, this may create an empty file and ruin setup.
  if (fs::file_exists(makevars_path)) {
    fs::file_touch(makevars_path)
    has_been_touched <- TRUE
  }

  if (fs::file_exists(makevars_win_path)) {
    fs::file_touch(makevars_win_path)
    has_been_touched <- TRUE
  }

  # If there are no Makevars(.win), alert user that Rust changes have been detected,
  # but build system cannot be notified.
  # This is also a sing of a serious misconfiguration of the project.
  if (isFALSE(has_been_touched)) {
    cli::cli_alert_danger(
      c(
        "No {.file src/Makevars} or {.file src/Makevars.win} files have been found. ",
        "Modifications to Rust source code will not trigger recompilation!"
      )
    )
  }

  invisible(NULL)
}

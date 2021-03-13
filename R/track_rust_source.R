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
      rprojroot::find_package_root_file("src", path = path),
      "{pkg_name}{.Platform$dynlib.ext}",
      .sep = .Platform$file.sep
    )
  )
}

#' Obtains paths to the Rust source files.
#'
#' Enumerates all Rust files, changes to which should trigger re-compilation.
#' This inclides `*.rs` and `Cargo.toml`.
#' @param path Path from which package root is looked up.
#' @returns A vector of file paths (can be empty).
#' @keywords internal
get_rust_files <- function(path = ".") {

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

#' Checks if re-compilation is needed.
#'
#' Tracks changes in Rust source files (`*.rs`) and `Cargo.toml`.
#' @param path Path from which package root is looked up.
#' @param quiet Logical scalar indicating wether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @returns Logical `TRUE` if Rust source has been modified, `FALSE` otherwise.
#' @keywords internal
needs_compilation <- function(path = ".", quiet = FALSE) {
  library_path <- get_library_path(path)

  # This will likely never happen.
  # Shortcut: missing library file requires compilation in any case.
  if (!fs::file_exists(library_path)) {
    if (!isTRUE(quiet)) {
      library_path_rel <- pretty_rel_path(library_path, path)
      cli::cli_alert_warning("No library found at {.file {library_path_rel}}, recompilation is required.")
    }
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

  # Leaves files that were modified *after* the library
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
  if (!isTRUE(quiet)) {
    purrr::walk(
      pretty_rel_path(modified_files_info[["path"]], search_from = path),
      ~ cli::cli_alert_info("File {.file {.x}} has been modified since last compilation.")
    )
  }

  TRUE
}


#' Returns `default` value if `expr` throws an error.
#'
#' This allows to silently handle errors and return a pre-defined
#' default value.
#' @param expr An expression to invoke (can be anything).
#' @param default Value to return if `expr` throws an error.
#' @return Either the result of `expr` or `default`. No
#' type checks or type coersions performed.
#' @example
#' on_error_return_default(stop("This will be consumed"), "You get this instead")
#' @noRd
on_error_return_default <- function(expr, default = NULL) {
  tryCatch(
    expr,
    error = function(e) {
      default
    }
  )
}

# Converts any path to path, relative to the package root
# E.g., outer_root/some_folder/code/packages/my_package/src/rust/src/lib.rs
# becomes src/rust/src/lib.rs.
# Used for pretty printing.
# Assumes that `path` is within `package_root`.
# @param path Scalar path to format.
# @param search_from Path from which package root is looked up.
# @returns `path`, relative to the package root.
pretty_rel_path <- function(path, search_from = ".") {
  # Absolute path to the package root.
  # If package root cannot be identified,
  # an error is thrown, which gets converted into
  # `""` using `on_error_return_default`.
  package_root <-
    on_error_return_default(
      normalizePath(
        rprojroot::find_package_root_file(path = search_from),
        winslash = "/"
      ),
      default = ""
    )

  # Absolute path.
  # `path` may not exist, so `mustWork` suppresses unnecessary warnings.
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)

  # If `package_root` is empty or not a parent of `path`,
  # return `path` unchanged (for simplicity).
  if (
    !nzchar(package_root) ||
      !stringi::stri_detect_fixed(
        str = path,
        pattern = package_root,
        case_insensitive = TRUE
      )
  ) {
    return(path)
  }

  # If `path` is a subpath of `package_root`,
  # then `path` contains `package_root` as a substring.
  # This removes `package_root` substring from `path`,
  # performing comparison case_insensitively.
  path <- stringi::stri_replace_first_fixed(
    str = path,
    pattern = package_root,
    replacement = "",
    case_insensitive = TRUE
  )

  # At this point, `path` can potentailly have a leading `/`
  # Removes leading `/` if present.
  path <- stringi::stri_replace_first_regex(path, "^/", "")

  if (!nzchar(path)) {
    path <- "."
  }

  path
}

get_library_path <- function(path = ".") {
  # Constructs path to the library file (e.g., package_name.dll)
  file.path(
    rprojroot::find_package_root_file("src", path = path),
    glue::glue("{pkg_name(path)}{.Platform$dynlib.ext}")
  )
}

#' Obtains paths to the Rust source files.
#'
#' Enumerates all Rust files, changes to which should trigger re-compilation.
#' This inclides `*.rs` and `Cargo.toml`.
#' @param path Path from which package root is looked up.
#' @returns A vector of file paths (can be empty).
#' @noRd
get_rust_files <- function(path = ".") {
  src_root <- rprojroot::find_package_root_file("src", path = path)
  if (!dir.exists(src_root)) {
    # No source code found
    ui_w("{.file src} directory is missing. Are you sure the package is set up to use Rust?")
    return(character(0))
  }

  # Recursively enumerating files wihtin pkg_root/src

  # This handles Cargo.toml files,
  cargo_toml_paths <- dir(
    path = src_root,
    recursive = TRUE,
    pattern = "Cargo\\.toml$",
    full.names = TRUE
  )

  # This handles *rs files
  rust_src_paths <- dir(
    path = src_root,
    recursive = TRUE,
    pattern = "\\.rs$",
    full.names = TRUE
  )

  result <- c(cargo_toml_paths, rust_src_paths)
  result
}

#' Checks if re-compilation is needed.
#'
#' Tracks changes in Rust source files (`*.rs`) and `Cargo.toml`.
#' @param path Path from which package root is looked up.
#' @param quiet Logical scalar indicating wether the output should be quiet (`TRUE`)
#'   or verbose (`FALSE`).
#' @returns Logical `TRUE` if Rust source has been modified, `FALSE` otherwise.
#' @noRd
needs_compilation <- function(path = ".", quiet = getOption("usethis.quiet", FALSE)) {
  library_path <- get_library_path(path)

  # This will likely never happen.
  # Shortcut: missing library file requires compilation in any case.
  if (!file.exists(library_path)) {
    if (!isTRUE(quiet)) {
      library_path_rel <- pretty_rel_path(library_path, path)
      ui_w("No library found at {.file {library_path_rel}}, recompilation is required.")
    }
    return(TRUE)
  }

  # Leaves files that were modified *after* the library
  modified_files_paths <- find_newer_files_than(get_rust_files(path), library_path)

  # Shortcut: no files have been modified since last compilation.
  if (length(modified_files_paths) == 0L) {
    return(FALSE)
  }

  # Takes relative to the project root paths of all modified files and walks it,
  # informing user of each modification.
  # This perhaps should have an `isFALSE(quiet)` check, but right now rextendr rocelts
  # do not support `quiet` arg.
  if (!isTRUE(quiet)) {
    purrr::walk(
      pretty_rel_path(modified_files_paths, search_from = path),
      ~ ui_i("File {.file {.x}} has been modified since last compilation.")
    )
  }

  TRUE
}

# Equivalent to `fs::file_info`.
#
# Takes paths, retrieves info using `file.info`
# and converts obtained `data.frame` in a more suitable `tibble`
# with `path` column representing file paths (instead of row names).
#
# @param path File paths to inspect (accepts multiple value).
# @returns A `tibble::tibble()` with information about files,
# including `path` and `mtime`, which are used elsewhere in `rextendr`.
get_file_info <- function(path) {
  # We do not need extra columns, only `mtime`
  info <- file.info(path, extra_cols = FALSE)
  info <- dplyr::mutate(info, path = rownames(info), .before = dplyr::everything())
  tibble::as_tibble(info)
}

# Find files newer than the reference file.
#
# @param files File paths to find newer ones than `reference`.
# @param reference A file path to compare `files` against.
# @return File paths newer than `reference`.
find_newer_files_than <- function(files, reference) {
  # If `files` is of length 0 or NULL, exit early.
  if (length(files) == 0L) {
    return(character(0))
  }

  error_details <- character(0)

  if (length(reference) != 1L) {
    error_details <- bullet_x("Expected vector of length {.var 1}, got {.var {length(reference)}}.")
  }

  if (typeof(reference) != "character") {
    error_details <- c(error_details, bullet_x("Expected type {.var character}, got {.var {typeof(reference)}}."))
  }

  # if `reference` is already found invalid, skip checking the existence
  # Here we want path, i.e the value of `reference`.
  if (length(error_details) == 0L && !file.exists(reference)) {
    error_details <- bullet_x("File {.file {reference}} doesn't exist.")
  }

  if (length(error_details) > 0L) {
    # Here `reference` is parameter name.
    ui_throw("Invalid argument {.var reference}.", details = error_details)
  }

  reference_mtime <- get_file_info(reference)[["mtime"]]

  modified_files_info <- dplyr::filter(
    get_file_info(files),
    .data$mtime > reference_mtime
  )

  modified_files_info[["path"]]
}

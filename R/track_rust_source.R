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

#' Converts any path to path, relative to the package root
#' E.g., outer_root/some_folder/code/packages/my_package/src/rust/src/lib.rs
#' becomes src/rust/src/lib.rs.
#' Used for pretty printing.
#' Assumes that `path` is within `package_root`.
#' @param path Scalar path to format.
#' @param search_from Path from which package root is looked up.
#' @returns `path`, relative to the package root.
#' @noRd
pretty_rel_single_path <- function(path, search_from = ".") {
  stopifnot("`path` may only be one single path" = length(path) == 1)
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

#' See [pretty_rel_single_path] for implementation details
#'
#' @inheritParams pretty_rel_single_path
#'
#' @noRd
pretty_rel_path <- function(path, search_from = ".") {
  map_chr(path, pretty_rel_single_path, search_from = search_from)
}

get_library_path <- function(path = ".") {
  # Constructs path to the library file (e.g., package_name.dll)
  file.path(
    rprojroot::find_package_root_file("src", path = path),
    glue::glue("{pkg_name(path)}{.Platform$dynlib.ext}")
  )
}

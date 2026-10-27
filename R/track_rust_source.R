#' Converts any path to path, relative to the package root
#' E.g., outer_root/some_folder/code/packages/my_package/src/rust/src/lib.rs
#' becomes src/rust/src/lib.rs.
#' Used for pretty printing.
#' Assumes that `path` is within `package_root`.
#' @param path Scalar path to format.
#' @param search_from Path from which package root is looked up.
#' @returns `path`, relative to the package root.
#' @noRd
pretty_rel_path <- function(path, search_from = ".") {
  stopifnot("`path` may only be one single path" = length(path) == 1)
  # Absolute path to the package root.
  # If package root cannot be identified,
  # an error is thrown, which gets converted into `""`.
  package_root <- tryCatch(
    normalizePath(
      rprojroot::find_package_root_file(path = search_from),
      winslash = "/"
    ),
    error = function(e) {
      ""
    }
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

#' Convert R `list()` into toml-compatible format.
#'
#' [to_toml()] can be used to build `Cargo.toml`.
#' The cargo manifest can be represented in terms of
#' R objects, allowing limited validation and syntax verification.
#' This function converts manifests written using R objects into
#' toml representation, applying basic formatting,
#' which is ideal for generating cargo
#' manifests at runtime.
#'
#' @param ... A list from which toml is constructed.
#'     Supports nesting and tidy evaluation.
#' @param .str_as_literal Logical indicating whether to treat
#'     strings as literal (single quotes no escapes) or
#'     basic (escaping some sequences) ones. Default is `TRUE`.
#' @param .format_int,.format_dbl Character scalar describing
#'     number formatting. Compatible with `sprintf`.
#' @return A character vector, each element corresponds to
#'     one line of the resulting output.
#' @examples
#' # Produces [workspace] with no children
#' to_toml(workspace = )
#'
#' to_toml(patch.crates_io = list(`extendr-api` = list(git = "git-ref")))
#'
#' # Single-element arrays are distinguished from scalars
#' # using explicitly set `dim`
#' to_toml(lib = list(`crate-type` = array("cdylib", 1)))
#' @export
to_toml <- function(...,
                    .str_as_literal = TRUE,
                    .format_int = "%d",
                    .format_dbl = "%g") {
  args <- dots_list(
    ...,
    .preserve_empty = TRUE,
    .ignore_empty = "none",
    .homonyms = "error",
    .check_assign = TRUE
  )
  names <- names2(args)

  # We disallow unnamed top-level atomic arguments
  invalid <- which(map_lgl(args, ~ is_atomic(.x) && !is.null(.x)))
  # If such args found, display an error message
  if (length(invalid) > 0) {
    ui_throw(
      get_toml_err_msg(),
      c(
        make_idx_msg(invalid),
        bullet_i("All top-level values should be named.")
      )
    )
  }

  tables <- map2_chr(names, args, function(nm, a) {
    header <- make_header(nm, a)
    body <- format_toml(
      a,
      .top_level = TRUE,
      .tbl_name = ifelse(is.data.frame(a), nm, character(0)),
      .str_as_literal = .str_as_literal,
      .format_int = .format_int,
      .format_dbl = .format_dbl
    )
    body <- glue_collapse(body, "\n")
    # The values can be (1) header and body, (2) header only, or (3) body only.
    # In the case of (2) and (3) the other element is of length 0, so we need to
    # remove them by `c()` first, and then concatenate by "\n" if both exists
    glue_collapse(c(header, body), "\n")
  })
  glue_collapse(tables, "\n\n")
}

make_header <- function(nm, arg) {
  # For future support of array-of-table
  # https://toml.io/en/v1.0.0-rc.3#array-of-tables
  if (nzchar(nm) && !is.data.frame(arg)) {
    as.character(glue("[{nm}]"))
  } else {
    character(0)
  }
}

make_idx_msg <- function(invalid, args_limit = 5L) {
  idx <- paste0(
    glue("`{utils::head(invalid, args_limit)}`"),
    collapse = ", "
  )
  if (length(invalid) > args_limit) {
    idx <- glue("{idx}, ... ")
  }

  bullet_x("Unnamed arguments found at position(s): {idx}.")
}
get_toml_err_msg <- function() "Object cannot be serialzied."
get_toml_missing_msg <- function() {
  "x Missing arument and `NULL` are only allowed at the top level."
}

simplify_row <- function(row) {
  result <- map_if(
    row,
    ~ is.list(.x) && all(!nzchar(names2(.x))),
    ~ .x[[1]],
    .else = ~.x
  )
  discard(
    result,
    ~ is_na(.x) || is_null(unlist(.x))
  )
}

format_toml <- function(x, ..., .top_level = FALSE) UseMethod("format_toml")

format_toml.default <- function(x, ..., .top_level = FALSE) {
  ui_throw(
    get_toml_err_msg(),
    bullet_x("`{typeof(x)}` cannot be converted to toml.")
  )
}

format_toml.data.frame <- function(x,
                                   ...,
                                   .tbl_name,
                                   .top_level = FALSE) {
  rows <- nrow(x)
  header <- glue("[[{.tbl_name}]]")
  if (rows == 0L) {
    return(as.character(header))
  }
  result <-
    map(
      seq_len(rows),
      function(idx) {
        item <- simplify_row(dplyr::slice(x, idx))
        if (length(item) == 0L) {
          result <- character(0)
        } else {
          result <- format_toml(
            item,
            ...,
            .top_level = TRUE
          )
        }
        if (!is_atomic(result)) {
          result <- flatten_chr(result)
        }

        c(header, result)
      }
    )
  flatten_chr(result)
}

# This handles missing args
# `to_toml(workspace = )` results into
# [workspace] with no children
format_toml.name <- function(x, ..., .top_level = FALSE) {
  if (isTRUE(.top_level)) {
    if (is_missing(x)) {
      return(character(0))
    } else {
      # This function errors and does not return
      format_toml.default(x, ..., .top_level = .top_level)
    }
  } else {
    if (is_missing(x)) {
      ui_throw(get_toml_err_msg(), get_toml_missing_msg())
    } else {
      # This function errors and does not return
      format_toml.default(x, ..., .top_level = .top_level)
    }
  }
}

# `NULL` is equivalent to missing arg
format_toml.NULL <- function(x, ..., .top_level = FALSE) {
  if (isTRUE(.top_level)) {
    return(character(0))
  } else {
    ui_throw(get_toml_err_msg(), get_toml_missing_msg())
  }
}

format_toml_atomic <- function(x,
                               ...,
                               .top_level = FALSE,
                               .formatter) {
  if (length(x) == 0L) {
    "[ ]"
  } else {
    formatter <- as_function(.formatter)
    items <- glue_collapse(formatter(x, ...), ", ")
    if (length(x) > 1L || !is.null(dim(x))) {
      items <- glue("[ {items} ]")
    }
    # Ensure type-stability
    as.character(items)
  }
}

# This should escape basic symbols
escape_dbl_quotes <- function(x) {
  stri_replace_all_regex(x, "([\"])", r"(\\$1)")
}

format_toml.character <- function(x,
                                  ...,
                                  .str_as_literal = TRUE,
                                  .top_level = FALSE) {
  if (isTRUE(.str_as_literal)) {
    .formatter <- ~ glue("'{.x}'")
  } else {
    .formatter <- ~ glue("\"{escape_dbl_quotes(.x)}\"")
  }
  format_toml_atomic(
    x,
    ...,
    .str_as_literal = .str_as_literal,
    .top_level = FALSE,
    .formatter = .formatter
  )
}

format_toml.integer <- function(x,
                                ...,
                                .format_int = "%d",
                                .top_level = FALSE) {
  format_toml_atomic(
    x,
    ...,
    .format_int = .format_int,
    .top_level = FALSE,
    .formatter = ~ sprintf(.format_int, .x)
  )
}

format_toml.double <- function(x,
                               ...,
                               .format_dbl = "%g",
                               .top_level = FALSE) {
  format_toml_atomic(
    x,
    ...,
    .format_dbl = .format_dbl,
    .top_level = FALSE,
    .formatter = ~ sprintf(.format_dbl, .x)
  )
}

format_toml.logical <- function(x,
                                ...,
                                .top_level = FALSE) {
  format_toml_atomic(
    x,
    ...,
    .top_level = FALSE,
    .formatter = ~ ifelse(.x, "true", "false")
  )
}

format_toml.list <- function(x, ..., .top_level = FALSE) {
  names <- names2(x)
  invalid <- which(!nzchar(names))
  if (length(invalid) > 0) {
    ui_throw(
      get_toml_err_msg(),
      c(
        make_idx_msg(invalid),
        bullet_i("List values should have names.")
      )
    )
  }
  result <- map2(names, x, function(nm, val) {
    glue("{nm} = {format_toml(val, ..., .top_level = FALSE)}")
  })

  if (!.top_level) {
    result <- glue("{{ {paste0(result, collapse = \", \")} }}")
  }
  if (!is_atomic(result)) {
    result <- flatten_chr(result)
  }
  # Ensure type-stability
  as.character(result)
}

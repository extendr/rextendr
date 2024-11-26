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
#' to_toml(workspace = NULL)
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
  invalid <- which(map2_lgl(names, args, ~ !nzchar(.x) && is.atomic(.y)))

  # If such args found, display an error message
  if (length(invalid) > 0) {
    cli::cli_abort(
      c(
        get_toml_err_msg(),
        "x" = "Unnamed arguments found at {cli::qty(length(invalid))} position{?s}: {invalid}.",
        "i" = "All top-level values should be named."
      ),
      class = "rextendr_error"
    )
  }

  tables <- map2(names, args, function(nm, a) {
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
    if (!nzchar(body)) {
      body <- NULL
    }

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

get_toml_err_msg <- function() "Object cannot be serialized."
get_toml_missing_msg <- function() {
  "Missing arument and `NULL` are only allowed at the top level."
}

simplify_row <- function(row) {
  result <- map_if(
    row,
    ~ is.list(.x) && all(!nzchar(names2(.x))),
    ~ .x[1],
    .else = ~.x
  )
  discard(
    result,
    ~ is_na(.x) || is_null(unlist(.x))
  )
}

format_toml <- function(x, ..., .top_level = FALSE) UseMethod("format_toml")

#' @export
format_toml.default <- function(x, ..., .top_level = FALSE) {
  cli::cli_abort(c(
    get_toml_err_msg(),
    "x" = "{.code {class(x)}} cannot be converted to toml."
  ), class = "rextendr_error")
}

#' @export
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
            as.list(item),
            ...,
            .top_level = TRUE
          )
        }
        if (!is_atomic(result)) {
          result <- list_c(result)
        }

        c(header, result)
      }
    )
  list_c(result)
}

# This handles missing args
# `to_toml(workspace = )` results into
# [workspace] with no children
#' @export
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
      cli::cli_abort(
        c(get_toml_err_msg(), "x" = get_toml_missing_msg()),
        class = "rextendr_error"
      )
    } else {
      # This function errors and does not return
      format_toml.default(x, ..., .top_level = .top_level)
    }
  }
}

# `NULL` is equivalent to missing arg
#' @export
format_toml.NULL <- function(x, ..., .top_level = FALSE) {
  if (isTRUE(.top_level)) {
    return(character(0))
  } else {
    cli::cli_abort(
      c(get_toml_err_msg(), "x" = get_toml_missing_msg()),
      class = "rextendr_error"
    )
  }
}

format_toml_atomic <- function(x,
                               ...,
                               .top_level = FALSE,
                               .formatter) {
  # Cache dimensions because slicing drops attributes
  dims <- dim(x)
  x <- x[!is.na(x)]
  len <- length(x)

  if (len == 0L) {
    "[ ]"
  } else {
    formatter <- rlang::as_function(.formatter)
    items <- glue_collapse(formatter(x, ...), ", ")
    if (len > 1L || !is.null(dims)) {
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

#' @export
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

#' @export
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

#' @export
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

#' @export
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

#' @export
format_toml.list <- function(x, ..., .top_level = FALSE) {
  names <- names2(x)
  invalid <- which(!nzchar(names))
  if (length(invalid) > 0) {
    cli::cli_abort(
      c(
        get_toml_err_msg(),
        "x" = "Unnamed arguments found at position{?s}: {invalid}.",
        "i" = "List values should have names."
      ),
      class = "rextendr_error"
    )
  }
  result <- map2(names, x, function(nm, val) {
    glue("{nm} = {format_toml(val, ..., .top_level = FALSE)}")
  })

  if (!.top_level) {
    result <- glue("{{ {paste0(result, collapse = \", \")} }}")
  }
  if (!is_atomic(result)) {
    result <- list_c(result)
  }
  # Ensure type-stability
  as.character(result)
}

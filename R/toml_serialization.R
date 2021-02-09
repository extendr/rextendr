#' Convert R `list()` into toml-compatible format.
#'
#' [to_toml()] can be used to build `Cargo.toml`.
#'
#' @param ... A list from which toml is constructed.
#'     Supports nesting and tidy evaluation.
#' @param .str_as_literal Logical indicating wether to treat
#'     strings as literal (single quotes no escapes) or
#'     basic (ecaping some sequences) ones. Default is `TRUE`.
#' @param .format_int,.format_dbl Character scalar describing
#'     number formatting. Compatible with `sprintf`.
#' @return A character vector, each element corresponds to
#'     one line of the resulting output.
#' @examples
#' \dontrun{
#' to_toml(workspace = )
#' # Produces [workspace] with no children
#'
#' to_toml(patch.crates_io = list(`extendr-api` = list(git = "git-ref")))
#' # [patch.crates_io]
#' # extendr-api = { git = 'git-ref' }
#' }
#' @export
to_toml <- function(
    ...,
    .str_as_literal = TRUE,
    .format_int = "%d",
    .format_dbl = "%g"
) {
    args <- dots_list(..., .preserve_empty = TRUE, .ignore_empty = "none")
    names <- names2(args)

    # We disallow unnamed top-level atomic arguments
    invalid <- which(map_lgl(args, is.atomic) & !nzchar(names))
    # If such args found, display an error message
    if (length(invalid) > 0) {
        args_limit <- 5
        idx <- paste0("`", utils::head(invalid, args_limit), "`", collapse = ", ")
        if (length(invalid) > args_limit)
        idx <- paste0(idx, ", ...")

        stop(
            paste(
                get_toml_err_msg(),
                paste0("  x Unnamed arguments found at position(s) ", idx, "."),
                "  i All top-level values should be named.",
                sep = "\n"
            ),
            call. = FALSE
        )
    }
    flatten_chr(
        map2(names, args, function(nm, a) {
            c(
                if (nzchar(nm)) paste0("[", nm, "]") else character(0),
                format_toml(
                    a,
                    .str_as_literal = .str_as_literal,
                    .format_int = .format_int,
                    .format_dbl = .format_dbl
                )
            )
        })
    )
}

get_toml_err_msg <- function() "Object cannot be serialzied."

format_toml <- function(x, ...) UseMethod("format_toml")

format_toml.default <- function(x, ...)
    stop(
        paste(
            get_toml_err_msg(),
            paste0("  x `", typeof(x), "` cannot be converted to toml."),
            sep = "\n"
        ),
        call. = FALSE)

# This handles missing args
# `to_toml(workspace = )` results into
# [workspace] with no children
format_toml.name <- function(x, ...) {
    if (is_missing(x))
        return(character(0))

     format_toml.default(x, ...)
}

format_toml_atomic <- function(x, ..., .formatter) {
    if (length(x) == 0L) {
        stop(
            paste(
                get_toml_err_msg(),
                "  x `x` has length of `0`.",
                "  i Input should be of length >= 1.",
                sep = "\n"
            ),
            call. = FALSE
        )
    } else {
        formatter <- as_function(.formatter)
        items <- paste0(formatter(x, ...), collapse = ", ")
        if (length(x) > 1L) {
            items <- paste0("[ ", items, " ]")
        }
        items
    }
}

# This should escape basic symbols
escape_dbl_quotes <- function(x) {
    stri_replace_all_regex(x, "([\"])", r"(\\$1)")
}

format_toml.character <- function(x, .str_as_literal = TRUE, ...) {
    if (isTRUE(.str_as_literal)) {
        .formatter <- ~paste0("'", .x, "'")
    }
    else {
        .formatter <- ~paste0("\"", escape_dbl_quotes(.x), "\"")
    }
    format_toml_atomic(x, ..., .formatter = .formatter)
}

format_toml.integer <- function(x, .format_int = "%d", ...) {
    format_toml_atomic(x, ..., .format_int = .format_int, .formatter = ~sprintf(.format_int, .x))
}

format_toml.double <- function(x, .format_dbl = "%g", ...) {
    format_toml_atomic(x, ..., .format_dbl = .format_dbl, .formatter = ~sprintf(.format_dbl, .x))
}

format_toml.list <- function(x, .top_level = TRUE, ...) {
    names <- names2(x)
    result <- map2(names, x, function(nm, val) {
        paste(nm, format_toml(val, .top_level = FALSE, ...), sep = " = ")
    })

    if (!.top_level) {
        result <- paste0(result, collapse = ", ")
        result <- paste0("{ ", result, " }")
    }
    if (!is.atomic(result))
        result <- flatten_chr(result)

    result
}

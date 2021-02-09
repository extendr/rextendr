to_toml <- function(
    ...,
    .str_as_literal = TRUE,
    .format_int = "%d",
    .format_dbl = "%g"
) {
    args <- dots_list(..., .preserve_empty = TRUE, .ignore_empty = "none")
    names <- names2(args)
    invalid <- which(map_lgl(args, is.atomic) & !nzchar(names))
    if (length(invalid) > 0) {
        args_limit <- 5
        idx <- paste0("`", head(invalid, args_limit), "`", collapse = ", ")
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
}

get_toml_err_msg <- function() "Object cannot be serialzied."
get_toml_size_err_msg <- function() "  x `x` has length of `0`.\n  i Input should be of length >= 1.\n"
format_toml <- function(x, ...) UseMethod("format_toml")

format_toml.default <- function(x, ...)
    stop(
        paste(
            get_toml_err_msg(),
            paste0("  x `", typeof(x), "` cannot be converted to toml."),
            sep = "\n"
        ),
        call. = FALSE)

format_toml.name <- function(x, ...) {
    if (is_missing(x))
        return(character(0))

     format_toml.default(x, ...)
}

format_toml_atomic <- function(x, ..., .formatter) {
    if (length(x) == 0L) {
        stop(
            paste(get_toml_err_msg(), get_toml_size_err_msg(), sep = "\n"),
            call. = FALSE
        )
    } else {
        formatter <- as_function(.formatter)
        items <- paste0(formatter(x, ...), collapse = ", ")
        if (length(x) > 1L) {
            items <- paste0("[ ", items, " ]")
        }
        items

        # debug
        vec_assert(items, ptype = character(), size = 1L)
    }

}

# This should escape basic symbols
escape_dbl_quotes <- function(x) {
    stringi::stri_replace_all_regex(x, "([\"])", r"(\\$1)")
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
    map2(names, x, function(nm, val) {
        paste(nm, format_toml(val, .top_level = FALSE, ...), sep = " = ")
    }) -> result

    if (!.top_level) {
        result <- paste0(result, collapse = ", ")
        result <- paste0("{ ", result, " }")
    }
    if (!is.atomic(result))
        result <- flatten_chr(result)

    # debug
    vec_assert(result, character())
    result
}



to_toml(
    workspace = ,
    ) %>% walk(cat, sep ="\n")
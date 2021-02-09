to_toml <- function(
    ...,
    .str_as_literal = TRUE,
    .format_int = "%d",
    .format_dbl = "%g"
) {
    args <- list2(...)
    map2(names2(args), args, function(nm, a) {
        vec_c(
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
        glue("{get_toml_err_msg()}\n  x `{vec_ptype_abbr(x)}` cannot be converted to toml.\n"),
        call. = FALSE)

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
    dependencies = list(`libR-sys` = "0.2.0"),
    vec_c(1L, 2L, 3),
    patch.crates_io = list(
        `extendr-api` = list(
            git = "github",
            branch = "master",
            nested = list(x = 1, y = 2)),
        `extendr-macros` = list(git = "another_ref")
    )) %>% walk(cat, sep ="\n")
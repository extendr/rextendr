to_toml <- function(...) {
    args <- list2(...) %T>% print
    map2(names2(args), args, function(nm, a) {
        vec_c(
            if (nzchar(nm)) paste0("[", nm, "]") else character(0),
            format_toml(a)
        )
    })
}

get_toml_err_msg <- function() "Object cannot be serialzied."

format_toml <- function(x, ...) UseMethod("format_toml")

format_toml.default <- function(x, ...)
    stop(
        glue("{get_toml_err_msg()}\n  x `{vec_ptype_abbr(x)}` cannot be converted to toml.\n"),
        call. = FALSE)

format_toml.character <- function(x, ...) {
    if (length(x) == 0L) {
        stop(
            glue("{get_toml_err_msg()}\n  x `x` has length of `0`.\n  i Input should be of length >= 1.\n"),
            call. = FALSE
        )
    } else {
        items <- paste0("\"", x, "\"", collapse = ", ")
        if (length(x) == 1L) {
            items <- paste0("[ ", items, " ]")
        }
        items

        # debug
        vec_assert(items, ptype = character(),  size = 1L)
    }


}

to_toml(vec_c(1L, 2L, 3L), patch.crates_io = "patch") %>% print
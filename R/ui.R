ui_x <- function(text = "") {
  glue::glue("{cli::col_red(cli::symbol$cross)} {text}")
}

ui_i <- function(text = "") {
  glue::glue("{cli::col_cyan(cli::symbol$info)} {text}")
}

ui_v <- function(text = "") {
  glue::glue("{cli::col_green(cli::symbol$tick)} {text}")
}

ui_throw <- function(message, details = character(0)) {
  if (missing(message) || !nzchar(message)) {
    message <- "Internal error."
  }

  if (length(details) != 0L) {
    details <- glue::glue_collapse(
        details,
        sep = "\n"
      )
    stop(
      glue::glue(
        message,
        details,
        .sep = "\n"
      ),
      call. = FALSE
    )
  } else {
    stop(message, call. = FALSE)
  }
}
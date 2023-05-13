#' Report on Rust infrastructure
#'
#' Prints out a detailed report on the state of Rust infrastructure on the host machine.
#' @return Nothing
rust_sitrep <- function() {
  cargo_v <- get_version("cargo")
  cargo_msg <- if (is.na(cargo_v)) {
    c("x" = "{.val cargo}: {.strong not found}")
  } else {
    c("v" = "{.val cargo}: {.emph {cargo_v}}")
  }

  rustup_v <- get_version("rustup")
  rustup_msg <- if (is.na(rustup_v)) {
    c("x" = "{.val rustup}: {.strong not found}")
  } else {
    c("v" = "{.val rustup}: {.emph {rustup_v}}")
  }

  msgs <- c(
    "Rust infrastructure sitrep:",
    rustup_msg,
    cargo_msg
  )

  if (!is.na(rustup_v)) {
    rustup_status <- rustup_toolchain_target() # nolint: object_usage
    msgs <- c(
      msgs,
      "i" = "host: {.emph {rustup_status$host}}",
      "i" = "toolchain: {.emph {rustup_status$toolchain}}",
      "i" = "target{?s}: {.emph {rustup_status$targets}}"
    )
  } else {
    msgs <- c(
      msgs,
      "x" = "Cannot determine host, toolchain, and targets without {.val rustup}"
    )
  }

  if (is.na(cargo_v)) {
    msgs <- c(
      msgs,
      "x" = "{.val cargo} is required to build {.pkg rextendr}-powered packages"
    )
  }

  if (is.na(cargo_v) || is.na(rustup_v)) {
    msgs <- c(
      msgs,
      "i" = "It is recommended to use {.val rustup} to manage {.val cargo} and {.val rustc}",
      "i" = "See {.url https://rustup.rs/} for installation instructions"
    )
  }

  cli::cli_inform(msgs)

  invisible(NULL)
}

try_exec_cmd <- function(cmd, args = character()) {
  result <- tryCatch(
    processx::run(cmd, args, error_on_status = FALSE),
    error = \(...) list(status = -1)
  )
  if (result[["status"]] != 0) {
    NA_character_
  } else {
    result$stdout
  }
}

get_version <- function(cmd) {
  output <- try_exec_cmd(cmd, "--version")
  if (is.na(output)) {
    NA_character_
  } else {
    stringi::stri_trim_both(stringi::stri_sub(output, nchar(cmd) + 1L))
  }
}

rustup_toolchain_target <- function() {
  host <- try_exec_cmd("rustup", "show") %>%
    stringi::stri_split_lines1() %>%
    stringi::stri_sub(from = 15L) %>%
    vctrs::vec_slice(1L)

  toolchain <- try_exec_cmd("rustup", c("show", "active-toolchain")) %>%
    stringi::stri_replace_last_fixed("(default)", "") %>%
    stringi::stri_trim_both()

  targets <- try_exec_cmd("rustup", c("target", "list", "--installed")) %>%
    stringi::stri_split_lines1() %>%
    stringi::stri_trim_both()

  list(host = host, toolchain = toolchain, targets = targets)
}

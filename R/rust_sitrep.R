#' Report on Rust infrastructure
#'
#' Prints out a detailed report on the state of Rust infrastructure on the host machine.
#' @export
#' @return Nothing
rust_sitrep <- function() {
  cargo_v <- get_version("cargo")
  cargo_msg <- if (is.na(cargo_v)) {
    c("x" = "{.val cargo}: {.strong not found}")
  } else {
    c("v" = "{.val cargo}: {cargo_v}")
  }

  rustup_v <- get_version("rustup")
  rustup_msg <- if (is.na(rustup_v)) {
    c("x" = "{.val rustup}: {.strong not found}")
  } else {
    c("v" = "{.val rustup}: {rustup_v}")
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
      "i" = "host: {rustup_status$host}",
      "i" = "toolchain: {rustup_status$toolchain}",
      "i" = "target{?s}: {rustup_status$targets}"
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

get_version <- function(cmd) {
  # cargo --version
  # cargo x.yy.z (ninehashs YYYY-MM-DD)
  output <- try_exec_cmd(cmd, "--version")
  if (is.na(output)) {
    NA_character_
  } else {
    stringi::stri_trim_both(stringi::stri_sub(output, nchar(cmd) + 1L))
  }
}

rustup_toolchain_target <- function() {
  # > rustup show
  # Default host: x86_64-pc-windows-msvc
  # rustup home:  some\path\.rustup
  #
  # installed targets for active toolchain
  # --------------------------------------
  #
  # i686-pc-windows-gnu
  # x86_64-pc-windows-gnu
  # x86_64-pc-windows-msvc
  #
  # active toolchain
  # ----------------
  #
  # stable-x86_64-pc-windows-msvc (default)
  host <- try_exec_cmd("rustup", "show") %>%
    stringi::stri_sub(from = 15L) %>%
    vctrs::vec_slice(1L)

  # > rustup show active-toolchain
  # stable-x86_64-pc-windows-msvc (default)
  toolchain <- try_exec_cmd("rustup", c("show", "active-toolchain")) %>%
    stringi::stri_replace_last_fixed("(default)", "") %>%
    stringi::stri_trim_both()

  # > rustup target list --installed
  # i686-pc-windows-gnu
  # x86_64-pc-windows-gnu
  # x86_64-pc-windows-msvc
  targets <- try_exec_cmd("rustup", c("target", "list", "--installed")) %>%
    stringi::stri_trim_both()

  list(host = host, toolchain = toolchain, targets = targets)
}

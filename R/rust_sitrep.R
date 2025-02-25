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
      "i" = if (length(rustup_status[["toolchains"]]) > 0) {
        "toolchain{?s}: {rustup_status$toolchains}"
      } else {
        NULL
      }
    )

    if (!is.null(rustup_status[["candidate_toolchains"]])) {
      msgs <- c(
        msgs,
        "!" = "{?This/One of these} toolchain{?s} should be default: {.strong {rustup_status$candidate_toolchains}}",
        "i" = "Run e.g. {.code rustup default {rustup_status$candidate_toolchains[1]}}"
      )
    } else if (!is.null(rustup_status[["missing_toolchain"]])) {
      msgs <- c(
        msgs,
        "!" = "Toolchain {.strong {rustup_status$missing_toolchain}} is required to be installed and set as default",
        "i" = "Run {.code rustup toolchain install {rustup_status$missing_toolchain}} to install it",
        "i" = "Run {.code rustup default  {rustup_status$missing_toolchain}} to make it default"
      )
    } else {
      msgs <- c(msgs,
        "i" = "target{?s}: {rustup_status$targets}"
      )
      if (!is.null(rustup_status[["missing_target"]])) {
        msgs <- c(
          msgs,
          "!" = "Target {.strong {rustup_status$missing_target}} is required on this host machine",
          "i" = "Run {.code rustup target add {rustup_status$missing_target}} to install it"
        )
      }
    }
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
  host <- if (get_os() == "osx" && is.na(try_exec_cmd("rustup", "show"))) {
    output <- try_exec_cmd("rustc", c("--version", "--verbose"))
    host_index <- grep("host:", output)
    gsub("host: ", "", output[host_index])
  } else {
    try_exec_cmd("rustup", "show") %>%
      stringi::stri_sub(from = 15L) %>%
      vctrs::vec_slice(1L)
  }

  # > rustup toolchain list
  # stable-x86_64-pc-windows-msvc
  # nightly-x86_64-pc-windows-msvc (default)
  toolchain_info <- try_exec_cmd("rustup", c("toolchain", "list")) %>%
    stringi::stri_trim_both() %>%
    verify_toolchains(host)

  if (is.null(toolchain_info[["missing_toolchain"]]) && is.null(toolchain_info[["candidate_toolchains"]])) {
    # > rustup target list --installed
    # i686-pc-windows-gnu
    # x86_64-pc-windows-gnu
    # x86_64-pc-windows-msvc
    targets_info <- try_exec_cmd("rustup", c("target", "list", "--installed")) %>%
      stringi::stri_trim_both() %>%
      verify_targets(host)
  } else {
    targets_info <- list()
  }

  list(host = host) %>%
    append(targets_info) %>%
    append(toolchain_info)
}

#' Verify that the required toolchain is available.
#'
#' If a toolchain with architecture matching host's is default, color it green.
#' If a default toolchain does not match host's architecture, color it red.
#' Color yellow all toolchains that match hots's architecutre and return then as \code{$candidate_toolchains}.
#' If not matching toolchain is found, determine the best candidate using host's architecture
#' and return it as \code{$missing_toolchain}.#'
#' @param toolchains A character vector of toolchains
#' @param host Host architecture identifier
#' @return A list with the following elements:
#' \itemize{
#'  \item \code{toolchains}: A character vector of toolchains, colored
#'    \itemize{
#'      \item green if matching and default,
#'      \item yellow if candidate,
#'      \item red if matching and not default,
#'    }
#'  \item \code{missing_toolchain}: An identifier of the toolchain that should be available on the system,
#'  \item \code{candidate_toolchains}: A character vector of toolchains that are candidates to be default.
#' }
#' @noRd
verify_toolchains <- function(toolchains, host) {
  if (rlang::is_empty(toolchains)) {
    return(list(toolchains = toolchains, missing_toolchain = glue("stable-{host}")))
  }

  default_toolchain_index <- stringi::stri_detect_fixed(toolchains, "(default)")
  missing_toolchain <- NULL
  candidate_toolchains <- NULL
  if (isTRUE(stringi::stri_detect_fixed(toolchains[default_toolchain_index], host))) {
    toolchains[default_toolchain_index] <- cli::col_green(toolchains[default_toolchain_index])
  } else {
    toolchains[default_toolchain_index] <- cli::col_red(toolchains[default_toolchain_index])
    candidates <- stringi::stri_detect_fixed(toolchains, host)
    if (!all(is.na(candidates)) && any(candidates)) {
      candidate_toolchains <- toolchains[candidates]
      toolchains[candidates] <- cli::col_yellow(toolchains[candidates])
    } else {
      missing_toolchain <- glue("stable-{host}")
    }
  }
  list(toolchains = toolchains, missing_toolchain = missing_toolchain, candidate_toolchains = candidate_toolchains)
}

#' Search for targets that are matching the host.
#'
#' On machines other than Windows, the target should match the host exactly.
#' On Windows, the target is GNU.
#' If a matching target is found, color it green.
#' @param targets A character vector of targets
#' @param host Host architecture identifier
#' @return A list with the following elements:
#' \itemize{
#'  \item \code{targets}: A character vector of targets with matching target colored green,
#'  \item \code{missing_target}: An identifier of the target that should be available on the system.
#' }
#' @noRd
verify_targets <- function(targets, host) {
  expected_target <- get_required_target(host)

  target_index <- stringi::stri_cmp_eq(targets, expected_target)
  targets[target_index] <- cli::col_green(targets[target_index])

  if (any(target_index)) {
    missing_target <- NULL
  } else {
    missing_target <- expected_target
  }

  list(targets = targets, missing_target = missing_target)
}

#' Return the expected target identifier given host identifier.
#' @param host Host architecture identifier
#' @return Required target identifier
#' @noRd
get_required_target <- function(host) {
  if (.Platform[["OS.type"]] == "windows") {
    stringi::stri_replace_first_regex(host, pattern = "-[a-z]+$", replacement = "-gnu")
  } else {
    host
  }
}

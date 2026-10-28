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
    host <- try_exec_cmd("rustup", "show") |>
      stringi::stri_sub(from = 15L) |>
      vctrs::vec_slice(1L)

    # > rustup toolchain list
    # stable-x86_64-pc-windows-msvc
    # nightly-x86_64-pc-windows-msvc (default)
    toolchains <- try_exec_cmd("rustup", c("toolchain", "list")) |>
      stringi::stri_trim_both()

    # If a toolchain with architecture matching host's is default, color it green.
    # If a default toolchain does not match host's architecture, color it red.
    # Color yellow all toolchains that match host's architecture, these are
    # candidates to be default.
    # If no matching toolchain is found, the stable toolchain for host's
    # architecture is missing.
    missing_toolchain <- NULL
    candidate_toolchains <- NULL

    if (rlang::is_empty(toolchains)) {
      missing_toolchain <- glue("stable-{host}")
    } else {
      default_toolchain_index <- stringi::stri_detect_fixed(
        toolchains,
        "default"
      )
      if (
        isTRUE(stringi::stri_detect_fixed(
          toolchains[default_toolchain_index],
          host
        ))
      ) {
        toolchains[default_toolchain_index] <- cli::col_green(toolchains[
          default_toolchain_index
        ])
      } else {
        toolchains[default_toolchain_index] <- cli::col_red(toolchains[
          default_toolchain_index
        ])
        candidates <- stringi::stri_detect_fixed(toolchains, host)
        if (!all(is.na(candidates)) && any(candidates)) {
          candidate_toolchains <- toolchains[candidates]
          toolchains[candidates] <- cli::col_yellow(toolchains[candidates])
        } else {
          missing_toolchain <- glue("stable-{host}")
        }
      }
    }

    msgs <- c(
      msgs,
      "i" = "host: {host}",
      "i" = if (length(toolchains) > 0) {
        "toolchain{?s}: {toolchains}"
      } else {
        NULL
      }
    )

    if (!is.null(candidate_toolchains)) {
      msgs <- c(
        msgs,
        "!" = "{?This/One of these} toolchain{?s} should be default: {.strong {candidate_toolchains}}",
        "i" = "Run e.g. {.code rustup default {candidate_toolchains[1]}}"
      )
    } else if (!is.null(missing_toolchain)) {
      msgs <- c(
        msgs,
        "!" = "Toolchain {.strong {missing_toolchain}} is required to be installed and set as default",
        "i" = "Run {.code rustup toolchain install {missing_toolchain}} to install it",
        "i" = "Run {.code rustup default  {missing_toolchain}} to make it default"
      )
    } else {
      # > rustup target list --installed
      # i686-pc-windows-gnu
      # x86_64-pc-windows-gnu
      # x86_64-pc-windows-msvc
      targets <- try_exec_cmd(
        "rustup",
        c("target", "list", "--installed")
      ) |>
        stringi::stri_trim_both()

      # On machines other than Windows, the target should match the host exactly.
      # On Windows, the target is GNU.
      if (.Platform[["OS.type"]] == "windows") {
        expected_target <- stringi::stri_replace_first_regex(
          host,
          pattern = "-[a-z]+$",
          replacement = "-gnu"
        )
      } else {
        expected_target <- host
      }

      # If a matching target is found, color it green.
      target_index <- stringi::stri_cmp_eq(targets, expected_target)
      targets[target_index] <- cli::col_green(targets[target_index])

      msgs <- c(msgs, "i" = "target{?s}: {targets}")
      if (!any(target_index)) {
        msgs <- c(
          msgs,
          "!" = "Target {.strong {expected_target}} is required on this host machine",
          "i" = "Run {.code rustup target add {expected_target}} to install it"
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

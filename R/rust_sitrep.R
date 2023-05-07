rust_sitrep <- function() {
  # Windows-specific code


  cargo_v <- get_version("cargo")
  cargo_msg <- if(is.na(cargo_v)) {
    c("x" = "{.val cargo}: {.strong not found}")
  } else {
    c("v" = "{.val cargo}: {.emph {cargo_v}}")
  }

  rustup_v <- get_version("rustup")
  rustup_msg <- if(is.na(rustup_v)) {
    c("x" = "{.val rustup}: {.strong not found}")
  } else {
    c("v" = "{.val rustup}: {.emph {rustup_v}}")
  }

  if(!is.na(rustup_v)) {
    rustup_status <- rustup_toolchain_target()
    additions <- c(
      "i" = "{.val host}: {.emph {rustup_status$host}}",
      "i" = "{.val toolchain}: {.emph {rustup_status$toolchain}}",
      "i" = "{.val targets}: {.emph {rustup_status$targets}}"
    )
  } else {
    additions <- c(
      "x" = "Cannot determine host, toolchain, and targets without {.val rustup}",
      "i" = "It is recommended to install {.val rustup} to manage {.val cargo} and {.val rustc}",
      "i" = "See {.link https://rustup.rs} for more information"
    )
  }

  msgs <- c(
    cargo_msg,
    rustup_msg,
    additions
  )


  cli::cli_inform(msgs)

}

try_exec_cmd <- function(cmd, args = character()) {
  result <- tryCatch(
    processx::run(cmd, args, error_on_status = FALSE),
    error = \(e) list(status = -1)
  )
  if(result[["status"]] != 0) {
    NA_character_
  } else {
    result$stdout
  }
}

get_version <- function(cmd) {
  output <- try_exec_cmd(cmd, "--version")
    if(is.na(output)) {
      NA_character_
    } else {
        stringi::stri_trim_both(stringi::stri_sub(output, nchar(cmd) + 1L))
    }
}

get_cli_notification <- function(cmd, version) {
  if(is.na(version))
  {
    c("x" = glue::glue("{{.val {cmd}}}: {{.strong not found}}"))
  } else {
    c("v" = glue::glue("{{.val {cmd}}}: {{.emph {version}}}"))
  }
}

rustup_toolchain_target <- function(){
  host <- try_exec_cmd("rustup", "show") %>%
    stringi::stri_split_lines1() %>%
    stringi::stri_sub(from = 15L) %>%
    vctrs::vec_slice(1L)

  toolchain <- try_exec_cmd("rustup", c("show", "active-toolchain")) %>%
    stringi::stri_replace_last_fixed("(default)", "") %>%
    stringi::stri_trim_both()

  targets <- try_exec_cmd("rustup", c("target", "list",  "--installed")) %>%
    stringi::stri_split_lines1() %>%
    stringi::stri_trim_both()

  list(host = host, toolchain = toolchain, targets = targets)
}

rust_sitrep()
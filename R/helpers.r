tty_has_colors <- function() isTRUE(cli::num_ansi_colors() > 1L)

get_cargo_envvars <- function() {
  if (identical(.Platform$OS.type, "windows")) {
    # On Windows, PATH to Rust toolchain should be set by the installer.
    # If R >= 4.2, we need to override the linker setting.
    if (identical(R.version$crt, "ucrt")) {
      # libgcc_mock is created in configure.ucrt on installation.
      libgcc_path <- system.file("libgcc_mock", package = "rextendr")
      if (identical(libgcc_path, "")) {
        ui_throw(
          "Unable to find {.file inst/libgcc_mock}. Please reinstall the rextendr package",
        )
      }

      cargo_envvars <- c("current",
        CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = "x86_64-w64-mingw32.static.posix-gcc.exe",
        LIBRARY_PATH = paste0(libgcc_path, ";", Sys.getenv("LIBRARY_PATH"))
      )
    } else {
      cargo_envvars <- NULL
    }
  } else {
    # In some environments, ~/.cargo/bin might not be included in PATH, so we need
    # to set it here to ensure cargo can be invoked. It's added to the tail as a
    # fallback, which is used only when cargo is not found in the user's PATH.
    path_envvar <- Sys.getenv("PATH", unset = "")
    cargo_path <- path.expand("~/.cargo/bin")
    # "current" means appending or overwriting the envvars in addition to the current ones.
    cargo_envvars <- c("current", PATH = glue("{path_envvar}:{cargo_path}"))
  }
  cargo_envvars
}

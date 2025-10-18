get_r_version <- function() {
  R.version
}

is_windows_arm <- function() {
  proc_arch <- Sys.getenv("PROCESSOR_ARCHITECTURE")
  r_arch <- get_r_version()[["arch"]]

  if (identical(proc_arch, "ARM64") && !identical(r_arch, "aarch64")) {
    cli::cli_abort(
      c(
        "Architecture mismatch detected.",
        "i" = "You are running the {.code {proc_arch}} version of Windows, but the {.code {r_arch}} version of R.",
        "i" = "You can find ARM64 build of R at {.url https://www.r-project.org/nosvn/winutf8/aarch64}"
      ),
      class = "rextendr_error"
    )
  }

  identical(proc_arch, "ARM64") && identical(r_arch, "aarch64")
}

throw_if_no_rtools <- function() {
  if (!suppressMessages(pkgbuild::has_rtools())) {
    cli::cli_abort(
      c(
        "Unable to find Rtools that are needed for compilation.",
        "i" = "Required version is {.emph {pkgbuild::rtools_needed()}}."
      ),
      class = "rextendr_error"
    )
  }
}

throw_if_not_ucrt <- function() {
  if (!identical(get_r_version()[["ucrt"]], "ucrt")) {
    cli::cli_abort(
      c(
        "R must be built with UCRT to use rextendr.",
        "i" = "Please install the UCRT version of R from {.url https://cran.r-project.org/}."
      ),
      class = "rextendr_error"
    )
  }
}

get_rtools_version <- function() {
  minor_patch <- package_version(get_r_version()[["minor"]])

  if (minor_patch >= "5.0") {
    "45"
  } else if (minor_patch >= "4.0") {
    "44"
  } else if (minor_patch >= "3.0") {
    "43"
  } else {
    "42"
  }
}

get_path_to_cargo_folder_arm <- function(rtools_root) {
  path_to_cargo_folder <- file.path(rtools_root, "clangarm64", "bin")
  path_to_cargo <- file.path(path_to_cargo_folder, "cargo.exe")
  if (!file.exists(path_to_cargo)) {
    cli::cli_abort(
      c(
        "{.code rextendr} on ARM Windows requires an ARM-compatible Rust toolchain.",
        "i" = "Check this instructions to set up {.code cargo} using ARM version of RTools: {.url https://github.com/r-rust/faq?tab=readme-ov-file#does-rust-support-windows-on-arm64-aarch64}." # nolint: line_length_linter
      ),
      class = "rextendr_error"
    )
  }

  normalizePath(path_to_cargo_folder, mustWork = TRUE)
}

get_rtools_home <- function(rtools_version, is_arm) {
  env_var <- if (is_arm) {
    sprintf("RTOOLS%s_AARCH64_HOME", rtools_version)
  } else {
    sprintf("RTOOLS%s_HOME", rtools_version)
  }

  default_path <- if (is_arm) {
    sprintf("C:\\rtools%s-aarch64", rtools_version)
  } else {
    sprintf("C:\\rtools%s", rtools_version)
  }

  normalizePath(
    Sys.getenv(env_var, default_path),
    mustWork = TRUE
  )
}

get_rtools_bin_path <- function(rtools_home, is_arm) {
  # c.f. https://github.com/wch/r-source/blob/f09d3d7fa4af446ad59a375d914a0daf3ffc4372/src/library/profile/Rprofile.windows#L70-L71 # nolint: line_length_linter
  subdir <- if (is_arm) {
    c("aarch64-w64-mingw32.static.posix", "usr", "bin")
  } else {
    c("x86_64-w64-mingw32.static.posix", "usr", "bin")
  }

  normalizePath(file.path(rtools_home, subdir), mustWork = TRUE)
}

use_rtools <- function(.local_envir = parent.frame()) {
  throw_if_no_rtools()
  throw_if_not_ucrt()

  is_arm <- is_windows_arm()
  rtools_version <- get_rtools_version()
  rtools_home <- get_rtools_home(rtools_version, is_arm)
  rtools_bin_path <- get_rtools_bin_path(rtools_home, is_arm)

  withr::local_path(rtools_bin_path, action = "suffix", .local_envir = .local_envir)

  if (is_arm) {
    cargo_path <- get_path_to_cargo_folder_arm(rtools_home)
    withr::local_path(cargo_path, .local_envir = .local_envir)
  }

  invisible()
}

clean <- function(path = ".", profile = c("release", "dev")) {
  profile <- match.arg(profile)
  root <- rprojroot::find_package_root_file(path = path)

  rust_folder <- normalizePath(
    file.path(root, "src", "rust"),
    winslash = "/",
    mustWork = FALSE
  )

  toml_path <- normalizePath(
    file.path(rust_folder, "Cargo.toml"),
    winslash = "/",
    mustWork = FALSE
  )

  # Note: This should be adjusted if `TARGET_DIR` changes in `Makevars`
  target_dir <- normalizePath(
    file.path(rust_folder, "target"),
    winslash = "/",
    mustWork = FALSE
  )

  if (!file.exists(toml_path)) {
    ui_throw(
      "Unable to clean binaries.",
      c(
        bullet_w(
          "{.file Cargo.toml} not found in {.path {rust_folder}}."
        )
      )
    )
  }

  env <- rlang::current_env()
  cargo_envvars <- get_cargo_envvars()

  exec_result <- processx::run(
    command = "cargo",
    args = c(
      "clean",
      glue("--manifest-path={toml_path}"),
      glue("--target-dir={target_dir}"),
      if (profile == "release") "--release" else NULL,
      if (tty_has_colors()) {
        "--color=always"
      } else {
        "--color=never"
      },
      "--quiet"
    ),
    echo_cmd = FALSE,
    windows_verbatim_args = FALSE,
    stderr = "|",
    stdout = "|",
    error_on_status = FALSE,
    env = cargo_envvars
  )

  if (!isTRUE(exec_result$status == 0)) {
    if (!tty_has_colors()) {
      err_msg <- cli::ansi_strip(exec_result$stderr)
    } else {
      err_msg <- exec_result$stderr
    }
    ui_throw(
      "Unable to execute {.code cargo clean}.",
      bullet_x(paste(err_msg, collapse = "\n")),
      call = caller_env(),
      glue_open = "{<{",
      glue_close = "}>}"
    )
  }
  pkgbuild::clean_dll(path = root)
}
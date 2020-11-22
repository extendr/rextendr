#' Install libR bindings for Rust
#'
#' Install libR bindings for Rust.
#' @param force Logical indicating whether install should be forced
#'   even if bindings have already been installed previously.
#' @param quiet Logical indicating whether compile output should be generated or not.
#' @export
install_libR_bindings <- function(force = FALSE, quiet = FALSE) {
  package_dir <- find.package("rextendr")
  if (file.access(package_dir, 2) != 0L) {
    stop(
      "Cannot write to package location: ", package_dir,
      call. = FALSE
    )
  }

  bindings_file <- file.path(package_dir, "rust", "libR-sys", "src", "bindings.rs")
  if (isTRUE(file.exists(bindings_file))) {
    message("libR bindings are already installed. Rerun with `force = TRUE` to force re-install.")
    return(invisible())
  }

  # set up dummy build
  dir <- tempfile()
  dir.create(dir)
  dir.create(file.path(dir, "src"))
  cargo.toml <- c(
    '[package]\nname = "build-libR-sys"\nversion = "0.0.1"\nedition = "2018"',
    '[dependencies]\nlibR-sys = {path = "/Users/clauswilke/github/libR-sys"}'
  )
  brio::write_lines(cargo.toml, file.path(dir, "Cargo.toml"))
  lib.rs <- c(
    '#![allow(non_snake_case)]',
    'pub const DUMMY: u32 = 0;'
  )
  brio::write_lines(lib.rs, file.path(dir, "src", "lib.rs"))

  if (!isTRUE(quiet)) {
    cat(sprintf("build directory: %s\n", dir))
    stdout <- "" # to be used by `system2()` below
  } else {
    stdout <- NULL
  }

  system2(
    command = "cargo",
    args = c(
      "build",
      sprintf("--manifest-path=%s", file.path(dir, "Cargo.toml"))
    ),
    stdout = stdout,
    stderr = stdout,
    env = c(
      glue::glue(
        "LIBRSYS_BINDINGS_DIR={path}",
        path = file.path(package_dir, "rust", "libR-sys", "src")
      )
    )
  )
}

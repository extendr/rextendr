## This has been disabled. It needs to be deleted or reworked for libR-sys 0.2.0,
## which includes support for pre-computed bindings.

# Install libR bindings for Rust
#
# Call [install_libR_bindings()] once after installing rextendr to locally prebuild and install
# libR bindings for Rust. This is not required for any other parts of the package to function
# properly, but it will speed up subsequent calls to [rust_source()] as the bindings don't have
# to be regenerated over and over.
# @param version libR-sys version, provided as a Rust version string. `"*"` will install the
#   latest available version on crates.io.
# @param force Logical indicating whether install should be forced
#   even if bindings have already been installed previously.
# @param quiet Logical indicating whether compile output should be generated or not.
# @param patch.crates_io Character vector of patch statements for crates.io to
#   be added to the `Cargo.toml` file.
# @return Integer error code as returned by [system2()]. A value of `0L` indicates success.
# @export
install_libR_bindings <- function(version = "*", force = FALSE, quiet = FALSE, patch.crates_io = NULL) {
  package_dir <- find.package("rextendr")
  if (file.access(package_dir, 2) != 0L) {
    ui_throw("Cannot write to package location: {package_dir}")
  }

  bindings_file <- file.path(package_dir, "rust", "libR-sys", "src", "bindings.rs")
  if (!isTRUE(force) && isTRUE(file.exists(bindings_file))) {
    ui_i("libR bindings are already installed. Rerun with `force = TRUE` to force re-install.")
    return(invisible())
  }

  # set up dummy build
  dir <- tempfile()
  dir.create(dir)
  dir.create(file.path(dir, "src"))
  cargo.toml <- c(
    '[package]\nname = "build-libR-sys"\nversion = "0.0.1"\nedition = "2018"',
    glue('[dependencies]\nlibR-sys = "{version}"'),
    "[patch.crates-io]",
    patch.crates_io
  )
  brio::write_lines(cargo.toml, file.path(dir, "Cargo.toml"))
  lib.rs <- c(
    "#![allow(non_snake_case)]",
    "pub const DUMMY: u32 = 0;"
  )
  brio::write_lines(lib.rs, file.path(dir, "src", "lib.rs"))
  on.exit(unlink(dir, recursive = TRUE))

  if (!isTRUE(quiet)) {
    cat(sprintf("build directory: %s\n", dir))
    stdout <- "" # to be used by `system2()` below
  } else {
    stdout <- NULL
  }

  Sys.setenv(
    LIBRSYS_BINDINGS_DIR = file.path(package_dir, "rust", "libR-sys", "src")
  )

  status <- system2(
    command = "cargo",
    args = c(
      "build",
      sprintf("--manifest-path=%s", file.path(dir, "Cargo.toml"))
    ),
    stdout = stdout,
    stderr = stdout
  )

  if (status == 0L) { # success, finish setup
    # get libR-sys version that was compiled
    cargo.lock <- brio::read_lines(file.path(dir, "Cargo.lock"))
    idx <- which(grepl("name = \"libR-sys\"", cargo.lock))
    version_line <- cargo.lock[idx + 1]
    # message("Installed libR-sys version:\n", version_line)

    # patch Cargo.toml file
    installed_cargo.toml <- file.path(package_dir, "rust", "libR-sys", "Cargo.toml")
    lines <- brio::read_lines(installed_cargo.toml)
    lines[3] <- version_line # swap out version
    brio::write_lines(lines, installed_cargo.toml)
  }
  invisible(status)
}

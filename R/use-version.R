
#' Modify Package Version
#' @export
use_version <- function(which = c("major", "minor", "patch")) {

  # check if the cargo-bump crate is available
  if (!cargo_command_available(c("bump", "--help"))) {
    cli::cli_abort(
      c(
        "The {.code cargo bump} command is required to run the {.fun use_version} function.",
        "*" = "Please install cargo-bump ({.url https://crates.io/crates/cargo-bump}) first.",
        i = "Run {.code cargo install cargo-bump} from your terminal."
      ),
      class = "rextendr_error"
    )
  }

  v_type <- match.arg(which)

  # increment version
  usethis::use_version(v_type)

  # defer to sync version
  sync_version()
}

#' @rdname use_version
#' @export
sync_version <- function(path = ".") {

  # check if the cargo-bump crate is available
  if (!cargo_command_available(c("bump", "--help"))) {
    cli::cli_abort(
      c(
        "The {.code cargo bump} command is required to run the {.fun use_version} function.",
        "*" = "Please install cargo-bump ({.url https://crates.io/crates/cargo-bump}) first.",
        i = "Run {.code cargo install cargo-bump} from your terminal."
      ),
      class = "rextendr_error"
    )
  }

  # read description
  x <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))

  # get manifest
  manifest_file <- rprojroot::find_package_root_file("src", "rust", "Cargo.toml", path = path)

  # get the new version from the description file
  new_v <- x$get_version()

  # check if there is a version such as 0.1.0.9000
  # these are not supported by rust
  if (length(new_v) > 3) {
    rlang::abort("Package must be a semantic version following `major.minor.patch`")
  }

  # assign to object to prevent printing anything
  res <- processx::run(
    "cargo",
    c(
      "bump",
      as.character(new_v),
      "--manifest-path",
      manifest_file
    )
  )

}


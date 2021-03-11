# See https://github.com/r-lib/pkgbuild/blob/2aaecf838eb023b788b7a31e267ac644d616dae0/R/compile-dll.R

get_library_path <- function(path = ".") {
  pkg <- desc::desc(rprojroot::find_package_root_file("DESCRIPTION", path = path))
  pkg_name <- pkg$get("Package")
  fs::path(
    glue::glue(
      "src",
      "{pkg_name}{.Platform$dynlib.ext}",
      .sep = .Platform$file.sep
    )
  )
}

get_rust_files <- function(path = ".") {
  rust_root <- rprojroot::find_package_root_file("src", "rust", path = path)
  result <- fs::path()
  cargo_toml_path <- fs::path(rust_root, "Cargo.toml")
  if (fs::file_exists(cargo_toml_path)) {
    result <- c(result, cargo_toml_path)
  }
  rust_src_subdir <- fs::path(rust_root, "src")
  if (fs::dir_exists(rust_src_subdir)) {
    result <- c(
      result,
      fs::dir_ls(
        path = rust_src_subdir,
        recurse = TRUE,
        glob = "*rs"
      )
    )
  }

  result
}

needs_compilation <- function(path = ".") {
  library_path <- get_library_path(path)

  if (!fs::file_exists(library_path)) {
    cli::cli_alert_info("No library found at {.file {library_path}}, recompilation is required.")
    return(TRUE)
  }

  rust_files <- get_rust_files(path)
  if (length(rust_files) == 0L) {
    return(FALSE)
  }

  rust_info <- fs::file_info(rust_files)
  library_info <- fs::file_info(library_path)

  modified_files_info <- dplyr::filter(rust_info, .data$modification_time > library_info[["modification_time"]][1])

  if (nrow(modified_files_info) == 0L) {
    return(FALSE)
  }

  purrr::walk(
    modified_files_info[["path"]],
    ~cli::cli_alert_info("File {.file {.x}} has been modified since last compilation.")
  )

  TRUE
}

touch_makevars <- function(path = ".") {
  src_root <- rprojroot::find_package_root_file("src", path = path)
  makevars_path <- fs::path(src_root, "Makevars")
  makevars_win_path <- fs::path(src_root, "Makevars.win")

  if (fs::file_exists(makevars_path)) {
    fs::file_touch(makevars_path)
  }

  if (fs::file_exists(makevars_win_path)) {
    fs::file_touch(makevars_win_path)
  }

}


#' Create a project for R package development with Rust
#'
#' @description
#' This function creates an R project directory for package development with Rust extensions.
#' The function can be called on an existing project; you will be asked before
#' any existing files are changed.
#'
#' @inheritParams use_extendr
#' @inheritParams usethis::create_package
#' @param usethis logical, should usethis be used to build package directory?
#' @param ... ignored
#'
#' @return Path to the newly created project or package, invisibly.
#' @keywords internal
#'
#' @examples
create_extendr_package <- function(path,
                                   usethis = TRUE,
                                   roxygen = TRUE,
                                   check_name = TRUE,
                                   crate_name = NULL,
                                   lib_name = NULL,
                                   edition = c("2021", "2018"),
                                   ...){

  # check if rust infrastructure is available
  # rust_sitrep()

  # build package directory, but don't open yet!
  if (!usethis) {

    dir.create(path, recursive = TRUE, showWarnings = FALSE)

    # generate header for INDEX file
    header <- c(
      paste0("Package: ", basename(path)),
      "",
      "WARNING:",
      "The project build failed to generate the necessary R package files.",
      "Please consider installing {usethis} with `install.packages('usethis')` and running",
      "usethis::create_package(getwd()).",
      ""
    )

  } else {

    usethis::create_package(
      path,
      fields = list(),
      rstudio = TRUE,
      roxygen,
      check_name,
      open = FALSE
    )

    # generate header for INDEX file
    header <- c(
      paste0("Package: ", basename(path)),
      "",
      "BUILD COMPLETE:",
      "The project build successfully generated the necessary R package files.",
      paste0("Roxygen: ", roxygen),
      ""
    )

  }

  # add rust scaffolding to project dir
  # hunch is that rstudio project text input widgets return empty strings
  # when no value is given
  use_extendr(
    path,
    crate_name = if (crate_name == "") NULL else crate_name,
    lib_name = if (lib_name == "") NULL else lib_name,
    quiet = TRUE,
    overwrite = TRUE,
    edition
  )

  text <- c(
    "NOTE:",
    "To use {rextendr} in any meaningful way, it is required that the user have",
    "Rust and Cargo available on their local machine. To check your own machine",
    "please run `rextendr::rust_sitrep()` in the console. This will provide a",
    "detailed report of the current state of your Rust infrastructure, along",
    "with some helpful advice about how to address any issues that may arise."
  )

  content <- paste(
    paste(header, collapse = "\n"),
    paste(text, collapse = "\n"),
    sep = "\n"
  )

  writeLines(content, con = file.path(path, "INDEX"))

  return(invisible(path))

}


#' Create a project for R package development with Rust
#'
#' @description
#' This function creates an R project directory for package development
#' with Rust extensions.
#'
#' @param path a path to new directory
#' @param ... arguments passed on to `usethis::create_package()` and
#' `rextendr::use_extendr()`
#'
#' @return Path to the newly created project or package, invisibly.
#' @keywords internal
#'
#' @examples
create_extendr_package <- function(path, ...){

  args <- rlang::list2(...)

  # hunch is that rstudio project text input widgets return empty strings
  # when no value is given, want to make sure it is NULL so `use_extendr()`
  # handles it correctly
  args <- lapply(args, \(x){ if (x == "") return(NULL) else return(x) })

  # generate header for INDEX file
  header <- paste0("Package: ", basename(path))

  # build package directory, but don't open yet!
  if (!args[["usethis"]]) {

    dir.create(path, recursive = TRUE, showWarnings = FALSE)

    header <- c(
      header,
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
      roxygen = args[["roxygen"]],
      check_name = args[["check_name"]],
      open = FALSE
    )

    header <- c(
      header,
      "",
      "BUILD COMPLETE:",
      "The project build successfully generated the necessary R package files.",
      paste0("Roxygen: ", args[["roxygen"]]),
      ""
    )

  }

  # add rust scaffolding to project dir
  use_extendr(
    path,
    crate_name = args[["crate_name"]],
    lib_name = args[["lib_name"]],
    quiet = TRUE,
    overwrite = TRUE,
    edition = args[["edition"]]
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

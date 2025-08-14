#' Set up VS Code configuration for an rextendr project
#'
#' @description This creates a `.vscode` folder (if needed) and populates it with a
#' `settings.json` template. If already exists, it will be updated to include
#' the `rust-analyzer.linkedProjects` setting.
#'
#' @param quiet If `TRUE`, suppress messages.
#' @param overwrite If `TRUE`, overwrite existing files.
#' @details Rust-Analyzer VSCode extension looks for a `Cargo.toml` file in the
#'   workspace root by default. This function creates a `.vscode` folder and
#'   populates it with a `settings.json` file that sets the workspace root to
#'   the `src` directory of the package. This allows you to open the package
#'   directory in VSCode and have the Rust-Analyzer extension work correctly.
#' @return `TRUE` (invisibly) if the settings file was created or updated.
#' @export
use_vscode <- function(quiet = FALSE, overwrite = NULL) {
  if (!dir.exists(".vscode")) {
    dir.create(".vscode")
  }

  usethis::use_build_ignore(file.path(".vscode"))

  settings_path <- file.path(".vscode", "settings.json")
  rust_analyzer_path <- "${workspaceFolder}/src/rust/Cargo.toml"
  files_associations <- list(
    "Makevars.in" = "makefile",
    "Makevars.win" = "makefile",
    "configure" = "shellscript",
    "configure.win" = "shellscript",
    "cleanup" = "shellscript",
    "cleanup.win" = "shellscript"
  )

  if (file.exists(settings_path) && isFALSE(overwrite)) {
    if (!quiet) message("Updating existing .vscode/settings.json")

    # settings.json accepts trailing commas before braces and brackets and {jsonlite} doesn't dig that
    tryCatch({
      settings <- jsonlite::read_json(settings_path)
    }, error = function(e) {
      if (grepl("parse error", e$message)) {
        stop(
          "Could not parse .vscode/settings.json. Do you have a trailing comma before braces or brackets?\n",
          "Original error: : ", e$message
        )
      } else {
        stop(e$message)
      }
    })

    # checking and updating cargo.toml path for Rust-Analyzer
    if (!"rust-analyzer.linkedProjects" %in% names(settings)) {
      settings[["rust-analyzer.linkedProjects"]] <- list(rust_analyzer_path)
    } else if (!rust_analyzer_path %in% settings[["rust-analyzer.linkedProjects"]]) {
      settings[["rust-analyzer.linkedProjects"]] <- c(
        settings[["rust-analyzer.linkedProjects"]],
        rust_analyzer_path
      )
    }

    # checking and updating files associations
    if (!"files.associations" %in% names(settings)) {
      settings[["files.associations"]] <- files_associations
    } else {
      current_assoc <- settings[["files.associations"]]
      for (name in names(files_associations)) {
        current_assoc[[name]] <- files_associations[[name]]
      }
      settings[["files.associations"]] <- current_assoc
    }

    jsonlite::write_json(
      settings,
      settings_path,
      auto_unbox = TRUE,
      pretty = TRUE
    )
  } else {
    use_rextendr_template(
      "settings.json",
      save_as = settings_path,
      quiet = quiet,
      overwrite = overwrite
    )
  }

  invisible(TRUE)
}

#' @rdname use_vscode
#' @export
use_positron <- use_vscode

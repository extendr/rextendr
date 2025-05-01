#' Set up VS Code configuration for a rextendr project
#'
#' @description This creates a `.vscode` folder (if needed) and populates it with a
#' `settings.json` template. If already exists, it will be updated to include
#' the `rust-analyzer.linkedProjects` setting.
#'
#' @param quiet If `TRUE`, suppress messages.
#' @param overwrite If `TRUE`, overwrite existing files.
#' @details Rust-Analyzer VSCode extension looks for a cargo.toml file in the
#'   workspace root by default. This function creates a `.vscode` folder and
#'   populates it with a `settings.json` file that sets the workspace root to
#'   the `src` directory of the package. This allows you to open the package
#'   directory in VSCode and have the Rust-Analyzer extension work correctly.
#' @return `TRUE` (invisibly) if the settings file was created or updated.
#' @export
use_vscode <- function(quiet = FALSE, overwrite = FALSE) {
  if (!dir.exists(".vscode")) {
    dir.create(".vscode")
  }

  settings_path <- file.path(".vscode", "settings.json")
  proj_entry <- "${workspaceFolder}/src/rust/Cargo.toml"

  if (file.exists(settings_path) && !overwrite) {
    if (!quiet) message("Updating existing .vscode/settings.json")
    settings <- jsonlite::read_json(settings_path)

    if (!"rust-analyzer.linkedProjects" %in% names(settings)) {
      settings[["rust-analyzer.linkedProjects"]] <- list(proj_entry)
    } else if (!proj_entry %in% settings[["rust-analyzer.linkedProjects"]]) {
      settings[["rust-analyzer.linkedProjects"]] <- c(
        settings[["rust-analyzer.linkedProjects"]],
        proj_entry
      )
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

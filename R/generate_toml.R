enable_features <- function(extendr_deps, features) {
  features <- setdiff(features, "graphics")
  if (length(features) == 0L) {
    return(extendr_deps)
  }

  extendr_api <- extendr_deps[["extendr-api"]]
  if (is.null(extendr_api)) {
    ui_throw("{.arg extendr_deps} should contain a reference to {.code extendr-api} crate.")
  }

  if (is.character(extendr_api)) {
    extendr_api <- list(version = extendr_api, features = array(features))
  } else if (is.list(extendr_api)) {
    existing_features <- extendr_api[["features"]] %||% character(0)
    extendr_api[["features"]] <- array(unique(c(existing_features, features)))
  } else {
    ui_throw("{.arg extendr_deps} contains an invalid reference to {.code extendr-api} crate.")
  }

  extendr_deps[["extendr-api"]] <- extendr_api

  extendr_deps
}

add_features_dependencies <- function(dependencies, features) {
  feature_deps <- rep(list("*"), length(features))
  names(feature_deps) <- features

  purrr::list_modify(feature_deps, !!!dependencies)
}


generate_cargo.toml <- function(libname = "rextendr",
                                dependencies = NULL,
                                patch.crates_io = NULL,
                                extendr_deps = NULL,
                                features = character(0)) {
  to_toml(
    package = list(
      name = libname,
      version = "0.0.1",
      edition = "2021",
      resolver = "2"
    ),
    lib = list(
      `crate-type` = array("cdylib", 1)
    ),
    dependencies = purrr::list_modify(
      add_features_dependencies(dependencies, features),
      !!!enable_features(extendr_deps, features)
    ),
    `patch.crates-io` = patch.crates_io,
    `profile.perf` = list(
      inherits = "release",
      lto = "thin",
      `opt-level` = 3,
      panic = "abort",
      `codegen-units` = 1
    )
  )
}

generate_cargo_config.toml <- function() {
  to_toml(
    build = list(
      rustflags = c("-C", "target-cpu=native"),
      `target-dir` = "target"
    )
  )
}

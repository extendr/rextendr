merge_named_lists <- function(existing, overwriting,
                              existing_arg = rlang::caller_arg(existing),
                              overwriting_arg = rlang::caller_arg(overwriting)) {
  existing <- existing %||% list()
  existing_names <- unique(names(existing) %||% character(0))
  if (!is.list(existing) || length(existing_names) != length(existing)) {
    ui_throw("{.arg {existing_arg}} should be a uniquely named list.")
  }

  overwriting <- overwriting %||% list()
  extendr_deps_names <- unique(names(overwriting) %||%  character(0))
  if (!is.list(overwriting) || length(extendr_deps_names) != length(overwriting)) {
    ui_throw("{.arg {overwriting_arg}} should be a uniquely named list.")
  }

  overwritten_names <- base::intersect(names(existing), names(overwriting))

  append(overwriting, existing[setdiff(names(existing), overwritten_names)])
}

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

  merge_named_lists(existing = feature_deps, overwriting = dependencies)
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
    dependencies = merge_named_lists(
      existing = add_features_dependencies(dependencies, features),
      overwriting = enable_features(extendr_deps, features)
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

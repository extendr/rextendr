generate_cargo.toml <- function(libname = "rextendr",
                                dependencies = NULL,
                                patch.crates_io = NULL,
                                extendr_deps = NULL,
                                features = character(0)) {

  # create an empty list if no dependencies are provided
  deps <- dependencies %||% list()
  # enabled extendr features that we need to impute into all of the
  # dependencies
  to_impute <- enable_features(extendr_deps, features)

  for (.name in names(to_impute)) {
    deps[[.name]] <- to_impute[[.name]]
  }

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
    dependencies = deps,
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

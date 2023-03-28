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
      dependencies %||% list(),
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

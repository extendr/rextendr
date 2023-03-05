merge_dependencies <- function(dependencies, extendr_deps) {
  dependencies <- dependencies %||% list()
  existing_names <- unique(names(dependencies) %||% character(0))
  if(!is.list(dependencies) || length(existing_names) != length(dependencies)) {
    ui_throw("{.var dependencies} should be a uniquely named list.")
  }
  extendr_deps_names <- unique(names(extendr_deps) %||%  character(0))
  if(!is.list(extendr_deps) || length(extendr_deps_names) != length(extendr_deps)) {
    ui_throw("{.var extendr_deps} should be a uniquely named list.")
  }

  overwritten_names <- base::intersect(names(dependencies), names(extendr_deps))

  append(extendr_deps, dependencies[setdiff(names(dependencies), overwritten_names)])
}

generate_cargo.toml <- function(libname = "rextendr",
                                dependencies = NULL,
                                patch.crates_io = NULL,
                                extendr_deps = NULL) {
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
    dependencies = merge_dependencies(
      dependencies = dependencies,
      extendr_deps = extendr_deps
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
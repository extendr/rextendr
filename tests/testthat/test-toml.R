test_that("`toml` is generated correctly", {
  # Using cargo's Cargo.toml file for reference
  # https://github.com/rust-lang/cargo/blob/master/Cargo.toml
  # Testing arrays, names, and nested values
  toml <- to_toml(
    package = list(
      name = "cargo",
      version = "0.52.0",
      edition = "2018",
      authors = c("author_1", "author_2", "author_3"),
      license = "MIT OR Apache-2.0",
      homepage = "https://crates.io",
      repository = "https://github.com/rust-lang/cargo",
      documentation = "https://docs.rs/cargo",
      readme = "README.md",
      description = "Cargo, a package manager for Rust."
    ),
    dependencies = list(
      semver = list(version = "0.10", features = array("serde", 1)),
      serde = list(version = "1.0.82", features = array("derive", 1))
    ),
    `target.'cfg(target_os = "macos")'.dependencies` = list(
      `core-foundation` = list(
        version = "0.9.0",
        features = array("mac_os_10_7_support", 1)
      )
    ),
    `target.'cfg(windows)'.dependencies` = list(
      miow = "0.3.6",
      fwdansi = "1.1.0"
    ),
    empty_block = NULL,
    lib = data.frame(
      name = "cargo",
      test = FALSE,
      doc = FALSE
    ),
    empty_table = data.frame(),
    table_array = data.frame(
      x = c(1L, NA_integer_, 2L),
      y = c("1", NA_character_, "2")
    ),
    single_row_array = data.frame(x = 1),
    .str_as_literal = FALSE
  )

  reference <- c(
    "[package]",
    "name = \"cargo\"",
    "version = \"0.52.0\"",
    "edition = \"2018\"",
    "authors = [ \"author_1\", \"author_2\", \"author_3\" ]",
    "license = \"MIT OR Apache-2.0\"",
    "homepage = \"https://crates.io\"",
    "repository = \"https://github.com/rust-lang/cargo\"",
    "documentation = \"https://docs.rs/cargo\"",
    "readme = \"README.md\"",
    "description = \"Cargo, a package manager for Rust.\"",
    "",
    "[dependencies]",
    "semver = { version = \"0.10\", features = [ \"serde\" ] }",
    "serde = { version = \"1.0.82\", features = [ \"derive\" ] }",
    "",
    "[target.'cfg(target_os = \"macos\")'.dependencies]",
    "core-foundation = { version = \"0.9.0\", features = [ \"mac_os_10_7_support\" ] }",
    "",
    "[target.'cfg(windows)'.dependencies]",
    "miow = \"0.3.6\"",
    "fwdansi = \"1.1.0\"",
    "",
    "[empty_block]",
    "",
    "[[lib]]",
    "name = \"cargo\"",
    "test = false",
    "doc = false",
    "",
    "[[empty_table]]",
    "",
    "[[table_array]]",
    "x = 1",
    "y = \"1\"",
    "[[table_array]]",
    "[[table_array]]",
    "x = 2",
    "y = \"2\"",
    "",
    "[[single_row_array]]",
    "x = 1"
  )

  reference <- glue_collapse(reference, "\n")

  expect_equal(toml, reference)
})

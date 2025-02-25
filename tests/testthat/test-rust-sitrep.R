test_that("`cargo` or `rustup` are not found", {
  local_mocked_bindings(try_exec_cmd = function(...) {
    NA_character_
  })
  expect_snapshot(rust_sitrep())
})

test_that("`cargo` is found, `rustup` is missing", {
  local_mocked_bindings(try_exec_cmd = function(cmd, ...) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("`rustup` is found, `cargo` is missing", {
  local_mocked_bindings(get_required_target = function(host) "arch-pc-os-tool")

  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      NA_character_
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      "stable-arch-pc-os-tool (default)"
    } else if (all(args %in% c("target", "list", "--installed"))) {
      "arch-pc-os-tool"
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("`cargo` and`rustup` are found", {
  local_mocked_bindings(get_required_target = function(host) "arch-pc-os-tool")

  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      "stable-arch-pc-os-tool (default)"
    } else if (all(args %in% c("target", "list", "--installed"))) {
      "arch-pc-os-tool"
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("No toolchains found", {
  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      character(0)
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("Wrong toolchain found", {
  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      "not-a-valid-toolchain"
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("Wrong toolchain is set as default", {
  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      c("not-a-valid-toolchain (default)", "stable-arch-pc-os-tool")
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("Required target is not available", {
  local_mocked_bindings(get_required_target = function(host) "required-target")

  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("toolchain", "list"))) {
      c("not-a-valid-toolchain", "stable-arch-pc-os-tool (default)")
    } else if (all(args %in% c("target", "list", "--installed"))) {
      c("wrong-target-1", "wrong-target-2")
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("Detects host when default toolchain is not set (MacOS)", {
  skip_if_not(get_os() == "osx")

  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (cmd == "rustup" & all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (cmd == "rustc") {
      "host: aarch64-apple-darwin"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
      NA_character_
    } else if (all(args %in% c("toolchain", "list"))) {
      "stable-aarch64-apple-darwin"
    } else if (all(args %in% c("target", "list", "--installed"))) {
      NA_character_
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

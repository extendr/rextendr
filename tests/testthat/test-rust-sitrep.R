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
  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      NA_character_
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("show", "active-toolchain"))) {
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
  local_mocked_bindings(try_exec_cmd = function(cmd, args) {
    if (cmd == "cargo") {
      "cargo 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "--version")) {
      "rustup 1.0.0 (0000000 0000-00-00)"
    } else if (all(args %in% "show")) {
      "Default host: arch-pc-os-tool"
    } else if (all(args %in% c("show", "active-toolchain"))) {
      "stable-arch-pc-os-tool (default)"
    } else if (all(args %in% c("target", "list", "--installed"))) {
      "arch-pc-os-tool"
    } else {
      NA_character_
    }
  })
  expect_snapshot(rust_sitrep())
})

test_that("use_vscode creates .vscode and writes settings.json", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  withr::local_options(usethis.quiet = FALSE)

  use_vscode(quiet = TRUE, overwrite = TRUE)

  expect_true(dir.exists(".vscode"))
  settings <- jsonlite::read_json(file.path(".vscode", "settings.json"))
  expect_equal(
    settings[["rust-analyzer.linkedProjects"]],
    list("${workspaceFolder}/src/rust/Cargo.toml")
  )
})

test_that("use_vscode is idempotent and does not duplicate entries", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  withr::local_options(usethis.quiet = FALSE)

  use_vscode(quiet = TRUE, overwrite = TRUE)
  use_vscode(quiet = TRUE, overwrite = FALSE)

  settings <- jsonlite::read_json(file.path(".vscode", "settings.json"))
  expect_equal(length(settings[["rust-analyzer.linkedProjects"]]), 1)
})

test_that("overwrite = TRUE replaces existing settings.json", {
  skip_if_not_installed("usethis")

  path <- local_package("testpkg")
  withr::local_options(usethis.quiet = FALSE)

  use_vscode(quiet = TRUE, overwrite = TRUE)
  # corrupt the file
  jsonlite::write_json(list(foo = "bar"), file.path(".vscode", "settings.json"), auto_unbox = TRUE)
  use_vscode(quiet = TRUE, overwrite = TRUE)

  settings2 <- jsonlite::read_json(file.path(".vscode", "settings.json"))
  expect_null(settings2$foo)
  expect_equal(
    settings2[["rust-analyzer.linkedProjects"]],
    list("${workspaceFolder}/src/rust/Cargo.toml")
  )
})

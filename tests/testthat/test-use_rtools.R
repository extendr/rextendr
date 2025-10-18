test_that("is_windows_arm returns TRUE on Windows ARM64 with R aarch64", {
  getenv_mock <- mockery::mock("ARM64")
  abort_spy <- mockery::mock()

  mockery::stub(is_windows_arm, "Sys.getenv", getenv_mock)
  mockery::stub(is_windows_arm, "cli::cli_abort", abort_spy)
  mockery::stub(is_windows_arm, "get_r_version", list(arch = "aarch64"))

  result <- is_windows_arm()

  expect_true(result)

  mockery::expect_called(getenv_mock, 1)
  mockery::expect_args(getenv_mock, 1, "PROCESSOR_ARCHITECTURE")

  mockery::expect_called(abort_spy, 0)
})

test_that("is_windows_arm returns FALSE on Windows AMD64 with R x86_64", {
  getenv_mock <- mockery::mock("AMD64")
  abort_spy <- mockery::mock()

  mockery::stub(is_windows_arm, "Sys.getenv", getenv_mock)
  mockery::stub(is_windows_arm, "cli::cli_abort", abort_spy)
  mockery::stub(is_windows_arm, "get_r_version", list(arch = "x86_64"))

  result <- is_windows_arm()

  expect_false(result)

  mockery::expect_called(getenv_mock, 1)
  mockery::expect_args(getenv_mock, 1, "PROCESSOR_ARCHITECTURE")

  mockery::expect_called(abort_spy, 0)
})

test_that("is_windows_arm throws on Windows ARM64 with R not aarch64", {
  getenv_mock <- mockery::mock("ARM64")
  abort_mock <- mockery::mock(stop("Aborted in test"))

  mockery::stub(is_windows_arm, "Sys.getenv", getenv_mock)
  mockery::stub(is_windows_arm, "cli::cli_abort", abort_mock)
  mockery::stub(is_windows_arm, "get_r_version", list(arch = "x64"))

  expect_error(is_windows_arm(), "Aborted in test")

  abort_mock_args <- mockery::mock_args(abort_mock)[[1]]
  expect_equal(abort_mock_args[[1]][[1]], "Architecture mismatch detected.")
  expect_equal(abort_mock_args[["class"]], "rextendr_error")
})

test_that("throw_if_no_rtools throws when Rtools is not found", {
  abort_mock <- mockery::mock(stop("Aborted in test"))

  mockery::stub(throw_if_no_rtools, "pkgbuild::has_rtools", FALSE)
  mockery::stub(throw_if_no_rtools, "cli::cli_abort", abort_mock)

  expect_error(throw_if_no_rtools(), "Aborted in test")

  abort_mock_args <- mockery::mock_args(abort_mock)[[1]]
  expect_equal(abort_mock_args[[1]][[1]], "Unable to find Rtools that are needed for compilation.")
  expect_equal(abort_mock_args[["class"]], "rextendr_error")
})

test_that("throw_if_no_rtools does not throw when Rtools is found", {
  has_rtools_mock <- mockery::mock(TRUE)
  abort_mock <- mockery::mock(stop("Aborted in test"))

  mockery::stub(throw_if_no_rtools, "pkgbuild::has_rtools", TRUE)
  mockery::stub(throw_if_no_rtools, "cli::cli_abort", abort_mock)

  expect_silent(throw_if_no_rtools())

  mockery::expect_called(abort_mock, 0)
})

test_that("throw_if_not_ucrt throws when R is not UCRT", {
  abort_mock <- mockery::mock(stop("Aborted in test"))

  mockery::stub(throw_if_not_ucrt, "get_r_version", list(ucrt = "non-ucrt"))
  mockery::stub(throw_if_not_ucrt, "cli::cli_abort", abort_mock)

  expect_error(throw_if_not_ucrt(), "Aborted in test")

  abort_mock_args <- mockery::mock_args(abort_mock)[[1]]
  expect_equal(abort_mock_args[[1]][[1]], "R must be built with UCRT to use rextendr.")
  expect_equal(abort_mock_args[["class"]], "rextendr_error")
})

test_that("throw_if_not_ucrt does not throw when R is UCRT", {
  abort_mock <- mockery::mock(stop("Aborted in test"))

  mockery::stub(throw_if_not_ucrt, "get_r_version", list(ucrt = "ucrt"))
  mockery::stub(throw_if_not_ucrt, "cli::cli_abort", abort_mock)

  expect_silent(throw_if_not_ucrt())

  mockery::expect_called(abort_mock, 0)
})

patrick::with_parameters_test_that("get_rtools_version returns correct Rtools version:", {
  mockery::stub(get_rtools_version, "get_r_version", list(minor = minor_version))

  result <- get_rtools_version()

  expect_equal(result, expected_rtools_version)
},
  minor_version = c("5.1", "5.0", "4.3", "4.2", "4.1", "4.0", "3.3", "2.3"),
  expected_rtools_version = c("45", "45", "44", "44", "44", "44", "43", "42"),
  .test_name = "when R minor version is {minor_version}, Rtools should be {expected_rtools_version}"
)

test_that("get_path_to_cargo_folder_arm constructs correct path when folder exists", {
  path_to_cargo_folder_stub <- "path/to/cargo/folder"
  path_to_cargo_stub <- "path/to/cargo"
  normalized_path <- "normalized/path"

  abort_spy <- mockery::mock()
  file_path_mock <- mockery::mock(path_to_cargo_folder_stub, path_to_cargo_stub)
  normalize_path_mock <- mockery::mock(normalized_path)
  file_exists_mock <- mockery::mock(TRUE)

  mockery::stub(get_path_to_cargo_folder_arm, "file.path", file_path_mock)
  mockery::stub(get_path_to_cargo_folder_arm, "file.exists", file_exists_mock)
  mockery::stub(get_path_to_cargo_folder_arm, "cli::cli_abort", abort_spy)
  mockery::stub(get_path_to_cargo_folder_arm, "normalizePath", normalize_path_mock)

  result <- get_path_to_cargo_folder_arm("rtools/root")

  expect_equal(result, normalized_path)
  mockery::expect_args(file_path_mock, 1, "rtools/root", "clangarm64", "bin")
  mockery::expect_args(file_path_mock, 2, path_to_cargo_folder_stub, "cargo.exe")
  mockery::expect_args(file_exists_mock, 1, path_to_cargo_stub)
  mockery::expect_args(normalize_path_mock, 1, path_to_cargo_folder_stub, mustWork = TRUE)
  mockery::expect_called(abort_spy, 0)
})

test_that("get_path_to_cargo_folder_arm throws when cargo.exe does not exist", {
  path_to_cargo_folder_stub <- "path/to/cargo/folder"
  path_to_cargo_stub <- "path/to/cargo"

  abort_mock <- mockery::mock(stop("Aborted in test"))
  file_path_mock <- mockery::mock(path_to_cargo_folder_stub, path_to_cargo_stub)
  file_exists_mock <- mockery::mock(FALSE)

  mockery::stub(get_path_to_cargo_folder_arm, "file.path", file_path_mock)
  mockery::stub(get_path_to_cargo_folder_arm, "file.exists", file_exists_mock)
  mockery::stub(get_path_to_cargo_folder_arm, "cli::cli_abort", abort_mock)

  expect_error(get_path_to_cargo_folder_arm("rtools/root"), "Aborted in test")

  mockery::expect_args(file_path_mock, 1, "rtools/root", "clangarm64", "bin")
  mockery::expect_args(file_path_mock, 2, path_to_cargo_folder_stub, "cargo.exe")
  mockery::expect_args(file_exists_mock, 1, path_to_cargo_stub)

  abort_mock_args <- mockery::mock_args(abort_mock)[[1]]
  expect_equal(abort_mock_args[[1]][[1]], "{.code rextendr} on ARM Windows requires an ARM-compatible Rust toolchain.")
  expect_equal(abort_mock_args[["class"]], "rextendr_error")
})
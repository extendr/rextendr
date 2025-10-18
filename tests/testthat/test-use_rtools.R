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

patrick::with_parameters_test_that("get_rtools_version returns correct Rtools version:",
  {
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

patrick::with_parameters_test_that("get_rtools_home returns correct path:",
  {
    env_var <- "env_var"
    default_path <- "default_path"
    get_env_result <- "get_env_result"
    normalize_path_result <- "normalize_path_result"

    sprintf_mock <- mockery::mock(env_var, default_path)
    getenv_mock <- mockery::mock(get_env_result)
    normalize_path_mock <- mockery::mock(normalize_path_result)

    mockery::stub(get_rtools_home, "sprintf", sprintf_mock)
    mockery::stub(get_rtools_home, "Sys.getenv", getenv_mock)
    mockery::stub(get_rtools_home, "normalizePath", normalize_path_mock)

    rtools_version <- "rtools_version"

    result <- get_rtools_home(rtools_version, is_arm)

    expect_equal(result, normalize_path_result)
    mockery::expect_args(sprintf_mock, 1, rtools_env_var_template, rtools_version)
    mockery::expect_args(sprintf_mock, 2, rtools_default_path_template, rtools_version)
    mockery::expect_args(getenv_mock, 1, env_var, default_path)
    mockery::expect_args(normalize_path_mock, 1, get_env_result, mustWork = TRUE)
  },
  is_arm = c(TRUE, FALSE),
  rtools_env_var_template = c("RTOOLS%s_AARCH64_HOME", "RTOOLS%s_HOME"),
  rtools_default_path_template = c("C:\\rtools%s-aarch64", "C:\\rtools%s"),
  .test_name = "when is_arm is {is_arm}, env var should be {rtools_env_var_template} and default path should start with {rtools_default_path_template}" # nolint: line_length_linter
)

patrick::with_parameters_test_that("get_rtools_bin_path returns correct path:",
  {
    rtools_home <- "rtools_home"
    file_path_result <- "file/path/result"
    expected_path <- "normalized/path"
    file_path_mock <- mockery::mock(file_path_result)
    normalize_path_mock <- mockery::mock(expected_path)

    mockery::stub(get_rtools_bin_path, "file.path", file_path_mock)
    mockery::stub(get_rtools_bin_path, "normalizePath", normalize_path_mock)

    result <- get_rtools_bin_path(rtools_home, is_arm)

    expect_equal(result, expected_path)
    expected_arg <- c(subdir, "usr", "bin")
    mockery::expect_args(file_path_mock, 1, rtools_home, expected_arg)
    mockery::expect_args(normalize_path_mock, 1, file_path_result, mustWork = TRUE)
  },
  is_arm = c(TRUE, FALSE),
  subdir = c("aarch64-w64-mingw32.static.posix", "x86_64-w64-mingw32.static.posix"),
  .test_name = "when is_arm is {is_arm}, subdir should start with {subdir}"
)

test_that("use_rtools handled x86_64 architecture", {
  rtools_version <- "rtools_version"
  rtools_home <- "rtools_home"
  rtools_bin_path <- "rtools_bin_path"

  withr_local_path_mock <- mockery::mock()
  get_rtools_home_mock <- mockery::mock(rtools_home)
  get_rtools_bin_path_mock <- mockery::mock(rtools_bin_path)

  mockery::stub(use_rtools, "throw_if_no_rtools", NULL)
  mockery::stub(use_rtools, "throw_if_not_ucrt", NULL)
  mockery::stub(use_rtools, "is_windows_arm", FALSE)
  mockery::stub(use_rtools, "get_rtools_version", rtools_version)

  mockery::stub(use_rtools, "withr::local_path", withr_local_path_mock)
  mockery::stub(use_rtools, "get_path_to_cargo_folder_arm", function(...) stop("Should not be called"))
  mockery::stub(use_rtools, "get_rtools_home", get_rtools_home_mock)
  mockery::stub(use_rtools, "get_rtools_bin_path", get_rtools_bin_path_mock)

  parent_env <- "parent_env"

  use_rtools(parent_env)

  mockery::expect_args(get_rtools_home_mock, 1, rtools_version, FALSE)
  mockery::expect_args(get_rtools_bin_path_mock, 1, rtools_home, FALSE)
  mockery::expect_args(withr_local_path_mock, 1, rtools_bin_path, action = "suffix", .local_envir = parent_env)
})

test_that("use_rtools handled aarch64 architecture", {
  rtools_version <- "rtools_version"
  rtools_home <- "rtools_home"
  rtools_bin_path <- "rtools_bin_path"
  cargo_path <- "cargo_path"

  withr_local_path_mock <- mockery::mock()
  get_rtools_home_mock <- mockery::mock(rtools_home)
  get_rtools_bin_path_mock <- mockery::mock(rtools_bin_path) # nolint: object_length_linter
  get_path_to_cargo_folder_arm_mock <- mockery::mock(cargo_path) # nolint: object_length_linter

  mockery::stub(use_rtools, "throw_if_no_rtools", NULL)
  mockery::stub(use_rtools, "throw_if_not_ucrt", NULL)
  mockery::stub(use_rtools, "is_windows_arm", TRUE)
  mockery::stub(use_rtools, "get_rtools_version", rtools_version)

  mockery::stub(use_rtools, "withr::local_path", withr_local_path_mock)
  mockery::stub(use_rtools, "get_rtools_home", get_rtools_home_mock)
  mockery::stub(use_rtools, "get_rtools_bin_path", get_rtools_bin_path_mock)
  mockery::stub(use_rtools, "get_path_to_cargo_folder_arm", get_path_to_cargo_folder_arm_mock)

  parent_env <- "parent_env"

  use_rtools(parent_env)

  mockery::expect_args(get_rtools_home_mock, 1, rtools_version, TRUE)
  mockery::expect_args(get_rtools_bin_path_mock, 1, rtools_home, TRUE)
  mockery::expect_args(withr_local_path_mock, 1, rtools_bin_path, action = "suffix", .local_envir = parent_env)
  mockery::expect_args(get_path_to_cargo_folder_arm_mock, 1, rtools_home)
  mockery::expect_args(withr_local_path_mock, 2, cargo_path, .local_envir = parent_env)
})

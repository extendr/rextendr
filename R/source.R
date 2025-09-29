the <- rlang::new_environment()
the$build_dir <- NULL
the$count <- 1L

#' Compile Rust code and call from R
#'
#' [rust_source()] compiles and loads a single Rust file for use in R.
#' [rust_function()] compiles and loads a single Rust function for use in R.
#' [extendr_options()] is a helper function to make it easier to pass additional
#' options when sourcing Rust code. It also proivdes defaults for each option
#' and does additional type checking.
#'
#' @param file character scalar, input rust file to source.
#' @param code character scalar, input rust code to be used instead of `file`.
#' @param env environment, the R environment in which the wrapping functions
#'   will be defined. Default is `parent.frame()`.
#' @param echo logical scalar, whether to print standard output and errors of
#'   `cargo` commands to the console. Default is `FALSE`.
#' @param quiet logical scalar, whether to print `cli` errors and warnings.
#'   Default is `FALSE`.
#' @param opts `extendr_opts` list, set using `extendr_options()`. Default is
#'   `NULL`.
#' @param ... user supplied extendr options to be injected into the
#'   `extendr_opts` list (for backwards compatibility).
#' @param extendr_fn_options A list of extendr function options that are
#'   inserted into the `#[extendr(...)]` attribute
#' @param cache_build logical scalar, whether builds should be cached between
#'   calls to [rust_source()].
#' @param dependencies character vector, dependencies to be added to `Cargo.toml`.
#' @param extendr_deps named list, versions of `extendr-*` crates. Defaults to
#'   `rextendr.extendr_deps` option (\code{list(`extendr-api` = "*")}) if
#'   `use_dev_extendr` is not `TRUE`, otherwise, uses
#'   `rextendr.extendr_dev_deps` option (\code{list(`extendr-api` = list(git =
#'   "https://github.com/extendr/extendr")}).
#' @param features character vector, `extendr-api` features that should be enabled.
#'  Supported values are `"ndarray"`, `"faer"`, `"either"`, `"num-complex"`, `"serde"`, and `"graphics"`.
#'  Unknown features will produce a warning if `quiet` is not `TRUE`.
#' @param generate_module_macro logical scalar, whether the Rust module
#'   macro should be automatically generated from the code. Default is `TRUE`.
#'   Ignored for Rust source provided via `file`. The macro generation is done
#'   with [make_module_macro()] and it may fail in complex cases. If something
#'   doesn't work, try calling [make_module_macro()] on your code to see whether
#'   the generated macro code has issues.
#' @param module_name character scalar, name of the module defined in the Rust source via
#'   `extendr_module!`. Default is `"rextendr"`. If `generate_module_macro` is `FALSE`
#'    or if `file` is specified, should *match exactly* the name of the module defined in the source.
#' @param patch.crates_io character vector, patch statements for crates.io to
#'   be added to `Cargo.toml`.
#' @param profile character scalar, Rust profile. Can be either `"dev"`, `"release"` or `"perf"`.
#'  The default, `"dev"`, compiles faster but produces slower code.
#' @param toolchain character scalar, Rust toolchain. The default, `NULL`, compiles with the
#'  system default toolchain. Accepts valid Rust toolchain qualifiers,
#'  such as `"nightly"`, or (on Windows) `"stable-msvc"`.
#' @param use_dev_extendr logical scalar, whether to use development version of
#'   `extendr`. Has no effect if `extendr_deps` are set.
#' @param use_extendr_api logical scalar, whether `use extendr_api::prelude::*;`
#'   should be added at the top of the Rust source provided via `code`. Default
#'   is `TRUE`. Ignored for Rust source provided via `file`.
#' @param use_rtools logical scalar, whether to append the path to Rtools to the
#'   `PATH` variable on Windows using the `RTOOLS4X_HOME` environment variable
#'   (if it is set). The appended path depends on the process architecture. Does
#'   nothing on other platforms.
#' @param x an `extendr_opts` list
#'
#' @return For `rust_source()` and `rust_function()`, the result from
#'   [dyn.load()], which is an object of class `DLLInfo`. See [getLoadedDLLs()]
#'   for more details. For `extendr_options()`, an `extendr_opts` list.
#'
#' @name rust_source
#' @export
#'
#' @examples
#' \dontrun{
#' # creating a single rust function
#' rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")
#' add(2.5, 4.7)
#'
#' # creating multiple rust functions at once
#' code <- r"(
#' #[extendr]
#' fn hello() -> &'static str {
#'     "Hello, world!"
#' }
#'
#' #[extendr]
#' fn test( a: &str, b: i64) {
#'     rprintln!("Data sent to Rust: {}, {}", a, b);
#' }
#' )"
#'
#' rust_source(code = code)
#' hello()
#' test("a string", 42)
#'
#' # use case with an external dependency: a function that converts
#' # markdown text to html, using the `pulldown_cmark` crate.
#' code <- r"(
#'   use pulldown_cmark::{Parser, Options, html};
#'
#'   #[extendr]
#'   fn md_to_html(input: &str) -> String {
#'     let mut options = Options::empty();
#'     options.insert(Options::ENABLE_TABLES);
#'     let parser = Parser::new_ext(input, options);
#'     let mut output = String::new();
#'     html::push_html(&mut output, parser);
#'     output
#'   }
#' )"
#'
#' rust_source(
#'   code = code,
#'   opts = extendr_options(
#'     dependencies = list(`pulldown-cmark` = "0.8")
#'   )
#' )
#'
#' md_text <- "# The story of the fox
#' The quick brown fox **jumps over** the lazy dog.
#' The quick *brown fox* jumps over the lazy dog."
#'
#' md_to_html(md_text)
#'
#' # see default options
#' extendr_options()
#' }
rust_source <- function(
  file = NULL,
  code = NULL,
  env = parent.frame(),
  echo = FALSE,
  quiet = FALSE,
  opts = NULL,
  ...
) {
  check_bool(
    quiet,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  local_quiet_cli(quiet)

  check_string(
    file,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_string(
    code,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_environment(
    env,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    echo,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  if (rlang::is_null(file) && rlang::is_null(code)) {
    cli::cli_abort(
      "One of {.var file} or {.var code} must be non-null.",
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
  }

  if (!rlang::is_null(file) && !rlang::is_null(code)) {
    cli::cli_abort(
      c(
        "User supplied {.var file} and {.var code}.",
        "i" = "Please specify only one or the other, not both."
      ),
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
  }

  # replace any extendr_opts defaults with user-supplied values
  user_opts <- rlang::list2(...)

  if (rlang::is_null(opts)) {
    opts <- rlang::inject(extendr_options(!!!user_opts))
  } else if (!rlang::is_empty(user_opts)) {
    cli::cli_abort(
      c(
        "Options may be passed through `...` or `opts = extendr_options()`, not both!",
        "i" = "User is encouraged to use `extendr_options()`."
      ),
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
  }

  check_extendr_opts(opts, call = rlang::caller_call())

  if (!opts[["cache_build"]] && !rlang::is_null(the$build_dir)) {
    cli::cli_alert_info("Removing build directory {.path {the$build_dir}}")
    unlink(the$build_dir, recursive = TRUE)
    the$build_dir <- NULL
  }

  if (rlang::is_null(the$build_dir)) {
    dir <- tempfile()
    dir.create(dir)
    dir.create(file.path(dir, "R"))
    dir.create(file.path(dir, "src"))
    dir.create(file.path(dir, ".cargo"))
    the$build_dir <- normalizePath(dir, winslash = "/")
  }

  cli::cli_alert_info("build directory: {.file {the$build_dir}}")

  # copy rust code into src/lib.rs and determine library name
  rust_file <- file.path(the$build_dir, "src", "lib.rs")

  if (rlang::is_null(code)) {
    file <- normalizePath(file, winslash = "/")
    file.copy(file, rust_file, overwrite = TRUE)

    libname <- as_valid_rust_name(paste0(
      tools::file_path_sans_ext(basename(file)),
      rlang::hash(file),
      the$count
    ))
  } else {
    if (opts[["generate_module_macro"]]) {
      code <- c(code, make_module_macro(code, opts[["module_name"]]))
    }

    if (opts[["use_extendr_api"]]) {
      code <- c("use extendr_api::prelude::*;", code)
    }

    brio::write_lines(code, rust_file)

    # generate lib name
    libname <- paste0("rextendr", the$count)
  }

  the$count <- the$count + 1L

  if (!opts[["cache_build"]]) {
    withr::defer({
      unlink(the$build_dir, recursive = TRUE)
      the$build_dir <- NULL
    })
  }

  # generate Cargo.toml file and compile shared library
  cargo.toml_content <- generate_cargo.toml(
    libname = libname,
    dependencies = opts[["dependencies"]],
    patch.crates_io = opts[["patch.crates_io"]],
    extendr_deps = opts[["extendr_deps"]],
    features = opts[["features"]]
  )

  brio::write_lines(
    cargo.toml_content,
    file.path(the$build_dir, "Cargo.toml")
  )

  # add cargo configuration file to the package
  cargo_config.toml_content <- generate_cargo_config.toml()

  brio::write_lines(
    cargo_config.toml_content,
    file.path(the$build_dir, ".cargo", "config.toml")
  )

  # append rtools path to the end of PATH on Windows
  if (opts[["use_rtools"]] && .Platform$OS.type == "windows") {
    if (!suppressMessages(pkgbuild::has_rtools())) {
      cli::cli_abort(
        c(
          "Unable to find Rtools that are needed for compilation.",
          "i" = "Required version is {.emph {pkgbuild::rtools_needed()}}."
        ),
        class = "rextendr_error"
      )
    }

    if (identical(R.version$crt, "ucrt")) {
      # TODO: update this when R 5.0 is released.
      if (!identical(R.version$major, "4")) {
        cli::cli_abort(
          "rextendr currently supports R 4.2",
          call = rlang::caller_call(),
          class = "rextendr_error"
        )
      }

      minor_patch <- package_version(R.version$minor)

      if (minor_patch >= "5.0") {
        rtools_version <- "45" # nolint: object_usage_linter
      } else if (minor_patch >= "4.0") {
        rtools_version <- "44" # nolint: object_usage_linter
      } else if (minor_patch >= "3.0") {
        rtools_version <- "43" # nolint: object_usage_linter
      } else {
        rtools_version <- "42" # nolint: object_usage_linter
      }

      rtools_home <- normalizePath(
        Sys.getenv(
          glue("RTOOLS{rtools_version}_HOME"),
          glue("C:\\rtools{rtools_version}")
        ),
        mustWork = TRUE
      )

      # c.f. https://github.com/wch/r-source/blob/f09d3d7fa4af446ad59a375d914a0daf3ffc4372/src/library/profile/Rprofile.windows#L70-L71 # nolint: line_length_linter
      subdir <- c("x86_64-w64-mingw32.static.posix", "usr")
    } else {
      # rtools_path() returns path to the RTOOLS40_HOME\usr\bin,
      # but we need RTOOLS40_HOME\mingw{arch}\bin, hence the "../.."
      rtools_home <- normalizePath(
        # `pkgbuild` may return two paths for R < 4.2 with Rtools40v2
        file.path(pkgbuild::rtools_path()[1], "..", ".."),
        winslash = "/",
        mustWork = TRUE
      )

      subdir <- paste0("mingw", ifelse(R.version$arch == "i386", "32", "64"))
      # if RTOOLS40_HOME is properly set, this will have no real effect
      withr::local_envvar(RTOOLS40_HOME = rtools_home)
    }

    rtools_bin_path <- normalizePath(file.path(rtools_home, subdir, "bin"))
    withr::local_path(rtools_bin_path, action = "suffix")
  }

  # get target name, not null for Windows
  specific_target <- get_specific_target_name()

  # get args for cargo build command
  args <- c(
    sprintf("+%s", opts[["toolchain"]]),
    "build",
    "--lib",
    sprintf("--target=%s", specific_target),
    sprintf("--manifest-path=%s", file.path(the$build_dir, "Cargo.toml")),
    sprintf("--target-dir=%s", file.path(the$build_dir, "target")),
    sprintf("--profile=%s", opts[["profile"]]),
    "--message-format=json-diagnostic-rendered-ansi",
    if (tty_has_colors()) {
      "--color=always"
    } else {
      "--color=never"
    }
  )

  # try running cargo command
  rlang::try_fetch(
    run_cargo(args, echo = echo, wd = NULL),
    error = function(cnd) {
      cli::cli_abort(
        "Rust code could not be compiled successfully. Aborting.",
        parent = cnd,
        class = "rextendr_error"
      )
    }
  )

  # load shared library
  libfilename <- as_rust_lib_file_name(paste0(
    get_dynlib_name(libname),
    get_dynlib_ext()
  ))

  target_folder <- ifelse(
    rlang::is_null(specific_target),
    "target",
    sprintf("target%s%s", .Platform$file.sep, specific_target)
  )

  shared_lib <- file.path(
    the$build_dir,
    target_folder,
    ifelse(opts[["profile"]] == "dev", "debug", opts[["profile"]]),
    libfilename
  )

  # Capture loaded dll
  dll_info <- dyn.load(shared_lib, local = TRUE, now = TRUE)

  # generate R bindings for shared library
  wrapper_file <- file.path(the$build_dir, "target", "extendr_wrappers.R")

  make_wrappers(
    module_name = as_valid_rust_name(opts[["module_name"]]),
    package_name = dll_info[["name"]],
    outfile = wrapper_file,
    use_symbols = FALSE,
    quiet = quiet
  )

  source(wrapper_file, local = env)

  # Invisibly returns to fulfill contract
  invisible(dll_info)
}

#' @rdname rust_source
#' @export
rust_function <- function(
  code,
  extendr_fn_options = NULL,
  env = parent.frame(),
  echo = FALSE,
  quiet = FALSE,
  opts = NULL,
  ...
) {
  check_bool(
    quiet,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  local_quiet_cli(quiet)

  check_string(
    code,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_environment(
    env,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    echo,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  # replace any extendr_opts defaults with user-supplied values
  user_opts <- rlang::list2(...)

  if (rlang::is_null(opts)) {
    opts <- rlang::inject(extendr_options(!!!user_opts))
  } else if (!rlang::is_empty(user_opts)) {
    cli::cli_abort(
      c(
        "Options may be passed through `...` or `opts = extendr_options()`, not both!",
        "i" = "User is encouraged to use `extendr_options()`."
      ),
      call = rlang::caller_call(),
      class = "rextendr_error"
    )
  }

  check_extendr_opts(opts, call = rlang::caller_call())

  # if there are options passed to extendr macro, we need to insert them into
  # the macro call added before the function definition
  # note: only accepted values are logical and character
  if (!rlang::is_null(extendr_fn_options)) {
    check_extendr_fn_options(
      extendr_fn_options,
      opts[["use_dev_extendr"]]
    )

    # get names and values
    nms <- names(extendr_fn_options)

    vls <- vapply(
      extendr_fn_options,
      FUN = function(.x) {
        if (rlang::is_character(.x)) {
          sprintf('"%s"', .x)
        } else if (rlang::is_logical(.x)) {
          tolower(as.character(.x))
        } else {
          as.character(.x)
        }
      },
      FUN.VALUE = character(1),
      USE.NAMES = FALSE
    )

    # insert args into extendr macro
    extendr_args <- paste(nms, vls, sep = " = ", collapse = ", ")
    extendr_macro <- sprintf("#[extendr(%s)]", extendr_args)
  } else {
    extendr_macro <- "#[extendr]"
  }

  code <- paste(
    extendr_macro,
    stringi::stri_trim(code),
    sep = "\n"
  )

  rust_source(
    code = code,
    echo = echo,
    env = env,
    quiet = quiet,
    opts = opts
  )
}

#' @rdname rust_source
#' @export
extendr_options <- function(
  cache_build = TRUE,
  dependencies = NULL,
  extendr_deps = NULL,
  features = NULL,
  generate_module_macro = TRUE,
  module_name = "rextendr",
  patch.crates_io = getOption("rextendr.patch.crates_io"),
  profile = c("dev", "release", "perf"),
  toolchain = getOption("rextendr.toolchain"),
  use_dev_extendr = FALSE,
  use_extendr_api = TRUE,
  use_rtools = TRUE
) {
  check_bool(
    cache_build,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    generate_module_macro,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_string(
    module_name,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  # check patch.crates_io list?
  profile <- rlang::arg_match(
    profile,
    values = c("dev", "release", "perf"),
    multiple = FALSE
  )
  check_string(
    toolchain,
    allow_null = TRUE,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    use_dev_extendr,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    use_extendr_api,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )
  check_bool(
    use_rtools,
    call = rlang::caller_call(),
    class = "rextendr_error"
  )

  features <- validate_extendr_features(
    features,
    suppress_warnings = use_dev_extendr
  )

  if (rlang::is_null(extendr_deps)) {
    if (use_dev_extendr) {
      extendr_deps <- getOption("rextendr.extendr_dev_deps")
    } else {
      extendr_deps <- getOption("rextendr.extendr_deps")
    }
  }

  structure(
    list(
      module_name = module_name,
      dependencies = dependencies,
      patch.crates_io = patch.crates_io,
      profile = profile,
      toolchain = toolchain,
      extendr_deps = extendr_deps,
      features = features,
      use_extendr_api = use_extendr_api,
      generate_module_macro = generate_module_macro,
      cache_build = cache_build,
      use_rtools = use_rtools,
      use_dev_extendr = use_dev_extendr
    ),
    class = c("extendr_opts", "list")
  )
}

#' @rdname rust_source
#' @export
print.extendr_opts <- function(x, ...) {
  parameters <- names(x)
  values <- unlist(as.character(x), use.names = FALSE)

  df <- data.frame(VALUE = values)
  rownames(df) <- parameters

  cli::cli_text("extendr options")
  print(df, quote = FALSE)
}

#' Check For `extendr_opts` List
#'
#' @keywords internal
#' @noRd
check_extendr_opts <- function(opts, call = rlang::caller_call()) {
  if (!rlang::inherits_all(opts, c("extendr_opts", "list"))) {
    cli::cli_abort(
      c(
        "{.var opts} must be an {.cls extendr_opts} list.",
        "i" = "You can make sure it is by using `opts = extendr_options()`."
      ),
      call = call,
      class = "rextendr_error"
    )
  }
}

#' Check For `extendr_fn_options` List
#'
#' @keywords internal
#' @noRd
check_extendr_fn_options <- function(
  extendr_fn_options,
  use_dev_extendr,
  call = rlang::caller_call()
) {
  # check names
  if (!rlang::is_named(extendr_fn_options)) {
    cli::cli_abort(
      "{.var extendr_fn_options} must be a named list!",
      call = call,
      class = "rextendr_error"
    )
  }

  nms <- names(extendr_fn_options)

  # is valid name?
  valid_names <- is_valid_rust_name(nms)

  # is known name?
  unknown_names <- setdiff(
    nms,
    c("r_name", "mod_name", "use_rng")
  )

  unknown_dev_names <- setdiff(
    unknown_names,
    "invisible"
  )

  if (length(unknown_dev_names) > 0L) {
    cli::cli_abort(
      c(
        "Found unknown {.code extendr} function option{?s}: {.val {unknown_names}}.",
        "i" = "These are not available on release or development versions of extendr."
      ),
      call = call,
      class = "rextendr_error"
    )
  } else if (length(unknown_names) > 0L && !use_dev_extendr) {
    cli::cli_abort(
      c(
        "Found unknown {.code extendr} function option{?s}: {.val {unknown_names}}.",
        "i" = inf_dev_extendr_used()
      ),
      call = call,
      class = "rextendr_error"
    )
  }

  # check values
  empty <- vector(mode = "logical", length = length(extendr_fn_options))
  scalar <- vector(mode = "logical", length = length(extendr_fn_options))

  for (i in seq_along(extendr_fn_options)) {
    value <- extendr_fn_options[[i]]

    # is substantive?
    empty[i] <- rlang::is_na(value) ||
      rlang::is_null(value) ||
      rlang::is_empty(value) ||
      !nzchar(value)

    # is scalar?
    scalar[i] <- length(value) == 1L
  }

  message <- "Found {.val {n_invalid_opts}} invalid {.code extendr} function option{?s}:"

  if (any(!valid_names)) {
    invalid_names <- nms[which(!valid_names)]
    message <- c(
      message,
      x = "Unsupported name{?s}: {.val {invalid_names}}.",
      i = "Option names should be valid rust names."
    )
  }

  if (any(empty)) {
    null_values <- nms[which(empty)]
    message <- c(
      message,
      x = "Null value{?s}: {.val {null_values}}.",
      i = "{.code NULL} values are disallowed."
    )
  }

  if (any(!scalar)) {
    vector_values <- nms[which(!scalar)]
    message <- c(
      message,
      x = "Vector value{?s}: {.val {vector_values}}.",
      i = "Only scalars are allowed as option values."
    )
  }

  n_invalid_opts <- sum(c(!valid_names, empty, !scalar))

  if (n_invalid_opts > 0L) {
    # sort to maintain order with previous version of rextendr
    x_idx <- which(names(message) == "x")
    i_idx <- which(names(message) == "i")
    message <- message[c(1, x_idx, i_idx)]

    cli::cli_abort(
      message,
      call = call,
      class = "rextendr_error"
    )
  }

  invisible(extendr_fn_options)
}

#' Generates valid rust library path given file_name.
#'
#' Internally calls [as_valid_rust_name()], but also replaces `-` with `_`, as Rust does.
#'
#' @param file_name_no_parent \[string\] File name, no parent.
#' @returns Sanitized and corrected name.
#' @noRd
as_rust_lib_file_name <- function(file_name_no_parent) {
  ext <- tools::file_ext(file_name_no_parent)

  file_name_no_parent <- tools::file_path_sans_ext(file_name_no_parent)
  file_name_no_parent <- as_valid_rust_name(file_name_no_parent)

  paste(
    stringi::stri_replace_all_fixed(file_name_no_parent, "-", "_"),
    ext,
    sep = "."
  )
}

get_dynlib_ext <- function() {
  # .Platform$dynlib.ext is not reliable on OS X, so need to work around it
  sysinf <- Sys.info()
  if (!rlang::is_null(sysinf)) {
    os <- sysinf["sysname"]
    if (os == "Darwin") {
      return(".dylib")
    }
  }
  .Platform$dynlib.ext
}

get_dynlib_name <- function(libname) {
  if (.Platform$OS.type == "windows") {
    libname
  } else {
    paste0("lib", libname)
  }
}

get_specific_target_name <- function() {
  sysinf <- Sys.info()

  if (!rlang::is_null(sysinf) && sysinf["sysname"] == "Windows") {
    if (R.version$arch == "x86_64") {
      return("x86_64-pc-windows-gnu")
    }

    if (R.version$arch == "i386") {
      return("i686-pc-windows-gnu")
    }

    cli::cli_abort(
      "Unknown Windows architecture",
      class = "rextendr_error"
    )
  }

  NULL
}

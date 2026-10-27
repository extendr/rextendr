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
#' @param file character scalar, input rust file to source. The file must
#'   contain its own `use extendr_api::prelude::*;` and `extendr_module!` call,
#'   as these are not generated like they are for `code`. See Details for more
#'   information.
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
#'   Ignored for Rust source provided via `file`. Note that macro generation may
#'   fail in complex cases, for example, if `#[extendr]` is used inside
#'   `macro_rules!`. In that case, set `generate_module_macro = FALSE` and
#'   write the `extendr_module!` block by hand.
#' @param module_name character scalar, name of the module defined in the Rust source via
#'   `extendr_module!`. Default is `"rextendr"`. If `generate_module_macro` is `FALSE`
#'    or if `file` is specified, should *match exactly* the name of the module defined in the source.
#' @param patch.crates_io a named list where the name corresponds with the dependency to be patched and the values are a named list of dependency values—e.g. `git = "https://github.com/org/repo`.
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
#' @details
#' The extendr crate requires that all functions be registered with
#' `extendr_module!` so that R `.Call()` wrappers can be generated and the Rust
#' code can be called in R. When you pass a string of Rust code to `code`,
#' rextendr will scan your code for the `#[extendr]` macro, collect functions
#' and impls, and generate the `extendr_module!` for you. When you pass a path
#' to `file`, you must manually insert `extendr_module!` in `file` yourself,
#' just as you would when developing an R package with Rust code. If you pass a
#' string to `code` and set `generate_module_macro = FALSE`, that is basically
#' equivalent to using `file`, but with a string, meaning you will have to
#' insert the module yourself in that case, too.
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
#' # use the development version of `extendr-api` from GitHub
#' rust_function(
#'   "fn add(a: f64, b: f64) -> f64 { a + b }",
#'   opts = extendr_options(
#'     patch.crates_io = list(
#'       `extendr-api` = list(git = "https://github.com/extendr/extendr")
#'     )
#'   )
#' )
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
  check_bool(quiet, class = "rextendr_error")

  local_quiet_cli(quiet)

  check_string(file, allow_null = TRUE, class = "rextendr_error")
  check_string(code, allow_null = TRUE, class = "rextendr_error")
  check_environment(env, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

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
      # Simple regular expressions are used to find functions or
      # implementations with the `#[extendr]` attribute, which can get confused
      # by valid Rust code, e.g. implementations for generics.
      lns <- stringi::stri_split_lines(code, omit_empty = TRUE)[[1]]
      lns <- remove_empty_or_whitespace(lns)

      # Replace each `/* block comment */` with a line break rather than deleting it.
      txt <- paste0(lns, collapse = "\n")

      # One pass finds both delimiters without overlaps: in `/*/**/*/`,
      # matching is left-to-right, so `/*/` can't yield both `/*` and `*/`.
      pos <- stringi::stri_locate_all_regex(txt, "/\\*|\\*/")[[1]]

      if (!is.na(pos[1, "start"])) {
        delims <- stringi::stri_sub(txt, pos[, "start"], pos[, "end"])
        depth <- cumsum(ifelse(delims == "/*", 1L, -1L))

        if (depth[length(depth)] != 0L) {
          n_open <- sum(delims == "/*") # nolint
          n_close <- sum(delims == "*/") # nolint
          cli::cli_abort(
            c(
              "Malformed comments.",
              "x" = "Number of start {.code /*} and end {.code */} \\
                     delimiters are not equal.",
              "i" = "Found {n_open} occurrence{?s} of {.code /*}.",
              "i" = "Found {n_close} occurrence{?s} of {.code */}."
            ),
            class = "rextendr_error"
          )
        }

        if (any(depth < 0L)) {
          cli::cli_abort(
            c(
              "Malformed comments.",
              "x" = "{.code /*} and {.code */} are not paired correctly.",
              "i" = "This error may be caused by a code fragment like \\
                     {.code */ ... /*}."
            ),
            class = "rextendr_error"
          )
        }

        # A top-level block spans from a delimiter entered at depth 0
        # to the delimiter that returns to depth 0.
        prev_depth <- c(0L, depth[-length(depth)])
        txt <- stringi::stri_sub_replace_all(
          txt,
          pos[prev_depth == 0L, "start"],
          pos[depth == 0L, "end"],
          replacement = "\n"
        )
      }

      lns <- stringi::stri_split_lines(txt, omit_empty = TRUE)[[1]]
      lns <- stringi::stri_replace_first_regex(lns, "//.*$", "")
      lns <- remove_empty_or_whitespace(lns)

      # Finds lines which contain #[extendr] (allowing additional spaces)
      # Excludes #[extendr(default=...)] which is used for function arguments
      ids <- which(stringi::stri_detect_regex(
        lns,
        r"{#\s*\[\s*extendr(\s*\((?!.*default\s*=).*\))?\s*\]}"
      ))
      ends <- c(ids[-1], length(lns) + 1L) - 1L
      exports <- character(0)

      for (i in seq_along(ids)) {
        item <- lns[ids[i]:ends[i]]

        # Matches first occurrence of struct|enum|fn|impl<'a> item_name.
        # Columns are match, struct, enum, fn, impl, lifetime, name.
        meta <- stringi::stri_match_first_regex(
          glue_collapse(item, sep = "\n"),
          "(?:(?<struct>struct)|(?<enum>enum)|(?<fn>fn)|(?<impl>impl)(?:\\s*<(?<lifetime>.+?)>)?)\\s+(?<name>(?:r#)?(?:_\\w+|[A-z]\\w*))" # nolint: line_length_linter
        )

        # If no matches have been found, then the attribute is misplaced
        if (is.na(meta[1, 1])) {
          # This unfortunately does not provide
          # meaningful output or source line numbers.
          code_sample <- stringi::stri_sub(
            glue_collapse(item, sep = "\n  "),
            1,
            80
          )

          rlang::abort(
            cli::cli_fmt({
              cli::cli_text(
                "Rust code contains invalid attribute macros."
              )
              cli::cli_alert_danger(
                "No valid {.code fn} or {.code impl} block found in the \\
                following sample:"
              )
              cli::cli_code(code_sample)
              cli::cli_alert_info(
                "If {.code #[extendr]} is used inside {.code macro_rules!}, set \\
                {.arg generate_module_macro = FALSE} and write the \\
                {.code extendr_module!} block by hand."
              )
            }),
            class = "rextendr_error"
          )
        }

        # structs and enums are not registered in the module
        item_type <- if (is.na(meta[1, 5])) meta[1, 4] else meta[1, 5]
        if (!is.na(item_type)) {
          exports <- c(exports, glue("{item_type} {meta[1, 7]};"))
        }
      }

      code <- c(
        code,
        "extendr_module! {",
        glue("mod {opts[['module_name']]};"),
        exports,
        "}"
      )
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
  # create an empty list if no dependencies are provided
  dependencies <- opts[["dependencies"]] %||% list()
  extendr_deps <- opts[["extendr_deps"]]

  # enabled extendr features that we need to impute into all of the
  # dependencies
  features <- setdiff(opts[["features"]], "graphics")

  if (length(features) > 0L) {
    extendr_api <- extendr_deps[["extendr-api"]]
    if (is.null(extendr_api)) {
      cli::cli_abort(
        "{.arg extendr_deps} should contain a reference to {.code extendr-api} crate.",
        class = "rextendr_error"
      )
    }

    if (is.character(extendr_api)) {
      extendr_api <- list(version = extendr_api, features = array(features))
    } else if (is.list(extendr_api)) {
      existing_features <- extendr_api[["features"]] %||% character(0)
      extendr_api[["features"]] <- array(unique(c(existing_features, features)))
    } else {
      cli::cli_abort(
        "{.arg extendr_deps} contains an invalid reference to {.code extendr-api} crate.",
        class = "rextendr_error"
      )
    }

    extendr_deps[["extendr-api"]] <- extendr_api
  }

  for (.name in names(extendr_deps)) {
    dependencies[[.name]] <- extendr_deps[[.name]]
  }

  cargo.toml_content <- to_toml(
    package = list(
      name = libname,
      version = "0.0.1",
      edition = "2021",
      resolver = "2"
    ),
    lib = list(
      `crate-type` = array("cdylib", 1)
    ),
    dependencies = dependencies,
    `patch.crates-io` = opts[["patch.crates_io"]],
    `profile.perf` = list(
      inherits = "release",
      lto = "thin",
      `opt-level` = 3,
      panic = "abort",
      `codegen-units` = 1
    )
  )

  brio::write_lines(
    cargo.toml_content,
    file.path(the$build_dir, "Cargo.toml")
  )

  # add cargo configuration file to the package
  cargo_config.toml_content <- to_toml(
    build = list(
      rustflags = c("-C", "target-cpu=native"),
      `target-dir` = "target"
    )
  )

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
  sysinf <- Sys.info()
  specific_target <- NULL

  if (!rlang::is_null(sysinf) && sysinf["sysname"] == "Windows") {
    specific_target <- switch(
      R.version$arch,
      aarch64 = "aarch64-pc-windows-gnullvm",
      x86_64 = "x86_64-pc-windows-gnu",
      i386 = "i686-pc-windows-gnu",
      cli::cli_abort(
        "Unknown Windows architecture",
        class = "rextendr_error"
      )
    )
  }

  # get args for cargo build command
  args <- c(
    sprintf("+%s", opts[["toolchain"]]),
    "build",
    "--lib",
    if (!echo) "--quiet",
    sprintf("--target=%s", specific_target),
    sprintf("--manifest-path=%s", file.path(the$build_dir, "Cargo.toml")),
    sprintf("--target-dir=%s", file.path(the$build_dir, "target")),
    sprintf("--profile=%s", opts[["profile"]])
  )

  # try running cargo command
  cargo(args, echo = echo, wd = getwd())

  # load shared library, replacing `-` with `_` in its name, as Rust does
  # .Platform$dynlib.ext is not reliable on OS X, so need to work around it
  libfilename <- paste0(
    if (.Platform$OS.type == "windows") "" else "lib",
    stringi::stri_replace_all_fixed(libname, "-", "_"),
    if (identical(unname(sysinf["sysname"]), "Darwin")) {
      ".dylib"
    } else {
      .Platform$dynlib.ext
    }
  )

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

  rlang::try_fetch(
    {
      # Invokes `wrap__make_{module_name}_wrappers` exported from
      # the Rust library and writes obtained R wrappers to `wrapper_file`.
      module_name <- as_valid_rust_name(opts[["module_name"]])
      wrapper_function <- glue("wrap__make_{module_name}_wrappers")
      wrappers <- .Call(
        wrapper_function,
        use_symbols = FALSE,
        package_name = dll_info[["name"]],
        PACKAGE = dll_info[["name"]]
      )
      wrappers <- stringi::stri_split_lines1(wrappers)

      write_file(
        text = c(
          wrappers[1],
          "",
          "# nolint start",
          "",
          wrappers[-1],
          "",
          "# nolint end"
        ),
        path = wrapper_file
      )
    },
    error = function(cnd) {
      cli::cli_abort(
        "Failed to generate wrapper functions.",
        parent = cnd,
        class = "rextendr_error"
      )
    }
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
  check_bool(quiet, class = "rextendr_error")

  local_quiet_cli(quiet)

  check_string(code, class = "rextendr_error")
  check_environment(env, class = "rextendr_error")
  check_bool(echo, class = "rextendr_error")

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
    # check names
    if (!rlang::is_named(extendr_fn_options)) {
      cli::cli_abort(
        "{.var extendr_fn_options} must be a named list!",
        class = "rextendr_error"
      )
    }

    # get names and values
    nms <- names(extendr_fn_options)

    # is known name?
    unknown_names <- setdiff(nms, c("r_name", "mod_name", "use_rng"))
    unknown_dev_names <- setdiff(unknown_names, "invisible")

    if (length(unknown_dev_names) > 0L) {
      cli::cli_abort(
        c(
          "Found unknown {.code extendr} function option{?s}: {.val {unknown_dev_names}}.",
          "i" = "These are not available on release or development versions of extendr."
        ),
        class = "rextendr_error"
      )
    } else if (length(unknown_names) > 0L && !opts[["use_dev_extendr"]]) {
      cli::cli_abort(
        c(
          "Found unknown {.code extendr} function option{?s}: {.val {unknown_names}}.",
          "i" = inf_dev_extendr_used()
        ),
        class = "rextendr_error"
      )
    }

    # is empty
    empty <- vapply(
      extendr_fn_options,
      FUN = function(.x) {
        rlang::is_na(.x) ||
          rlang::is_null(.x) ||
          rlang::is_empty(.x) ||
          !nzchar(.x)
      },
      FUN.VALUE = logical(1)
    )

    if (any(empty)) {
      null_values <- nms[which(empty)] # nolint: object_usage_linter
      cli::cli_abort(
        c(
          x = "Null value{?s}: {.val {null_values}}.",
          i = "{.code NULL} values are disallowed."
        ),
        class = "rextendr_error"
      )
    }

    # check values
    check_string(
      extendr_fn_options[["r_name"]],
      allow_null = TRUE,
      class = "rextendr_error"
    )
    check_string(
      extendr_fn_options[["mod_name"]],
      allow_null = TRUE,
      class = "rextendr_error"
    )
    check_bool(
      extendr_fn_options[["use_rng"]],
      allow_null = TRUE,
      class = "rextendr_error"
    )
    check_bool(
      extendr_fn_options[["invisible"]],
      allow_null = TRUE,
      class = "rextendr_error"
    )

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
  check_bool(cache_build, class = "rextendr_error")
  check_bool(generate_module_macro, class = "rextendr_error")
  check_string(module_name, class = "rextendr_error")
  # check patch.crates_io list?
  profile <- rlang::arg_match(
    profile,
    values = c("dev", "release", "perf"),
    multiple = FALSE
  )
  check_string(toolchain, allow_null = TRUE, class = "rextendr_error")
  check_bool(use_dev_extendr, class = "rextendr_error")
  check_bool(use_extendr_api, class = "rextendr_error")
  check_bool(use_rtools, class = "rextendr_error")

  features <- features %||% character(0)

  if (!vctrs::vec_is(features, character())) {
    cli::cli_abort(
      c(
        "!" = "{.arg features} expected to be a vector of type {.cls character}, but got {.cls {class(features)}}."
      ),
      class = "rextendr_error"
    )
  }

  features <- unique(features)

  unknown_features <- setdiff(
    features,
    c("ndarray", "faer", "serde", "either", "num-complex", "graphics")
  )
  unknown_features <- unknown_features[nzchar(unknown_features)]

  if (!use_dev_extendr && length(unknown_features) > 0) {
    # alerts are to be short 1 liners
    # these are called separately
    cli::cli_warn(
      c(
        "Found unknown {.code extendr} feature{?s}: {.val {unknown_features}}.",
        "i" = inf_dev_extendr_used()
      )
    ) # nolint: object_usage_linter
  }

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

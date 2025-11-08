# Compile Rust code and call from R

`rust_source()` compiles and loads a single Rust file for use in R.
`rust_function()` compiles and loads a single Rust function for use in
R. `extendr_options()` is a helper function to make it easier to pass
additional options when sourcing Rust code. It also proivdes defaults
for each option and does additional type checking.

## Usage

``` r
rust_source(
  file = NULL,
  code = NULL,
  env = parent.frame(),
  echo = FALSE,
  quiet = FALSE,
  opts = NULL,
  ...
)

rust_function(
  code,
  extendr_fn_options = NULL,
  env = parent.frame(),
  echo = FALSE,
  quiet = FALSE,
  opts = NULL,
  ...
)

extendr_options(
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
)

# S3 method for class 'extendr_opts'
print(x, ...)
```

## Arguments

- file:

  character scalar, input rust file to source.

- code:

  character scalar, input rust code to be used instead of `file`.

- env:

  environment, the R environment in which the wrapping functions will be
  defined. Default is
  [`parent.frame()`](https://rdrr.io/r/base/sys.parent.html).

- echo:

  logical scalar, whether to print standard output and errors of `cargo`
  commands to the console. Default is `FALSE`.

- quiet:

  logical scalar, whether to print `cli` errors and warnings. Default is
  `FALSE`.

- opts:

  `extendr_opts` list, set using `extendr_options()`. Default is `NULL`.

- ...:

  user supplied extendr options to be injected into the `extendr_opts`
  list (for backwards compatibility).

- extendr_fn_options:

  A list of extendr function options that are inserted into the
  `#[extendr(...)]` attribute

- cache_build:

  logical scalar, whether builds should be cached between calls to
  `rust_source()`.

- dependencies:

  character vector, dependencies to be added to `Cargo.toml`.

- extendr_deps:

  named list, versions of `extendr-*` crates. Defaults to
  `rextendr.extendr_deps` option (`` list(`extendr-api` = "*") ``) if
  `use_dev_extendr` is not `TRUE`, otherwise, uses
  `rextendr.extendr_dev_deps` option
  (`` list(`extendr-api` = list(git = "https://github.com/extendr/extendr") ``).

- features:

  character vector, `extendr-api` features that should be enabled.
  Supported values are `"ndarray"`, `"faer"`, `"either"`,
  `"num-complex"`, `"serde"`, and `"graphics"`. Unknown features will
  produce a warning if `quiet` is not `TRUE`.

- generate_module_macro:

  logical scalar, whether the Rust module macro should be automatically
  generated from the code. Default is `TRUE`. Ignored for Rust source
  provided via `file`. The macro generation is done with
  [`make_module_macro()`](https://extendr.github.io/rextendr/dev/reference/make_module_macro.md)
  and it may fail in complex cases. If something doesn't work, try
  calling
  [`make_module_macro()`](https://extendr.github.io/rextendr/dev/reference/make_module_macro.md)
  on your code to see whether the generated macro code has issues.

- module_name:

  character scalar, name of the module defined in the Rust source via
  `extendr_module!`. Default is `"rextendr"`. If `generate_module_macro`
  is `FALSE` or if `file` is specified, should *match exactly* the name
  of the module defined in the source.

- patch.crates_io:

  character vector, patch statements for crates.io to be added to
  `Cargo.toml`.

- profile:

  character scalar, Rust profile. Can be either `"dev"`, `"release"` or
  `"perf"`. The default, `"dev"`, compiles faster but produces slower
  code.

- toolchain:

  character scalar, Rust toolchain. The default, `NULL`, compiles with
  the system default toolchain. Accepts valid Rust toolchain qualifiers,
  such as `"nightly"`, or (on Windows) `"stable-msvc"`.

- use_dev_extendr:

  logical scalar, whether to use development version of `extendr`. Has
  no effect if `extendr_deps` are set.

- use_extendr_api:

  logical scalar, whether `use extendr_api::prelude::*;` should be added
  at the top of the Rust source provided via `code`. Default is `TRUE`.
  Ignored for Rust source provided via `file`.

- use_rtools:

  logical scalar, whether to append the path to Rtools to the `PATH`
  variable on Windows using the `RTOOLS4X_HOME` environment variable (if
  it is set). The appended path depends on the process architecture.
  Does nothing on other platforms.

- x:

  an `extendr_opts` list

## Value

For `rust_source()` and `rust_function()`, the result from
[`dyn.load()`](https://rdrr.io/r/base/dynload.html), which is an object
of class `DLLInfo`. See
[`getLoadedDLLs()`](https://rdrr.io/r/base/getLoadedDLLs.html) for more
details. For `extendr_options()`, an `extendr_opts` list.

## Examples

``` r
if (FALSE) { # \dontrun{
# creating a single rust function
rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")
add(2.5, 4.7)

# creating multiple rust functions at once
code <- r"(
#[extendr]
fn hello() -> &'static str {
    "Hello, world!"
}

#[extendr]
fn test( a: &str, b: i64) {
    rprintln!("Data sent to Rust: {}, {}", a, b);
}
)"

rust_source(code = code)
hello()
test("a string", 42)

# use case with an external dependency: a function that converts
# markdown text to html, using the `pulldown_cmark` crate.
code <- r"(
  use pulldown_cmark::{Parser, Options, html};

  #[extendr]
  fn md_to_html(input: &str) -> String {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_TABLES);
    let parser = Parser::new_ext(input, options);
    let mut output = String::new();
    html::push_html(&mut output, parser);
    output
  }
)"

rust_source(
  code = code,
  opts = extendr_options(
    dependencies = list(`pulldown-cmark` = "0.8")
  )
)

md_text <- "# The story of the fox
The quick brown fox **jumps over** the lazy dog.
The quick *brown fox* jumps over the lazy dog."

md_to_html(md_text)

# see default options
extendr_options()
} # }
```

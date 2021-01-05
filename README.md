
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Call Rust code from R using the ‘extendr’ crate

<!-- badges: start -->

[![R build
status](https://github.com/extendr/rextendr/workflows/R-CMD-check/badge.svg)](https://github.com/extendr/rextendr/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/rextendr)](https://CRAN.R-project.org/package=rextendr)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

## Installation

To install the package, run:

    remotes::install_github("extendr/rextendr")

Note that this will install the package but does not guarantee that the
package can do anything useful. You will also need to set up a working
Rust toolchain, including libclang/llvm-config support to run
[bindgen](https://rust-lang.github.io/rust-bindgen/). See the
[installation instructions for
libR-sys](https://github.com/extendr/libR-sys) for help. If you can
successfully build libR-sys you’re good.

## Usage

Basic use example:

    library(rextendr)

    # create a single rust function
    rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")

    add(2.5, 4.7)
    #> [1] 7.2

    # create a function using some more complex Rust code, including
    # a dependency on an external crate; here we create a function that
    # converts markdown text to html
    code <- "use extendr_api::*;
    use pulldown_cmark::{Parser, Options, html};

    #[extendr]
    fn md_to_html(input: &str) -> Robj {
        let mut options = Options::empty();
        options.insert(Options::ENABLE_TABLES);
        let parser = Parser::new_ext(input, options);
        let mut output = String::new();
        html::push_html(&mut output, parser);
        Robj::from(&*output)
    }
    "
    rust_source(code = code, dependencies = 'pulldown-cmark = "0.8"')

    md_text <- "# The story of the fox
    The quick brown fox **jumps over** the lazy dog. The quick *brown fox* jumps over the lazy dog."

    md_to_html(md_text)
    #> [1] "<h1>The story of the fox</h1>\n<p>The quick brown fox <strong>jumps over</strong> the lazy dog. The quick <em>brown fox</em> jumps over the lazy dog.</p>\n"

The package also enables a new chunk type for knitr, `extendr`, which
compiles and evaluates Rust code. For example, a code chunk such as this
one:

    ```{extendr}
    rprintln!("Hello from Rust!");

    let x = 5;
    let y = 7;
    let z = x*y;

    z
    ```

would create the following output in the knitted document:

    rprintln!("Hello from Rust!");

    let x = 5;
    let y = 7;
    let z = x*y;

    z
    #> Hello from Rust!
    #> [1] 35

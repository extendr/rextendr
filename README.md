
<!-- README.md is generated from README.Rmd. Please edit that file -->

Call Rust code from R using the ‘extendr’ crate
===============================================

<!-- badges: start -->
<!-- badges: end -->

Basic use example:

    library(rextendr)

    # some simple Rust code with two functions
    rust_src <- "use extendr_api::*;

    #[extendr]
    fn hello() -> &'static str {
        \"Hello, this string was created by Rust.\"
    }

    #[extendr]
    fn add(a: i64, b: i64) -> i64 {
        a + b
    }
    "

    rust_source(
      code = rust_src,
      # use `patch.crates_io` argument to override crate locations
      patch.crates_io = c(
        'extendr-api = {path = "/Users/clauswilke/github/extendr/extendr-api"}',
        'extendr-macros = {path = "/Users/clauswilke/github/extendr/extendr-macros"}'
      ),
      quiet = TRUE
    )

    # call `hello()` function from R
    hello()
    #> [1] "Hello, this string was created by Rust."

    # call `add()` function from R
    add(14, 23)
    #> [1] 37

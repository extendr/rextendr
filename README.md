# Call Rust code from R using the 'extendr' crate

Basic use example:

``` r
library(rextendr)

code <- "use extendr_api::*;

#[extendr]
fn hello() -> &'static str {
    \"hello\"
}
"

rust_source(code = code)
.Call("wrap__hello")
```


test_that("Module macro generation", {
  rust_src <- r"(
#[extendr]
/* multiline
comment
*/fn hello() -> &'static str {
    "Hello from Rust!"
}

#[extendr]
// An awkwardly placed comment
// to verify comments are stripped
fn foo(a: &str, b: i64) {
    rprintln!("Data sent to Rust: {}, {}", a, b);
}

struct Counter {
    n: i32,
}

#[extendr]
#[allow(dead_code)]
impl Counter {
    fn new() -> Self {
      Self { n: 0 }
    }

    fn increment(&mut self) {
        self.n += 1;
    }

    fn get(&self) -> i32 {
        self.n
    }
})"

  expect_equal(
    make_module_macro(rust_src),
    c(
      "extendr_module! {",
      "mod rextendr;",
      "fn hello;",
      "fn foo;",
      "impl Counter;",
      "}"
    )
  )

  expect_equal(
    make_module_macro(rust_src, module_name = "abcd"),
    c(
      "extendr_module! {",
      "mod abcd;",
      "fn hello;",
      "fn foo;",
      "impl Counter;",
      "}"
    )
  )
})

test_that("Macro generation fails", {
  expect_error(
    make_module_macro("#[extendr]\nlet invalid_var = ();"),
    "Rust code contains invalid attribute macros.
 x No valid `fn` or `impl` block found in the following sample:"
  )
})
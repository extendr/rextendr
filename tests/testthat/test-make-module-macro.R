test_that("Module macro generation", {
  skip_if_cargo_unavailable()

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

test_that("Macro generation fails on invalid rust code", {
  skip_if_cargo_unavailable()

  expect_rextendr_error(
    make_module_macro("#[extendr]\nlet invalid_var = ();"),
    "Rust code contains invalid attribute macros."
  )
})


test_that("Macro generation fails on invalid comments in code", {
  skip_if_cargo_unavailable()

  expect_rextendr_error(
    make_module_macro("/*/*/**/"),
    "Malformed comments."
  )
  expect_rextendr_error(
    make_module_macro("/*/*/**/"),
    "delimiters are not equal"
  )
  expect_rextendr_error(
    make_module_macro("/*/*/**/"),
    "Found 3 occurrences"
  )
  expect_rextendr_error(
    make_module_macro("/*/*/**/"),
    "Found 1 occurrence"
  )

  expect_rextendr_error(
    make_module_macro("*/  /*"),
    "This error may be caused by a code fragment like",
  )
})


test_that("Rust code cleaning", {
  skip_if_cargo_unavailable()

  expect_equal(
    fill_block_comments(c(
      "Nested /*/* this is */ /*commented*/ out */",
      "/*/*/**/*/*/comments."
    )),
    c(
      "Nested                                     ",
      "            comments."
    )
  )

  expect_equal(
    remove_line_comments("This is visible //this is not."),
    "This is visible "
  )

  expect_equal(
    sanitize_rust_code(c(
      "/* Comment #1 */",
      "   // Comment #2",
      "              ",
      " /* Comment #3 //   */"
    )),
    character(0)
  )
})

test_that("Rust metadata capturing", {
  skip_if_cargo_unavailable()

  expect_equal(
    find_extendr_attrs_ids(c(
      "#1",
      "#[extendr]",
      "    # 3  ",
      " #\t [ \textendr   ]",
      "#5",
      "#[extendr(some_option=true)]",
      "#[extendr ( some_option =  true ) ]",
      "#[extendr()]"
    )),
    c(2L, 4L, 6L, 7L, 8L)
  )

  expect_equal(
    extract_meta("#[extendr] pub \tfn\t      test_fn  \t() {}"),
    tibble::tibble(
      match = "fn\t      test_fn",
      fn = "fn",
      impl = NA_character_,
      lifetime = NA_character_,
      name = "test_fn"
    )
  )

  expect_equal(
    extract_meta(c(
      "#[extendr]",
      "pub impl  <'a, \t 'b>  X   <a', 'b> {}"
    )),
    tibble::tibble(
      match = "impl  <'a, \t 'b>  X",
      fn = NA_character_,
      impl = "impl",
      lifetime = "'a, \t 'b",
      name = "X"
    )
  )
})

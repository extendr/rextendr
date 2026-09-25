# Snapshot test of knitr-engine

    Code
      cat_file(output)
    Output
      
      
      
      Basic use example:
      
      
      ``` r
      library(rextendr)
      
      # create a Rust function
      rust_function("fn add(a:f64, b:f64) -> f64 { a + b }")
      
      # call it from R
      add(2.5, 4.7)
      #> [1] 7.2
      ```
      
      The package also enables a new chunk type for knitr, `extendr`, which compiles and evaluates Rust code. For example, a code chunk such as this one:
      ````markdown
      ```{extendr}
      rprintln!("Hello from Rust!");
      
      let x = 5;
      let y = 7;
      let z = x*y;
      
      z
      ```
      ````
      
      would create the following output in the knitted document:
      
      ``` rust
      rprintln!("Hello from Rust!");
      
      let x = 5;
      let y = 7;
      let z = x*y;
      
      z
      #> Hello from Rust!
      #> [1] 35
      ```
      
      Define variable `_x`:
      
      
      ``` rust
      let _x = 1;
      ```
      
      Define variable `_y`:
      
      
      ``` rust
      let _y = 2;
      ```
      
      Print:
      
      
      ``` rust
      rprintln!("x = {}, y = {}", _x, _y);
      #> x = 1, y = 2
      ```
      
      
      ``` rust
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
      ```
      
      
      ``` r
      md_text <- "# The story of the fox
      The quick brown fox **jumps over** the lazy dog.
      The quick *brown fox* jumps over the lazy dog."
      
      md_to_html(md_text)
      #> [1] "<h1>The story of the fox</h1>\n<p>The quick brown fox <strong>jumps over</strong> the lazy dog.\nThe quick <em>brown fox</em> jumps over the lazy dog.</p>\n"
      ```
      
      Print compilation errors if chunk option `error = TRUE`.
      
      
      ``` rust
      #[extendr]
      fn add_one(x: &str) -> f64 {
          x + 1.0
      }
      #> error[E0369]: cannot add `{float}` to `&str`
      #>  --> src/lib.rs:4:7
      #>   |
      #> 4 |     x + 1.0
      #>   |     - ^ --- {float}
      #>   |     |
      #>   |     &str
      #> 
      #> For more information about this error, try `rustc --explain E0369`.
      #> error: could not compile `rextendr` (lib) due to 1 previous error
      ```
      
      
      ``` r
      add_one(2.3)
      #> Error in `add_one()`:
      #> ! could not find function "add_one"
      ```


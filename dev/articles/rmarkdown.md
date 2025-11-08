# Using Rust code in R Markdown documents

The rextendr package enables two new chunk types for knitr, `extendr`
and `extendrsrc`. The former can be used to evaluate individual Rust
statements while the latter can be used to define Rust functions and
export them to R. To use either chunk type, you need to first load the
rextendr package in a regular R chunk. You would normally do this in a
hidden setup chunk at the top of your R Markdown document.

``` r
library(rextendr)
```

## Evaluating Rust statements

Chunks of type `extendr` evaluate a block of Rust statements. The value
of the last statement can be returned to R and will be printed as chunk
output. For example:

```` markdown
```{extendr}
rprintln!("Hello from Rust!");

let x = 5;
let y = 7;
let z = x*y;

z
```
````

This chunk will look in the knitted document as follows:

``` rust
rprintln!("Hello from Rust!");

let x = 5;
let y = 7;
let z = x*y;

z
```

    ## Hello from Rust!
    ## [1] 35

In the background, the `extendr` knit engine casts the Rust integer
variable into type `Result<Robj>` and returns its value to R. Notice the
lack of a semicolon (`;`) at the end of this line, to indicate that you
want to return a value. You can also write code that doesn’t return any
result to R. In this case, the last line would end in a semicolon, as in
this example:

``` rust
let x = 5;
let y = 7;
let z = x*y;

rprintln!("{}*{} = {}", x, y, z);
```

    ## 5*7 = 35

## Accessing R values from Rust

It is possible to access variables defined in R from Rust. Let’s define
two R variables, a numeric and a string:

``` r
x <- 5.3
y <- "hello"
```

We can read these variables from Rust using the `R!()` macro.
Unfortunately, it takes a bit of error checking and type-converting to
get these into native Rust values. This is the case because things could
go wrong at each step. We’re handling the errors with `?`. For example,
`R!()` calls the R interpreter and it could generate an error. And even
if it returns a value, we’re not guaranteed that the value can be
coerced into a real value or a string. However, `as_real()` and
`as_str()` don’t return errors, they return options, so we need to turn
the `None` option into an error via `ok_or()`.

``` rust
let x:f64 = R!(x)?
    .as_real()
    .ok_or("expected a real")?;

let y:String = R!(y)?
    .as_str()
    .ok_or("expected a string reference")?
    .to_string();

rprintln!("The value of x: {}\nThe value of y: {}", x, y);
```

    ## The value of x: 5.3
    ## The value of y: hello

## Chaining chunks together

We may sometimes want to break a block of Rust code into separate
Markdown chunks but treat them as one compile unit. We can do so by
including the code from one chunk into the compile unit of another, by
specifying a `preamble` chunk option. This option takes a character
vector of chunk names, which get included into the compile unit in the
order provided.

Consider this example Markdown code:

```` markdown
Define variable `x`:

```{extendr chunk_x, eval = FALSE}
let x = 1;
```

Define variable `y`:

```{extendr chunk_y, eval = FALSE}
let y = 2;
```

Print:

```{extendr out, preamble = c("chunk_x", "chunk_y")}
rprintln!("x = {}, y = {}", x, y);
```
````

It produces the following output.

Define variable `x`:

``` rust
let x = 1;
```

Define variable `y`:

``` rust
let y = 2;
```

Print:

``` rust
rprintln!("x = {}, y = {}", x, y);
```

    ## x = 1, y = 2

## Exporting Rust functions or objects to R

The chunk type `extendrsrc` compiles Rust functions and objects and
registers them with R to be called later. For example, consider this
code chunk. It creates R functions `hello()` and `foo()`, as well as a
class called `Counter`.

```` markdown
```{extendrsrc}
#[extendr]
fn hello() -> &'static str {
    "Hello from Rust!"
}

#[extendr]
fn foo(a: &str, b: i64) {
    rprintln!("Data sent to Rust: {}, {}", a, b);
}

#[extendr]
struct Counter {
    n: i32,
}

#[extendr]
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
}
```
````

The only output the chunk itself creates is the Rust source code:

``` rust
#[extendr]
fn hello() -> &'static str {
    "Hello from Rust!"
}

#[extendr]
fn foo(a: &str, b: i64) {
    rprintln!("Data sent to Rust: {}, {}", a, b);
}

#[extendr]
struct Counter {
    n: i32,
}

#[extendr]
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
}
```

However, now we can call the functions `hello()` and `foo()` from R and
use the `Counter` object:

``` r
out <- hello()
out
```

    ## [1] "Hello from Rust!"

``` r
foo(out, nchar(out))
```

    ## Data sent to Rust: Hello from Rust!, 16

``` r
x <- Counter$new()
x$get()
```

    ## [1] 0

``` r
x$increment()
x$increment()
x$get()
```

    ## [1] 2

If your code requires external crates, you can set dependencies via the
`engine.opts` chunk option, like so:

```` markdown
```{extendrsrc engine.opts = list(dependencies = list(`pulldown-cmark` = "0.8"))}
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
````

As before, the Rust code chunk just outputs the source:

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

And the generated functions can be used from R:

``` r
md_text <- "# The story of the fox
The quick brown fox **jumps over** the lazy dog.
The quick *brown fox* jumps over the lazy dog."

md_to_html(md_text)
```

    ## [1] "<h1>The story of the fox</h1>\n<p>The quick brown fox <strong>jumps over</strong> the lazy dog.\nThe quick <em>brown fox</em> jumps over the lazy dog.</p>\n"

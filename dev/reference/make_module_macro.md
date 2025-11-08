# Generate extendr module macro for Rust source

Read some Rust source code, find functions or implementations with the
`#[extendr]` attribute, and generate an `extendr_module!` macro
statement.

## Usage

``` r
make_module_macro(code, module_name = "rextendr")
```

## Arguments

- code:

  Character vector containing Rust code.

- module_name:

  Module name

## Value

Character vector holding the contents of the generated macro statement.

## Details

This function uses simple regular expressions to do the Rust parsing and
can get confused by valid Rust code. It is only meant as a convenience
for simple use cases. In particular, it cannot currently handle
implementations for generics.

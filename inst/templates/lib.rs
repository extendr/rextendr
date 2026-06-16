use extendr_api::prelude::*;

/// Return string `"Hello world!"` to R.
/// @param name A name to greet.
/// @export
#[extendr]
fn hello(name: String) -> String {
    format!("Hello {name}!")
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod {{{mod_name}}};
    fn hello;
}

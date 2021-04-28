// We need to forward routine registration from C to Rust
// to avoid the linker removing the static library.

void R_init_{{{pkg_name}}}_extendr(void *dll);

void R_init_{{{pkg_name}}}(void *dll) {
    R_init_{{{pkg_name}}}_extendr(dll);
}

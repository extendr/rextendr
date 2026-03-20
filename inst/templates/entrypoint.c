// We need to forward routine registration from C to Rust
// to avoid the linker removing the static library.

void R_init_{{{mod_name}}}_extendr(void *dll);
void register_extendr_panic_hook(void);

void R_init_{{{mod_name}}}(void *dll) {
    register_extendr_panic_hook();
    R_init_{{{mod_name}}}_extendr(dll);
}

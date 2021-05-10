# use_extendr() sets up extendr files correctly

    Code
      use_extendr()
    Message <message>
      v Creating 'src/rust/src'.
      v Writing 'src/entrypoint.c'
      v Writing 'src/Makevars'
      v Writing 'src/Makevars.win'
      v Writing 'src/.gitignore'
      v Writing 'src/rust/Cargo.toml'.
      v Writing 'src/rust/src/lib.rs'
      v Writing 'R/extendr-wrappers.R'
      v Finished configuring extendr for package testpkg.
      * Please update the system requirement in 'DESCRIPTION' file.
      * Please run `rextendr::document()` for changes to take effect.

---

    Code
      cat_file("R", "extendr-wrappers.R")
    Output
      #' @docType package
      #' @usage NULL
      #' @useDynLib testpkg, .registration = TRUE
      NULL
      
      #' Return string `"Hello world!"` to R.
      #' @export
      hello_world <- function() .Call(wrap__hello_world)

---

    Code
      cat_file("src", "Makevars")
    Output
      LIBDIR = ./rust/target/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      $(STATLIB):
      	cargo build --lib --release --manifest-path=./rust/Cargo.toml
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target

---

    Code
      cat_file("src", "Makevars.win")
    Output
      TARGET = $(subst 64,x86_64,$(subst 32,i686,$(WIN)))-pc-windows-gnu
      LIBDIR = ./rust/target/$(TARGET)/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg -lws2_32 -ladvapi32 -luserenv
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      $(STATLIB):
      	cargo build --target=$(TARGET) --lib --release --manifest-path=./rust/Cargo.toml
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target

---

    Code
      cat_file("src", "entrypoint.c")
    Output
      // We need to forward routine registration from C to Rust
      // to avoid the linker removing the static library.
      
      void R_init_testpkg_extendr(void *dll);
      
      void R_init_testpkg(void *dll) {
          R_init_testpkg_extendr(dll);
      }

---

    Code
      cat_file("src", "rust", "Cargo.toml")
    Output
      [package]
      name = 'testpkg'
      version = '0.1.0'
      edition = '2018'
      
      [lib]
      crate-type = [ 'staticlib' ]
      
      [dependencies]
      extendr-api = '*'

---

    Code
      cat_file("src", "rust", "src", "lib.rs")
    Output
      use extendr_api::prelude::*;
      
      /// Return string `"Hello world!"` to R.
      /// @export
      #[extendr]
      fn hello_world() -> &'static str {
          "Hello world!"
      }
      
      // Macro to generate exports.
      // This ensures exported functions are registered with R.
      // See corresponding C code in `entrypoint.c`.
      extendr_module! {
          mod testpkg;
          fn hello_world;
      }


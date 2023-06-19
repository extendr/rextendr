# use_extendr() sets up extendr files correctly

    Code
      use_extendr()
    Message
      i First time using rextendr. Upgrading automatically...
      i Setting `Config/rextendr/version` to "0.3.1"
      v Creating 'src/rust/src'.
      v Writing 'src/entrypoint.c'
      v Writing 'src/Makevars'
      v Writing 'src/Makevars.win'
      v Writing 'src/Makevars.ucrt'
      v Writing 'src/.gitignore'
      v Adding '^src/\\.cargo$' to '.Rbuildignore'
      v Writing 'src/rust/Cargo.toml'
      v Writing 'src/rust/src/lib.rs'
      v Writing 'src/testpkg-win.def'
      v Writing 'R/extendr-wrappers.R'
      v Finished configuring extendr for package testpkg.
      * Please update the system requirement in 'DESCRIPTION' file.
      * Please run `rextendr::document()` for changes to take effect.

---

    Code
      cat_file("R", "extendr-wrappers.R")
    Output
      # nolint start
      
      #' @docType package
      #' @usage NULL
      #' @useDynLib testpkg, .registration = TRUE
      NULL
      
      #' Return string `"Hello world!"` to R.
      #' @export
      hello_world <- function() .Call(wrap__hello_world)
      
      # nolint end

---

    Code
      cat_file("src", "Makevars")
    Output
      TARGET_DIR = ./rust/target
      LIBDIR = $(TARGET_DIR)/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      CARGOTMP = $(CURDIR)/.cargo
      
      $(STATLIB):
      	# In some environments, ~/.cargo/bin might not be included in PATH, so we need
      	# to set it here to ensure cargo can be invoked. It is appended to PATH and
      	# therefore is only used if cargo is absent from the user's PATH.
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		export CARGO_HOME=$(CARGOTMP); \
      	fi && \
      		export PATH="$(PATH):$(HOME)/.cargo/bin" && \
      		cargo build --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		rm -Rf $(CARGOTMP) && \
      		rm -Rf $(LIBDIR)/build; \
      	fi
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) rust/target

---

    Code
      cat_file("src", "Makevars.win")
    Output
      TARGET = $(subst 64,x86_64,$(subst 32,i686,$(WIN)))-pc-windows-gnu
      
      TARGET_DIR = ./rust/target
      LIBDIR = $(TARGET_DIR)/$(TARGET)/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg -lws2_32 -ladvapi32 -luserenv -lbcrypt -lntdll
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      CARGOTMP = $(CURDIR)/.cargo
      
      $(STATLIB):
      	mkdir -p $(TARGET_DIR)/libgcc_mock
      	# `rustc` adds `-lgcc_eh` flags to the compiler, but Rtools' GCC doesn't have
      	# `libgcc_eh` due to the compilation settings. So, in order to please the
      	# compiler, we need to add empty `libgcc_eh` to the library search paths.
      	#
      	# For more details, please refer to
      	# https://github.com/r-windows/rtools-packages/blob/2407b23f1e0925bbb20a4162c963600105236318/mingw-w64-gcc/PKGBUILD#L313-L316
      	touch $(TARGET_DIR)/libgcc_mock/libgcc_eh.a
      
      	# CARGO_LINKER is provided in Makevars.ucrt for R >= 4.2
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		export CARGO_HOME=$(CARGOTMP); \
      	fi && \
      		export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="$(CARGO_LINKER)" && \
      		export LIBRARY_PATH="$${LIBRARY_PATH};$(CURDIR)/$(TARGET_DIR)/libgcc_mock" && \
      		cargo build --target=$(TARGET) --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		rm -Rf $(CARGOTMP) && \
      		rm -Rf $(LIBDIR)/build; \
      	fi
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(TARGET_DIR)

---

    Code
      cat_file("src", "Makevars.ucrt")
    Output
      # Rtools42 doesn't have the linker in the location that cargo expects, so we
      # need to overwrite it via configuration.
      CARGO_LINKER = x86_64-w64-mingw32.static.posix-gcc.exe
      
      include Makevars.win

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
      cat_file("src", "testpkg-win.def")
    Output
      EXPORTS
      R_init_testpkg

---

    Code
      cat_file("src", "rust", "Cargo.toml")
    Output
      [package]
      name = 'testpkg'
      version = '0.1.0'
      edition = '2021'
      
      [lib]
      crate-type = [ 'staticlib' ]
      name = 'testpkg'
      
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

# use_extendr() quiet if quiet=TRUE

    Code
      use_extendr(quiet = TRUE)


# use_cran_defaults() modifies and creates files correctly

    Code
      use_extendr()
    Message
      i First time using rextendr. Upgrading automatically...
      i Setting `Config/rextendr/version` to "0.3.1.9000" in the 'DESCRIPTION' file.
      i Setting `SystemRequirements` to "Cargo (rustc package manager)" in the 'DESCRIPTION' file.
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
      * Please run `rextendr::document()` for changes to take effect.

---

    Code
      use_cran_defaults()
    Message
      v Writing 'configure'
      v Writing 'configure.win'
      > File 'src/Makevars' already exists. Skip writing the file.
      > File 'src/Makevars.win' already exists. Skip writing the file.
      v Adding '^src/rust/vendor$' to '.Rbuildignore'
      v Adding 'src/rust/vendor' to '.gitignore'

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
      cat_file("configure")
    Output
      #!/usr/bin/env sh
      
      # https://github.com/eitsupi/prqlr/blob/main/configure
      export PATH="$PATH:$HOME/.cargo/bin"
      
      if [ ! "$(command -v cargo)" ]; then
          echo "----------------------- [RUST NOT FOUND]---------------------------"
          echo "The 'cargo' command was not found on the PATH. Please install rustc"
          echo "from: https://www.rust-lang.org/tools/install"
          echo ""
          echo "Alternatively, you may install cargo from your OS package manager:"
          echo " - Debian/Ubuntu: apt-get install cargo"
          echo " - Fedora/CentOS: dnf install cargo"
          echo " - macOS: brew install rustc"
          echo "-------------------------------------------------------------------"
          echo ""
          exit 1
      fi
      
      exit 0

---

    Code
      cat_file("configure.win")
    Output
      #!/bin/sh
      
      # https://github.com/eitsupi/prqlr/blob/main/configure.win
      export PATH="$PATH:$HOME/.cargo/bin"
      
      if [ ! "$(command -v cargo)" ]; then
          echo "----------------------- [RUST NOT FOUND]---------------------------"
          echo "The 'cargo' command was not found on the PATH. Please install rustc"
          echo "from: https://www.rust-lang.org/tools/install"
          echo "-------------------------------------------------------------------"
          echo ""
          exit 1
      fi
      
      exit 0

# use_cran_defaults() quiet if quiet=TRUE

    Code
      use_extendr(quiet = TRUE)
      use_cran_defaults(quiet = TRUE)

# vendor_pkgs() vendors dependencies

    Code
      cat_file("src", "rust", "vendor-config.toml")
    Output
      [source.crates-io]
      replace-with = "vendored-sources"
      
      [source.vendored-sources]
      directory = "vendor"

---

    Code
      package_versions
    Output
      # A tibble: 9 x 2
        crate          version
        <chr>          <chr>  
      1 extendr-api    *.*.*  
      2 extendr-macros *.*.*  
      3 libR-sys       *.*.*  
      4 once_cell      *.*.* 
      5 paste          *.*.* 
      6 proc-macro2    *.*.* 
      7 quote          *.*.* 
      8 syn            *.*.* 
      9 unicode-ident  *.*.* 


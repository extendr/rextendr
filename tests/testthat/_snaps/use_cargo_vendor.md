# use_cargo_vendor() sets up extendr files correctly

    Code
      cat_file("src", "Makevars")
    Output
      TARGET_DIR = ./rust/target
      LIBDIR = $(TARGET_DIR)/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      CRAN_FLAGS=-j 2 --offline
      CARGOTMP = $(CURDIR)/.cargo
      
      $(STATLIB):
      	# In some environments, ~/.cargo/bin might not be included in PATH, so we need
      	# to set it here to ensure cargo can be invoked. It is appended to PATH and
      	# therefore is only used if cargo is absent from the user's PATH.
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		export CARGO_HOME=$(CARGOTMP); \
      	fi && \
      		export PATH="$(PATH):$(HOME)/.cargo/bin" && \
      		if [ -f rust/vendor.tar.xz ]; then tar xf rust/vendor.tar.xz && mkdir -p $(CARGOTMP) && cp rust/vendor-config.toml $(CARGOTMP)/config.toml; fi
      		# To comply with CRAN policy the versions of cargo and rustc
      		# need to be inlcuded in the installation log
      	  echo `cargo --version` && echo `rustc --version`
      		cargo build $(CRAN_FLAGS) --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		rm -Rf $(CARGOTMP) vendor && \
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
      
      CRAN_FLAGS=-j 2 --offline
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
      	  echo `cargo --version` && echo `rustc --version`
      	  tar xf rust/vendor.tar.xz && mkdir -p $(CARGOTMP) && cp rust/vendor-config.toml $(CARGOTMP)/config.toml
      		export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="$(CARGO_LINKER)" && \
      		export LIBRARY_PATH="$${LIBRARY_PATH};$(CURDIR)/$(TARGET_DIR)/libgcc_mock" && \
      		cargo build $(CRAN_FLAGS) --target=$(TARGET) --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
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
      cat_file(".gitignore")
    Output
      src/rust/vendor

---

    Code
      cat_file(".Rbuildignore")
    Output
      ^src/\.cargo$
      ^src/rust/vendor$

---

    Code
      cat_file("src", "rust", "vendor-config.toml")
    Output
      [source.crates-io]
      replace-with = "vendored-sources"
      
      [source.vendored-sources]
      directory = "vendor"

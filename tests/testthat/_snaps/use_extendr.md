# use_extendr() sets up extendr files correctly

    Code
      cat_file(".gitignore")
    Output
      src/rust/vendor
      src/Makevars
      src/Makevars.win

---

    Code
      cat_file(".Rbuildignore")
    Output
      ^src/\.cargo$
      ^src/rust/vendor$
      ^src/Makevars$
      ^src/Makevars\.win$

---

    Code
      cat_file("configure")
    Output
      #!/usr/bin/env sh
      : "${R_HOME=`R RHOME`}"
      "${R_HOME}/bin/Rscript" tools/msrv.R 
      
      # Set CRAN_FLAGS based on the NOT_CRAN value
      if [ "${NOT_CRAN}" != "true" ] && [ -f ./src/rust/vendor.tar.xz ]; then
        export CRAN_FLAGS="-j 2 --offline"
      else
        export CRAN_FLAGS=""
      fi
      
      # delete Makevars if it is present
      [ -f src/Makevars ] && rm src/Makevars
      
      # Substitute @CRAN_FLAGS@ in Makevars.in with the actual value of $CRAN_FLAGS
      sed -e "s|@CRAN_FLAGS@|$CRAN_FLAGS|" src/Makevars.in > src/Makevars

---

    Code
      cat_file("configure.win")
    Output
      #!/usr/bin/env sh
      "${R_HOME}/bin${R_ARCH_BIN}/Rscript.exe" tools/msrv.R
      
      # Set CRAN_FLAGS based on the NOT_CRAN value
      if [ "${NOT_CRAN}" != "true" ] && [ -f ./src/rust/vendor.tar.xz ]; then
        export CRAN_FLAGS="-j 2 --offline"
      else
        export CRAN_FLAGS=""
      fi
      
      # delete Makevars.win if it is present
      [ -f src/Makevars.win ] && rm src/Makevars.win
      
      # Substitute @CRAN_FLAGS@ in Makevars.in with the actual value of $CRAN_FLAGS
      sed -e "s|@CRAN_FLAGS@|$CRAN_FLAGS|" src/Makevars.win.in > src/Makevars.win

---

    Code
      cat_file("tools", "msrv.R")
    Output
      # read the DESCRIPTION file
      desc <- read.dcf("DESCRIPTION")
      
      if (!"SystemRequirements" %in% colnames(desc)) {
        fmt <- c(
          "`SystemRequirements` not found in `DESCRIPTION`.",
          "Please specify `SystemRequirements: Cargo (Rust's package manager), rustc`"
        )
        stop(paste(fmt, collapse = "\n"))
      }
      
      # extract system requirements
      sysreqs <- desc[, "SystemRequirements"]
      
      # check that cargo and rustc is found
      if (!grepl("cargo", sysreqs, ignore.case = TRUE)) {
        stop("You must specify `Cargo (Rust's package manager)` in your `SystemRequirements`")
      }
      
      if (!grepl("rustc", sysreqs, ignore.case = TRUE)) {
        stop("You must specify `Cargo (Rust's package manager), rustc` in your `SystemRequirements`")
      }
      
      # split into parts
      parts <- strsplit(sysreqs, ", ")[[1]]
      
      # identify which is the rustc
      rustc_ver <- parts[grepl("rustc", parts)]
      
      # perform checks for the presence of rustc and cargo on the OS
      no_cargo_msg <- c(
        "----------------------- [CARGO NOT FOUND]--------------------------",
        "The 'cargo' command was not found on the PATH. Please install Cargo",
        "from: https://www.rust-lang.org/tools/install",
        "",
        "Alternatively, you may install Cargo from your OS package manager:",
        " - Debian/Ubuntu: apt-get install cargo",
        " - Fedora/CentOS: dnf install cargo",
        " - macOS: brew install rustc",
        "-------------------------------------------------------------------"
      )
      
      no_rustc_msg <- c(
        "----------------------- [RUST NOT FOUND]---------------------------",
        "The 'rustc' compiler was not found on the PATH. Please install",
        paste(rustc_ver, "or higher from:"),
        "https://www.rust-lang.org/tools/install",
        "",
        "Alternatively, you may install Rust from your OS package manager:",
        " - Debian/Ubuntu: apt-get install rustc",
        " - Fedora/CentOS: dnf install rustc",
        " - macOS: brew install rustc",
        "-------------------------------------------------------------------"
      )
      
      # Add {user}/.cargo/bin to path before checking
      new_path <- paste0(
        Sys.getenv("PATH"),
        ":",
        paste0(Sys.getenv("HOME"), "/.cargo/bin")
      )
      
      # set the path with the new path
      Sys.setenv("PATH" = new_path)
      
      # check for rustc installation
      rustc_version <- tryCatch(
        system("rustc --version", intern = TRUE),
        error = function(e) {
          stop(paste(no_rustc_msg, collapse = "\n"))
        }
      )
      
      # check for cargo installation
      cargo_version <- tryCatch(
        system("cargo --version", intern = TRUE),
        error = function(e) {
          stop(paste(no_cargo_msg, collapse = "\n"))
        }
      )
      
      # helper function to extract versions
      extract_semver <- function(ver) {
        if (grepl("\\d+\\.\\d+(\\.\\d+)?", ver)) {
          sub(".*?(\\d+\\.\\d+(\\.\\d+)?).*", "\\1", ver)
        } else {
          NA
        }
      }
      
      # get the MSRV
      msrv <- extract_semver(rustc_ver)
      
      # extract current version
      current_rust_version <- extract_semver(rustc_version)
      
      # perform check
      if (!is.na(msrv)) {
        # -1 when current version is later
        # 0 when they are the same
        # 1 when MSRV is newer than current
        is_msrv <- utils::compareVersion(msrv, current_rust_version)
        if (is_msrv == 1) {
          fmt <- paste0(
            "\n------------------ [UNSUPPORTED RUST VERSION]------------------\n",
            "- Minimum supported Rust version is %s.\n",
            "- Installed Rust version is %s.\n",
            "---------------------------------------------------------------"
          )
          stop(sprintf(fmt, msrv, current_rust_version))
        }
      }
      
      # print the versions
      versions_fmt <- "Using %s\nUsing %s"
      message(sprintf(versions_fmt, cargo_version, rustc_version))

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
      cat_file("src", ".gitignore")
    Output
      *.o
      *.so
      *.dll
      target
      .cargo

---

    Code
      cat_file("src", "Makevars.in")
    Output
      TARGET_DIR = ./rust/target
      LIBDIR = $(TARGET_DIR)/release
      STATLIB = $(LIBDIR)/libtestpkg.a
      PKG_LIBS = -L$(LIBDIR) -ltestpkg
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      CARGOTMP = $(CURDIR)/.cargo
      VENDOR_DIR = $(CURDIR)/vendor
      
      
      # RUSTFLAGS appends --print=native-static-libs to ensure that 
      # the correct linkers are used. Use this for debugging if need. 
      #
      # CRAN note: Cargo and Rustc versions are reported during
      # configure via tools/msrv.R.
      #
      # When the NOT_CRAN flag is *not* set, the vendor.tar.xz, if present,
      # is unzipped and used for offline compilation.
      $(STATLIB):
      
      	# Check if NOT_CRAN is false and unzip vendor.tar.xz if so
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		if [ -f ./rust/vendor.tar.xz ]; then \
      			tar xf rust/vendor.tar.xz && \
      			mkdir -p $(CARGOTMP) && \
      			cp rust/vendor-config.toml $(CARGOTMP)/config.toml; \
      		fi; \
      	fi
      
      	export CARGO_HOME=$(CARGOTMP) && \
      	export PATH="$(PATH):$(HOME)/.cargo/bin" && \
      	RUSTFLAGS="$(RUSTFLAGS) --print=native-static-libs" cargo build @CRAN_FLAGS@ --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      
      	# Always clean up CARGOTMP
      	rm -Rf $(CARGOTMP);
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(TARGET_DIR) $(VENDOR_DIR)

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
      cat_file("src", "Makevars.win.in")
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
      
      	# When the NOT_CRAN flag is *not* set, the vendor.tar.xz, if present,
      	# is unzipped and used for offline compilation.
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		if [ -f ./rust/vendor.tar.xz ]; then \
      			tar xf rust/vendor.tar.xz && \
      			mkdir -p $(CARGOTMP) && \
      			cp rust/vendor-config.toml $(CARGOTMP)/config.toml; \
      		fi; \
      	fi
      
      	# CARGO_LINKER is provided in Makevars.ucrt for R >= 4.2
      	# Build the project using Cargo with additional flags
      	export CARGO_HOME=$(CARGOTMP) && \
      	export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="$(CARGO_LINKER)" && \
      	export LIBRARY_PATH="$${LIBRARY_PATH};$(CURDIR)/$(TARGET_DIR)/libgcc_mock" && \
      	RUSTFLAGS="$(RUSTFLAGS) --print=native-static-libs" cargo build @CRAN_FLAGS@ --target=$(TARGET) --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      
      	# Always clean up CARGOTMP
      	rm -Rf $(CARGOTMP);
      
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
      publish = false
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

# use_extendr() skip pre-existing files in non-interactive sessions

    Code
      use_extendr()
    Message
      > File 'src/entrypoint.c' already exists. Skip writing the file.
      > File 'src/Makevars.in' already exists. Skip writing the file.
      > File 'src/Makevars.win.in' already exists. Skip writing the file.
      > File 'src/Makevars.ucrt' already exists. Skip writing the file.
      > File 'src/.gitignore' already exists. Skip writing the file.
      > File 'src/rust/Cargo.toml' already exists. Skip writing the file.
      > File 'src/rust/src/lib.rs' already exists. Skip writing the file.
      > File 'src/testpkg.wrap-win.def' already exists. Skip writing the file.
      > File 'R/extendr-wrappers.R' already exists. Skip writing the file.
      > File 'tools/msrv.R' already exists. Skip writing the file.
      > File 'configure' already exists. Skip writing the file.
      > File 'configure.win' already exists. Skip writing the file.
      v Finished configuring extendr for package testpkg.wrap.
      * Please run `rextendr::document()` for changes to take effect.

# use_extendr() can overwrite files in non-interactive sessions

    Code
      use_extendr(crate_name = "foo", lib_name = "bar", overwrite = TRUE)
    Message
      v Writing 'src/entrypoint.c'
      v Writing 'src/Makevars.in'
      v Writing 'src/Makevars.win.in'
      v Writing 'src/Makevars.ucrt'
      v Writing 'src/.gitignore'
      v Writing 'src/rust/Cargo.toml'
      v Writing 'src/rust/src/lib.rs'
      v Writing 'src/testpkg-win.def'
      > File 'R/extendr-wrappers.R' already exists. Skip writing the file.
      v Writing 'tools/msrv.R'
      v Writing 'configure'
      v Writing 'configure.win'
      v Finished configuring extendr for package testpkg.
      * Please run `rextendr::document()` for changes to take effect.

---

    Code
      cat_file("src", "rust", "Cargo.toml")
    Output
      [package]
      name = 'foo'
      publish = false
      version = '0.1.0'
      edition = '2021'
      
      [lib]
      crate-type = [ 'staticlib' ]
      name = 'bar'
      
      [dependencies]
      extendr-api = '*'

# use_rextendr_template() can overwrite existing files

    Code
      cat_file("src", "Makevars.in")
    Output
      TARGET_DIR = ./rust/target
      LIBDIR = $(TARGET_DIR)/release
      STATLIB = $(LIBDIR)/libbar.a
      PKG_LIBS = -L$(LIBDIR) -lbar
      
      all: C_clean
      
      $(SHLIB): $(STATLIB)
      
      CARGOTMP = $(CURDIR)/.cargo
      VENDOR_DIR = $(CURDIR)/vendor
      
      
      # RUSTFLAGS appends --print=native-static-libs to ensure that 
      # the correct linkers are used. Use this for debugging if need. 
      #
      # CRAN note: Cargo and Rustc versions are reported during
      # configure via tools/msrv.R.
      #
      # When the NOT_CRAN flag is *not* set, the vendor.tar.xz, if present,
      # is unzipped and used for offline compilation.
      $(STATLIB):
      
      	# Check if NOT_CRAN is false and unzip vendor.tar.xz if so
      	if [ "$(NOT_CRAN)" != "true" ]; then \
      		if [ -f ./rust/vendor.tar.xz ]; then \
      			tar xf rust/vendor.tar.xz && \
      			mkdir -p $(CARGOTMP) && \
      			cp rust/vendor-config.toml $(CARGOTMP)/config.toml; \
      		fi; \
      	fi
      
      	export CARGO_HOME=$(CARGOTMP) && \
      	export PATH="$(PATH):$(HOME)/.cargo/bin" && \
      	RUSTFLAGS="$(RUSTFLAGS) --print=native-static-libs" cargo build @CRAN_FLAGS@ --lib --release --manifest-path=./rust/Cargo.toml --target-dir $(TARGET_DIR)
      
      	# Always clean up CARGOTMP
      	rm -Rf $(CARGOTMP);
      
      C_clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS)
      
      clean:
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(TARGET_DIR) $(VENDOR_DIR)


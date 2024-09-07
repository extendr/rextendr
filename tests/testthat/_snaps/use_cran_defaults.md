# use_cran_defaults() modifies and creates files correctly

    Code
      use_extendr()
    Message
      i First time using rextendr. Upgrading automatically...
      i Setting `Config/rextendr/version` to "0.3.1.9001" in the 'DESCRIPTION' file.
      i Setting `SystemRequirements` to "Cargo (Rust's package manager), rustc" in the 'DESCRIPTION' file.
      v Creating 'src/rust/src'.
      v Writing 'src/entrypoint.c'
      v Writing 'src/Makevars'
      v Writing 'src/Makevars.win'
      v Writing 'src/Makevars.ucrt'
      v Writing 'src/.gitignore'
      v Adding "^src/\\.cargo$" to '.Rbuildignore'.
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
      v Writing 'tools/msrv.R'
      v Writing 'configure'
      v Writing 'configure.win'
      > File 'src/Makevars' already exists. Skip writing the file.
      > File 'src/Makevars.win' already exists. Skip writing the file.
      v Adding "^src/rust/vendor$" to '.Rbuildignore'.
      v Adding "src/rust/vendor" to '.gitignore'.

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
      	rm -Rf $(SHLIB) $(STATLIB) $(OBJECTS) $(TARGET_DIR)

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
      : "${R_HOME=`R RHOME`}"
      "${R_HOME}/bin/Rscript" tools/msrv.R

---

    Code
      cat_file("configure.win")
    Output
      #!/usr/bin/env sh
      "${R_HOME}/bin${R_ARCH_BIN}/Rscript.exe" tools/msrv.R

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


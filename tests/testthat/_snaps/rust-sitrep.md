# `cargo` or `rustup` are not found

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      x "rustup": not found
      x "cargo": not found
      x Cannot determine host, toolchain, and targets without "rustup"
      x "cargo" is required to build rextendr-powered packages
      i It is recommended to use "rustup" to manage "cargo" and "rustc"
      i See <https://rustup.rs/> for installation instructions

# `cargo` is found, `rustup` is missing

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      x "rustup": not found
      v "cargo": 1.0.0 (0000000 0000-00-00)
      x Cannot determine host, toolchain, and targets without "rustup"
      i It is recommended to use "rustup" to manage "cargo" and "rustc"
      i See <https://rustup.rs/> for installation instructions

# `rustup` is found, `cargo` is missing

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      x "cargo": not found
      i host: arch-pc-os-tool
      i toolchain: stable-arch-pc-os-tool
      i target: arch-pc-os-tool
      x "cargo" is required to build rextendr-powered packages
      i It is recommended to use "rustup" to manage "cargo" and "rustc"
      i See <https://rustup.rs/> for installation instructions

# `cargo` and`rustup` are found

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: arch-pc-os-tool
      i toolchain: stable-arch-pc-os-tool
      i target: arch-pc-os-tool


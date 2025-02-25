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
      i toolchain: stable-arch-pc-os-tool (default)
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
      i toolchain: stable-arch-pc-os-tool (default)
      i target: arch-pc-os-tool

# No toolchains found

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: arch-pc-os-tool
      ! Toolchain stable-arch-pc-os-tool is required to be installed and set as default
      i Run `rustup toolchain install stable-arch-pc-os-tool` to install it
      i Run `rustup default stable-arch-pc-os-tool` to make it default

# Wrong toolchain found

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: arch-pc-os-tool
      i toolchain: not-a-valid-toolchain
      ! Toolchain stable-arch-pc-os-tool is required to be installed and set as default
      i Run `rustup toolchain install stable-arch-pc-os-tool` to install it
      i Run `rustup default stable-arch-pc-os-tool` to make it default

# Wrong toolchain is set as default

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: arch-pc-os-tool
      i toolchains: not-a-valid-toolchain (default) and stable-arch-pc-os-tool
      ! This toolchain should be default: stable-arch-pc-os-tool
      i Run e.g. `rustup default stable-arch-pc-os-tool`

# Required target is not available

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: arch-pc-os-tool
      i toolchains: not-a-valid-toolchain and stable-arch-pc-os-tool (default)
      i targets: wrong-target-1 and wrong-target-2
      ! Target required-target is required on this host machine
      i Run `rustup target add required-target` to install it

# Detects host when default toolchain is not set (MacOS)

    Code
      rust_sitrep()
    Message
      Rust infrastructure sitrep:
      v "rustup": 1.0.0 (0000000 0000-00-00)
      v "cargo": 1.0.0 (0000000 0000-00-00)
      i host: aarch64-apple-darwin
      i toolchain: stable-aarch64-apple-darwin
      ! This toolchain should be default: stable-aarch64-apple-darwin
      i Run e.g. `rustup default stable-aarch64-apple-darwin`


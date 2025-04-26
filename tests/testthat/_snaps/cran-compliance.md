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
                  crate version
      1     build-print   *.*.*
      2     extendr-api   *.*.*
      3     extendr-ffi   *.*.*
      4  extendr-macros   *.*.*
      5       once_cell  *.*.*
      6           paste  *.*.*
      7     proc-macro2  *.*.*
      8           quote  *.*.*
      9             syn *.*.*
      10  unicode-ident  *.*.*


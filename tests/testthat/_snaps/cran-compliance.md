# vendor_crates() vendors dependencies

    Code
      cat_file("src", "rust", "vendor-config.toml")
    Output
      [source.crates-io]
      replace-with = "vendored-sources"
      
      [source."git+https://github.com/extendr/extendr"]
      git = "https://github.com/extendr/extendr"
      replace-with = "vendored-sources"
      
      [source.vendored-sources]
      directory = "vendor"

---

    Code
      package_versions
    Output
                  crate version
      1     extendr-api   *.*.*
      2     extendr-ffi   *.*.*
      3  extendr-macros   *.*.*
      4     lazy_static   *.*.*
      5       once_cell  *.*.*
      6           paste  *.*.*
      7     proc-macro2 *.*.*
      8           quote  *.*.*
      9        readonly  *.*.*
      10            syn *.*.*
      11  unicode-ident  *.*.*


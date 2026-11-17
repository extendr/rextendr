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

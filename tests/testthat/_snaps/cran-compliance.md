# vendor_pkgs() vendors dependencies

    Code
      cat_file("src", "rust", "vendor-config.toml")
    Output
      [source.crates-io]
      replace-with = "vendored-sources"
      
      [source.vendored-sources]
      directory = "vendor"


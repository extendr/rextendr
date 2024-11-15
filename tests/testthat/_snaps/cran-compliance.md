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


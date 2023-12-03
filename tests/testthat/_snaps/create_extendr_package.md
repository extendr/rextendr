# create_extendr_package() creates an extendr package project correctly

    Code
      rextendr:::create_extendr_package(path = dir, roxygen = TRUE, check_name = TRUE,
        edition = "2021")
    Message
      v Setting active project to 'TEMPORARY_PACKAGE_PATH'
      v Creating 'R/'
      v Writing 'DESCRIPTION'
    Output
      Package: testCreateExtendrPackage
      Title: What the Package Does (One Line, Title Case)
      Version: 0.0.0.9000
      Authors@R (parsed):
          * First Last <first.last@example.com> [aut, cre] (YOUR-ORCID-ID)
      Description: What the package does (one paragraph).
      License: `use_mit_license()`, `use_gpl3_license()` or friends to pick a
          license
      Encoding: UTF-8
      Roxygen: list(markdown = TRUE)
      RoxygenNote: 7.2.3
    Message
      v Writing 'NAMESPACE'
      v Writing 'testCreateExtendrPackage.Rproj'
      v Adding '^testCreateExtendrPackage\\.Rproj$' to '.Rbuildignore'
      v Adding '.Rproj.user' to '.gitignore'
      v Adding '^\\.Rproj\\.user$' to '.Rbuildignore'
      v Setting active project to '<no active project>'
      v Setting active project to 'TEMPORARY_PACKAGE_PATH'
      v Adding '^src/\\.cargo$' to '.Rbuildignore'

---

    Code
      cat_file("INDEX")
    Output
      Package: testCreateExtendrPackage
      
      BUILD COMPLETE:
      The project build successfully generated the necessary R package files.
      
      NOTE:
      To use {rextendr} in any meaningful way, the user must have
      Rust and Cargo available on their local machine. To check that you do,
      please run `rextendr::rust_sitrep()`. This will provide a
      detailed report of the current state of your Rust infrastructure, along
      with some helpful advice about how to address any issues that may arise.


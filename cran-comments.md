## R CMD check results
0 errors ✔ | 0 warnings ✔ | 1 note ✖

*  Found the following (possibly) invalid URLs:
    URL: https://crates.io/crates/cargo-license
      From: man/write_license_note.Rd
      Status: 404
      Message: Not Found

This url is valid, but it returns 404 if no Accept header is specified, which is what happens when it is automatically scanned.
See https://github.com/rust-lang/crates.io/issues/788 for details.

* Patch release is needed to fix the bundled template incompatible with the new Rust 1.70 version, which was released on June 1st, 2023.
  See https://github.com/extendr/extendr/issues/559 for relevant discussion.

## revdepcheck results

We checked 0 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages

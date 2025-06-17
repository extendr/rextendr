## Remarks on the previous version

`rextendr` version `0.4.0` was submitted to CRAN but failed to pass some checks due to a complex testing suite, which is designed to support development process via GitHub Actions CI. We adjusted our tests to ensure that the package is CRAN-compliant.

## revdepcheck results

We checked 1 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages

 * Note from developers: The package `tergo` was subjected to revdep check, however the check was inconclusive. The process was manually interrupted after 30 minutes without producing a definitive result. According to [CRAN](https://cran.r-project.org/web/packages/tergo/index.html), `tergo` has `rextendr` (this package) pinned to version `0.3.1`, so releasing new version of `rextendr` should not cause any regressions in `tergo`.
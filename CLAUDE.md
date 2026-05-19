# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in the `extendr/rextendr` repository.

## Branch convention — work on `main-claude`, not `main`

This local clone uses a long-lived branch called **`main-claude`** as Claude's working trunk. Treat it the way you'd normally treat `origin/main`:

- **All Claude-authored commits land on `main-claude`** (or on feature branches forked from `main-claude`). Never commit directly to `main`.
- `main` stays in lockstep with `origin/main` (the real `extendr/rextendr` upstream). It's only updated by `git pull` (or `git fetch && git merge --ff-only`) — Claude does not touch it.
- **Feature branches that will become PRs MUST be forked from `main` (not `main-claude`)**, or rebased onto `origin/main` before they are pushed. `main-claude` holds scratch state (this `CLAUDE.md`, throwaway notes, in-progress tooling) that must NOT appear in proposed upstream PRs.
- Before opening or updating a PR, verify with `git log --oneline origin/main..HEAD` — every commit listed must be one you intended to propose. If `CLAUDE.md` or other helper commits show up, rebase onto `origin/main` with `git rebase --onto origin/main main-claude <branch>`.
- To resync: `git switch main && git pull --ff-only && git switch main-claude && git merge main` (fast-forward where possible; otherwise rebase deliberately). Resolve any conflicts on `main-claude`.
- If `git status` reports the current branch is `main`, switch back before doing any work: `git switch main-claude`.

This separation exists so Claude's experimental commits, scratch notes, and tooling files can accumulate without contaminating the upstream-tracking branch — and so they never accidentally land in a PR.

## What this package is

`{rextendr}` is the R-side companion to [`extendr`](https://github.com/extendr/extendr) (the Rust crates). It scaffolds, compiles, and loads Rust code inside R packages and ad-hoc R sessions. Two surfaces:

- **Package scaffolding** — `use_extendr()` / `update_scaffold()` write `src/Makevars(.in|.win.in)`, `src/entrypoint.c`, `src/rust/Cargo.toml`, `src/rust/src/lib.rs`, `configure`, `tools/msrv.R`, the wrapper-generation glue (`src/rust/document.c`, `src/rust/document.R`), and assorted `.gitignore`/`.Rbuildignore` entries. Templates live in `inst/templates/` and are rendered via `{whisker}`-style `{{{lib_name}}}` interpolation.
- **Ad-hoc Rust eval** — `rust_source()` / `rust_function()` build a transient Rust crate, compile it via `cargo`, and `dyn.load()` the resulting library. `rust_eval()` returns `extendr_api::error::Result<Robj>` since the wrapper-generation overhaul.

The sibling `../tests/extendrtests/` (in the extendr workspace) is the integration test for the scaffolding path: changes to `inst/templates/` MUST be exercised by re-running `use_extendr()` and `R CMD check` against extendrtests, or by running this package's snapshot tests.

## Repository layout

- `R/` — exported and internal functions. Key files:
  - `use_extendr.R` — top-level scaffolding entry point; orchestrates template rendering, DESCRIPTION updates, gitignore wiring.
  - `update_scaffold.R` — re-runs the scaffolding-overwrite path on an existing package.
  - `eval.R`, `find_extendr.R`, `find_exports.R` — `rust_source()` / `rust_function()` machinery.
  - `cran-compliance.R` — `vendor_crates()` (formerly `vendor_pkgs()`); produces `src/rust/vendor.tar.xz` for offline-buildable packages.
  - `clean.R` — sweeps `src/rust/target/`, `src/rust/vendor/`, `.cargo/` from packages.
  - `helpers.r`, `generate_toml.R`, `features.R`, `badge.R` — small utilities.
- `inst/templates/` — text templates rendered into user packages. The Makevars templates use `@LIBDIR@`, `@PANIC_EXPORTS@`, `@PROFILE@`, `@TARGET@`, `@CRAN_FLAGS@`, `@CLEAN_TARGET@` substitutions filled in at `configure` time by `tools/config.R`.
- `tests/testthat/` — snapshot tests are the primary check that template output stays stable. Snapshot files in `tests/testthat/_snaps/` are git-tracked.

## Common commands

The `justfile` is short — most workflows use `devtools` directly:

- `just test` — `devtools::test()`. Snapshot mismatches are FAIL, not WARN.
- `just check` — `devtools::check()`.
- `just doc` — `devtools::document()`.
- `just update-snaps` — `testthat::snapshot_accept()`. Use after intentional template changes.
- `just lint` / `just lint-fix` — `jarl check R/`.
- `just fmt` — `air format R/`.

Snapshot tests skip on CRAN; to surface drift locally set `NOT_CRAN=true`:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-use_extendr.R")'
```

After accepting snapshots, re-run the test file to confirm zero drift.

## Coupling with the extendr Rust workspace

`{rextendr}` lives at `.rextendr/` inside the extendr-claude super-checkout. The extendr-side `tests/extendrtests/` integration package is rebuilt against the local `{rextendr}` via `devtools::load_all("../../rextendr")` in `just document` (run from the extendr workspace).

When changing wrapper-generation templates (`document.c`, `document.R`, `Makevars(.win).in`), you usually need parallel edits in `tests/extendrtests/src/` of the extendr repo so the integration check picks up the new wiring. The two should stay in sync modulo `{{{lib_name}}}` / `{{{mod_name}}}` substitution.

## Conventions

- Use `usethis::` helpers where the upstream codebase already does; do not introduce a parallel mechanism.
- Templates render `lib_name`, `crate_name`, `pkg_name`, `mod_name` — they may differ when an R package name contains dots (R) but Rust crates need underscores. `use_extendr()` normalizes.
- `use_extendr()` is non-interactive by default in CI but interactive in `usethis`'s default. Tests force `overwrite = TRUE` or use `local_package()` fixtures to stay deterministic.
- Skip CRAN via `skip_on_cran()` for tests that compile, run `R CMD check`, or hit the network.

# This retrieves expressions that represent
# default arguments of rust_source,
# which are used for reference.
rust_source_defaults <- formals(rust_source)

# Toolchain is a string, so can be read as is
toolchain <- Sys.getenv("REXTENDR_TOOLCHAIN")
if (!is.null(toolchain) && nzchar(toolchain)) {
  rust_source_defaults$toolchain <- toolchain
  message(paste0(">> {rextendr}: Using toolchain from 'REXTENDR_TOOLCHAIN': ", toolchain))
}

# Patch is represented as vector of character.
# In environment variable different crates are separated using ';'
# E.g., "extendr-api = { git = \"https://github.com/extendr/extendr\" };extendr-macros = { git = \"https://github.com/extendr/extendr\" }"
patch <- Sys.getenv("REXTENDR_PATCH_CRATES_IO")
if (!is.null(patch) && nzchar(patch)) {
  rust_source_defaults$patch.crates_io <- strsplit(patch, ";")[[1]]
  message(paste0(">> {rextendr}: Using cargo patch from 'REXTENDR_PATCH_CRATES_IO': ", patch))
}# else {
#  # Patch should be evaluated because it can be represented as a vector
#  rust_source_defaults$patch.crates_io <- eval(rust_source_defaults$patch.crates_io)
#}

# overwrite formals for testthat run
formals(rust_source) <- rust_source_defaults

# Toolchain is a string, so can be read as is
toolchain <- Sys.getenv("REXTENDR_TOOLCHAIN")
if (!is.null(toolchain) && nzchar(toolchain)) {
  options(rextendr.toolchain = toolchain)
  message(paste0(">> {rextendr}: Using toolchain from 'REXTENDR_TOOLCHAIN': ", toolchain))
}

# Patch is represented as vector of character.
# In environment variable different crates are separated using ';'
# E.g., "extendr-api = { git = \"https://github.com/extendr/extendr\" };extendr-macros = { git = \"https://github.com/extendr/extendr\" }"
patch <- Sys.getenv("REXTENDR_PATCH_CRATES_IO")
if (!is.null(patch) && nzchar(patch)) {
  options(rextendr.patch.crates_io = strsplit(patch, ";")[[1]])
  message(paste0(">> {rextendr}: Using cargo patch from 'REXTENDR_PATCH_CRATES_IO': ", patch))
}

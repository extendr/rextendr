# Toolchain is a string, so can be read as is
toolchain <- Sys.getenv("REXTENDR_TOOLCHAIN")
if (!is.null(toolchain) && nzchar(toolchain)) {
  options(rextendr.toolchain = toolchain)
  message(
    paste0(
      ">> {rextendr}: Using toolchain from 'REXTENDR_TOOLCHAIN': ",
      toolchain
    )
  )
}

# Patch is represented as vector of character.
# In environment variable different crates are separated using ';'
# E.g., "extendr-api = { path = "/local/path" };extendr-macros =
# { git = \"https://github.com/extendr/extendr\" }"
patch <- Sys.getenv("REXTENDR_PATCH_CRATES_IO")
if (!is.null(patch) && nzchar(patch)) {
  patch_val <- gsub(
    "([a-zA-Z0-9_\\-\\.]+)(?=\\s*=)", "`\\1`",
    patch,
    perl = TRUE
  )
  patch_val <- gsub("\\{", "list(", patch_val)
  patch_val <- gsub("\\}", ")", patch_val)
  patch_val <- gsub(";", ", ", patch_val)
  patch_expr <- parse(text = paste0("list(", patch_val, ")"))

  options(rextendr.patch.crates_io = eval(patch_expr))
  message(
    paste0(
      ">> {rextendr}: Using cargo patch from 'REXTENDR_PATCH_CRATES_IO': ",
      patch
    )
  )
}

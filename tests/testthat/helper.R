expect_rextendr_error <- function(...) {
  expect_error(..., class = "rextendr_error")
}

local_temp_dir <- function(envir = parent.frame()) {
  current_wd <- getwd()
  path <- tempfile()
  dir.create(path)

  setwd(path)

  withr::defer(
    {
      setwd(current_wd)
      usethis::proj_set(NULL)
      unlink(path)
    },
    envir = envir
  )

  invisible(path)
}

local_proj_set <- function(envir = parent.frame()) {
  old_proj <- usethis::proj_set(getwd(), force = TRUE)
  withr::defer(usethis::proj_set(old_proj), envir = envir)
}

local_package <- function(nm, envir = parent.frame()) {
  local_temp_dir(envir = envir)
  dir <- usethis::create_package(nm)
  setwd(dir)
  local_proj_set(envir = envir)

  invisible(dir)
}

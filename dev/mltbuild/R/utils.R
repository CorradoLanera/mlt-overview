# Small shared helpers for the mltbuild engine.

# NULL-coalescing: return x unless it is NULL, else y. (Base R exports %||% since
# 4.4, but we define it explicitly so the engine is self-contained and version-stable.)
`%||%` <- function(x, y) if (is.null(x)) y else x

# Workshop library path for the given R version: renv/library/windows/R-<maj.min>/x86_64-w64-mingw32.
wlib_path <- function(workshop, r_version) {
  rv <- paste(strsplit(r_version, ".", fixed = TRUE)[[1]][1:2], collapse = ".")  # "4.6.0" -> "4.6"
  file.path(workshop, "renv", "library", "windows", paste0("R-", rv), "x86_64-w64-mingw32")
}

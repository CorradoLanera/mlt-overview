# Small shared helpers for the mltbuild engine.

# NULL-coalescing: return x unless it is NULL, else y. (Base R exports %||% since
# 4.4, but we define it explicitly so the engine is self-contained and version-stable.)
`%||%` <- function(x, y) if (is.null(x)) y else x

# Workshop library path for the given R version: renv/library/windows/R-<maj.min>/x86_64-w64-mingw32.
wlib_path <- function(workshop, r_version) {
  rv <- paste(strsplit(r_version, ".", fixed = TRUE)[[1]][1:2], collapse = ".")  # "4.6.0" -> "4.6"
  file.path(workshop, "renv", "library", "windows", paste0("R-", rv), "x86_64-w64-mingw32")
}

# Slice the text strictly between the first `start` and the first `end` marker (both literal).
# Returns NA when either marker is absent. Used to lift a rendered report's body out of its
# Quarto chrome for embedding in the transform-terminal teacher wrapper.
.extract_between <- function(text, start, end) {
  s <- regexpr(start, text, fixed = TRUE)
  e <- regexpr(end, text, fixed = TRUE)
  if (s == -1L || e == -1L) return(NA_character_)
  substr(text, s + attr(s, "match.length"), e - 1L)
}

# Small shared helpers for the mltbuild engine.

# NULL-coalescing: return x unless it is NULL, else y. (Base R exports %||% since
# 4.4, but we define it explicitly so the engine is self-contained and version-stable.)
`%||%` <- function(x, y) if (is.null(x)) y else x

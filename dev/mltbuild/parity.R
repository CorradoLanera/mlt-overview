# Structural parity: each generated _solved/<step>.html renders the expected KINDS of output.
# Expectations are read per-step from meta$check (workshop-agnostic). Numbers are NOT pinned.
# Run: Rscript dev/mltbuild/parity.R workshops/<slug>
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 1L)
workshop <- args[[1]]
self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- dirname(self)
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
wk     <- read_workshop(file.path(workshop, "_authoring"))
checks <- parity_checks(wk)

fails <- character(0)
for (slug in names(checks)) {
  f <- file.path(workshop, "_solved", paste0(slug, ".html"))
  if (!file.exists(f)) { fails <- c(fails, paste0(slug, " - HTML not produced")); next }
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  for (k in checks[[slug]]$kw) {
    if (!grepl(k, html, fixed = TRUE)) fails <- c(fails, paste0(slug, " - missing: ", k))
  }
  nimg <- length(gregexpr("<img", html, fixed = TRUE)[[1]])
  if (gregexpr("<img", html, fixed = TRUE)[[1]][1] == -1L) nimg <- 0L
  if (nimg < checks[[slug]]$imgs) {
    fails <- c(fails, paste0(slug, " - expected >=", checks[[slug]]$imgs, " plots, found ", nimg))
  }
}
if (length(fails)) {
  cat("STRUCTURAL PARITY FAIL\n", paste(fails, collapse = "\n"), "\n"); quit(status = 1L)
}
cat("STRUCTURAL PARITY OK - every step renders the expected outputs.\n")

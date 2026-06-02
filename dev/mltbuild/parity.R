# Structural parity: each generated _solved/<step>.html renders the expected KINDS
# of output. Numbers are NOT pinned (the workshop teaches a method; seeds / renv /
# targets / torch legitimately vary). Run: Rscript dev/mltbuild/parity.R workshops/mlt-r-basic
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
workshop <- args[[1]]

# Per-step expectations: kw = substrings that MUST appear (in code echo or output);
# imgs = minimum number of embedded plots (<img ...>).
checks <- list(
  "00-setup"    = list(kw = c("panel-tabset", "To fill", "Solved", "dim"),        imgs = 0L),
  "01-import"   = list(kw = c("outcome", "died", "survived", "glimpse"),          imgs = 0L),
  "02-eda"      = list(kw = c("ejection_fraction", "tbl_summary"),                imgs = 1L),
  "03-logistic" = list(kw = c("roc_auc", "pr_auc", "augment"),                    imgs = 0L),
  "04-zoo"      = list(kw = c("penlog", "knn", "svm", "rf", "accuracy", "last_fit"), imgs = 2L),
  "05-report"   = list(kw = c("Random forest", "roc_auc", "Reproducibility"),     imgs = 2L)
)

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

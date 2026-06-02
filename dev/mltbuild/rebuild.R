# Rebuild (materialize + per-step locks + render) and structurally gate every workshop
# that has an _authoring/ source. One command to remember instead of the per-workshop incantation.
#
# Usage (from repo root, R 4.6):
#   Rscript dev/mltbuild/rebuild.R                       # ALL workshops with _authoring/workshop.yml
#   Rscript dev/mltbuild/rebuild.R mlt-r-basic [slug...] # only the named workshop slug(s)
args <- commandArgs(trailingOnly = TRUE)
self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
here <- dirname(self)                                   # dev/mltbuild
rscript <- file.path(R.home("bin"),
                     if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")

workshops <- if (length(args)) {
  file.path("workshops", args)
} else {
  sort(dirname(dirname(Sys.glob(file.path("workshops", "*", "_authoring", "workshop.yml")))))
}
if (!length(workshops)) stop("no workshops found (need <workshop>/_authoring/workshop.yml)")

run <- function(script, ws) system2(rscript, c(file.path(here, script), ws))

failed <- character(0)
for (ws in workshops) {
  cat("\n========== ", ws, " ==========\n", sep = "")
  ok <- run("build.R", ws) == 0L && run("parity.R", ws) == 0L
  if (!ok) failed <- c(failed, ws)
}

cat("\n")
if (length(failed)) {
  cat("REBUILD FAILED:", paste(basename(failed), collapse = ", "), "\n")
  quit(status = 1L)
}
cat("REBUILD OK -", length(workshops), "workshop(s) built + parity passed:",
    paste(basename(workshops), collapse = ", "), "\n")

# Parse + materialize a workshop's generated tree from its authoring source.
# Plan-1 stub: writes steps/ + full/ to a TEMP dir and reports it. Real wiring into
# workshops/<slug>/{steps,full} + _solved/ + renv.lock lands in plan 2.
# Usage: Rscript dev/mltbuild/build.R <authoring_dir>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
root <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
wk <- read_workshop(args[[1]])
out <- tempfile("mlt-")
materialize_workshop(wk, out)
cat("built workshop:", wk$slug, "(", length(wk$steps), "steps ) ->", out, "\n")

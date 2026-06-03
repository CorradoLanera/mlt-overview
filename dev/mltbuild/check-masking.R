# Hoist-safety / masking certification. Hoisting all library() calls to the top is only safe if no
# beat uses a function that a LATER-loaded package masks with a different implementation. The only
# definitive test is to run the all-solved analysis (full.R) BOTH ways — library() calls in their
# ORIGINAL interleaved positions vs HOISTED to the top — and confirm the deterministic result
# metrics are identical. (We compare the extracted metric estimates, not raw output, so tuning
# timing/chatter never causes a false mismatch.)
#
# Heavier than the structural parity gate (it runs the tuning twice) — run on demand, e.g. after
# changing package loading or before cutting a release, NOT on every edit.
# Requires the workshop to have been built first (full/ must exist with .here + data-raw/).
#
# Usage: Rscript dev/mltbuild/check-masking.R workshops/<slug>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
workshop <- args[[1]]
root <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)

wk   <- read_workshop(file.path(workshop, "_authoring"))
# Opt-out: a workshop whose full.R cannot be re-run in a bare cert subprocess (e.g. torch's
# Lantern backend, or any non-portable runtime) declares `skip_masking: true`. Hoist-safety is
# then covered by the pkg:: discipline + the adversarial invariant verifier instead of this gate.
if (isTRUE(wk$skip_masking)) {
  cat("MASKING CHECK SKIPPED - workshop declares skip_masking: true (full.R is not cert-subprocess portable).\n")
  quit(status = 0L)
}
wlib <- normalizePath(wlib_path(workshop, wk$r_version), winslash = "/", mustWork = FALSE)
full <- normalizePath(file.path(workshop, "full"), winslash = "/", mustWork = FALSE)
if (!file.exists(file.path(full, ".here"))) stop("build the workshop first (no full/.here): ", full)
metas <- lapply(wk$steps, `[[`, "meta")
beats <- lapply(wk$steps, `[[`, "beat")
ab    <- beats[vapply(metas, function(m) identical(m$type, "append"), logical(1))]
interleaved <- strip_frag_markers(.join_beats(lapply(ab, render_beat, mode = "solved")))  # original order
hoisted     <- assemble_full(ab)                                                          # libraries at top
writeLines(interleaved, file.path(full, "_cert-interleaved.R"))
writeLines(hoisted,     file.path(full, "_cert-hoisted.R"))

# A fresh-process runner: source one variant, save the deterministic metrics.
runner <- file.path(full, "_cert-run.R")
writeLines(c(
  "a <- commandArgs(TRUE)",
  sprintf(".libPaths(c(\"%s\", .libPaths()))", wlib),
  sprintf("setwd(\"%s\")", full),
  "pdf(NULL)",
  "e <- new.env()",
  "suppressMessages(suppressWarnings(sys.source(a[1], envir = e)))",
  "m <- as.data.frame(tune::collect_metrics(e$final_fit))[, c(\".metric\", \".estimate\")]",
  "saveRDS(m[order(m$.metric), ], a[2])"
), runner)

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
cert <- function(variant, out) system2(rscript, c(runner, file.path(full, variant), out))
io <- file.path(full, "_cert-int.rds"); ho <- file.path(full, "_cert-hoi.rds")
cert("_cert-interleaved.R", io)
cert("_cert-hoisted.R",     ho)
mi <- readRDS(io); mh <- readRDS(ho)
file.remove(file.path(full, c("_cert-interleaved.R", "_cert-hoisted.R", "_cert-run.R")), io, ho)

cat("INTERLEAVED (library() in original positions):\n"); print(mi)
cat("HOISTED (all library() at top):\n");                print(mh)
if (!isTRUE(all.equal(mi, mh))) {
  cat("\nMASKING CHECK FAIL - hoisting library() changed the result metrics (a masking dependency: a\n",
      "beat uses a function a later package masks differently). Qualify the offending call as pkg::fun.\n", sep = "")
  quit(status = 1L)
}
cat("\nMASKING CHECK OK - hoisting library() is result-preserving (no masking dependency).\n")

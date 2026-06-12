# Build a workshop end-to-end from its _authoring/ source.
# Usage (from repo root, R 4.6):
#   Rscript dev/mltbuild/build.R workshops/mlt-r-basic
# Produces, under <workshop>/: steps/<NN>/{<NN>.R | report.qmd, packages.txt, renv.lock, .here, data-raw/},
# full/, and _solved/<NN>.html (teacher tabs for append; rendered report for transform).
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
workshop  <- normalizePath(args[[1]], winslash = "/")
authoring <- file.path(workshop, "_authoring")
root      <- normalizePath(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))), winslash = "/")
for (f in list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)

# Make quarto's child R see the workshop library (packages are NOT in the global lib).
wk   <- read_workshop(authoring)
wlib <- wlib_path(workshop, wk$r_version)
Sys.setenv(R_LIBS = normalizePath(wlib, winslash = "/"))
.libPaths(c(normalizePath(wlib, winslash = "/"), .libPaths()))
ppm <- paste0("https://packagemanager.posit.co/cran/", wk$ppm_snapshot)

# 1. Steps + full (.R / report.qmd, packages.txt, .here, data-raw)
materialize_workshop(wk, workshop)

# 2. Per-step renv.lock (from inside the project so renv is active)
old <- getwd(); on.exit(setwd(old), add = TRUE)
setwd(workshop); source(file.path("renv", "activate.R"))
metas <- lapply(wk$steps, `[[`, "meta")
for (n in seq_along(wk$steps) - 1L) {
  slug <- wk$steps[[n + 1L]]$slug
  pk   <- packages_for_step(metas, n)
  write_step_lock(file.path(workshop, "steps", slug, "renv.lock"), pk, ppm)
}
# full/ lock = all packages
all_pkgs <- unique(unlist(lapply(metas, function(m) m$packages)))
write_step_lock(file.path(workshop, "full", "renv.lock"), all_pkgs, ppm)
setwd(old)

# 3. Render _solved/ HTML
solved_dir <- file.path(workshop, "_solved"); dir.create(solved_dir, showWarnings = FALSE)
beats <- lapply(wk$steps, `[[`, "beat")
append_beats <- beats[vapply(metas, function(m) identical(m$type, "append"), logical(1))]

render_one <- function(qmd_abs, html_out) {
  quarto::quarto_render(input = qmd_abs, quiet = TRUE)
  produced <- sub("[.]qmd$", ".html", qmd_abs)
  if (!file.exists(produced)) stop("render produced no HTML: ", produced)
  file.copy(produced, html_out, overwrite = TRUE); unlink(produced)
}

ai <- -1L
for (n in seq_along(wk$steps) - 1L) {
  step <- wk$steps[[n + 1L]]; slug <- step$slug
  sdir <- file.path(workshop, "steps", slug)
  dir.create(file.path(sdir, "output"), showWarnings = FALSE)   # for any ggsave in solved
  if (identical(step$meta$type, "transform-terminal")) {
    if (identical(step$meta$engine, "targets")) {
      tdir <- tempfile("tar-solved-"); dir.create(tdir)
      .emit_targets_step(file.path(authoring, slug), tdir, mode = "solved")
      .copy_data_raw(wk$data_raw_dir, tdir)
      old2 <- getwd(); setwd(tdir)
      # The ellmer target runs live: surface OPENAI_API_KEY from the workshop-root .Renviron
      # (gitignored) into this process so the tar_make() callr subprocess inherits it. Missing
      # key -> the pipeline falls back to a labeled example (no fakery shipped as live).
      if (file.exists(file.path(workshop, ".Renviron"))) readRenviron(file.path(workshop, ".Renviron"))
      # Default callr_function: targets runs the DAG analysis + pipeline in a fresh callr
      # subprocess that inherits R_LIBS (set above) -> finds the workshop library. A cold
      # in-process run (callr_function = NULL) hits a spurious is_dag() cycle in targets'
      # static analysis, so we use the standard subprocess path here.
      targets::tar_make()
      setwd(old2)
      produced <- file.path(tdir, "report.html")
      if (!file.exists(produced)) stop("targets pipeline produced no report.html: ", produced)
      # Solution = three tabs: the student `_targets.R`, the solved one, and the pipeline-compiled
      # report. We lift the report body out of its rendered chrome and inject it as raw HTML so the
      # solution stays one self-contained file (and the parity gate sees the plots/keywords here),
      # while report.qmd itself stays a pristine, DAG-wired, student-safe document.
      report_html <- paste(readLines(produced, warn = FALSE), collapse = "\n")
      body <- .extract_between(report_html, "<!--MLT-REPORT-START-->", "<!--MLT-REPORT-END-->")
      if (is.na(body)) stop("report body markers not found in: ", produced)
      auth_targets <- file.path(authoring, slug, "_targets.R")
      blank  <- .render_authored_file(auth_targets, "blank")
      solved <- .render_authored_file(auth_targets, "solved")
      tq <- file.path(tdir, paste0("_teacher-", slug, ".qmd"))
      writeLines(build_targets_teacher_qmd(step$meta$title, blank, solved, body), tq)
      render_one(tq, file.path(solved_dir, paste0(slug, ".html")))
      unlink(tdir, recursive = TRUE)
    } else {
      render_one(file.path(sdir, "report.qmd"), file.path(solved_dir, paste0(slug, ".html")))
    }
  } else {
    ai <- ai + 1L
    blank  <- assemble_step(append_beats, ai)
    solved <- assemble_solved_through(append_beats, ai)
    tq <- file.path(sdir, paste0("_teacher-", slug, ".qmd"))
    writeLines(build_teacher_qmd(step$meta$title, blank, solved), tq)
    render_one(tq, file.path(solved_dir, paste0(slug, ".html")))
    unlink(tq)   # transient: don't leave a teacher artifact in the student step folder
  }
  cat("rendered", slug, "\n")
}
cat("BUILD OK:", wk$slug, "->", workshop, "\n")

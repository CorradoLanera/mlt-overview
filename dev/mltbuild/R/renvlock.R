# Generate one per-step renv.lock = cumulative packages 00..N-1, pinned to PPM.
# Must be called from a process whose getwd() is the workshop project root (so
# renv/activate.R has been sourced and the project library is active).

write_step_lock <- function(lockfile_abs, packages, ppm_url) {
  if (!length(packages)) return(invisible(NULL))   # step 00: no lock
  options(repos = c(CRAN = ppm_url))
  dir.create(dirname(lockfile_abs), recursive = TRUE, showWarnings = FALSE)
  renv::snapshot(lockfile = lockfile_abs, packages = packages, prompt = FALSE)
  invisible(lockfile_abs)
}

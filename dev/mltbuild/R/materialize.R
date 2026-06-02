# Materialize a generated workshop tree (steps/ + full/) from a read_workshop() object.

.write_lines <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.copy_data_raw <- function(authoring_dir, dest_dir) {
  src <- file.path(authoring_dir, "data-raw")
  if (dir.exists(src)) {
    dir.create(file.path(dest_dir, "data-raw"), recursive = TRUE, showWarnings = FALSE)
    file.copy(list.files(src, full.names = TRUE), file.path(dest_dir, "data-raw"),
              recursive = TRUE)
  }
}

materialize_workshop <- function(wk, out_dir) {
  beats <- lapply(wk$steps, `[[`, "beat")
  metas <- lapply(wk$steps, `[[`, "meta")
  # HARDENED: never unlink out_dir itself — it may hold the committed _authoring/ +
  # data-raw/ source-of-truth. Remove ONLY the generated subtrees.
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (sub in c("steps", "full", "_solved")) {
    unlink(file.path(out_dir, sub), recursive = TRUE)
  }

  for (n in seq_along(wk$steps) - 1L) {           # 0-based index
    slug <- wk$steps[[n + 1L]]$slug
    step_dir <- file.path(out_dir, "steps", slug)
    .write_lines(assemble_step(beats, n), file.path(step_dir, paste0(slug, ".R")))
    .write_lines(packages_through(metas, n), file.path(step_dir, "packages.txt"))
    .write_lines(character(0), file.path(step_dir, ".here"))
    .copy_data_raw(wk$authoring_dir, step_dir)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$authoring_dir, full_dir)
  invisible(out_dir)
}

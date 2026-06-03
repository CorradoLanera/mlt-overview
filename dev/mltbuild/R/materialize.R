# Materialize a generated workshop tree (steps/ + full/) from a read_workshop() object.

.write_lines <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.copy_data_raw <- function(data_raw_dir, dest_dir) {
  if (is.na(data_raw_dir) || !dir.exists(data_raw_dir)) return(invisible())
  dir.create(file.path(dest_dir, "data-raw"), recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(data_raw_dir, full.names = TRUE),
            file.path(dest_dir, "data-raw"), recursive = TRUE)
}

materialize_workshop <- function(wk, out_dir) {
  beats <- lapply(wk$steps, `[[`, "beat")
  metas <- lapply(wk$steps, `[[`, "meta")
  frags <- collect_fragments(wk)

  # HARDENED: never unlink out_dir itself — it may hold the committed _authoring/ +
  # data-raw/ source-of-truth. Remove ONLY the generated subtrees.
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (sub in c("steps", "full", "_solved")) {
    unlink(file.path(out_dir, sub), recursive = TRUE)
  }

  append_beats <- beats[vapply(metas, function(m) identical(m$type, "append"), logical(1))]

  for (n in seq_along(wk$steps) - 1L) {           # 0-based
    step  <- wk$steps[[n + 1L]]
    slug  <- step$slug
    sdir  <- file.path(out_dir, "steps", slug)
    if (identical(step$meta$type, "transform-terminal")) {
      .write_lines(render_report(step$template, frags), file.path(sdir, "report.qmd"))
    } else if (identical(step$meta$type, "append")) {
      ai <- sum(vapply(metas[seq_len(n + 1L)], function(m) identical(m$type, "append"), logical(1))) - 1L
      .write_lines(assemble_step(append_beats, ai), file.path(sdir, paste0(slug, ".R")))
    } else {
      stop("unknown step type for '", slug, "': ", step$meta$type)
    }
    pk <- packages_for_step(metas, n)
    .write_lines(pk, file.path(sdir, "packages.txt"))
    .write_lines(character(0), file.path(sdir, ".here"))
    .copy_data_raw(wk$data_raw_dir, sdir)
    # 00-setup has no cumulative packages -> bare .Rproj; all others -> full renv project.
    write_step_project(sdir, wk$renv_dir, with_renv = length(pk) > 0L)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(append_beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$data_raw_dir, full_dir)
  write_step_project(full_dir, wk$renv_dir, with_renv = TRUE)
  invisible(out_dir)
}

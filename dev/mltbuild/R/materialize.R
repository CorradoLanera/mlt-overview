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

.render_authored_file <- function(src, mode) {
  # Parse hole markers in an authored .R/.qmd, render to `mode` (blank|solved), strip frag markers.
  strip_frag_markers(render_beat(parse_beat(readLines(src)), mode = mode))
}

.emit_targets_step <- function(auth_step, dest, mode) {
  # Emit every authored file (except meta.yml): .R/.qmd hole-rendered to `mode`, others copied verbatim.
  base <- normalizePath(auth_step, winslash = "/")
  for (src in list.files(auth_step, recursive = TRUE, full.names = TRUE)) {
    if (basename(src) == "meta.yml") next
    rel <- sub(paste0("^", base, "/?"), "", normalizePath(src, winslash = "/"))
    dst <- file.path(dest, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    if (grepl("[.](R|qmd)$", src)) .write_lines(.render_authored_file(src, mode), dst)
    else                          file.copy(src, dst, overwrite = TRUE)
  }
}

.copy_carry <- function(authoring_dir, metas, upto_n, dest_dir) {
  # Copy every file declared in `carry:` by steps 0..upto_n into dest_dir at the same rel path.
  files <- unique(unlist(lapply(metas[seq_len(upto_n + 1L)], function(m) m$carry %||% character(0))))
  for (rel in files) {
    owner <- which(vapply(metas[seq_len(upto_n + 1L)],
                          function(m) rel %in% (m$carry %||% character(0)), logical(1)))[1]
    src <- file.path(authoring_dir, metas[[owner]]$slug, rel)
    if (!file.exists(src)) stop("carry: file not found: ", src)
    dst <- file.path(dest_dir, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    file.copy(src, dst, overwrite = TRUE)
  }
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
      if (identical(step$meta$engine, "targets")) {
        .emit_targets_step(file.path(wk$authoring_dir, slug), sdir, mode = "blank")
      } else {
        .write_lines(render_report(step$template, frags), file.path(sdir, "report.qmd"))
      }
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
    .copy_carry(wk$authoring_dir, metas, n, sdir)
    # 00-setup has no cumulative packages -> bare .Rproj; all others -> full renv project.
    write_step_project(sdir, wk$renv_dir, with_renv = length(pk) > 0L)
  }

  full_dir <- file.path(out_dir, "full")
  .write_lines(assemble_full(append_beats), file.path(full_dir, "full.R"))
  .write_lines(character(0), file.path(full_dir, ".here"))
  .copy_data_raw(wk$data_raw_dir, full_dir)
  .copy_carry(wk$authoring_dir, metas, length(metas) - 1L, full_dir)
  write_step_project(full_dir, wk$renv_dir, with_renv = TRUE)
  invisible(out_dir)
}

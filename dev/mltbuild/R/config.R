# Load the authoring tree (workshop.yml + per-step meta.yml + beat.R).

read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages <- as.character(m$packages %||% character(0))
  m$type     <- m$type %||% "append"
  m$template <- m$template %||% NULL
  m
}

read_workshop <- function(authoring_dir) {
  wk <- yaml::read_yaml(file.path(authoring_dir, "workshop.yml"))
  steps <- lapply(wk$steps, function(slug) {
    step_dir  <- file.path(authoring_dir, slug)
    meta      <- read_meta(step_dir)
    beat_file <- file.path(step_dir, "beat.R")
    is_xform  <- identical(meta$type, "transform-terminal")
    tmpl_file <- if (is_xform) file.path(step_dir, meta$template %||% "report.qmd") else NA_character_
    list(
      slug     = slug,
      meta     = meta,
      beat     = if (!is_xform && file.exists(beat_file)) parse_beat(readLines(beat_file)) else list(),
      template = if (is_xform) {
        if (!file.exists(tmpl_file))
          stop("transform-terminal step '", slug, "': template not found: ", tmpl_file)
        readLines(tmpl_file)
      } else character(0)
    )
  })
  # data-raw lives under _authoring/data-raw, else at the workshop root (parent of _authoring).
  cand <- c(file.path(authoring_dir, "data-raw"),
            file.path(dirname(authoring_dir), "data-raw"))
  data_raw_dir <- cand[dir.exists(cand)][1]
  list(
    slug = wk$slug, r_version = wk$r_version, ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset, authoring_dir = authoring_dir,
    data_raw_dir = data_raw_dir,
    steps = steps
  )
}

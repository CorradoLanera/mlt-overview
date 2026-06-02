# Load the authoring tree (workshop.yml + per-step meta.yml + beat.R).

read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages <- as.character(m$packages %||% character(0))
  m$type <- m$type %||% "append"
  m
}

read_workshop <- function(authoring_dir) {
  wk <- yaml::read_yaml(file.path(authoring_dir, "workshop.yml"))
  steps <- lapply(wk$steps, function(slug) {
    step_dir <- file.path(authoring_dir, slug)
    beat_file <- file.path(step_dir, "beat.R")
    list(
      slug = slug,
      meta = read_meta(step_dir),
      beat = if (file.exists(beat_file)) parse_beat(readLines(beat_file)) else list()
    )
  })
  list(
    slug = wk$slug,
    r_version = wk$r_version,
    ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset,
    authoring_dir = authoring_dir,
    steps = steps
  )
}

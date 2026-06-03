# Load the authoring tree (workshop.yml + per-step meta.yml + beat.R).

read_meta <- function(step_dir) {
  m <- yaml::read_yaml(file.path(step_dir, "meta.yml"))
  m$packages  <- as.character(m$packages %||% character(0))
  m$type      <- m$type %||% "append"
  m$template  <- m$template %||% NULL
  m$carry     <- as.character(m$carry %||% character(0))
  m$check     <- m$check %||% NULL
  m$engine    <- m$engine %||% NULL
  m$seed_from <- m$seed_from %||% NULL
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
    raw_beat <- if (!is_xform && file.exists(beat_file)) readLines(beat_file) else character(0)
    meta$seeded <- FALSE
    if (!is.null(meta$seed_from)) {
      sf <- sibling_full(authoring_dir, meta$seed_from)
      raw_beat <- c(sf$lines, "", raw_beat)
      meta$packages <- unique(c(sf$packages, meta$packages))
      meta$seeded <- TRUE
    }
    list(
      slug     = slug,
      meta     = meta,
      beat     = if (!is_xform) parse_beat(raw_beat) else list(),
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
  # canonical renv/ (activate.R + settings.json) to seed per-step projects:
  # under the authoring dir (fixtures) or at the workshop root (real layout).
  renv_cand <- c(file.path(authoring_dir, "renv"),
                 file.path(dirname(authoring_dir), "renv"))
  renv_dir <- renv_cand[dir.exists(renv_cand)][1]
  list(
    slug = wk$slug, r_version = wk$r_version, ppm_snapshot = wk$ppm_snapshot,
    dataset = wk$dataset, authoring_dir = authoring_dir,
    data_raw_dir = data_raw_dir, renv_dir = renv_dir,
    steps = steps
  )
}

# Assemble a sibling workshop's full.R (append beats, solved) from its _authoring.
sibling_full <- function(authoring_dir, slug) {
  sib <- file.path(dirname(dirname(authoring_dir)), slug, "_authoring")
  if (!dir.exists(sib)) stop("seed_from: sibling workshop not found: ", sib)
  swk    <- read_workshop(sib)
  smetas <- lapply(swk$steps, `[[`, "meta")
  sbeats <- lapply(swk$steps, `[[`, "beat")
  ab     <- sbeats[vapply(smetas, function(m) identical(m$type, "append"), logical(1))]
  list(
    lines    = assemble_full(ab),
    packages = unique(unlist(lapply(smetas, function(m) m$packages %||% character(0))))
  )
}

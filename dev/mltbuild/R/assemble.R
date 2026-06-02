# Cumulative assembly of beats into step / full scripts.

.join_beats <- function(rendered_list) {
  # rendered_list: list of character vectors; join with one blank line between beats.
  out <- character(0)
  for (k in seq_along(rendered_list)) {
    if (k > 1L) out <- c(out, "")
    out <- c(out, rendered_list[[k]])
  }
  out
}

assemble_step <- function(beats, n) {
  # beats: list of parsed beats (0-indexed conceptually); n: 0-based step index.
  stopifnot(n >= 0, n < length(beats))
  prior   <- if (n >= 1L) lapply(beats[seq_len(n)], render_beat, mode = "solved") else list()
  current <- list(render_beat(beats[[n + 1L]], mode = "blank"))
  strip_frag_markers(.join_beats(c(prior, current)))
}

assemble_full <- function(beats) {
  strip_frag_markers(.join_beats(lapply(beats, render_beat, mode = "solved")))
}

assemble_solved_through <- function(beats, n) {
  # All of beats 0..n rendered SOLVED (teacher "Solved" tab). 0-based n.
  stopifnot(n >= 0, n < length(beats))
  strip_frag_markers(.join_beats(lapply(beats[seq_len(n + 1L)], render_beat, mode = "solved")))
}

packages_through <- function(metas, n) {
  # Lock for step n = union of packages introduced by beats 0..n-1 (the START state).
  stopifnot(n >= 0, n <= length(metas))
  if (n == 0L) return(character(0))
  pk <- unlist(lapply(metas[seq_len(n)], function(m) m$packages %||% character(0)))
  unique(pk %||% character(0))
}

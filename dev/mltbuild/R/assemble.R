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
  prior <- if (n >= 1L) lapply(beats[seq_len(n)], render_beat, mode = "solved") else list()
  current <- list(render_beat(beats[[n + 1L]], mode = "blank"))
  .join_beats(c(prior, current))
}

assemble_full <- function(beats) {
  .join_beats(lapply(beats, render_beat, mode = "solved"))
}

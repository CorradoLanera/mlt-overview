# Named-fragment markers: build-time-only annotations inside beat solved code.
#   # >>>frag id=<id>
#   <canonical solved lines>
#   # <<<frag
# Stripped from every student/teacher/full artifact; sliced by id for the report.

.FRAG_OPEN  <- "^\\s*#\\s*>>>frag\\s+id=([^ ]+)\\s*$"
.FRAG_CLOSE <- "^\\s*#\\s*<<<frag\\s*$"

strip_frag_markers <- function(lines) {
  lines[!grepl(.FRAG_OPEN, lines) & !grepl(.FRAG_CLOSE, lines)]
}

extract_fragment <- function(lines, id) {
  open <- which(grepl(.FRAG_OPEN, lines) & sub(.FRAG_OPEN, "\\1", lines) == id)
  if (!length(open)) stop("fragment id not found: ", id)
  start <- open[[1]]
  close <- which(grepl(.FRAG_CLOSE, lines) & seq_along(lines) > start)
  if (!length(close)) stop("unclosed fragment: ", id)
  lines[(start + 1L):(close[[1]] - 1L)]
}

collect_fragments <- function(wk) {
  frags <- list()
  for (st in wk$steps) {
    if (!length(st$beat)) next                 # transform-terminal steps carry no beat
    solved <- render_beat(st$beat, "solved")   # keeps frag markers
    open   <- grep(.FRAG_OPEN, solved, value = TRUE)
    for (line in open) {
      id <- sub(.FRAG_OPEN, "\\1", line)
      if (!is.null(frags[[id]])) warning("duplicate fragment id: ", id)
      frags[[id]] <- extract_fragment(solved, id)
    }
  }
  frags
}

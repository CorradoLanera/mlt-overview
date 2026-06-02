# Parse / render beat fragments with hole markers. Base R only.

.parse_hole_header <- function(line) {
  rest <- sub("^#\\s*>>>hole\\s+", "", line)
  id     <- sub("^.*\\bid=([^ ]+).*$", "\\1", rest)
  kind   <- if (grepl("\\bkind=", rest)) sub("^.*\\bkind=([^ ]+).*$", "\\1", rest) else "fill"
  prompt <- if (grepl("\\bprompt=", rest)) sub("^.*\\bprompt=(.*)$", "\\1", rest) else ""
  list(id = id, kind = kind, prompt = prompt)
}

parse_beat <- function(lines) {
  segs <- list()
  text_buf <- character(0)
  flush_text <- function() {
    if (length(text_buf)) {
      segs[[length(segs) + 1L]] <<- list(type = "text", lines = text_buf)
      text_buf <<- character(0)
    }
  }
  i <- 1L
  n <- length(lines)
  while (i <= n) {
    line <- lines[[i]]
    if (grepl("^#\\s*>>>hole\\b", line)) {
      flush_text()
      hdr <- .parse_hole_header(line)
      solved <- character(0); blank <- character(0); section <- NA_character_
      i <- i + 1L
      while (i <= n && !grepl("^#\\s*<<<hole\\s*$", lines[[i]])) {
        l <- lines[[i]]
        if (grepl("^#\\s*solved:\\s*$", l)) { section <- "solved" }
        else if (grepl("^#\\s*blank:\\s*$", l)) { section <- "blank" }
        else if (identical(section, "solved")) { solved <- c(solved, l) }
        else if (identical(section, "blank"))  { blank  <- c(blank,  l) }
        i <- i + 1L
      }
      segs[[length(segs) + 1L]] <- list(
        type = "hole", id = hdr$id, kind = hdr$kind, prompt = hdr$prompt,
        solved = solved, blank = blank
      )
      i <- i + 1L  # skip the closing marker
    } else {
      text_buf <- c(text_buf, line)
      i <- i + 1L
    }
  }
  flush_text()
  segs
}

.render_hole <- function(seg, mode) {
  if (identical(mode, "solved")) return(seg$solved)
  # mode == "blank"
  switch(seg$kind,
    fill    = seg$blank,
    prose   = paste0("# TODO: ", seg$prompt),
    parsons = c(paste0("# Reorder the lines to: ", seg$prompt), rev(seg$solved)),
    stop("unknown hole kind: ", seg$kind)
  )
}

render_beat <- function(segments, mode = c("solved", "blank")) {
  mode <- match.arg(mode)
  out <- character(0)
  for (seg in segments) {
    out <- c(out, if (seg$type == "text") seg$lines else .render_hole(seg, mode))
  }
  out
}

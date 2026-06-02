# Substitute {{frag:id}} tokens in a transform-terminal template with the named
# fragment's solved lines (verbatim, preserving the fragment's own indentation).

.FRAG_TOKEN <- "^\\s*\\{\\{frag:([^}]+)\\}\\}\\s*$"

render_report <- function(template_lines, fragments) {
  out <- character(0)
  for (line in template_lines) {
    if (grepl(.FRAG_TOKEN, line)) {
      id <- sub(.FRAG_TOKEN, "\\1", line)
      if (is.null(fragments[[id]])) stop("unknown fragment token in report: ", id)
      out <- c(out, fragments[[id]])
    } else {
      out <- c(out, line)
    }
  }
  out
}

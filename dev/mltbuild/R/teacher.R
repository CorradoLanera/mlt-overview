# Build the per-step teacher HTML source: a panel-tabset .qmd with a verbatim
# "To fill" tab (the student script) and an executed "Solved" tab (cumulative solved).

build_teacher_qmd <- function(title, blank_lines, solved_lines) {
  c(
    "---",
    paste0("title: \"", title, " (teacher)\""),
    "format:",
    "  html:",
    "    embed-resources: true",
    "    toc: true",
    "execute:",
    "  warning: false",
    "  message: false",
    "---",
    "",
    "::: {.panel-tabset}",
    "",
    "## To fill",
    "",
    "```r",
    blank_lines,
    "```",
    "",
    "## Solved",
    "",
    "```{r}",
    "#| code-fold: false",
    solved_lines,
    "```",
    "",
    ":::"
  )
}

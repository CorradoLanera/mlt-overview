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

# Build the teacher HTML source for a transform-terminal (engine:targets) step: three tabs —
# the student `_targets.R` (verbatim, the exercise), the solved `_targets.R` (verbatim), and the
# pipeline-compiled report body injected as raw HTML (already rendered by tar_make, so its plots
# and tables carry over and the parity gate sees them in this file). No R is executed here.
build_targets_teacher_qmd <- function(title, blank_lines, solved_lines, report_body) {
  c(
    "---",
    paste0("title: \"", title, " (teacher)\""),
    "format:",
    "  html:",
    "    embed-resources: true",
    "    toc: false",
    "---",
    "",
    "::: {.panel-tabset}",
    "",
    "## `_targets.R` — your turn",
    "",
    "```r",
    blank_lines,
    "```",
    "",
    "## `_targets.R` — solved",
    "",
    "```r",
    solved_lines,
    "```",
    "",
    "## Compiled report",
    "",
    "```{=html}",
    report_body,
    "```",
    "",
    ":::"
  )
}

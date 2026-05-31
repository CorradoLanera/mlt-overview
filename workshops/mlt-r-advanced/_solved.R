# _solved.R — render a step driver in both modes. Usage: Rscript _solved.R steps/01-import/01-import.qmd
args <- commandArgs(trailingOnly = TRUE)
qmd  <- args[[1]]
quarto::quarto_render(qmd, execute_params = list(solved = TRUE),
                      output_file = sub("\\.qmd$", "-solved.html", basename(qmd)))
quarto::quarto_render(qmd, execute_params = list(solved = FALSE),
                      output_file = sub("\\.qmd$", "-blank.html", basename(qmd)))
cat("rendered both modes for", qmd, "\n")

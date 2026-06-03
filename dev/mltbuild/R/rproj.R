# Per-step R-project scaffolding: make each generated step openable as an
# RStudio + renv project. A step with no cumulative packages (00-setup) ships a
# BARE .Rproj only — that is where the student runs renv::init() from scratch.
# Steps with packages (and full/) ship a complete renv project so opening them
# auto-activates renv and `renv::restore()` installs the pinned environment.

RPROJ_TEMPLATE <- c(
  "Version: 1.0", "",
  "RestoreWorkspace: No", "SaveWorkspace: No", "AlwaysSaveHistory: No", "",
  "EnableCodeIndexing: Yes", "UseSpacesForTab: Yes", "NumSpacesForTab: 2",
  "Encoding: UTF-8", "",
  "RnwWeave: knitr", "LaTeX: pdfLaTeX"
)

RENV_GITIGNORE <- c("library/", "local/", "cellar/", "lock/",
                    "python/", "sandbox/", "staging/")

# step_dir: the materialized step (or full/) directory.
# renv_src_dir: the workshop's canonical renv/ (NA in degenerate setups).
# with_renv: TRUE for steps/full that own packages; FALSE for the bare 00-setup.
write_step_project <- function(step_dir, renv_src_dir, with_renv) {
  slug <- basename(step_dir)
  .write_lines(RPROJ_TEMPLATE, file.path(step_dir, paste0(slug, ".Rproj")))
  if (!isTRUE(with_renv)) return(invisible())
  if (is.na(renv_src_dir) || !dir.exists(renv_src_dir))
    stop("write_step_project: renv source dir not found for ", step_dir)
  .write_lines('source("renv/activate.R")', file.path(step_dir, ".Rprofile"))
  renv_out <- file.path(step_dir, "renv")
  dir.create(renv_out, recursive = TRUE, showWarnings = FALSE)
  activate_src <- file.path(renv_src_dir, "activate.R")
  if (!file.exists(activate_src))
    stop("write_step_project: renv/activate.R not found in ", renv_src_dir)
  file.copy(activate_src, file.path(renv_out, "activate.R"), overwrite = TRUE)
  settings_src <- file.path(renv_src_dir, "settings.json")
  if (file.exists(settings_src))
    file.copy(settings_src, file.path(renv_out, "settings.json"), overwrite = TRUE)
  .write_lines(RENV_GITIGNORE, file.path(renv_out, ".gitignore"))
  invisible()
}

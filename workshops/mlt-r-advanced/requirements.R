# requirements.R — install the Advanced workshop package set, then snapshot.
# Agnostic SHAP via kernelshap (CRAN, pure R) + shapviz — replaces the archived fastshap.
# Run from the workshop root with renv active (do NOT use --vanilla).
options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs_cran <- c(
  "here", "rio", "tidyverse", "janitor",
  "tidymodels", "workflowsets", "ranger",       # reload the Basic RF
  "vip", "kernelshap", "shapviz",                # interpretability (all CRAN, pure R)
  "torch", "luz", "brulee", "coro",              # deep learning (no Python)
  "ellmer",                                       # LLM typed ETL
  "targets", "quarto", "renv"
)

# Install CRAN packages one by one to avoid renv_install_report bug in renv < 1.2.4
# (batch install with already-cached deps triggers a vapply length-0 error in the reporter)
failed <- character(0)
for (pkg in pkgs_cran) {
  message("Installing: ", pkg)
  tryCatch(
    install.packages(pkg, dependencies = TRUE),
    error = function(e) {
      message("  WARNING: ", conditionMessage(e))
      failed <<- c(failed, pkg)
    }
  )
}
if (length(failed) > 0) {
  stop(
    "The following packages failed to install:\n",
    paste0("  - ", failed, collapse = "\n"),
    "\nFix the errors above, then re-run requirements.R."
  )
}

# type = "all": pin every package in the (isolated) renv library + transitive deps,
# because no workshop code references them yet — an implicit snapshot would pin nothing.
renv::snapshot(type = "all", prompt = FALSE)

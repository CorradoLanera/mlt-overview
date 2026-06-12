library(targets)
library(tarchetypes)

# Packages every target needs (loaded in the targets worker process) ----
tar_option_set(
  packages = c(
    "tidymodels", "ranger", "glmnet", "kknn", "kernlab", "workflowsets", "yardstick",
    "vip", "kernelshap", "shapviz", "brulee", "ellmer",
    "rio", "janitor", "dplyr", "tidyr", "tibble"
  ),
)

# The LLM step needs OPENAI_API_KEY. The student's key lives in the workshop-root .Renviron
# (gitignored); read it here so the worker sees it. At build time the key is already in the
# environment, so the missing-file case is harmless. ----
if (file.exists("../../.Renviron")) readRenviron("../../.Renviron")

source("R/pipeline-fns.R")  # load_cohort(), explore_cohort(), split_cohort(), make_recipe(), ...

# The DAG: two input files fan out into the whole workshop arc, and the report is itself a target
# COMPILED from the intermediate ones, so document and inputs can never disagree. Each analysis is
# an EXPLICIT, INSPECTABLE target (tar_read() one at a time); tar_visnetwork(FALSE) draws the graph,
# and changing one input invalidates ONLY its downstream targets.
# NOTE: target names are deliberately distinct from the {recipes}/{rsample}/base symbols the
# pipeline functions call (recipe(), split, ...), so targets' static dep-analysis builds a clean DAG.
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(notes_file,  "data-raw/hf_notes.csv",      format = "file"),
  tar_target(cohort,      load_cohort(cohort_file)),
  tar_target(eda,         explore_cohort(cohort)),
  # >>>hole id=tar-split kind=fill prompt=make the train/test split a target with split_cohort()
  #   solved:
  tar_target(cohort_split, split_cohort(cohort)),
  #   blank:
  tar_target(cohort_split, ___(cohort)),
  # <<<hole
  tar_target(prep_recipe,  make_recipe(cohort_split)),
  tar_target(base_compare, compare_models(cohort_split, prep_recipe)),
  tar_target(rf_model,     fit_rf(cohort_split, prep_recipe)),
  tar_target(vimp,         explain_model(rf_model, cohort)),
  tar_target(shap,         shap_explain(rf_model, cohort_split)),
  tar_target(mlp_curve,    learning_curve(cohort_split, prep_recipe)),
  tar_target(records,      extract_notes(notes_file)),
  tar_quarto(report, path = "report.qmd")
)

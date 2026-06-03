library(targets)
library(tarchetypes)

# Packages every target needs (loaded in the targets worker process) ----
tar_option_set(
  packages = c("tidymodels", "ranger", "vip", "rio", "janitor", "dplyr"),
)

source("R/pipeline-fns.R")  # load_cohort(), split_cohort(), make_recipe(), fit_rf(), explain_model()

# The DAG: input file -> cohort -> split -> recipe -> trained model -> explanation -> report.
# Each analysis is an EXPLICIT, INSPECTABLE intermediate target (tar_read() one at a time);
# the pipeline COMPILES THE REPORT itself from those targets, so document and inputs can never disagree.
# NOTE: target names are deliberately distinct from the {recipes}/{rsample}/base symbols the
# pipeline functions call (recipe(), split, ...), so targets' static dep-analysis builds a clean DAG.
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(cohort,       load_cohort(cohort_file)),
  # >>>hole id=tar-split kind=fill prompt=make the train/test split a target with split_cohort()
  #   solved:
  tar_target(cohort_split, split_cohort(cohort)),
  #   blank:
  tar_target(cohort_split, ___(cohort)),
  # <<<hole
  tar_target(prep_recipe,  make_recipe(cohort_split)),
  tar_target(rf_model,     fit_rf(cohort_split, prep_recipe)),
  tar_target(explanation,  explain_model(rf_model, cohort)),
  tar_quarto(report, path = "report.qmd")
)

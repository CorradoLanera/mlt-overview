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
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(cohort,      load_cohort(cohort_file)),
  # >>>hole id=tar-split kind=fill prompt=make the train/test split a target with split_cohort()
  #   solved:
  tar_target(split,       split_cohort(cohort)),
  #   blank:
  tar_target(split,       ___(cohort)),
  # <<<hole
  tar_target(recipe,      make_recipe(split)),
  tar_target(model,       fit_rf(split, recipe)),
  tar_target(explanation, explain_model(model, cohort)),
  tar_quarto(report, path = "report.qmd")
)

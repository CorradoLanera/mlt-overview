library(targets)

# Packages every target needs (loaded in the targets worker process) ----
# vip (not fastshap): the bridge explains the RF via permutation VIMP.
# ranger is the RF engine; janitor::clean_names() rebuilds the cohort.
tar_option_set(
  packages = c("tidymodels", "vip", "ranger", "rio", "janitor", "dplyr"),
)

source("R/pipeline-fns.R")  # load_cohort(), reload_model(), explain_model()

# The DAG: input files -> reloaded objects -> the explanation bridge ----
list(
  tar_target(cohort_file, "data-raw/heart_failure.csv", format = "file"),
  tar_target(cohort,      load_cohort(cohort_file)),
  tar_target(model_file,  "model/final_fit.rds", format = "file"),
  tar_target(model,       reload_model(model_file)),
  # bridge: consumes the reloaded Basic RF + the cohort, emits a VIMP explanation
  tar_target(explanation, explain_model(model, cohort))
)

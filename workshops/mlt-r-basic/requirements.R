# requirements.R — install the Basic workshop package set, then snapshot.
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak", repos = "https://cloud.r-project.org")
pak::pak(c(
  "here", "rio", "tidyverse", "janitor", "gtsummary",
  "tidymodels", "workflowsets", "glmnet", "kknn", "kernlab", "ranger",
  "future", "quarto", "medicaldata", "renv"
))
renv::snapshot()

# Pipeline functions for the targets capstone. Paths come from format="file" targets,
# resolved by targets relative to its project root (this step folder) — do NOT use here().

# Rebuild the modelling cohort exactly as in steps 00-01 (clean_names first) ----
load_cohort <- function(cohort_file) {
  rio::import(cohort_file, setclass = "tibble") |>
    janitor::clean_names() |>
    dplyr::select(-time) |>
    dplyr::mutate(
      outcome = factor(
        dplyr::if_else(death_event == 1, "died", "survived"),
        levels = c("died", "survived"),
      ),
    ) |>
    dplyr::select(-death_event) |>
    dplyr::mutate(
      dplyr::across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor),
    )
}

# Reload the validated Basic random forest workflow (no retraining) ----
# extract_workflow() is a hardhat generic; tidymodels (attached via tar_option_set's
# packages) puts it on the search path and workflows supplies the S3 method.
reload_model <- function(model_file) {
  extract_workflow(readRDS(model_file))
}

# The bridge: explain the reloaded Basic RF with permutation VIMP (reuses step 01's pattern) ----
# vip unwraps the workflow and hands the bare engine to pred_wrapper, so the closure routes
# the prediction through the captured `model` workflow instead of the unwrapped `object`.
# vip::vi() (not vip::vip()) is used deliberately: the target value must be a plain tibble,
# not a ggplot — serializable objects keep tar_read() and downstream targets reliable.
explain_model <- function(model, cohort) {
  pred_wrapper <- function(object, newdata) predict(model, newdata, type = "prob")$.pred_died
  set.seed(1)
  vip::vi(
    model,
    method       = "permute",
    train        = cohort,
    target       = "outcome",
    metric       = "roc_auc",
    pred_wrapper = pred_wrapper,
    nsim         = 10,
    event_level  = "first",
  )
}

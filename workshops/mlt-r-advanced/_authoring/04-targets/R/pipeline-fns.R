# Pipeline functions for the targets capstone. Paths come from format="file" targets,
# resolved by targets relative to its project root (this step folder) — do NOT use here().
# Self-contained per spec §4.3: pkg::fun() throughout; S3 generics need their namespace loaded.
requireNamespace("workflows", quietly = TRUE)   # supplies predict.workflow / the workflow S3 methods
requireNamespace("parsnip",   quietly = TRUE)
requireNamespace("recipes",   quietly = TRUE)
requireNamespace("rsample",   quietly = TRUE)

# Rebuild the modelling cohort exactly as in the Basic workshop (clean_names first) ----
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

# A held-out split (the same convention as Basic) ----
split_cohort <- function(cohort) {
  set.seed(123)
  rsample::initial_split(cohort, prop = 0.75, strata = outcome)
}

# The preprocessing recipe (no imputation; dummy + zv + normalize) ----
make_recipe <- function(split) {
  recipes::recipe(outcome ~ ., data = rsample::training(split)) |>
    recipes::step_dummy(recipes::all_nominal_predictors()) |>
    recipes::step_zv(recipes::all_predictors()) |>
    recipes::step_normalize(recipes::all_numeric_predictors())
}

# Train the random forest workflow on the training split ----
fit_rf <- function(split, recipe) {
  spec <- parsnip::rand_forest() |>
    parsnip::set_engine("ranger") |>
    parsnip::set_mode("classification")
  wf <- workflows::workflow() |>
    workflows::add_recipe(recipe) |>
    workflows::add_model(spec)
  parsnip::fit(wf, data = rsample::training(split))
}

# The bridge: explain the trained forest with permutation VIMP (a serializable tibble) ----
# vip unwraps the workflow and hands the bare engine to pred_wrapper, so the closure routes
# the prediction through the captured `model` workflow. vip::vi() (not vip()) keeps the target
# value a plain tibble so tar_read()/downstream targets stay reliable.
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

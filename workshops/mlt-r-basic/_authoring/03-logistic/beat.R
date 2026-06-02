library(tidymodels)
set.seed(123)

# Split ----
# >>>frag id=split
data_split <- initial_split(hf, prop = 0.75, strata = outcome)
train <- training(data_split)
test  <- testing(data_split)
# <<<frag

# Recipe (no imputation: heart_failure has no missing values) ----
# >>>frag id=recipe
base_rec <- recipe(outcome ~ ., data = train) |>
  step_dummy(all_nominal_predictors()) |>
  step_zv(all_predictors()) |>
  step_normalize(all_numeric_predictors())
# <<<frag

# Spec ----
log_spec <- logistic_reg() |> set_engine("glm")

# Workflow ----
log_wf <- workflow() |>
  add_recipe(base_rec) |>
  add_model(log_spec)

# Fit ----
log_fit <- fit(log_wf, data = train)
log_fit

# Predict & score (both metrics) ----
hf_metrics <- metric_set(roc_auc, pr_auc)

# >>>hole id=score kind=fill prompt=augment the test set, then score both metrics on .pred_died
#   solved:
log_fit |>
  augment(new_data = test) |>
  hf_metrics(truth = outcome, .pred_died)
#   blank:
log_fit |>
  augment(new_data = ___) |>
  hf_metrics(truth = outcome, ___)
# <<<hole

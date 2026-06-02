library(workflowsets)
library(future)

# Optional speed-up: parallelize tuning across cores, leaving one for the OS.
# Comment this line out and everything still runs — just sequentially.
plan(multisession, workers = max(1, parallel::detectCores() - 1))
set.seed(123)

# Model specs (hyper-parameters left to tune) ----
# >>>frag id=specs
penlog_spec <- logistic_reg(penalty = tune(), mixture = tune()) |> set_engine("glmnet")
knn_spec    <- nearest_neighbor(neighbors = tune()) |> set_engine("kknn")   |> set_mode("classification")
svm_spec    <- svm_rbf(cost = tune(), rbf_sigma = tune()) |> set_engine("kernlab") |> set_mode("classification")
rf_spec     <- rand_forest(mtry = tune(), min_n = tune()) |> set_engine("ranger")  |> set_mode("classification")
# <<<frag

# Resamples ----
folds <- vfold_cv(train, v = 5, strata = outcome)

# Two metrics, watched together ----
hf_metrics <- metric_set(roc_auc, pr_auc)

# Workflow set ----
wf_set <- workflow_set(
  preproc = list(rec = base_rec),
  models  = list(penlog = penlog_spec, knn = knn_spec, svm = svm_spec, rf = rf_spec),
)

# Tune every workflow ----
wf_res <- wf_set |>
  workflow_map(
    "tune_grid",
    resamples = folds,
    grid      = 8,
    metrics   = hf_metrics,
    verbose   = TRUE,
    seed      = 123,
  )

# Compare the candidates ----
rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE)
autoplot(wf_res)

# Finalize & validate ----
# >>>hole id=finalize kind=fill prompt=rank, pull the winner id + best params, finalize, then last_fit on the original split
#   solved:
best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(wflow_id)
best_res    <- extract_workflow_set_result(wf_res, best_id)
best_params <- select_best(best_res, metric = "roc_auc")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(best_params)

final_fit <- last_fit(final_wf, split = data_split, metrics = metric_set(roc_auc, pr_auc, accuracy))
collect_metrics(final_fit)
#   blank:
best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(___)
best_res    <- extract_workflow_set_result(wf_res, ___)
best_params <- select_best(best_res, metric = "___")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(___)

final_fit <- last_fit(final_wf, split = ___, metrics = metric_set(roc_auc, pr_auc, accuracy))
collect_metrics(final_fit)
# <<<hole

# Test-set ROC & PR curves ----
preds <- collect_predictions(final_fit)
preds |> roc_curve(outcome, .pred_died) |> autoplot()
preds |> pr_curve(outcome, .pred_died) |> autoplot()

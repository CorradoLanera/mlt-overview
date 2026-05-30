# Your turn — Step 04: pick the winner, finalize it, validate on the test set.
#
# `wf_res` holds the cross-validated results for all four models. Now:
#   1. rank the models by ROC-AUC and take the top one's id,
#   2. pull its tuning result and its best hyper-parameters,
#   3. finalize that workflow with those parameters,
#   4. run last_fit() on the ORIGINAL split to score it on the held-out test set,
#      reporting ROC-AUC, PR-AUC, and accuracy.
#
# Event-first convention (`died` is the first level), so no `event_level` is needed.
# Fill the ___ blanks.

best_id     <- rank_results(wf_res, rank_metric = "roc_auc", select_best = TRUE) |>
  dplyr::slice(1) |> dplyr::pull(___)
best_res    <- extract_workflow_set_result(wf_res, ___)
best_params <- select_best(best_res, metric = "___")
final_wf    <- wf_set |> extract_workflow(best_id) |> finalize_workflow(___)

final_fit <- last_fit(final_wf, split = ___, metrics = metric_set(roc_auc, pr_auc, accuracy))
collect_metrics(final_fit)

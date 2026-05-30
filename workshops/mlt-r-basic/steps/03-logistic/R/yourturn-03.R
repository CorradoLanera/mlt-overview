# Your turn — Step 03: score the fitted logistic workflow on the test set.
#
# `log_fit` is the workflow fitted on `train`. Use augment() to attach predictions
# to the held-out `test` set, then score BOTH metrics at once.
#
# Remember the EVENT-FIRST convention: the event `died` is the first factor level,
# so point yardstick at the `.pred_died` column — no `event_level` argument needed.
#
# Fill the ___ blanks.

hf_metrics <- metric_set(roc_auc, pr_auc)

log_fit |>
  augment(new_data = ___) |>
  hf_metrics(truth = outcome, ___)

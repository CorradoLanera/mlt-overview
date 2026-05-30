# Your turn — Step 03: score the fitted logistic workflow on the test set.
#
# `log_fit` is the workflow fitted on `train`. Use augment() to attach
# predictions to the held-out `test` set, then compute the ROC-AUC.
#
# Remember: the event is `1_yes`, the SECOND factor level — so point yardstick at
# the `.pred_1_yes` column and set event_level = "second".
#
# Fill the ___ blanks.

log_fit |>
  augment(new_data = ___) |>
  roc_auc(truth = outcome, ___, event_level = "___")

library(vip)
library(kernelshap)
library(shapviz)

# The validated Basic random forest, already fitted in the recap, as a workflow ----
rf_wf <- extract_workflow(final_fit)

# Permutation VIMP — what the forest relies on ----
# NOTE: vip unwraps the workflow and hands the bare engine (ranger) to pred_wrapper, so we
# ignore `object` and route the prediction through the captured workflow `rf_wf` instead.
vimp_pred <- function(object, newdata) predict(rf_wf, newdata, type = "prob")$.pred_died
set.seed(1)
vip(
  rf_wf,
  method       = "permute",
  train        = train,
  target       = "outcome",
  metric       = "roc_auc",
  pred_wrapper = vimp_pred,
  nsim         = 10,
  event_level  = "first",
)

# SHAP on the logistic anchor (log_fit, fitted in the recap): the sanity check ----
# kernelshap's pred_fun signature is function(object, X, ...).
pred_fun <- function(object, X) predict(object, X, type = "prob")$.pred_died
bg <- train |> select(-outcome)
set.seed(2)
bg_small <- bg |> slice_sample(n = 40)

# Background size, shown: full vs reduced (same explainer, same patient) ----
# Full background (~224 rows): lower-variance attributions, slower.
set.seed(2)
ks_log_full <- permshap(log_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_log_full) |> sv_waterfall()

# Fixed 40-row background: cheaper and slightly noisier, the waterfall barely moves.
# We reuse this background for every model (logistic -> forest -> MLP) so comparisons match.
set.seed(2)
ks_log_small <- permshap(log_fit, X = bg[1, ], bg_X = bg_small, pred_fun = pred_fun)
shapviz(ks_log_small) |> sv_waterfall()

# The SHAP signs must echo the logistic coefficients ----
tidy(log_fit) |> dplyr::arrange(dplyr::desc(abs(estimate)))

# Your turn: swap the model and the function (permshap -> kernelshap), reuse bg_small ----
# >>>hole id=shap-rf kind=fill prompt=point the agnostic explainer at the random forest with kernelshap on rf_wf and the same fixed bg_small
#   solved:
set.seed(3)
ks_rf <- kernelshap(rf_wf, X = bg[1, ], bg_X = bg_small, pred_fun = pred_fun)
shapviz(ks_rf) |> sv_waterfall()
#   blank:
set.seed(3)
ks_rf <- kernelshap(___, X = bg[1, ], bg_X = ___, pred_fun = ___)
shapviz(ks_rf) |> sv_waterfall()
# <<<hole

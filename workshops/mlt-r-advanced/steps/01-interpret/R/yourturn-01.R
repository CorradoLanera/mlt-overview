# Your turn — point the SAME agnostic explainer at the RANDOM FOREST.
# Fill the blanks: it is the anchor's call with ONE thing swapped — the model.
#
# PREREQUISITE: run the 01-interpret.qmd chunks first (or have these in your environment):
#   bg       = the training set minus `outcome` (built in the shap-anchor chunk)
#   rf_wf    = the Basic random forest workflow (built in the given chunk)
#   pred_fun = the predict adapter (re-declared just below for convenience)
pred_fun <- function(object, X) predict(object, X, type = "prob")$.pred_died
set.seed(3)
ks_rf <- kernelshap(___,              # which model? (the one new thing)
                    X        = bg[1, ],
                    bg_X     = ___,    # same background as the anchor
                    pred_fun = ___)    # same adapter as the anchor
shapviz(ks_rf) |> sv_waterfall()

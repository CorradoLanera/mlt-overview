# Formative · min 38 · predict-output (after Step 01, SHAP on logistic anchor)

- **Type:** predict-output (predict before the reveal)
- **Concept-graph nodes checked:** `SHAP` — Agnostic SHAP via kernelshap + shapviz; `ANCHOR` — Logistic regression ANCHOR; `COEF` — Logistic coefficients = sanity check

## Prompt

We ran `kernelshap` on the **logistic regression** (the anchor model) and called
`sv_waterfall()`. Before we look at the plot:

1. What **shape** do you expect the waterfall bars to have compared to the model's
   raw `coef()` output — same sign, same relative order, or something else entirely?
2. Why do we run SHAP on the **logistic** model *first*, before pointing the
   explainer at the random forest?

## Expected answer

**Shape:** for a logistic regression, the same predictors that dominate the
coefficient table will dominate the SHAP waterfall, and their **directions agree**:
a predictor with a negative coefficient will show a negative (blue) SHAP bar for a
patient whose feature value pushes the prediction downward. Concretely:

- the **signs match** the coefficient signs (times the patient's standardized feature
  value);
- the **relative magnitudes** tend to mirror the weighted feature contributions.

This is a **directional sanity check, not an exact identity**: we explain in
probability space (`pred_fun` returns `.pred_died`), and `permshap` samples at this
feature count, so the attribution is not exactly proportional to
$\beta_j \cdot (x_j - \bar{x}_j)$.

**Why first:** starting on the logistic anchor is a **sanity check for the
method itself**. We know the ground truth (the coefficients); if the agnostic
explainer (`kernelshap`) recovers the same dominant features with the same
directions, we can trust it when we point it at the random forest — whose internal
logic we *cannot* inspect directly. Running it on the black box first would leave us
no way to know whether the explanation is correct or an artefact of the
approximation.

## Diagnostic note (teacher)

If the room asks whether SHAP recovers the logistic story "exactly": the answer is
no in our setup — the same predictors dominate, and each attribution's direction
matches the sign of its coefficient times the patient's (standardized) feature value
— a directional sanity check, not an exact identity (we explain in probability space,
and permshap samples at this feature count). Use the moment to emphasise that
"model-agnostic" means the approximation is the point: it costs a little exactness on
the linear model to gain universality across all model classes.

# Formative · min 66 · your-turn (after Step 02, MLP trained)

- **Type:** your-turn (compute + `{countdown}`, then my-turn live-solve)
- **Concept-graph nodes checked:** `MLP` — Tiny MLP via brulee/luz; `SHAP` — Agnostic SHAP via kernelshap + shapviz; `HONESTY` — Honesty rule: nothing pre-baked shown as live

## Prompt

We now have `mlp_fit` — the trained MLP workflow. Using the **same explainer call**
we used on the logistic anchor (just swap `mlp_fit` for `glm_fit`), produce a
waterfall plot for observation 1:

```r
kernelshap(mlp_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun) |>
  shapviz() |>
  sv_waterfall()
```

Run it and note the shape: do the important features match what VIMP told us?

## Expected answer

The call runs unchanged — only the first argument (the fitted model) differs.
`kernelshap` uses `pred_fun` as its only interface to the model; it never looks
inside the object. The waterfall should still place `ejection_fraction` and
`serum_creatinine` near the top, consistent with the VIMP ranking, although the
exact magnitudes will differ (SHAP is per-observation; VIMP is averaged over all
permutations).

The key observation: the **same three lines of R** work unchanged across the
logistic and RF (step 01) and now the MLP — the explainer is truly model-agnostic.

## Stretch (Davide)

Why does the **same explainer** work on logistic regression, random forest, and
neural network without modification?

`kernelshap` requires only a function `pred_fun(object, X, ...)` that maps input
rows to predicted probabilities. It treats the model as a **black box**: it never
inspects coefficients, tree splits, or weight matrices. The algorithm works by
evaluating the model on carefully chosen feature coalitions (subsets of features
set to background values) and fitting a weighted linear regression on the resulting
predictions to recover Shapley values. Because the only assumption is "give me a
prediction function", the method is **model-class agnostic** by design — and that
is exactly why SHAP is the go-to tool when you need a single explanation framework
across a diverse model zoo.

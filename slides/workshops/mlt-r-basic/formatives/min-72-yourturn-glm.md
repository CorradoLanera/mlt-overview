# Formative · min 72 · your-turn (after Step 03)

- **Type:** your-turn (compute + `{countdown}`, then my-turn live-solve)
- **Concept-graph node checked:** `WF` — Workflow (recipe + model); `GLM` baseline; `METRIC`

## Prompt

You have just fit a plain `glm` logistic baseline two ways: (a) a bare
`glm()`-engine `logistic_reg()` fit, and (b) the same model wrapped in a
`workflow()` (recipe + spec). Score both on the held-out test set with **both**
metrics:

```r
hf_metrics <- metric_set(roc_auc, pr_auc)
... |> augment(new_data = test) |> hf_metrics(truth = outcome, .pred_died)
```

(No `event_level` needed — `died` is the *first* factor level.)

**Confirm:** do the two routes give the **same** ROC-AUC and PR-AUC? Say in one
sentence why.

## Expected answer

Yes — both metrics are **identical** across the two routes ("same model, more
scaffolding"). The `workflow` does not change the statistical model; it only
**bundles** the recipe and the spec so the *same* logistic regression is fit on the
*same* preprocessed data. The numbers match because the estimator is identical.

## Stretch (Davide)

If the metrics are the same, what does the recipe + workflow **buy** you over a bare
`glm`? Answer: it makes preprocessing **part of the model** (dummy-coding,
normalization, zero-variance removal travel with the fit), so the *exact* same
transformations are re-applied at prediction time — no leakage, no "I forgot to
scale the test set", and the whole thing becomes one swappable, tunable object
(which is exactly what lets Step 04 swap engines and tune four models at once).

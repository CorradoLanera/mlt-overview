# Item 04 — Comparing techniques: the second selection that looks invisible

**ID**: IB-04-model-selection-04
**Learning objective**: Argue, using the chapter's tools (train / validation / test split, $K$-fold CV as validation, *contamination principle*; recall that *validation chooses among candidate models / hyperparameter settings*), why a procedure that *appears* to follow best practice — including tuning each candidate technique correctly with CV — can still violate the contamination principle when used to compare *multiple* techniques against each other on the test set; propose the correct procedure (Obj. 1 + Obj. 2).
**Category**: Argumentation
**Type**: argomentativa (open-ended)
**Difficulty**: medium–high
**Chapter**: 04-model-selection

## Question

A colleague wants to choose, for the same clinical 2-class task, among **three different ML techniques**: $k$-Nearest Neighbor, Support-Vector Machine with kernel, and Random Forest. Each technique has its own hyperparameters ($k$ for $k$NN; $C$ and kernel choice for SVM; *mtry* and *ntree* for RF). Here is the colleague's procedure:

| Day | Action |
|---|---|
| **1** | Split the dataset into **three** parts: a training set, a validation set, and a **test set**. The test set is *immediately set aside* and locked away. |
| **2** | **For each of the three techniques separately**, use $5$-fold CV on the (training + validation) data to find its **best hyperparameter setting**. The colleague obtains: best $k$NN setting → $k = 5$; best SVM setting → kernel + $C$; best RF setting → $\text{mtry}$ + $\text{ntree}$. |
| **3** | **Retrain each of the three best-tuned candidates** — *one per technique* — on the **combined training + validation data**. |
| **4** | Evaluate the three retrained candidates on the **held-out test set**; record each one's **test error**. |
| **5** | Pick the technique with the **lowest test error**, call it $M_\star$, and report $M_\star$'s test error as the expected performance on new patients. |

The colleague defends the procedure:

> *"For each technique, I used CV to tune its hyperparameters — exactly as the chapter prescribes. Then I retrained the best version of each on training + validation, and only then evaluated on the test set. The test set was never touched during any tuning. The number I am reporting is the test error of the chosen classifier on data it never saw during training. What could possibly be wrong?"*

Argue your answer in two parts, using only the language of this chapter.

1. **Find the exact flaw** in the colleague's procedure: at which step (and *how*) is the contamination principle violated, **even though each technique was tuned correctly with its own CV and the test set was never used for training**?
2. **Propose the correct procedure** for choosing among multiple techniques (each with its own hyperparameters), and explain *why* it does not have the same flaw.

## Expected answer

1. The flaw is at **Steps 4–5**: the colleague used the **test set to *choose* among the three retrained techniques**. Picking the technique with the lowest test error among three is a **decision based on test-set numbers**, and the **contamination principle** rules it out: *every time you take a decision based on a number on a dataset, that number is no longer a valid estimate*. The test set has therefore been **spent** in selecting $M_\star$. The reported "test error" of $M_\star$ is no longer an unbiased estimate of its performance on new patients: it is the **minimum of three test errors**, optimistically biased downward. The fact that each technique's own *within-technique* tuning was done correctly on CV (at Step 2) is irrelevant to this second-level selection — the chapter teaches that **validation chooses among candidate models / hyperparameter settings**, and *"comparing three techniques to pick the best"* is itself one such choice; doing it on the test set violates the rule. By framing the within-technique tunings as the "real" CV step and treating Step 4 as "mere evaluation", the colleague has hidden a **second selection step** inside what looks like a final estimate — effectively turning the test set into a *between-technique validation set*.

2. The correct procedure for comparing multiple techniques is to do **all** the selection at the validation step — both within-technique and between-technique. Concretely:

   - For each technique, use CV (on the training + validation data) to find its best hyperparameter setting — as the colleague already does at Step 2.
   - **Use the same CV (or a parallel validation procedure) to also compare the three best-tuned candidates against each other**, and commit to a single winner $M_\star$ — the technique-and-setting combination with the lowest CV error among the three. *This is the choice the colleague made on the test set, moved back to where it belongs.*
   - **Retrain only $M_\star$** — that single winning technique with its winning hyperparameters — on the training + validation data combined.
   - **Evaluate $M_\star$ once**, and only once, on the held-out **test set**, and report that test error.

   This procedure does not violate the contamination principle because **at the moment the test set is consulted, no decision is still open**: all selections — within each technique and across techniques — have been made on the validation set; the test set is used purely to *estimate* the already-chosen $M_\star$'s performance. Each dataset is spent exactly once, on exactly one task: training fits, **validation chose (at both levels)**, test estimated.

(Bonus, for the curious student: the colleague's intuition — *"each technique deserves its own fair test on data it has never seen"* — is sympathetic but procedurally fatal. Comparing multiple models *on test* always spends the test set, no matter how carefully each model was tuned beforehand. *Note that adding a fourth held-out set would not solve the underlying issue*: the same logic would apply at every new level — any time a number is used to choose, it stops being a clean estimator. **The fix is discipline, not more partitions**: keep all selection at the validation step, retrain only the chosen winner, evaluate once on test.)

## Rubric

See [rubriche/rubrica_04_skip-the-test-critique.md](../rubriche/rubrica_04_skip-the-test-critique.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

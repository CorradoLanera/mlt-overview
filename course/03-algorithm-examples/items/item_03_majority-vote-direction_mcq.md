# Item 03 — Which way does the majority vote move?

**ID**: IB-03-algorithm-examples-03
**Learning objective**: Predict how the accuracy of a majority vote of $m$ independent weak classifiers with per-classifier accuracy $p$ varies with $m$ and $p$, and state why the construction only improves on a single classifier when $p > 0.5$ (Obj. 3).
**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 03-algorithm-examples

## Question

Two ensemble configurations are being compared on the same binary task. Each ensemble combines its classifiers by **majority vote**, and the individual classifiers within each ensemble can be assumed independent.

- **Configuration X**: $100$ weak classifiers, each with per-classifier accuracy $p = 0.55$.
- **Configuration Y**: $100$ weak classifiers, each with per-classifier accuracy $p = 0.45$.

Which statement about the **majority-vote accuracy** of these two configurations is correct?

## Options

- A) X's vote is **more accurate than $0.55$** (the per-classifier accuracy), and Y's vote is **less accurate than $0.45$**.
- B) Both X's and Y's votes are more accurate than their respective single classifiers — combining more classifiers always helps.
- C) X's vote is approximately equal to $p = 0.55$, since the vote averages the classifiers and the average of a constant probability is that probability.
- D) Y's vote is more accurate than X's vote, because $p = 0.45$ leaves more room for the majority vote to correct mistakes.

## Expected answer

**Correct: A.** The chapter's binomial-vote analysis shows that, for $m$ independent weak classifiers with per-classifier accuracy $p$, the **majority-vote accuracy concentrates** as $m$ grows:

- if $p > 0.5$, the vote accuracy goes **up toward $1$** — the vote is more accurate than any single classifier;
- if $p < 0.5$, the vote accuracy goes **down toward $0$** — the vote is *less* accurate than any single classifier.

So Configuration X ($p = 0.55 > 0.5$): vote accuracy $> 0.55$, with $100$ classifiers it is close to $1$. Configuration Y ($p = 0.45 < 0.5$): vote accuracy $< 0.45$, with $100$ classifiers it is close to $0$. The construction concentrates *whichever direction $p$ points* — *toward correctness* when $p > 0.5$, *toward error* when $p < 0.5$. Hence the **$p > 0.5$ requirement** for ensembles to make sense.

Why the distractors are plausible but wrong:

- **B** misses the **$p > 0.5$ requirement**. It is true that X's vote improves, but Y's vote does not — Y's vote *worsens* because the majority of $100$ classifiers, each more likely to be *wrong* than right, will systematically vote for the wrong answer. "More is always better" is wrong by symmetry: more classifiers concentrate the vote *in whichever direction $p$ points*.
- **C** confuses **majority vote with arithmetic average**. A majority vote does not return the *probability* $p$; it returns the *most-voted* label. The probability that the majority is correct is a *binomial tail* — $\sum_{j > m/2} \binom{m}{j} p^j (1-p)^{m-j}$ — which is *not* equal to $p$ and concentrates away from $p$ as $m$ grows.
- **D** is the **"underdog correction"** intuition: that low-accuracy classifiers somehow have more to gain from voting. The opposite is true: voting *amplifies whatever signal is there*, and a $p < 0.5$ signal amplifies toward *the wrong* answer. Y's vote is *worse* than X's, not better.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

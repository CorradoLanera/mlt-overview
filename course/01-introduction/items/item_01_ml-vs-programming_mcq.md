# Item 01 — Machine learning vs traditional programming

**ID**: IB-01-introduction-01
**Learning objective**: Contrast machine learning with traditional programming, stating what is provided as input and what is produced as output (Obj. 2).
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low–medium
**Chapter**: 01-introduction

## Question

A hospital deploys a model that predicts 30-day readmission from each patient's electronic health record. Which statement best captures how this machine-learning system differs from a traditional, rule-based program written for the same task?

## Options

- A) In traditional programming an engineer writes the decision rules and the program applies them to data; in machine learning the rules — the model — are *learned* from data paired with known outcomes.
- B) Machine learning needs no data, whereas a traditional program requires data as input.
- C) A traditional program can only handle numeric inputs, while machine learning is the only approach able to process patient records at all.
- D) Machine learning is guaranteed to be more accurate than any hand-written rule, because learning from data removes human bias.

## Expected answer

**Correct: A.** The defining difference is the input/output swap. In ordinary software the rules are the *input* (hand-written) and answers come out; in machine learning you provide the data *and* the known answers, and the model — the rule $Y \simeq f(X)$ — is the *output*, learned from training data.

Why the distractors are plausible but wrong:

- **B** inverts the dependency: ML is *more* data-dependent, not less — it needs training data with known outcomes to learn at all.
- **C** is a false capability claim: rule-based programs can process records too; data type is not what distinguishes the two approaches.
- **D** is the "ML is objective / always better" misconception: a model can score 95% accuracy and still be clinically useless on imbalanced data, and it inherits whatever bias is in its training data.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

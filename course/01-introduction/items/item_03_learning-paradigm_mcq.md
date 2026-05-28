# Item 03 — Which learning paradigm?

**ID**: IB-01-introduction-03
**Learning objective**: Classify a described scenario into the correct learning paradigm (unsupervised / supervised / active / reinforcement) and justify the choice from the kind and availability of supervision (Obj. 3).
**Category**: Application
**Type**: MCQ (scenario-based)
**Difficulty**: medium
**Chapter**: 01-introduction

## Question

A team builds a model that classifies chest X-rays as *normal* or *abnormal*. Labelling images by a radiologist is expensive, so they proceed like this: they train the model on a small set of already-labelled X-rays, then let it scan many unlabelled X-rays and **select the few it is most uncertain about**; a radiologist labels only those, the model is retrained, and the cycle repeats.

Which learning paradigm best describes this set-up?

## Options

- A) Supervised learning, because the model is ultimately trained on radiologist-labelled X-rays.
- B) Active learning, because the model repeatedly queries an expert (the oracle) to label the cases it is most uncertain about.
- C) Reinforcement learning, because the model improves over repeated cycles by interacting with its environment.
- D) Unsupervised learning, because the model scans many X-rays that have no labels.

## Expected answer

**Correct: B.** The defining feature is the loop in which the model itself *chooses* which unlabelled cases to send to a human oracle for labelling — this selective querying is exactly active learning.

Why the distractors are plausible but wrong:

- **A** is the seductive distractor: the underlying model *is* a supervised classifier, so "supervised" is not absurd — but it misses what distinguishes the scenario, namely the model's selective request for labels. Active learning is a strategy built *on top of* supervised learning.
- **C** confuses "repeated cycles / interaction" with reinforcement learning, which requires a reward (or penalty) signal guiding actions over time; there is no reward here, only requested labels.
- **D** notes that many X-rays are unlabelled, but the model is trained on labels (just sparingly requested), so it is not unsupervised.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

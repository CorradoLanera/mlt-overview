# Item 01 — The neuron as a generalised logistic

**ID**: IB-05-deep-learning-01
**Learning objective**: Describe an artificial neuron as a *generalised non-linear logistic unit* — $\text{out} = g(\sum_i a_i w_i)$ — i.e. a logistic regression in which the sigmoid has been replaced by any non-linear, differentiable activation function $g$ (Obj. 1).
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low–medium
**Chapter**: 05-deep-learning

## Question

A clinical colleague has been reading about "deep learning" and tells you over coffee: *"an artificial neuron is just a fancy version of logistic regression."* Among the following descriptions, which one identifies the **single mathematical change** that turns a logistic regression into an artificial neuron, as covered in this chapter?

## Options

- A) The sigmoid activation of logistic regression is replaced by **any non-linear, differentiable function** $g$ — e.g. ReLU, tanh, or sigmoid itself as one special case. The weighted-sum-of-inputs structure $\sum_i a_i w_i$ is unchanged.
- B) The **input features** themselves are squared ($a_i^2$ instead of $a_i$), so the neuron can model curved decision boundaries that a logistic regression cannot.
- C) The neuron carries **many weight vectors in parallel** instead of one, so it can produce multiple outputs at once from the same inputs.
- D) The activation function is **removed entirely**, so the neuron computes the bare weighted sum $\sum_i a_i w_i$ — a *purely linear* version of logistic regression.

## Expected answer

**Correct: A.** The chapter defines an artificial neuron as $\text{out} = g(\sum_i a_i w_i)$ where $g:\mathbb{R}\to\mathbb{R}$ is non-linear and differentiable. The logistic regression of chapter 02 is the special case $g = \sigma$ (sigmoid); the artificial neuron *frees* the choice of $g$ to any function satisfying the two requirements (ReLU, tanh, sigmoid, etc.). Nothing else changes: the input layer, the weights $w_i$, and the weighted sum structure are identical to logistic regression.

Why the distractors are plausible but wrong:

- **B** confuses non-linearity *in the activation function* with non-linearity *in the input features*. Squaring the inputs is the **kernel trick of chapter 03**, a completely different mechanism (it lives in the input pre-processing, not in the activation), and it does not turn a logistic regression into an artificial neuron. A student who picks B is replaying ch. 03 instead of reading ch. 05.
- **C** is a description of a **layer of neurons**, not of a single neuron. A layer is a *collection* of neurons in parallel, each with its own single weight vector. The student who has skimmed an MLP diagram in a hurry can fall here. The chapter's neuron is the *atom*; what C describes is the *molecule* (Obj. 2).
- **D** drops the activation entirely. This is the *worst* possible answer because removing $g$ — making the neuron purely linear — is exactly what the chapter's first requirement on $g$ (non-linearity) rules out. Stacking purely linear units would collapse the whole network into one big linear map, undoing the point of being "deep" (see Obj. 3). A student who picks D has missed the central pedagogical insight of the chapter.

The single discriminator is the **swap of the activation** ($\sigma$ → any non-linear differentiable $g$), with the rest of the equation left intact. Only A captures this.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

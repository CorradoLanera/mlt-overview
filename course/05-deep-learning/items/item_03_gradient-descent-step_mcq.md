# Item 03 — One step of gradient descent

**ID**: IB-05-deep-learning-03
**Learning objective**: Explain how a fully-connected network *learns* — weights as coordinates, loss as height, gradient descent $W \leftarrow W - \eta \, \nabla_W L(W)$ as walking the model downhill (Obj. 3, the procedural half).
**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 05-deep-learning

## Question

A toy neural network has only two weights, $w_1$ and $w_2$. At the current weights
$$W_{\text{now}} = (w_1,\ w_2) = (3,\ 1),$$
the loss-landscape gradient has been computed (no need to redo the computation) and equals
$$\nabla_W L(W_{\text{now}}) = (2,\ -4).$$
The training procedure is **gradient descent with learning rate** $\eta = 0.5$.

After **one** update step, the new weight vector $W_{\text{next}}$ is:

## Options

- A) $W_{\text{next}} = (2,\ 3)$
- B) $W_{\text{next}} = (4,\ -1)$
- C) $W_{\text{next}} = (1,\ 5)$
- D) $W_{\text{next}} = (5,\ -3)$

## Expected answer

**Correct: A.** Gradient descent updates the weights against the gradient, scaled by the learning rate:
$$W_{\text{next}} = W_{\text{now}} - \eta \, \nabla_W L(W_{\text{now}}) = (3,\ 1) - 0.5 \cdot (2,\ -4) = (3,\ 1) - (1,\ -2) = (2,\ 3).$$

That is, the update *subtracts* a small fraction of the gradient (a fraction set by $\eta$) from the current weights — so the model moves *downhill* on the loss landscape, *not too far in one step*.

Each distractor isolates one specific misconception about the update rule:

- **B ($W_{\text{next}} = (4,\ -1)$) — sign-flip error.** The student has **added** $\eta \nabla L$ instead of subtracting it: $(3,\ 1) + 0.5 \cdot (2,\ -4) = (4,\ -1)$. This is **gradient *ascent*** — it walks the model *uphill* on the loss landscape, *increasing* the error at every step. A student who picks B has reversed the central insight of Obj. 3 (descent goes *opposite* to the gradient).
- **C ($W_{\text{next}} = (1,\ 5)$) — forgot the learning rate.** The student has subtracted the full gradient with no $\eta$: $(3,\ 1) - (2,\ -4) = (1,\ 5)$. The *direction* is correct (downhill), but the *step size* is wrong. In practice this is the most pedagogical mistake — it asks "what is $\eta$ for?", and the answer is exactly: to control *how far* you move along the descent direction at each step (a step too big can overshoot the minimum, oscillate, or diverge).
- **D ($W_{\text{next}} = (5,\ -3)$) — both errors at once.** The student has added the full gradient with no learning rate: $(3,\ 1) + (2,\ -4) = (5,\ -3)$. Direction wrong **and** step size wrong — both the sign and the $\eta$ have been lost. This is the option chosen by a student who is operating "by analogy" without having read the chapter's update rule at all.

The single discriminator is the **update rule itself**: subtract a fraction $\eta$ of the gradient. The sign decides whether you descend or ascend; the learning rate decides how far you step. Only A applies both correctly.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

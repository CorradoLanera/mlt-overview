# Item bank — 05 Deep Learning

> Chapter: `05-deep-learning` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-29. Items student-facing in **English**; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED** (2026-05-29) after applying one fix: orphan cross-reference to "item 04" in [item 02](items/item_02_forward-pass-and-weight-count_applicativa.md) sub-q 3 expected-answer paragraph removed (item 04 was dropped by teacher's call, see set-size note below). Anti-leakage check from ch. 06+ (convolution, kernel, filter, stride, weight sharing, recurrent, CNN, RNN, transformer, attention, LLM, agent, dropout, regularization, batch norm) held cleanly across all 3 items + the one rubric. Numerical verification on item 02 ($W^{[1]} a^{[0]}$ component-wise, ReLU on the negative pre-activation) and item 03 ($W - \eta \nabla L$ for all four candidate updates) passed. No further fixes required.

> **Set size note:** chapter 5 closes at **3 items** (not 4 as in chapters 01–04). The Argumentation/evaluation item originally drafted (a critique of choosing the Heaviside step function as activation, linking Obj. 1 and Obj. 3) was dropped in conversation with the teacher: too complex for the chapter's 25′ budget and for the cognitive load already carried by item 02 (a numerical forward pass) and item 03 (a numerical descent step). The Argumentation category is *intentionally absent* from this chapter's item bank; the chapter still verifies all three learning objectives across two distinct cognitive categories (Comprehension + Application). Chapter 5 leans heavily *applicativa*, which is appropriate for a chapter whose core insight is *operational* — "you can write the equation and take the step yourself".

> **Note on numbers:** the items use architectures and weight matrices **different** from those in the chapter's summative exercise ($3 \to 2 \to 2 \to 1$ with $12$ weights, in [objectives.md](objectives.md)). Item 02 uses $3 \to 4 \to 2 \to 1$ with $22$ weights and a concrete $W^{[1]} \in \mathbb{R}^{4 \times 3}$; item 03 uses a toy 2-weight network with a concrete gradient $(2, -4)$ and learning rate $\eta = 0.5$. The items measure the *procedure* — "can you compose, count, descend?" — not the student's memory of the summative-exercise rows. Same convention as ch. 04.

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — describe the neuron as a generalised non-linear logistic unit ($\text{out} = g(\sum_i a_i w_i)$ with $g$ non-linear and differentiable), recognising the swap of activation as the *single* mathematical change relative to logistic regression | Comprehension | MCQ | low–medium | [item_01_neuron-as-generalised-logistic_mcq.md](items/item_01_neuron-as-generalised-logistic_mcq.md) |
| 02 | Obj. 2 — compose the forward pass of a small fully-connected network ($a^{[l]} = g^{[l]}(W^{[l]} a^{[l-1]})$): write the equations with explicit matrix dimensions, count the total weights decomposed by layer, and operate one forward pass numerically | Application | applicativa | medium | [item_02_forward-pass-and-weight-count_applicativa.md](items/item_02_forward-pass-and-weight-count_applicativa.md) |
| 03 | Obj. 3 — apply the gradient-descent update $W \leftarrow W - \eta \, \nabla_W L(W)$ for one step: pick the correct $W_{\text{next}}$ given $W_{\text{now}}$, $\nabla_W L(W_{\text{now}})$ and $\eta$, with distractors isolating sign-flip (ascent) and forgotten-$\eta$ misconceptions | Application | MCQ (scenario) | medium | [item_03_gradient-descent-step_mcq.md](items/item_03_gradient-descent-step_mcq.md) |

## Coverage

**By objective** (all three chapter objectives covered, one item per objective):

- **Obj. 1** (neuron as generalised non-linear logistic unit): item 01 (Comprehension).
- **Obj. 2** (forward pass + weight count, composition of layers): item 02 (Application, applicativa).
- **Obj. 3** (gradient descent on a loss landscape, requirements on $g$): item 03 (Application, MCQ scenario). Note: the *requirements on $g$* half of Obj. 3 (non-linearity + differentiability) is verified at *teaching* time (frame 4 of [storyboard.md](storyboard.md) + the in-class summative *"Open the box: $3 \to 2 \to 2 \to 1$"* in [objectives.md](objectives.md)) and is *not* a separate evaluative item — the Argumentation item that would have done this was deliberately dropped (see set-size note above).

**By cognitive category** (2 of 4 categories, no pure-recall item; Argumentation absent by design):

- Knowledge: 0
- Comprehension: 1
- Application: 2
- Argumentation/evaluation: 0

## Rubrics

- [rubrica_02_forward-pass-and-weight-count.md](rubriche/rubrica_02_forward-pass-and-weight-count.md) — item 02 (applicativa)

*(Items 01 and 03 are MCQ — single correct option, no rubric.)*

## Internal coherence — items 02 and 03 build the operational fluency the chapter requires

The two Application items are deliberately staged so the student must *operate* the two halves of the chapter's mechanism:

- **Item 02** asks the student to *operate the forward pass*: given an architecture and a concrete weight matrix, compute the first hidden layer's output. The teachable beat is the fourth pre-activation $z^{[1]}_4 = -2$ being killed by ReLU to $0$ — the non-linearity *doing visible work*.
- **Item 03** asks the student to *operate the backward pass at one point*: given the current weights and the gradient at that point, compute the next weights. The teachable beat is the sign of the update ($-$, not $+$) and the role of the learning rate $\eta$ (step size, not magic).

Together, items 02 and 03 cover one *full training iteration* — forward (input → hidden activations) and backward (gradient → updated weights) — without ever invoking backpropagation by name. The student who masters both items has *operated* the chapter's central machinery; item 01 then anchors the *recognition* that the atom of that machinery is the generalised logistic unit they already met in ch. 02.

## Anti-leakage — vocabulary boundary with ch. 06

The items stay strictly within ch. 05 vocabulary: *neuron*, *weight*, *layer*, *activation* $g$, *non-linear*, *differentiable*, *loss landscape*, *gradient*, *gradient descent*, *learning rate $\eta$*. They do **not** presuppose any concept from ch. 06+ (convolution, kernel, filter, stride, weight sharing, recurrent connection, time-step, CNN, RNN, transformer, attention, LLM, agents). The chapter's pre-hook to ch. 06 (chest X-ray, ECG/BP trace as data shapes too large for a 12-weight fully-connected first layer) is staged in the chapter's [narrative](narrative.md) and [storyboard frame 6](storyboard.md), *not* inside the items.

## Pre-hook to ch. 06 — left to the chapter, not embedded in items

Same convention as ch. 04 (whose pre-hook to ch. 05 was in narrative + storyboard, never in items). The items measure what *this* chapter has taught, with no forward references; the *narrative* of the chapter carries the bridge to the next one.

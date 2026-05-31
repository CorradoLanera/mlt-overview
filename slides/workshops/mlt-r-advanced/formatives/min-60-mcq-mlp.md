# Formative · min 60 · MCQ (after Step 02, MLP parameter slide)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph nodes checked:** `PARAMS_DL` — MLP knobs: epochs / learn_rate / hidden_units / batch / activation / penalty; `BV` — Bias-variance tradeoff

## Prompt

The live MLP is overfitting — the training loss keeps dropping but the validation
loss has levelled off or risen. Which of the following interventions would most
directly address the overfit?

## Options

- **A. ✓ (correct)** **Increase `penalty`** (L2 weight regularisation) **or
  decrease `hidden_units`**: both reduce the model's capacity and push it toward
  the high-bias / low-variance end of the tradeoff. These are the knobs for
  overfitting in an MLP.
- **B.** **Train for more epochs**: the model just needs more gradient steps to
  find the right weights; stopping early is what causes the overfit.
- **C.** **Raise the learning rate**: a larger step size allows the optimiser to
  escape the sharp minima associated with overfitting.
- **D.** **Change the activation function** (e.g. ReLU → tanh): activation choice
  acts as a regulariser; using a smoother activation smooths out the overfit.

## Misconception each distractor reveals

- **B → "more epochs fix overfit."** Has the direction backwards: more training
  time *deepens* an overfit by giving the model more opportunity to memorise the
  training set. Early stopping is a remedy, not a cause.
- **C → "raise learning rate to escape overfit."** Confuses optimisation dynamics
  with generalisation: a higher learning rate may destabilise training entirely
  and does not reduce model capacity; it does not act as regularisation.
- **D → "activation is the regulariser."** While activation choice affects
  gradient flow and expressiveness, it is not a direct regularisation mechanism;
  `penalty` and capacity (layer width/depth) are the primary levers for the
  bias–variance tradeoff in `brulee`/`torch`.

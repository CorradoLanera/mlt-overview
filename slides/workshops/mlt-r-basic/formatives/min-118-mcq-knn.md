# Formative · min 118 · MCQ (after Step 04, parameter slides)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph node checked:** `PARAM` → `BV` — Hyperparameters control bias–variance (k-NN `neighbors`)

## Prompt

For k-nearest-neighbours, how does the number of neighbours **`k`** affect
bias and variance?

## Options

- **A. ✓ (correct)** **Small `k`** (e.g. 1–3) gives **low bias, high variance** — the
  boundary follows local noise and overfits. **Large `k`** gives **high bias, low
  variance** — predictions are smoothed over many neighbours and may underfit. `k` is
  the bias–variance dial.
- **B.** **Larger `k` is always better**: more neighbours means more information, so
  accuracy keeps improving as `k` grows.
- **C.** `k` only controls **computation speed** — it trades runtime for memory but
  does not change the model's predictions or its bias/variance.
- **D.** Small `k` gives **high bias, low variance** and large `k` gives **low bias,
  high variance** (the bias–variance direction is the reverse of A).

## Misconception each distractor reveals

- **B → "more k is always better."** Treats `k` as a quality score to maximize rather
  than a tradeoff; ignores that very large `k` over-smooths and underfits.
- **C → "k is only a speed setting."** Thinks the knob is purely computational; misses
  that `k` governs model **flexibility** and therefore the bias–variance balance.
- **D → "bias–variance direction inverted."** Has the tradeoff backwards — believes a
  flexible small-`k` model is high-bias and a smooth large-`k` model is high-variance.

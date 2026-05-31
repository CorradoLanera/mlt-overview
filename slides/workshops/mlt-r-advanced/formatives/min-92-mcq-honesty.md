# Formative · min 92 · MCQ (after Step 02, option-B labeled loss curve)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph nodes checked:** `HONESTY` — Honesty rule: nothing pre-baked shown as live; `OPTB` — OPTION B: pre-trained loss curve labeled

## Prompt

We just showed the loss curve for the fused network and said
*"I trained this earlier on GPU."*
Which of the following best describes how this fits the workshop's honesty rule?

## Options

- **A. ✓ (correct)** The loss curve is the **single labeled exception**: it was
  explicitly announced as pre-trained on GPU and shown as a *didactic object*, not
  as a live result. The CPU epoch we killed *was* genuinely live — the kill
  demonstrated a real performance gap. Every other number in the workshop was
  computed in real time.
- **B.** No result in this workshop is ever cached or pre-computed — the honesty rule
  means everything runs live, including the fused network's loss curve.
- **C.** All deep learning outputs in the workshop can be pre-trained and shown
  without a label, because training time is a practical constraint that justifies
  skipping the live-coding doctrine.
- **D.** Showing a pre-trained result labeled as such is identical to the `targets`
  cache showing "skip" — both are pre-computed, so both follow the same rule.

## Misconception each distractor reveals

- **B → "nothing is ever cached."** Overstates the rule: the honesty constraint is
  "do not show a pre-cooked result **as if it were live**" — a clearly labeled
  pre-trained object is explicitly allowed as a didactic artifact.
- **C → "all DL can be pre-trained without a label."** Strips the rule of its key
  condition (the label / the announcement). Showing a pre-trained result without
  disclosure is exactly what the honesty rule prohibits.
- **D → "same rule as targets skip."** Conflates two different mechanisms:
  `targets` "skip" means the result is **re-derivable** from unchanged inputs
  (reproducibility, not pre-cooking); the labeled loss curve is a **one-off GPU
  artefact** that cannot be reproduced live in the classroom. They are conceptually
  distinct.

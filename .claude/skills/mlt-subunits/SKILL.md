---
name: mlt-subunits
description: Split a chapter into sub-learning-units, each with its own mini hook-challenge-resolution-payoff arc and a formative exercise pair (proposed at the start, solved at the end). On-demand per chapter. Use for "sub-units for chapter X", "sotto-unità", "formative proposto/risolto", or /mlt --phase subunits.
---

# mlt-subunits

On-demand, for ONE chapter at a time. Student-facing text **English**; teacher notes **Italian**.

## Collect

- Chapter slug/title (manifest) + its `objectives.md` and `narrative.md` if present (read them).

## Produce (write `course/<slug>/subunits.md`)

Split the chapter into 2-4 **sub-learning-units**. For each sub-unit:

1. **Mini-arc**: Hook → Challenge/Data → Resolution → Payoff (2-4 sentences each), aligned to the chapter arc.
2. **Formative exercise pair** (formative = for learning, not graded):
   - **Proposed** (at the sub-unit start): a short task the students attempt first.
   - **Solved** (at the sub-unit end): the worked solution + what the attempt should reveal.

Keep each sub-unit self-contained. Math in `$...$`.

## Output

Write `course/<slug>/subunits.md` (hook renders the HTML). Report and stop at the /mlt gate. Do NOT edit the manifest.

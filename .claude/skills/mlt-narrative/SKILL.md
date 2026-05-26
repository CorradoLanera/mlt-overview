---
name: mlt-narrative
description: Build the MLT narrative spine — global six-word + 100-word + arc, and per-chapter six-word, 100-word, and a hook-challenge-resolution-payoff arc with an explicit pre-hook to the next enabled chapter. Use for "narrative for chapter X", "spine narrativa", "arco del capitolo", or /mlt --phase narrative.
---

# mlt-narrative

Orchestrates the storia-companion v2 atoms across the MLT chapters. Student-facing prose in **English**;
design glosses in **Italian**. Requires storia-companion v2 installed.

## Global spine (write `course/_global/spine.md`), once

- **Six words**: invoke `sei-parole` for the whole-course theme (ML overview for clinicians). Pick the best
  with `narratore-critico`.
- **100 words, 3 acts**: invoke `bing-bang-bongo` for the whole course.
- **Course arc**: invoke `arco-narrativo-didattico` for the whole course (Hook → Challenge → Resolution → Payoff).

## Per chapter (write `course/<slug>/narrative.md`)

For each target enabled chapter (use `manifest.enabled_chapters`):

1. **Six words** (`sei-parole`) for the chapter theme — best variant via `narratore-critico`.
2. **100 words, 3 acts** (`bing-bang-bongo`) for the chapter.
3. **Arc** (`arco-narrativo-didattico`): full Hook → Challenge/Data → Resolution → Payoff prose for the chapter.
4. **Pre-hook**: an explicit 1-2 sentence bridge to the NEXT enabled chapter. Compute it with
   `manifest.next_enabled(m, slug)`; if it returns None (last chapter), write a pre-hook toward "what comes
   next" (the applied follow-up workshops). For the **Agents** chapter, the pre-hook may point to those
   workshops (see `docs/sources/agents-from-storia-workshop.md`).

Math in `$...$`.

## Output

Write `course/_global/spine.md` and each `course/<slug>/narrative.md` (hook renders the HTML). Report per
chapter and stop at the /mlt gate.

---
name: mlt-quarto-build
description: Assemble a chapter's Quarto revealjs slides FROM its storyboard. Each of the 6 storyboard beats expands into 1-N slides — the anchor slide carries img/storyboard/sb-NN_FF.png (the canonical beat image), expansion slides reuse supporting figures from img/ and formulas/explanations from _archive/legacy-xaringan/index.Rmd. Then (re)generate the modular master from the manifest. Use for "build slides for chapter X", "genera le slide Quarto", "render the deck", or /mlt --phase slides.
---

# mlt-quarto-build

Generate the new revealjs slides for ONE chapter from the Fase A artifacts. The storyboard is the **narrative
spine** (six dramaturgical beats per chapter); the slides are the **didactic device** that expands each beat.
Student-facing text in **English**; speaker notes (Voce docente) in **Italian**. Math in `$...$`.

## Collect

- Chapter slug/title/minutes from `course/_manifest.yml`.
- `course/<slug>/storyboard.md` (REQUIRED — the 6-frame blueprint), plus `narrative.md` and `objectives.md`.
- **Visual assets, in priority order:**
  1. **`img/storyboard/sb-<NN>_<FF>.png`** — the *canonical anchor image* of each beat, where `<NN>` is the
     2-digit prefix of the chapter slug (e.g. `04` for `04-model-selection`) and `<FF>` is the frame index
     `01`..`06`. The teacher prepares these; use them as-is for the corresponding beat's anchor slide.
  2. **`img/<...>`** — the historical supporting library (~139 figures from the original deck): algorithm
     diagrams, plots, attention animations, clinical examples, GIFs. Reused FREELY across the expansion slides
     of each beat by topical match.
  3. **`_archive/legacy-xaringan/index.Rmd` / `_archive/legacy-xaringan/index-full.Rmd`** — content source for reusable formulas (already in `$...$`), historical
     wording, and the teacher's previous figure↔concept pairings (helps choose from (2)).

## Produce `slides/course/<slug>.qmd`

The flow follows the storyboard's six **beats** (narrative functions: *Hook visivo · Contesto · Sfida/Dati ·
Nodo/Impatto · Metodo/Soluzione · Payoff/Domanda finale*). Each beat expands into **1 to N slides** (typically
1-4 in a 25′ chapter; size the expansion by the chapter's `minutes` and by topic density — a 4h overview ends
up around 80-120 slides total, *not* 6 per chapter).

For each beat:

- **Anchor slide** — the slide that opens (or, when more effective, closes/transitions) the beat carries the
  storyboard image: `![](../../img/storyboard/sb-<NN>_<FF>.png)`. This is the "hero shot" of the beat. Its
  visible text is the storyboard's *Testo a video* — the punchline of the beat. If the anchor PNG is missing,
  fall back to scanning `img/` for a thematic match; if nothing fits, insert a placeholder line plus an HTML
  comment with the storyboard's *Visual* prompt (English) for later image generation.
- **Expansion slides (0+)** — unfold the beat for didactic delivery: concept → example → formalisation → plot
  → clinical instance → take-away, as needed for the beat's role. Pull supporting figures from `img/` via
  topical match; consult `_archive/legacy-xaringan/index.Rmd`/`_archive/legacy-xaringan/index-full.Rmd` for which figure the teacher used historically for that
  concept. Keep visible text concise; details and narrative go into speaker notes.
- **Speaker notes (Italian)** on every slide as `::: {.notes}` … `:::` — these are the *Voce docente* from the
  storyboard plus any expansion the slide needs.
- The **Payoff/Domanda finale beat** closes with the chapter's pre-hook (from `narrative.md`) toward the next
  enabled chapter (use `manifest.next_enabled`).

Each slide is a `##` heading. The first slide of each beat may carry the beat name in its title (e.g.
`## Challenge — high-dimensional kNN`) and/or an HTML comment marker (`<!-- BEAT 3: Sfida/Dati -->`) for the
teacher's reference. Beat boundaries are dramaturgical, not syntactic — the teacher reads the storyboard
alongside the deck.

## Regenerate the modular master + render

1. Write/refresh `slides/course.qmd`:
   `python -c "import sys;sys.path.insert(0,'.claude/skills/lib');import manifest,quartoyml;open('slides/course.qmd','w',encoding='utf-8').write(quartoyml.build_slides_master(manifest.load()))"`
2. Render: `quarto render slides/course.qmd --to revealjs`.
3. **Visual QA** (mandatory): open the rendered chapter with chrome-devtools at 1920×1080 and at a narrow
   viewport; check overflow, cut-off images, contrast, math rendering. Fix and re-render until clean.

## Incremental rendering tip

If only some chapters have `slides/course/<slug>.qmd` built, toggle the not-yet-built chapters to
`include: false` in `course/_manifest.yml` before rendering — the manifest-driven master will then include
only the chapters whose `.qmd` exists, so `quarto render` won't fail on missing includes.

## Output

`slides/course/<slug>.qmd` + refreshed `slides/course.qmd`. Report and stop at the gate.

---
name: mlt-quarto-build
description: Assemble a chapter's Quarto revealjs slides FROM its storyboard (not by migrating index.Rmd), reusing images and formulas from the old deck, then (re)generate the modular master from the manifest. Use for "build slides for chapter X", "genera le slide Quarto", "render the deck", or /mlt --phase quarto.
---

# mlt-quarto-build

Generate the new revealjs slides for ONE chapter from the Fase A artifacts. The flow follows the **storyboard**,
not the old slide order. `index.Rmd` / `index-full.Rmd` and `img/` are an ASSET source. Student-facing text in
**English**; speaker notes (Voce docente) in **Italian**. Math in `$...$`.

## Collect

- Chapter slug/title/minutes from `course/_manifest.yml`.
- `course/<slug>/storyboard.md` (REQUIRED — the 6-frame blueprint), plus `narrative.md` and `objectives.md`.
- Reusable assets: scan `img/` for figures matching the chapter's topics; scan `index.Rmd`/`index-full.Rmd`
  for reusable formulas/explanations for the same concept.

## Produce `slides/chapters/<slug>.qmd`

- One section title slide: `# <Chapter title>`.
- For each storyboard frame (Hook visivo · Contesto · Sfida/Dati · Nodo/Impatto · Metodo/Soluzione · Payoff/Domanda finale):
  - a slide `## <short frame label>`;
  - **Testo a video** → the visible slide content (concise, English; keep math in `$...$`);
  - **Visual** → if a matching figure exists in `img/`, embed it `![](../../img/<file>)`; otherwise insert a
    placeholder image line plus an HTML comment with an English image-generation prompt taken from the storyboard;
  - **Voce docente** → speaker notes block `::: {.notes}` … `:::` (Italian);
  - the **Payoff/Domanda finale** frame carries the chapter's pre-hook (from `narrative.md`) toward the next chapter.

## Regenerate the modular master + render

1. Write/refresh `slides/slides.qmd` using `quartoyml.build_slides_master(manifest.load())` (only enabled chapters):
   `python -c "import sys;sys.path.insert(0,'.claude/skills/lib');import manifest,quartoyml;open('slides/slides.qmd','w',encoding='utf-8').write(quartoyml.build_slides_master(manifest.load()))"`
2. Render: `quarto render slides/slides.qmd --to revealjs`.
3. **Visual QA** (mandatory): open the rendered chapter with chrome-devtools at 1920×1080 and at a narrow
   viewport; check overflow, cut-off images, contrast, math rendering. Fix and re-render until clean.

## Output

`slides/chapters/<slug>.qmd` + refreshed `slides/slides.qmd`. Report and stop at the gate.

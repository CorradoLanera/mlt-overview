# CLAUDE.md — corso MLT (mlt-overview)

Repo del corso "Machine Learning — An Applied Overview" (UBEP). Rinnovazione: vedi
`docs/superpowers/specs/2026-05-26-mlt-course-toolkit-design.md`. Tracking nel vault:
`progetti/mlt-overview/` (privato).

## Convenzioni non negoziabili

- **Lingua:** artefatti rivolti agli studenti (slide, item, syllabus, testo-a-video) in **INGLESE**;
  note del docente, "voce del docente", commenti di design e note di lavoro in **ITALIANO**.
- **Matematica:** ogni formula, pedice, overline, simbolo stand-alone in `$...$` (mai combining-Unicode).
  L'HTML generato rende la matematica (MathML via pandoc).
- **Liste markdown:** sempre una riga vuota prima di un elenco puntato/numerato.
- **Item valutativi:** `item_<NN>_<slug>_<type>.md` + `.html` accanto; indice `items_valutativi.md` + `.html`.
- **Rubriche:** 3 livelli `base / good / excellent` (EN), descrittori osservabili, soglia di sufficienza.
- **Fonte di verità della struttura:** `course/_manifest.yml`. Aggiungere/togliere capitoli = editare `include:`.
- **Verifica visiva obbligatoria:** nessun HTML/slide è "pronto" senza ispezione visiva (chrome-devtools).

## Strumenti

- Skill atomiche riusate da `storia-companion` v2 (verifica: la skill è `itembank`, NON `itembank-bloom`).
- Skill/command project-local: `mlt-scaffold`, `mlt-objectives`, `mlt-narrative`, `mlt-subunits`,
  `mlt-quarto-build`, orchestratore `/mlt` (vedi spec).
- Hook `md-to-html-math.py`: ogni `course/**/*.md` scritto → `.html` self-contained con matematica.

## Stato build

- Fase 0 (fondazione): in corso. Fase A (contenuti), Fase B (Quarto/PDF): da fare.

## Architettura (3 moduli)

Un repo, un corso, tre moduli: **teoria/overview** (`course/` + `slides/`),
**pratica base** (`workshops/mlt-r-basic/`), **pratica advanced** (`workshops/mlt-r-advanced/`, da creare).
Layout e contratto: `docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`.
I `CLAUDE.md` dei workshop contengono **solo** il delta R-authoring; lingua/matematica/liste/verifica
visiva valgono da qui per tutti i moduli.

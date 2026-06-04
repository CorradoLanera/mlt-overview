# CLAUDE.md — corso MLT (mlt-overview)

Repo del corso "Machine Learning — An Applied Overview" (UBEP). Design di riferimento:
architettura unificata `dev-docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`
+ riordino `dev-docs/superpowers/specs/2026-06-04-mlt-repo-reorg-design.md`
(storico: `2026-05-26-mlt-course-toolkit-design.md`). Tracking nel vault:
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
- Skill project-local: `mlt-narrative`, `mlt-objectives`, `mlt-subunits`, `mlt-quarto-build`, `mlt-pilot`.
- Command project-local: `/mlt` (orchestratore), `/mlt-scaffold`, `/mlt-build`, `/mlt-beat`,
  `/mlt-workshop-build`, `/mlt-dist` (deprecato → usa `/mlt-build`).
- Hook `md-to-html-math.py`: ogni `course/**/*.md` scritto → `.html` self-contained con matematica.
- Hook `remind-workshop-dist.py`: dopo Write/Edit in `workshops/**`, `slides/workshops/**` o
  `styles/_brand.scss`, ricorda di rilanciare `/mlt-build`.

## Stato build

- Tutte le fasi completate e mergiate in `main`: overview deck Quarto (10 cap.), item
  valutativi per capitolo, due workshop R (Basic+Advanced) fragment-built, sito Quarto in `docs/`,
  dist ZIP + release assets. Build idempotente via `python scripts/build_all.py` (`/mlt-build`).
- Riordino strutturale (2026-06-04, HEAD `2681c11`, **pushato**): `slides/chapters/`→`slides/course/`,
  `slides/slides.qmd`→`slides/course.qmd` (sorgente==pubblicato `course.html`, **mai** rigenerare
  `slides.html`), `doc/` ritirata, `data-raw/` top-level tolta dagli ZIP fragment. Tutti e 7 gli asset
  `coorte-2026` ricaricati freschi.
- **Gotcha build:** i workshop richiedono **R 4.6.0**; col `Rscript` di default (R 4.5.2) `rebuild.R`
  fallisce con `no package called 'quarto'`. Prima di `build_all.py --release`:
  `$env:MLT_RSCRIPT="C:\Program Files\R\R-4.6.0\bin\Rscript.exe"`.

## Architettura (3 moduli)

Un repo, un corso, tre moduli: **teoria/overview** (`course/` + `slides/`),
**pratica base** (`workshops/mlt-r-basic/`), **pratica advanced** (`workshops/mlt-r-advanced/`).
Layout e contratto: `dev-docs/superpowers/specs/2026-05-31-unified-course-architecture-design.md`.
I `CLAUDE.md` dei workshop contengono **solo** il delta R-authoring; lingua/matematica/liste/verifica
visiva valgono da qui per tutti i moduli.

# Machine Learning — An Applied Overview

> **Resume the build (teacher):** reload Claude Code in this repo, then type *"andiamo avanti col corso MLT"* (or `/mlt`) and follow the guided steps — no commands to remember.

Introductory ML overview for biomedical/clinical graduate students (UBEP, University of Padova).
~4h gross. From the T-P-E framework to classifiers, model selection, deep learning, LLMs and agents,
with an applied clinical slant.

## Structure (modular)

The course is chapter-based. The single source of truth is [`course/_manifest.yml`](course/_manifest.yml):
each chapter has an `include:` toggle and an estimated duration. Add or drop a module by editing one line.

Per-chapter artifacts live in `course/<NN-slug>/`: learning objectives, narrative arc, optional
sub-units, storyboard, and an evaluative item bank with rubrics. Global narrative spine and syllabus
live in `course/_global/`.

## Build (planned, Fase B)

Slides are being migrated from xaringan (`index.Rmd`) to Quarto revealjs. Once migrated:

- render slides: `quarto render` (only chapters with `include: true`);
- export student PDF: requires `quarto install chrome-headless-shell`.

## Authoring

Student-facing content is in **English**; teacher notes are in Italian. Math is written in `$...$`.
Writing any `course/**/*.md` auto-generates a self-contained `.html` (with rendered math) next to it.

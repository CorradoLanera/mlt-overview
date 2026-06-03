---
description: (Re)generate the course tree and per-chapter folders from course/_manifest.yml without overwriting existing content.
---

Read `course/_manifest.yml`. For every chapter (regardless of `include:`), ensure the folder
`course/<slug>/` exists with empty subfolders `items/` and `rubriche/`. Never overwrite an existing
`.md`/`.qmd`/`.html`; only create what is missing and report a summary table (created vs already-present).
Do not touch `_archive/legacy-xaringan/index.Rmd`, `_archive/legacy-xaringan/index-full.Rmd`, or `img/`. Any student-facing stub text must be in English.

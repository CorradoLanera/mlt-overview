# Piano d'implementazione — Portale pubblico del corso (GitHub Pages)

- **Data:** 2026-06-01
- **Spec:** `docs/superpowers/specs/2026-06-01-course-portal-site-design.md` (→ dopo Fase 0: `dev-docs/superpowers/specs/…`)
- **Repo:** `CorradoLanera/mlt-overview` · branch di lavoro consigliato: `portal-site` (l'utente pusha; Claude non pusha mai)
- **Esecuzione:** fasi sequenziali, **un commit per cambiamento logico**; checkpoint di revisione a fine di ogni fase.
- **Vincolo guida:** non si riscrivono contenuti del corso — si scrivono solo `site/` + `scripts/build_*` + repoint/gitignore.

> Obiettivo: trasformare `portal.html` (dashboard d'autore) in un **sito pubblico GitHub Pages** che serve i tre moduli
> (teoria + 2 workshop) con slide, pianificazione e download. Dual-build: *live* = deck non-embed → `/docs`; *release* =
> deck embed + ZIP come asset di coorte. Serving A (Quarto website → `/docs`, no CI).

## Pre-flight

- [ ] Confermare che il working tree non abbia modifiche in sospeso che si vogliono mescolare (oggi risultano non-committate
  `data/PubMed_…csv` (D), `slides/workshops/mlt-r-basic/00-basic-deck.qmd` (M), `workshops/mlt-r-basic/.gitignore` (M) + PNG QA
  non tracciati): **non** verranno toccate da questo piano; commit separati dell'utente se servono.
- [ ] (Opz.) Creare il branch `portal-site` per isolare il lavoro.
- [ ] Verificare i tool: `quarto --version`, `python --version` (≥3.10), `git`.
- [ ] Confermare che l'overview deck **renderizza senza eseguire R** (prova: `quarto render slides/slides.qmd -M embed-resources:false`
  in una dir temporanea / o `--no-execute`). Se richiede R, annotare l'ambiente necessario (non blocca il piano).

---

## Fase 0 — Rilocazione note interne fuori da `/docs` + repoint

**Goal:** liberare `/docs` perché ospiti **solo** il sito; spostare le note interne in `dev-docs/` (tracciata, non pubblicata).

1. `git mv docs/superpowers dev-docs/superpowers` e `git mv docs/sources dev-docs/sources` (crea `dev-docs/`).
   - Questo sposta anche **spec e questo piano** sotto `dev-docs/superpowers/{specs,plans}/`.
2. Repoint dei riferimenti — `grep -rn "docs/superpowers\|docs/sources"` su tutto il repo (esclusi `.git`, `renv/`); aggiornare:
   - root `.claude/CLAUDE.md` (cita `docs/superpowers/specs/2026-05-26-…`);
   - `.claude/CLAUDE.md` di progetto (cita `docs/superpowers/specs/2026-05-26-…` e `…2026-05-31-…`);
   - eventuali cross-ref dentro i piani/spec stessi e in `scripts/` (es. `build_portal.py`), README.
3. Verificare che `docs/` ora contenga **solo** ciò che diventerà sito (al momento: vuota o assente → la creeremo in Fase 4).

**Verifica:** `grep -rn "docs/superpowers\|docs/sources"` non trova più riferimenti vivi; `git status` mostra solo rename + edit di repoint.
**Commit:** `Relocate internal design docs out of /docs (docs/{superpowers,sources} → dev-docs/) + repoint`.

> Nota: `dev-docs/` è il nome proposto; se preferisci `_specs/`/`notes/`, cambialo qui e nel resto del piano prima di eseguire.

---

## Fase 1 — Scaffold del Quarto website `site/`

**Goal:** la "shell" multipagina (landing + nav + brand), con wrapper sottili e meccanismo di include generati.

1. `site/_quarto.yml`:
   - `project: { type: website, output-dir: ../docs, render: [ "*.qmd" ] }`
   - `website:` titolo "Machine Learning — An Applied Overview"; `navbar` con: Home, Theory, Basic, Advanced, Schedule, Downloads;
     `page-footer` (UBEP · link al repo).
   - `format: html: { theme: [cosmo, _brand.scss], toc: false, page-layout: full }`
   - `lang: en` (sito rivolto a studenti/docenti — EN).
2. `site/_brand.scss` — riusa i token di `styles/_brand.scss` come variabili Bootstrap:
   `$primary: #E8741E; $secondary: #1F4257;` + font (Cabin / Noto Sans / Source Code Pro via `$font-family-sans-serif`,
   `$headings-font-family`, `$font-family-monospace`) + `/*-- scss:rules --*/` per card-modulo.
3. Pagine wrapper (EN, contenuto vivo via `{{< include _generated/… >}}`):
   - `index.qmd` — hero + 3 card-modulo (link "Open slides" + "Download") + learning path Overview→Basic→Advanced + prerequisiti.
   - `theory.qmd` — bottoni "Open slides" (`slides/slides.html`) + "Download self-contained deck" (release latest); include
     `_generated/theory-chapters.md` (tabella `NN · titolo · minuti · obiettivi`); blocco Syllabus (vedi Fase 2.5).
   - `basic.qmd` / `advanced.qmd` — include `_generated/<slug>-overview.md` (da README) + "Open deck"/"Download deck" +
     `_generated/<slug>-timeline.md` (checkpoint formative) + How-to-run (`use_course` + `renv::restore`; advanced: nota API key) +
     elenco formative + Syllabus.
   - `schedule.qmd` — include `_generated/schedule.md` (teoria con minuti + i due workshop con checkpoint).
   - `downloads.qmd` — link `releases/latest/download/<asset>` (nomi contrattuali §7 spec) + istruzioni R + modello per-coorte.
4. `.gitignore` (root): aggiungere `site/_generated/`.

**Verifica:** `quarto render site/` produce `/docs/*.html` con navbar e brand (anche con include vuoti/placeholder); ispezione
visiva rapida della Home (chrome-devtools) a ~1100px.
**Commit:** `Scaffold public Quarto website (site/) with brand + 6 thin pages`.

---

## Fase 2 — `scripts/build_site.py` (build live, deterministico, R-free salvo deck teoria)

**Goal:** un entry-point unico che genera `/docs` completo e auto-consistente.

1. **Partials generator** → `site/_generated/`:
   - `theory-chapters.md` da `course/_manifest.yml` (slug/title/minutes) + per capitolo gli obiettivi estratti da
     `course/<slug>/objectives.md`: prendi la lista sotto `## Learning objectives`, **ferma all'occorrenza di `*Nota docente:*`
     o del prossimo heading `##`**; nessun testo IT, nessun esercizio sommativo.
   - `<slug>-overview.md` (basic/advanced) da `workshops/<slug>/README.md` (sezioni overview / what you build / dataset / prereq).
   - `<slug>-timeline.md` dai nomi-file `slides/workshops/<slug>/formatives/min-NN-*` (ordina per NN → "min N · <tipo/slug>").
   - `schedule.md` = teoria (capitoli + minuti, somma) + i due workshop (~4h, checkpoint min-NN).
2. **Render site:** `quarto render site/` → `/docs`.
3. **Render deck NON-embed → `/docs/slides/`:**
   - Teoria: `quarto render slides/slides.qmd -M embed-resources:false` → copia `slides/slides.html` + `slides/slides_files/`
     in `/docs/slides/` (il deck referenzia `../img` → `/docs/img`, e `slides_files/`).
   - Workshop: per slug, `quarto render slides/workshops/<slug>/ -M embed-resources:false` → copia
     `00-*-deck.html` (+ `*_files/`) in `/docs/slides/workshops/<slug>/`.
4. **Sync asset:** copia `img/` → `/docs/img/`; scrivi `/docs/.nojekyll`.
5. **Syllabus (forward-compatible):** se esiste l'artefatto syllabus del modulo (path da definire quando `/mlt` lo produce —
   placeholder atteso es. `course/_global/syllabus-overview.*`, `workshops/<slug>/syllabus.*`), copialo/renderizzalo in `/docs`
   e setta una variabile/include che attiva il link; altrimenti scrivi un include "Syllabus — in preparazione".

**Idempotenza:** lo script pulisce/rigenera in modo deterministico (stessi input → stesso `/docs`, diff stabile).
**Verifica:** dopo `python scripts/build_site.py`, `/docs` contiene index+5 pagine, `slides/slides.html` + 2 deck workshop, `img/`,
`.nojekyll`; nessun file `> 100 MB` (`find docs -size +100M`); apertura locale del deck teoria carica le immagini da `/docs/img`.
**Commit:** `Add scripts/build_site.py (live site build → /docs)`.

> Scelta d'impl.: orchestratore Python standalone (chiaro/deterministico) invece di `pre-render`/`post-render` Quarto.
> (Opzionale) wrapper `/mlt-site` come slash-command, coerente con `/mlt-dist` — non bloccante.

---

## Fase 3 — `scripts/build_release.py` (asset di coorte) — riusa `/mlt-dist`

**Goal:** raccogliere in `dev/release-assets/` (gitignorato) i deliverable congelati per la release di coorte.

1. Render dei 3 deck `embed-resources: true` → `dev/release-assets/` con nomi contrattuali:
   `mlt-overview-theory-deck.html`, `mlt-r-basic-deck.html`, `mlt-r-advanced-deck.html`.
2. Riusa `/mlt-dist` per (ri)costruire gli ZIP in `dist/`, poi copia `dist/mlt-r-basic.zip` e `dist/mlt-r-advanced.zip` in
   `dev/release-assets/` (nomi invariati: combaciano con `use_course()` nei README).
3. Stampa un promemoria: l'utente aggiunge eventuale materiale di coorte, poi `git tag coorte-AAAA` + upload manuale degli asset.

**Verifica:** `dev/release-assets/` contiene 3 HTML self-contained (apribili offline) + 2 ZIP; `git status` non li traccia (`dev/`).
**Commit:** `Add scripts/build_release.py (per-cohort release assets → dev/release-assets/)`.

---

## Fase 4 — `.gitignore` + primo render + commit di `/docs`

**Goal:** pubblicare l'output committando `/docs`.

1. `.gitignore`: assicurarsi che **niente** intercetti `docs/slides/*.html`, `docs/slides/**/*_files/`, `docs/img/**`
   (le regole `slides/…`/`*.html` dei workshop sono path-specifiche all'albero sorgente; verificare con
   `git check-ignore -v docs/slides/slides.html docs/img/UBEP.png` → devono risultare **non** ignorati).
2. `python scripts/build_site.py` (render completo).
3. `git add docs/ && git commit` — **un** commit dell'output del sito.
   - Controllo dimensione: `find docs -type f -size +100M` deve essere vuoto.

**Verifica:** `git status` pulito su `docs/`; push (utente) non rifiutato per file > 100 MB.
**Commit:** `Publish initial site build to /docs`.

---

## Fase 5 — Verifica visiva (gate obbligatorio root CLAUDE.md)

**Goal:** nessuna pagina/deck "pronto" senza ispezione.

1. Servire `/docs` in locale (`python -m http.server` dentro `docs/` o `quarto preview`) e con chrome-devtools:
   - Home + Theory + Basic + Advanced + Schedule + Downloads a viewport ~1100px e a 1080p: niente overflow, nav funzionante,
     card/link corretti, brand coerente.
   - Aprire i **3 deck**: teoria (immagini caricate da `/docs/img`, math renderizzata), basic, advanced (slide 1 + navigazione).
   - Verificare che **nessun** testo IT interno (`*Nota docente:*`) sia trapelato nelle pagine estratte.
2. Fix mirati + ri-build finché il loop converge (leggibilità/coerenza, non "assenza di errori").

**Verifica:** screenshot delle pagine-chiave + dei 3 deck; checklist §13 dello spec soddisfatta.
**Commit:** eventuali fix → `Fix portal site visual issues from review` (se servono).

---

## Fase 6 — Documentazione, pointer e passi manuali

1. README di root: aggiungere il link al sito pubblico (`https://corradolanera.github.io/mlt-overview/`) e una riga sul modello
   release-per-coorte.
2. (Opz.) Nota in cima a `portal.html` che è uno **strumento d'autore interno** (non pubblicato; `/docs` serve il sito pubblico).
3. **Passi manuali dell'utente** (non eseguibili da Claude): Settings → Pages → Deploy from a branch → `main` (o `portal-site`) `/docs`;
   poi, a coorte: `build_release.py` → `git tag coorte-AAAA` → creare la Release → upload dei 5 asset.

**Verifica:** il sito risponde all'URL Pages dopo l'attivazione (controllo dell'utente).
**Commit:** `Document public site + release-per-cohort workflow in README`.

---

## Rischi e mitigazioni

- **Deck teoria esegue R** → il build live non è R-free: documentare l'ambiente; in alternativa renderizzare il deck a mano e far
  copiare allo script l'HTML+`_files` esistenti (build "copy-only").
- **`-M embed-resources:false` non onorato** dal `_quarto.yml` workshop (che fissa `true`) → usare un *profile* Quarto
  (`_quarto-site.yml` con `embed-resources: false`) o renderizzare con override esplicito; verificare la dimensione dell'HTML risultante.
- **Duplicazione `img/` in `/docs` (~123 MB)** → accettata ora; ottimizzazione opzionale futura (compressione PNG/GIF o git-lfs).
- **Estrazione obiettivi fragile** (formati eterogenei tra capitoli) → l'estrattore deve degradare con grazia (se non trova
  `## Learning objectives`, lascia il solo titolo+minuti e logga il capitolo).
- **Path syllabus ancora ignoto** → lo slot resta placeholder finché `/mlt` non genera i 3 syllabus; cablare il path allora.

## Open items (non bloccanti, da chiudere in impl)

- Nome cartella note interne (`dev-docs/` vs alternativa).
- Granularità timeline workshop (solo checkpoint vs minuti per sezione).
- Forma esatta delle card-modulo / hero (estetica) — soggetta al gate visivo.
- Profilo Quarto per il doppio embed (live false / release true).

## Definition of done

Tutti i criteri §13 dello spec verdi: URL Pages mostra la landing+nav; i 3 deck si aprono correttamente; Schedule mostra la
pianificazione completa; nessun file > 100 MB committato; `build_site.py` rigenera `/docs` in modo deterministico; nessun testo
IT interno né `dev-docs/` sotto il dominio Pages; Downloads punta agli asset di release con i nomi contrattuali.

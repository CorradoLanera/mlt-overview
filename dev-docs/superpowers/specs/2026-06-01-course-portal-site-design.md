# MLT — Portale pubblico del corso (GitHub Pages) — Design Spec

- **Data:** 2026-06-01
- **Repo:** `CorradoLanera/mlt-overview` → Pages URL attesa `https://corradolanera.github.io/mlt-overview/`
- **Autore:** Corrado Lanera (con Claude Code)
- **Stato:** bozza in revisione
- **Supersede per riferimento:** il `portal.html` di root (dashboard d'autore) per la parte *pubblica*; resta valido lo spec architetturale `2026-05-31-unified-course-architecture-design.md` (questo lo estende con il layer di pubblicazione).

> Trasformare il `portal.html` attuale — una **dashboard d'autore** (badge di copertura, link agli artefatti interni di
> design) — in un **sito pubblico GitHub Pages** che serve l'intero corso (teoria + 2 workshop), con slide, pianificazione
> e materiale da scaricare, navigabile da uno studente e leggibile da un docente esterno che valuta la programmazione.
> Vincolo guida: **non si riscrivono contenuti** — il sito *incorpora* artefatti che esistono già nel punto giusto;
> si scrivono solo i wrapper sottili del portale e gli script di build.

---

## 1. Contesto

Stato attuale (verificato 2026-06-01):

- Il "portale" è `portal.html` di root: layout a due pannelli (sidebar 320px + `iframe` reader), badge di copertura `N/6`,
  link agli artefatti **interni** (`narrative.html`, `storyboard.html`, `items_*`, `rubriche/`). È uno strumento d'autore,
  **non** rivolto a studenti/docenti esterni.
- Tre moduli, artefatti già presenti:
  - **Teoria** — deck globale `slides/slides.qmd` → `slides/slides.html` (oggi **148 MB** perché `embed-resources: true`
    inlinea i **123 MB** di `img/`). 10 capitoli in `course/_manifest.yml` (240 min totali) con artefatti per-capitolo
    in `course/<slug>/` (objectives, narrative, storyboard, items, rubriche).
  - **Basic** — `workshops/mlt-r-basic/` (progetto R) + deck `slides/workshops/mlt-r-basic/00-basic-deck.qmd`
    (7,4 MB embed) + `formatives/min-NN-*.md` + `README.md` (self-contained: `use_course()` + `renv::restore()`).
  - **Advanced** — simmetrico (`mlt-r-advanced`), + nota API key per lo step LLM.
- **Nessun** GitHub Pages configurato, **nessun** `.github/`, **nessun** `_quarto.yml` di root.
- ZIP workshop in `dist/` (gitignorato, ~4 MB l'uno) → asset di Release per-coorte (link `use_course()` già cablati nei README).
- `img/` è committata (159 file, 123 MB, **max singolo file 5,9 MB** → nessun file vicino al limite 100 MB di GitHub).

## 2. Decisioni prese (input utente, 2026-06-01)

| # | Domanda | Decisione |
|---|---------|-----------|
| 1 | Pubblicazione + deck teoria 148 MB | **Dual-build** (vedi §4): *live* = deck **non-embed** committati e serviti; *release* = deck **embed** self-contained come asset di coorte. Confermato. |
| 2 | Contenuti del sito pubblico | **Pulito: studente + docente.** Slide, pianificazione, learning path, prerequisiti, obiettivi, come scaricare/eseguire + download. **Nascosti** gli artefatti interni di design. |
| 3 | Impostazione visiva | **Landing + nav (multi-pagina).** |
| 4 | Meccanismo di serving Pages | **A — Quarto website renderizzato in locale → `/docs`**, Pages "from branch `main` /docs". **Nessuna CI.** |
| 5 | Syllabus | **3 syllabus (uno per modulo), forward-compatible:** link quando l'artefatto esiste, placeholder marcato quando manca. (Saranno prodotti da `/mlt` dopo le revisioni finali.) |
| 6 | Pulizia di `/docs` | **Rilocazione:** `docs/superpowers/` + `docs/sources/` → `dev-docs/` (top-level, non pubblicata); `/docs` = **solo** sito. Fatto via `git mv` + repoint dei riferimenti (CLAUDE.md root + progetto). Completato in Task A. |

## 3. Audience e principio di sorgente unica

Due lettori, un sito:

- **Studente** — capisce il percorso, apre le slide, scarica ed esegue i workshop.
- **Docente esterno** — valuta la **pianificazione**: timeline, obiettivi, learning path, prerequisiti, modello di valutazione.

**Principio:** ogni contenuto del sito è **estratto o linkato** da una sorgente che già esiste; il portale non duplica testo.
Le pagine `.qmd` sono *wrapper sottili*; il contenuto vivo arriva da `course/_manifest.yml`, `course/<slug>/objectives.md`,
i `README.md` dei workshop, i nomi-file `formatives/min-NN-*`, e i deck renderizzati.

**Esposto (pubblico):** deck (i 3 globali), titoli/minuti dei capitoli, obiettivi per capitolo, learning path, prerequisiti,
timeline/pianificazione, istruzioni d'installazione, download (release), syllabus (quando esiste).

**Nascosto (interno):** narrative spine, storyboard, item di valutazione, rubriche, esercizi sommativi per-capitolo, ogni blocco
`*Nota docente:*` (IT) dentro file altrimenti pubblici (es. `objectives.md`), le note di lavoro IT, e la dashboard `portal.html`.
Non vengono copiati né estratti in `/docs`, quindi non sono pubblicati.

## 4. Architettura di pubblicazione — dual-build

```
SORGENTI (committate)                      LIVE  → GitHub Pages (/docs, committato)
  course/_manifest.yml, course/*/objectives.md      site/ (Quarto website)  →  /docs/*.html  (Home, Theory, Basic,
  slides/slides.qmd + chapters/                                                  Advanced, Schedule, Downloads)
  slides/workshops/<slug>/00-*-deck.qmd             deck NON-embed          →  /docs/slides/slides.html (+ _files)
  workshops/<slug>/README.md, formatives/                                       /docs/slides/workshops/<slug>/…deck.html
  img/  (123 MB, max 5,9 MB/file)                   img/                   →  /docs/img/   (serve al deck teoria)
        │                                           .nojekyll              →  /docs/.nojekyll
        │
        └──────────────────────────────▶ RELEASE per-coorte  → dev/release-assets/ (GITIGNORATO) → upload manuale
                                            deck EMBED (3, single-file)  +  dist/*.zip (2 workshop)  +  materiale coorte
                                            → tag coorte (es. coorte-2026) → GitHub Release assets
```

- **Live (sempre l'ultima versione):** i 3 deck in `embed-resources: false` (HTML piccolo + `*_files/libs/` + riferimenti a
  `img/`) renderizzati dentro `/docs/slides/…`, più `img/` copiata in `/docs/img/`. Tutto committato; nessun file > 100 MB.
- **Release (snapshot congelato, offline, per-coorte):** i 3 deck in `embed-resources: true` (single-file portabile) + i 2 ZIP
  workshop + eventuale materiale di coorte, raccolti in `dev/release-assets/` (gitignorato) e caricati come asset di una
  release taggata per coorte. **Questo passo lo fa l'utente** (build assets via comando, poi tag + upload).
- **Perché regge:** i 148 MB erano solo base64 di `img/`; la live non inlinea nulla e `img/` ha max 5,9 MB/file → repo pushabile.

## 5. Layout target

```
mlt-overview/
├── site/                       # NUOVO — sorgenti del Quarto website (wrapper sottili)
│   ├── _quarto.yml             #   project: website · output-dir: ../docs · navbar · theme=brand
│   ├── index.qmd               #   Home: 3 card-modulo, learning path, prerequisiti
│   ├── theory.qmd              #   Teoria: deck globale + 10 capitoli (titolo/minuti/obiettivi) + syllabus
│   ├── basic.qmd               #   Basic: overview/dataset/prereq + deck + timeline + how-to-run + download + syllabus
│   ├── advanced.qmd            #   Advanced: idem + nota API key
│   ├── schedule.qmd            #   Pianificazione completa (teoria + 2 workshop) in una vista
│   ├── downloads.qmd           #   Asset dell'ultima release + istruzioni R + modello per-coorte
│   ├── _brand.scss             #   piccolo SCSS website che riusa i token di styles/_brand.scss
│   └── _generated/             #   include generati dal pre-render (GITIGNORATO)
├── docs/                       # OUTPUT del sito → servito da Pages (COMMITTATO)
│   ├── .nojekyll               #   disattiva Jekyll (serve *_files/ e site_libs/ as-is)
│   ├── index.html · theory.html · …
│   ├── slides/                 #   deck NON-embed (teoria + 2 workshop) + *_files/
│   └── img/                    #   copia di img/ (riferita dal deck teoria)   (~123 MB)
├── scripts/
│   ├── build_site.py           #   NUOVO — orchestratore live (vedi §6)
│   └── build_release.py        #   NUOVO — orchestratore release assets (vedi §7)
├── dev-docs/                   # NUOVO (rilocato da docs/) — note interne NON pubblicate: superpowers/ (specs+plans) + sources/
└── (dist/ + dev/ gitignorati, course/ · slides/ · workshops/ · img/ · styles/ … invariati)
```

**Pulizia di `/docs` (decisione #6).** Pages "from /docs" pubblicherebbe *tutto* ciò che sta in `docs/`. Perciò le note interne
che erano in `docs/superpowers/` (specs + plans) e `docs/sources/` sono state **rilocate** in `dev-docs/` (cartella top-level
non pubblicata), preservando la struttura interna (`dev-docs/superpowers/…`, `dev-docs/sources/…`). Così `/docs` ospita
**solo** il sito. La migrazione è stata un `git mv` (storia preservata) + **repoint** dei riferimenti. Task A completato.
Questo spec ora vive in `dev-docs/superpowers/specs/2026-06-01-course-portal-site-design.md`.

## 6. Build live — `scripts/build_site.py` (+ wrapper `/mlt-site`, opzionale)

Entry-point unico, deterministico, R-free (l'overview deck non esegue R — da confermare §11):

1. **Pre-render / partials.** Genera `site/_generated/` da: `course/_manifest.yml` (titoli + minuti), `course/<slug>/objectives.md`
   (la lista sotto `## Learning objectives`, **solo** EN — l'estrazione si ferma al primo `*Nota docente:*` o heading successivo,
   escludendo le note IT e l'esercizio sommativo), `workshops/<slug>/README.md` (overview/dataset/prereq/how-to-run), nomi-file
   `slides/workshops/<slug>/formatives/min-NN-*` (checkpoint timeline). Output = piccoli `.md` che le pagine `{{< include >}}`.
2. **Render site.** `quarto render site/` → pagine in `/docs`.
3. **Render deck NON-embed** (3) in `/docs/slides/…`:
   - `slides/slides.qmd` con `-M embed-resources:false` → `/docs/slides/slides.html` (+ `slides_files/`).
   - `slides/workshops/<slug>/` con `embed-resources:false` → `/docs/slides/workshops/<slug>/…deck.html`.
4. **Sync asset.** Copia `img/` → `/docs/img/`. Scrive `/docs/.nojekyll`.
5. **Syllabus (se presente).** Se l'artefatto syllabus del modulo esiste, lo renderizza/copia in `/docs/…` e attiva il link;
   altrimenti la pagina mostra "Syllabus — in preparazione".

Risultato: `/docs` completo e auto-consistente. L'utente fa `python scripts/build_site.py` in locale e **committa `/docs`**.
(Implementazione può usare `pre-render`/`post-render` di Quarto invece di un orchestratore esterno — scelta nel piano.)

## 7. Build release — `scripts/build_release.py` (+ wrapper `/mlt-release`, opzionale)

Riusa `/mlt-dist` (che già renderizza i deck workshop embed e costruisce gli ZIP in `dist/`). In più:

1. Render dei 3 deck in `embed-resources: true` → `dev/release-assets/` con nomi stabili:
   `mlt-overview-theory-deck.html`, `mlt-r-basic-deck.html`, `mlt-r-advanced-deck.html`.
2. Copia `dist/mlt-r-basic.zip`, `dist/mlt-r-advanced.zip` → `dev/release-assets/`.
3. L'utente aggiunge eventuale materiale di coorte, poi: `tag` coorte (es. `coorte-2026`) + upload assets su GitHub Release.

I nomi-asset sopra sono **contrattuali**: la pagina **Downloads** linka `releases/latest/download/<nome>` con esattamente questi nomi
(gli ZIP usano i nomi già cablati nei README: `mlt-r-basic.zip`, `mlt-r-advanced.zip`).

## 8. Contenuto pagina-per-pagina (tutto riusato)

- **Home (`index.qmd`)** — titolo + audience (UBEP); 3 **card-modulo** (Teoria / Basic / Advanced) con 1-riga + CTA (apri slide / scarica);
  **learning path** Overview→Basic→Advanced (dai pre-hook già descritti nei README/spec); prerequisiti inter-modulo; "come funziona il corso".
- **Theory (`theory.qmd`)** — bottone **Apri le slide** (deck globale `/docs/slides/slides.html`, a tutto schermo) + **Scarica deck self-contained**
  (release); tabella 10 capitoli: `NN · titolo · minuti · obiettivi` (da manifest + `objectives.md`); link **Syllabus** (se presente).
  **Solo deck globale**, niente slide per-sezione (richiesta utente).
- **Basic / Advanced (`basic.qmd` / `advanced.qmd`)** — overview + "what you build" + dataset + prerequisiti (dal README);
  **Apri deck** (non-embed) + **Scarica deck** (release); **timeline** (checkpoint `min-NN`); **How to get & run**
  (`use_course(release/latest)` + `renv::restore()`; Advanced: nota API key); elenco **formative**; link **Syllabus** (se presente).
- **Schedule (`schedule.qmd`)** — la **pianificazione completa** in una vista: capitoli teoria (minuti, somma 240) + i due workshop (~4h
  l'uno) con i checkpoint `min-NN`. È la pagina-chiave per il docente esterno.
- **Downloads (`downloads.qmd`)** — link agli asset dell'**ultima release** (3 deck self-contained + 2 ZIP + materiale coorte),
  istruzioni R (R ≥ 4.5, RStudio, `use_course` + `renv::restore`), spiegazione del modello **release per-coorte** (tag annuali).

## 9. Coerenza visiva e verifica

- **Brand.** Il website riusa i token di `styles/_brand.scss` (arancio `#E8741E`/`#C75A12`, teal `#1F4257`, font Cabin/Noto/Source Code Pro)
  via un piccolo `site/_brand.scss` (variabili Bootstrap derivate), così il portale è coerente con i deck.
- **Gate di verifica visiva (obbligatorio, root `CLAUDE.md`).** Nessuna pagina/deck è "pronto" senza ispezione visiva via
  chrome-devtools: Home + ogni pagina + apertura dei 3 deck (immagini teoria caricate da `/docs/img`), a viewport tipico (≈1100px) e a 1080p.

## 10. Modifiche a `.gitignore` (de-gitignore chirurgico)

- **Sblocca:** `/docs/` deve essere tracciato (oggi non è ignorato — ok), incluso `/docs/slides/**` e `/docs/img/**`. Le regole esistenti
  `slides/slides.html`, `slides/chapters/*.html`, e i `*.html` dei workshop **restano** (ignorano i build *nell'albero sorgente*, non in `/docs`).
- **Aggiungi ignore:** `site/_generated/` (include rigenerati dal build). `dev/` resta ignorato (staging release).
- **Verifica:** nessun pattern intercetta `docs/slides/*.html` o `docs/img/*` (sono sotto `docs/`, non `slides/`/`img/` di root).

## 11. Dettagli implementativi aperti (non bloccanti)

- Parse esatto di `course/<slug>/objectives.md` (front-matter vs sezione `## Objectives`) — da ispezionare in fase di piano.
- Granularità timeline workshop (solo checkpoint `min-NN` vs minuti per sezione del deck).
- Path d'output del **syllabus** prodotto da `/mlt` (per cablare il link) — TBD quando `/mlt` lo genera; il sito è già predisposto.
- Conferma che l'overview deck **non** esegua R (decide se il build è interamente R-free).
- Duplicazione `img/` in `/docs` (~123 MB): accettata; ottimizzazione opzionale futura (compressione PNG o git-lfs).
- Impostazione manuale una-tantum: **Settings → Pages → Deploy from branch → `main` / `/docs`** (la fa l'utente).

## 12. Non-goals (YAGNI)

- **Niente CI** (scelto serving A) — nessun `.github/workflows`.
- **Niente** deck teoria per-sezione pubblicati (solo globale).
- **Niente** esposizione di artefatti interni (narrative/storyboard/item/rubriche/note IT) né della dashboard `portal.html`.
- **Niente** commit di deck embed o ZIP nell'albero (solo asset di Release).
- **Niente** modifiche al tooling `/mlt`, ai contenuti `course/`, ai contenuti dei workshop: si scrivono **solo** `site/` + `scripts/build_*`.

## 13. Criteri di successo

1. `https://corradolanera.github.io/mlt-overview/` mostra una landing con navbar e le 6 pagine.
2. I 3 deck si aprono e renderizzano correttamente (immagini teoria caricate da `/docs/img`).
3. La pagina Schedule mostra la pianificazione completa; le pagine modulo mostrano prerequisiti, how-to-run e link di download.
4. Il gate di verifica visiva passa a viewport tipico e a 1080p.
5. Nessun file > 100 MB committato; `git push` pulito.
6. Ri-eseguire `build_site.py` rigenera `/docs` in modo deterministico (diff stabile).
7. La pagina Downloads punta agli asset di release con i nomi contrattuali (anche prima che la release esista: link "latest").
8. Nessun testo IT interno (`*Nota docente:*`, narrative/storyboard/rubriche) né la cartella `dev-docs/` compaiono sotto il dominio Pages.

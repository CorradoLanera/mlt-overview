# MLT — Architettura del corso unificato (un repo · tre moduli) — Design Spec

- **Data:** 2026-05-31
- **Branch:** `unify-course-architecture` (da creare al primo commit)
- **Repo:** `c:\Users\corra\github\cl\mlt-overview`
- **Autore:** Corrado Lanera (con Claude Code)
- **Stato:** bozza in revisione
- **Revisione r2 (2026-05-31):** §3/§5/§7/§9 aggiornate dopo decisione in fase di build — i **sorgenti** slide dei workshop vivono in `slides/workshops/<slug>/` (come l'overview separa `course/` da `slides/`); la cartella `workshops/<slug>/` distribuisce il progetto R + il deck **renderizzato** (iniettato in fase di build), **non** i sorgenti slide. Conseguenza: niente vendoring SCSS nello ZIP (il deck è `embed-resources`, autosufficiente) — §9.1 ritirata; inclusione ZIP guidata da `git ls-files` (deterministica) + il deck renderizzato − `CLAUDE.md`.

> Questo documento è il *piano architetturale* del corso unico: come `mlt-overview` diventa **un repo, un corso, tre moduli**
> (teoria/overview + pratica base + pratica advanced) senza spostare ciò che già funziona.
> Non è il lavoro sui contenuti: è la mappa di layout, documentazione, distribuzione, archivio, stile e ambienti R.
> Per le parti di layout/distribuzione/stile **supersede per riferimento** gli spec precedenti
> (`2026-05-26-mlt-course-toolkit-design.md`, `2026-05-30-mlt-r-workshops-design.md`); vedi §13.
> L'implementazione avviene **dopo** l'approvazione di questo spec.

---

## 1. Contesto e obiettivo

Oggi il repo contiene già, di fatto, i tre moduli — ma in forma **asimmetrica**:

- **M1 · Theory Overview:** vive in `course/` (10 capitoli, `course/_manifest.yml` come fonte di verità) + renderizza nel fratello `slides/` + pesca da `img/`. È un corso a *slide narrate da storyboard*.
- **M2 · Practice Basic:** `workshops/mlt-r-basic/` è un **progetto R autonomo** (`.Rproj`, `renv` proprio, `CLAUDE.md`, `README.md`, `_manifest.yml`, `steps/NN-slug/` cumulativi). È un workshop *live-coded* in T3 backward design.
- **M3 · Practice Advanced:** `workshops/mlt-r-advanced/` è **speccato ma non ancora creato**.

Il tooling `/mlt` (orchestratore `mlt-pilot` + sub-skill + 2 hook + `build_portal.py`) è cablato **esclusivamente** su `course/`/`slides/`; non tocca `workshops/`.

**Obiettivo:** dare ai tre moduli un'unica **identità** (README hub, percorso di apprendimento, contratto di stile) e un'unica **catena di distribuzione**, *senza* rimescolare l'albero e *senza* migrare il tooling — perché i tre moduli sono tipi di artefatto genuinamente diversi e la simmetria di cartella sarebbe cosmetica a fronte di un costo di accoppiamento reale (60 riferimenti immagine, 2 glob di hook, ogni path delle skill).

## 2. Decisioni prese (input dell'utente)

| # | Domanda | Decisione |
|---|---------|-----------|
| 1 | Layout + naming moduli | **Organic + meta-index**: alberi attuali invariati, identità nel README + contratto di stile. Zero migrazione tooling. |
| 2 | README + CLAUDE.md | **Hub + foglie sottili**: root possiede il contratto universale e l'identità; le foglie restano autonome/specializzate. |
| 3 | Distribuzione | **GitHub Release assets**: ZIP source-only in `dist/` gitignorato, allegati a release per-coorte, via `use_course()` + short link. |
| 4 | Archivio | **Archive + repoint**: legacy in `_archive/legacy-xaringan/` con `git mv`; i 2 riferimenti seguono il path; dipendenza recisa più avanti. |
| 5 | Contratto di stile | **Brand partial** `styles/_brand.scss` (inline in ZIP); narrativa a due livelli; ancore-immagine solo overview; `/mlt` solo overview. |
| 6 | renv | **Per-modulo + slim overview**: workshop con lock proprio (forzato); root ri-snapshot al footprint post-Quarto, eventuale ritiro. |
| + | Tweak A | **Niente `chalkboard`**, si tiene `embed-resources`. |
| + | Tweak B | **renv dentro `_archive/`**: il progetto legacy xaringan resta compilabile standalone. |

## 3. Layout target (Q1)

```
mlt-overview/
├── README.md                       # hub: identità, mappa 3 moduli, percorso, prerequisiti
├── styles/
│   └── _brand.scss                 # NUOVO — unica fonte di palette + font
├── course/                         # M1 · Theory Overview (INVARIATO — il tooling continua a funzionare)
│   ├── _manifest.yml               # fonte di verità dei capitoli overview
│   ├── _global/  ·  01-…/ … 10-…/
├── slides/                         # SORGENTI slide + deck overview renderizzato
│   ├── slides.qmd · chapters/      #   overview (theme list: ../styles/_brand.scss)
│   └── workshops/<slug>/           # NUOVO — sorgenti slide dei workshop (qmd/scss/_quarto.yml/formatives)
├── img/                            # asset overview condivisi (img/storyboard/sb-NN_FF.png)
├── workshops/
│   ├── mlt-r-basic/                # M2 · Practice Basic — DISTRIBUIBILE: progetto R + deck RENDERIZZATO
│   │                               #   (sorgenti slide NON qui → slides/workshops/mlt-r-basic/)
│   └── mlt-r-advanced/             # M3 · Practice Advanced (da scaffoldare più avanti)
├── dist/                           # NUOVO — ZIP workshop costruiti; GITIGNORATO
├── _archive/
│   └── legacy-xaringan/            # NUOVO — progetto xaringan congelato, riproducibile (vedi §6)
├── scripts/                        # build_portal.py + build_workshop_zip.py (NUOVO)
└── docs/superpowers/specs/         # questo spec + i due precedenti (superseded-by-reference)
```

L'identità "un corso" vive nel README + nel contratto di stile, **non** nei nomi di cartella. Nessun glob di hook, path di skill, scanner di portal, manifest o riferimento `../img/storyboard/` cambia.

**Meta-index = prosa, non macchina (YAGNI):** la mappa dei 3 moduli è una sezione *percorso di apprendimento* nel `README.md` root. **Niente** `_course.yml`: `course/_manifest.yml` resta overview-scoped, e il portal resta overview-scoped (al più un link in uscita alla pagina release dei workshop).

## 4. Modello documentazione: hub + foglie sottili (Q2)

Vincolo che forma tutto: il **README di un workshop viaggia dentro lo ZIP distribuito** → deve restare self-contained. Il **`CLAUDE.md` di un workshop è solo-authoring** (escluso dallo ZIP, co-locato col root) → può referenziare verso l'alto ed essere tagliato.

**Root `README.md` (hub):** mappa dei 3 moduli, percorso Overview→Basic→Advanced, prerequisiti inter-modulo, come ottenere ciascun modulo.

**Workshop `README.md` (foglia):** self-contained — `use_course()` + `renv::restore()`, dataset, meccanica `steps/` — + una riga "part of the MLT course →" verso l'alto.

**Root `.claude/CLAUDE.md` (contratto universale):** lingua EN/IT, matematica `$...$`, riga vuota prima delle liste, gate di verifica visiva, manifest-come-verità, policy d'archivio, mappa dei 3 moduli.

**Workshop `CLAUDE.md` (delta R-authoring):** solo le regole R (`|>`, `here::here()`, `rio`, snake_case+suffisso, un arg per riga, banner `# Section ----`, `set.seed`, live-coding/no-prebaked, step cumulativi). Tagliato di ciò che ora sta al root; Claude Code unisce root + nested in automatico quando si autora dentro il workshop.

**Cosa sale (assorbito UP):** la regola lingua EN-studenti/IT-note (oggi duplicata nei due `CLAUDE.md`); la narrativa cross-modulo (oggi orfana negli spec).
**Cosa resta locale:** setup standalone del workshop (ZIP); convenzioni R specifiche del workshop.

## 5. Distribuzione: Release assets (Q3 · path separato Q5)

```
edita  workshops/<slug>/  o  slides/workshops/<slug>/  ──▶ [reminder hook] ──▶ /mlt-dist
   1. quarto render slides/workshops/<slug>/   →  deck HTML embed-resources (autosufficiente)
   2. build_workshop_zip.py
        • git ls-files su workshops/<slug>/   →  sorgente R tracciato   (meno CLAUDE.md)
        • inietta il deck renderizzato in   <slug>/slides/
        • zip con cartella radice   <slug>/
                          ▼
            dist/<slug>.zip   (gitignorato, pochi MB)   ──▶  tag release per-coorte
                          ▼
   GitHub Release ◀── short link ──▶ use_course() nel README workshop
```

**Recipe ZIP** (per workshop) — guidata da `git`, deterministica:

- **Include:** tutto ciò che `git ls-files` traccia dentro `workshops/<slug>/` (cioè il **sorgente** R: `*.Rproj`, `.Rprofile`, `renv.lock`, `renv/activate.R`, `renv/settings.json`, `R/`, `data-raw/`, `steps/NN-slug/*.qmd` + scaffolding, `_manifest.yml`, `requirements.R`, `README.md`), **più** il deck **renderizzato** iniettato in `<slug>/slides/`, **meno** `CLAUDE.md` (authoring-only).
- **Escludi (automatico, perché gitignorato o non tracciato):** `renv/library/`, `**/.quarto/`, `steps/**/*.html` (render dei passi), `steps/**/output/*.{rds,png}` (output rigenerabili), `**/*_files/`. Lo studente li rigenera (`renv::restore()` + esecuzione dei passi).
- **Sorgenti slide NON nello ZIP:** vivono in `slides/workshops/<slug>/`; nello ZIP entra **solo** il deck renderizzato (`embed-resources`, autosufficiente). Perciò **niente vendoring SCSS** (vedi §9.1, ritirata).
- **Effetto:** da ~379 MB (quasi tutto `renv/library/`) a pochi MB.

**Comando:** `scripts/build_workshop_zip.py` (coerente con `build_portal.py`), wrappato da **`/mlt-dist`** (standalone — `/mlt` resta overview-only, vedi §7), che prima **renderizza** il deck da `slides/workshops/<slug>/` poi assembla lo ZIP. Workshop-scoped: l'overview si distribuisce diversamente (slide → GitHub Pages/PDF, non `use_course()`).

**Reminder = hook PostToolUse non bloccante** su scritture di sorgente in `workshops/**` **o** `slides/workshops/**` **o** `styles/_brand.scss` (vedi §9.2), ignorando cache `.quarto/`, lo zip stesso e i rendered: stampa "sorgente workshop cambiata → rigenera dist via /mlt-dist prima di pubblicare". Solo reminder — **non** auto-zippa a ogni keystroke.

**Tweak A:** il `_quarto.yml` del deck workshop (ora in `slides/workshops/<slug>/`) perde `chalkboard: true` e tiene `embed-resources: true` (`code-link` resta, è compatibile). Elimina l'incognita "chalkboard sopravvive a embed-resources" alla radice.

## 6. Archivio riproducibile (Q4 + Tweak B)

`_archive/legacy-xaringan/` non è una morgue ma un **progetto R legacy autonomo e ricompilabile**.

**Contenuto (via `git mv` + copia mirata):**

- File legacy spostati: `index.Rmd`, `index-full.Rmd`, `index.html`, `index_files/`, `xaringan-themer.css`.
- Ambiente R congelato: **copia** dell'attuale `renv.lock` root (118 pacchetti, era xaringan) + `renv/activate.R` + `renv/settings.json` + un `.Rprofile` + un piccolo `.Rproj` (`legacy-xaringan.Rproj`) così che RStudio attivi il progetto e `renv`.
- **Asset — sposta gli esclusivi, copia i condivisi.** Durante la migrazione si risolvono gli asset referenziati da `index.Rmd`/`index-full.Rmd` e si classificano rispetto all'uso nel tree *vivo* (`course/**`, `slides/**`, `workshops/**`):
  - usati **solo** da xaringan (non referenziati altrove) → **`git mv`** dentro `_archive/legacy-xaringan/` → toglie rumore dalla `img/` principale;
  - usati **anche** dal vivo → **copia** dentro `_archive/legacy-xaringan/` → restano in `img/` per il build vivo, duplicati in archivio per la riproducibilità.
  - css/dati: stessa regola.
- **Garanzia:** *apri la cartella → `renv::restore()` → `index.Rmd` knitta*, senza rompere nulla del build vivo. Si duplica solo il sottoinsieme condiviso (piccolo), non i 141 MB di `img/`.

**Repoint (Q4):** il `base_source` del manifest e l'input-quarry di `mlt-quarto-build` puntano a `_archive/legacy-xaringan/index.Rmd`. La skill *legge* il markdown (cue formule/figure), non lo compila → il repoint funziona a prescindere dal renv archiviato. La dipendenza si **recide più avanti** quando ogni capitolo è costruito (Fase A completa).

**Altri candidati:** `dev/` (24 MB di screenshot QA) → **gitignorato** d'ora in poi (non gonfia l'archivio); `doc/` (PDF/CV) → **lasciato dov'è**.

## 7. Contratto di stile e coerenza (Q5)

**SCSS — brand partial condiviso.** `styles/_brand.scss` è l'unica fonte di verità (palette arancio `#E8741E` / `#C75A12` / teal `#1F4257`, font Cabin / Noto Sans / Source Code Pro, token di sizing). Ogni deck-sorgente lo importa via theme list e ci stratifica sopra le regole di modulo (overview in `slides/`, workshop in `slides/workshops/<slug>/`: `code-link` + canvas largo 1648×1080 + override `font-size-root: 32px`). **Niente vendoring/inlining in fase di ZIP:** il deck workshop spedito è già renderizzato `embed-resources` (CSS compilato dentro l'HTML), quindi è autosufficiente e i sorgenti slide non viaggiano nello ZIP (vedi §9.1, ritirata).

**Narrativa — contratto a due livelli.**

- *Spina del corso* (attraversa i tre moduli): six-word/100-word globali + macro-arco **Overview → Basic → Advanced** con pre-hook formali (Payoff del cap. 10 overview → Hook del Basic; Payoff del Basic → Hook dell'Advanced) e prerequisiti dichiarati in testa a ogni modulo.
- *Dentro il modulo*: pedagogia nativa all'artefatto — overview = arco storyboard hook-sfida-risoluzione-payoff; workshop = T3 backward design (summative-first + formative). **Niente storyboard imposti** ai workshop live-coded.

**Immagini.** La convenzione ancora-storyboard `img/storyboard/sb-NN_FF.png` resta **overview-specific** (legata alla pedagogia storyboard + a `img/` condivisa). Le figure del workshop vivono col sorgente slide in `slides/workshops/<slug>/` (es. `concept-graph.mmd`) e finiscono **baked** nel deck `embed-resources`: il deck spedito è autosufficiente, non referenzia `img/` del monorepo. Si condivide *igiene di naming* + *styling* (via SCSS), **non** una cartella immagini.

**Autorità di build.** `/mlt` + `mlt-quarto-build` restano overview-scoped (storyboard-driven, che i workshop non hanno). I deck workshop si autorano a mano per T3 in `slides/workshops/<slug>/` + `quarto render`; lo ZIP/publish lo fa `/mlt-dist`. Tutti passano il **gate di verifica visiva universale** (root `CLAUDE.md`, via `chrome-devtools` a 1080p + viewport stretto).

## 8. Strategia renv (Q6)

Tre ambienti indipendenti.

- **Workshop (M2/M3):** ciascuno possiede il proprio `renv.lock` — **forzato** dal modello di distribuzione (lo ZIP standalone si ripristina con `renv::restore()` sulla macchina dello studente; un lock monorepo non potrebbe viaggiare nello ZIP).
- **Overview/root (M1):** ri-snapshot al footprint reale post-Quarto: si tolgono `xaringan`/`countdown`/`servr` (le dipendenze di presentazione, che **migrano** in `_archive/legacy-xaringan/` — §6, non spariscono). Si tiene solo ciò che i `.qmd` overview eseguono davvero. **Se l'overview non esegue R**, il renv root si **ritira** del tutto e l'overview diventa build pure-Quarto (R-free).
- **Shared monorepo renv:** *respinto* — non viaggia nello ZIP, forza 87 pacchetti ML-only nell'ambiente overview, contraddetto da analisi deps e modello di distribuzione.

## 9. Conseguenze trasversali (emergono combinando le risposte)

### 9.1 ~~Il comando di dist assorbe il contratto SCSS~~ — RITIRATA (rev. r2)

Originariamente il brand partial doveva essere inlineato/vendorizzato nello ZIP così che lo studente potesse ricompilare il deck. Con la rev. r2 i **sorgenti slide non viaggiano nello ZIP** (stanno in `slides/workshops/<slug>/`); nello ZIP entra solo il deck **renderizzato** `embed-resources`, che ha il CSS già compilato dentro. Quindi **nessun vendoring**: `build_workshop_zip.py` fa due lavori — (1) raccoglie il sorgente R tracciato (`git ls-files`, meno `CLAUDE.md`), (2) **inietta** il deck renderizzato in `<slug>/slides/`. Il render del deck avviene prima, in `/mlt-dist` (`quarto render slides/workshops/<slug>/`).

### 9.2 Il reminder hook sorveglia sorgente R, sorgente slide e brand

Il reminder "rigenera dist" scatta su scritture in `workshops/**` (progetto R) **o** `slides/workshops/**` (sorgente slide) **o** `styles/_brand.scss` (un cambio di token brand cambia il deck renderizzato di **ogni** workshop). Ignora cache `.quarto/`, lo zip e i rendered.

### 9.3 Meta-index in prosa (YAGNI)

La mappa dei 3 moduli sta nel `README.md` root come sezione percorso, **non** in un nuovo `_course.yml`; il portal resta overview-scoped (al più un link alla pagina release workshop).

## 10. Sequenza di migrazione (basso rischio · un commit per cambiamento logico)

1. **Archivio.** Crea `_archive/legacy-xaringan/`; **prima** copia l'attuale `renv.lock` root + `renv/activate.R` + `settings.json` lì dentro; `git mv` i file legacy; vendorizza gli asset usati da `index.Rmd`; aggiungi `.Rprofile` + `legacy-xaringan.Rproj`; repointa `base_source` + input di `mlt-quarto-build`. Gitignora `dev/`.
2. **Brand.** Crea `styles/_brand.scss` dai token dell'attuale `slides/theme.scss`; rifattorizza `slides/theme.scss` per importarlo + tenere le regole overview.
3. **renv overview.** Ri-snapshot del renv root al footprint post-Quarto (tolte le deps xaringan, già congelate nell'archivio al passo 1 — §6); decidi ritiro vs lean in base all'esecuzione R dell'overview.
4. **Docs.** Scrivi il `README.md` hub (percorso, mappa 3 moduli, prerequisiti); assorbi la regola lingua nel root `CLAUDE.md`; taglia il `CLAUDE.md` workshop a delta-R + pointer; aggiungi il pointer "part of the MLT course" nel README workshop.
5. **Distribuzione.** Sposta i sorgenti slide in `slides/workshops/<slug>/` (rimuovendo `chalkboard`, tenendo `embed-resources`, adottando il brand partial); `scripts/build_workshop_zip.py` (`git ls-files` − `CLAUDE.md` + deck renderizzato iniettato, **senza** vendoring); slash-command `/mlt-dist` (render del deck + zip); reminder hook (`workshops/**` ∨ `slides/workshops/**` ∨ `styles/_brand.scss`); gitignora `dist/`; cabla `use_course()` + short link nei README.
6. **Narrativa.** Formalizza i pre-hook inter-modulo (Overview cap.10 → Basic; Basic → Advanced) in narrative + prerequisiti.
7. **Futuro.** Scaffolda `workshops/mlt-r-advanced/` quando i contenuti esistono; recidi la dipendenza da `index.Rmd` a Fase A completa.

I passi 1–5 sono in larga parte indipendenti e committabili separatamente.

## 11. Dettagli implementativi aperti (non bloccanti)

- L'overview deck esegue R? (decide il ritiro del renv root — verifica al passo 3).
- Schema dei tag release: es. `workshops-2026` (per-coorte) o `mlt-r-basic-v2026` (per-modulo).
- Provider short-link: **Bitly** è disponibile via MCP → si possono coniare short link stabili agli asset release.
- Lista esatta degli asset *solo-xaringan* (da spostare) vs *condivisi* (da copiare) — risolta a build-time incrociando i riferimenti di `index.Rmd`/`index-full.Rmd` con `course/**`, `slides/**`, `workshops/**` (meccanismo deciso in §6).
- Forma esatta della sezione "percorso" nel README hub (tabella vs prosa).

## 12. Non-goals (YAGNI)

- **Niente** rimescolamento in `modules/NN-name/` (simmetria cosmetica, costo di accoppiamento reale).
- **Niente** `_course.yml` machine-readable finché il README basta.
- **Niente** estensione di `mlt-quarto-build`/`/mlt` ai workshop (pedagogie diverse).
- **Niente** cartella `img/` condivisa coi workshop (vincolo ZIP standalone).
- **Niente** commit dello ZIP nell'albero (Release assets).

## 13. Relazione con gli spec precedenti

- `2026-05-26-mlt-course-toolkit-design.md` — resta valido per il **tooling overview** (`/mlt`, sub-skill, hook, manifest). Questo spec non lo cambia; aggiunge solo il repoint `base_source` (§6) e lo slim renv (§8).
- `2026-05-30-mlt-r-workshops-design.md` — resta valido per la **pedagogia dei workshop** (T3, dataset, step). Questo spec **concretizza** le sue parti aperte di distribuzione/stile/renv (Release assets, brand partial, renv per-modulo) e ne **supersede** le indicazioni di packaging dove divergono.

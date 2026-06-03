# MLT — Final revision: contenuti collaterali, syllabus, release & pulizia — Design Spec

- **Data:** 2026-06-03
- **Branch:** `mlt-final-revision`
- **Repo:** `c:\Users\corra\github\cl\mlt-overview`
- **Autore:** Corrado Lanera (con Claude Code)
- **Stato:** bozza in revisione
- **Spec collegati:** [`2026-06-01-course-portal-site-design.md`](2026-06-01-course-portal-site-design.md) (architettura del sito pubblico `site/`→`docs/`, generatori dei partial), [`2026-05-31-unified-course-architecture-design.md`](2026-05-31-unified-course-architecture-design.md) (un repo / un corso / tre moduli, distribuzione via Release per coorte), [`2026-06-02-mlt-workshop-fragment-build-design.md`](2026-06-02-mlt-workshop-fragment-build-design.md) (sorgente `_authoring/` + `meta.yml` dei workshop)

> Lavoro di **revisione finale** a corso costruito: nessun rework della pipeline build/release (idempotente, già
> mergiata) né dei contenuti didattici core (slide, item, dataset, numeri). Si chiude ciò che è rimasto
> *placeholder* o *incoerente* nei materiali collaterali e si ritira il materiale obsoleto. Alla fine si ri-lancia
> `python scripts/build_site.py` e si verifica visivamente.

---

## 1. Contesto e problema

A corso costruito (overview 10 capitoli + workshop Basic e Advanced, deck e ZIP pubblicati come asset della
Release `coorte-2026`), una ricognicione read-only ha verificato 5 problemi nei materiali collaterali:

1. **Timeline solo teoria.** La pagina *Schedule & Planning* è generata da `scripts/build_site.py::_timeline_md()`,
   che cerca file `min-NN-*.md` in `slides/workshops/<slug>/formatives/`. Quelle cartelle contengono solo il
   `README.md` (la *mappa* formativa), quindi per Basic e Advanced la timeline cade su *"Timeline to be published."*.
   La teoria invece è resa capitolo-per-capitolo da `course/_manifest.yml` + i `course/<slug>/objectives.md`.
2. **Syllabus mancanti.** I tre partial `site/_generated/{theory,basic,advanced}-syllabus.md` sono il placeholder
   *"Syllabus in preparation…"*. `build_site.py::_syllabus_partial()` include *verbatim* un file sorgente se esiste
   (`course/_global/syllabus.md`, `workshops/<slug>/syllabus.md`) — nessuno dei tre esiste.
3. **3 link Release rotti.** Il sito linka **7** asset (3 deck self-contained + 4 ZIP); la Release `coorte-2026`
   contiene **solo i 4 ZIP**. I 3 link *"Download self-contained deck"* (theory/basic/advanced) danno **404**. I deck
   esistono già in `dev/release-assets/` (il bundle completo *gitignored* prodotto da `scripts/build_release.py`):
   sono stati caricati solo i contenuti di `dist/` (gli ZIP). `dist/` = output ZIP canonico; `dev/release-assets/` =
   bundle di upload completo (ZIP **+** deck). Theory deck = **155 MB**, basic 13 MB, advanced 7.5 MB.
4. **Portale obsoleto tracciato.** `portal.html` (root) + `scripts/build_portal.py` sono **tracciati ma morti**: la
   vecchia dashboard d'autore pre-Quarto, **non** invocata da `scripts/build_all.py`, superata dal sito Quarto
   `site/`→`docs/`. Esiste anche un hook `.claude/hooks/rebuild-portal.py` cablato in `.claude/settings.json`.
5. **Incoerenze minori.** `_manifest.yml` dichiara `total_minutes_gross: 240` ma i capitoli sommano **225**
   (`index.qmd`/`theory.qmd` stampano "≈240 min"); `_manifest.yml` ha `objectives: []`/`subunits: []` per ogni
   capitolo nonostante i contenuti esistano su disco; il `README` dice "prerequisites at the top of each module"
   (in realtà vivono nei partial generati dai README dei workshop); `_archive/legacy-xaringan/data/` (il CSV PubMed)
   è **untracked** benché l'archivio sia inteso come *riproducibile*; l'hook `remind-workshop-dist.py` cita il
   comando deprecato `/mlt-dist`.

**Fatti ufficiali** (da `doc/Offerta Formativa 2025-2026_…_Lanera.pdf`, estratto con `pypdf` — `poppler/pdftoppm`
non è installato): SSD **MEDS-24/A**; ogni modulo **10 ore, 1 CFU, Duale, Inglese, obbligo presenza 80%**.
Theory (docenti **Baldi + Lanera**, **II semestre**, esame **Moodle quiz**, nessun prerequisito); Basic
(**Lanera + Vedovelli + Lorenzoni**, **I semestre**, esame **vuoto**, prereq "base di statistica e
programmazione"); Advanced (stessi docenti, **II semestre**, esame **vuoto**, prereq "base di R e ML, aver seguito
il corso base"). ⚠️ I blurb *Contenuti/Obiettivi* dell'Offerta sono **datati** rispetto al corso realmente erogato
(es. Advanced ufficiale = RF/boosting/unsupervised/feature-engineering; reale = SHAP + deep learning torch + ELLMer
LLM ETL + targets).

## 2. Principi e vincoli (invariati)

- **Lingua:** artefatti rivolti agli studenti (syllabus body, timeline, voci a sito) in **INGLESE**; note di design
  e *Nota docente* in **ITALIANO**.
- **Matematica:** ogni formula/pedice/overline/simbolo stand-alone in `$...$` (mai combining-Unicode).
- **Liste markdown:** sempre una riga vuota prima di un elenco.
- **Verifica visiva obbligatoria:** nessun HTML è "pronto" senza ispezione (chrome-devtools) a viewport tipico.
- **Git:** un solo cambiamento logico per commit; **Claude non committa senza approvazione esplicita e non pusha
  mai** — i commit locali vengono proposti a fine lavoro; il push lo fa l'utente.
- **Fonte di verità:** `course/_manifest.yml` (teoria) e `workshops/<slug>/_authoring/` (workshop). I file
  `site/_generated/*` e `docs/` sono **output** rigenerati da `scripts/build_site.py` — mai editarli a mano.

## 3. WS1 — Timeline workshop a livello di step (pagina Schedule)

**Obiettivo:** dare a Basic e Advanced una timeline simmetrica a quella della teoria — elenco ordinato degli step,
ognuno con titolo, durata approssimativa e una riga di sintesi — al posto del placeholder.

**Sorgente di verità (nuovi metadati).** Aggiungere a ogni `workshops/<slug>/_authoring/<step>/meta.yml` due chiavi:

- `minutes:` (intero) — durata approssimativa; seminata dalla mappa dei checkpoint formativi
  (`slides/workshops/<slug>/formatives/README.md`) così che gli step di ciascun workshop sommino ~240 min (≈4h).
- `summary:` (stringa, 1 riga, **inglese**) — sintesi rivolta agli studenti di cosa si fa nello step.

> Sicuro per la build dei workshop: `dev/mltbuild/R/config.R::read_meta()` legge solo chiavi nominate
> (`packages/type/template/carry/check/engine/seed_from`) e **ignora** le chiavi sconosciute — verificato.

**Generatore.** In `scripts/site_content.py` un helper puro e unit-testato
`workshop_steps(workshop_yml_text, metas) -> list[dict]` (ordine step da `workshop.yml`, titolo/minuti/summary da
ogni `meta.yml`); in `scripts/build_site.py` un `_workshop_steps_md(root, slug)` che — come `_theory_chapters_md` —
emette per step `### NN · <title> · <min> min` + la riga di summary, con totale finale. Cablarlo nello `schedule.md`
e nei partial `{key}-timeline.md` **al posto di** `_timeline_md` per i workshop. Fallback al placeholder se i
metadati mancano.

**Test.** Estendere la suite `tests/` (pytest) con casi per `workshop_steps` (ordine, parsing minuti, summary
mancante → fallback).

**Durate seme** (da `formatives/README.md`, da rifinire in implementazione, somma ~240):
Basic — 00-setup, 01-import, 02-eda, 03-logistic, 04-zoo, 05-report. Advanced — 00-recap, 01-interpret,
02-deep-learning, 03-ellmer, 04-targets.

*Alternativa scartata:* un `timeline.yml` separato per workshop — separerebbe la durata dalla definizione dello
step. I metadati sullo step sono la scelta a sorgente unica, coerente con `_manifest.yml` per la teoria.

## 4. WS2 — Tre syllabus accademici concisi (~2 pagine)

Creare tre file markdown statici che il sito **già** include automaticamente (nessuna modifica al codice):
`course/_global/syllabus.md`, `workshops/mlt-r-basic/syllabus.md`, `workshops/mlt-r-advanced/syllabus.md`.
Ognuno **inglese** (testo studente) con *Nota docente* in **italiano** dove serve il razionale. Scheletro:

1. **Header (tabella)** — fatti amministrativi ufficiali *verbatim* (denominazione EN, SSD MEDS-24/A, docenti,
   10 ore / 1 CFU, semestre, erogazione = Duale, lingua = Inglese, obbligo presenza 80%, esame, prerequisiti).
2. **Course description** — il contenuto *realmente erogato* (1 paragrafo).
3. **Intended learning outcomes** — a livello di modulo, verbi osservabili, distillati dai `objectives.md`
   per-capitolo (teoria) / dai README dei workshop — **non** copia delle tabelle sommative a 6 righe.
4. **Topic / step outline** — rimando alla pagina Schedule; teoria = 10 capitoli con minuti, workshop = step con
   summary.
5. **Assessment** — teoria: Moodle quiz + formative/sommativi duali in aula; workshop: modello pratico/formativo
   (campo esame ufficialmente vuoto → modello di lavoro, segnalato).
6. **Prerequisiti + learning path** — Overview → Basic → Advanced.
7. **Materiali / bibliografia** — solo opere realmente usate nel corso (ISL, Mitchell 1997, Vaswani et al. 2017
   "Attention is all you need", Chicco & Jurman 2020 per il dataset). **Nessun riferimento inventato.**

## 5. WS3 — Fix dei 3 link Release rotti (upload dei 3 deck)

1. Ri-lanciare `python scripts/build_release.py` per (ri)assemblare `dev/release-assets/` (3 deck + 4 ZIP).
2. Upload dei 3 deck mancanti su `coorte-2026`:
   `gh release upload coorte-2026 dev/release-assets/{mlt-overview-theory-deck.html,mlt-r-basic-deck.html,mlt-r-advanced-deck.html}`.
3. Verifica post-upload: HEAD-check dei 3 URL `releases/latest/download/…`.

Nessuna modifica al sito (i link puntano già a `releases/latest/download/…`). ⚠️ **L'upload è azione esterna e
durevole (~176 MB)**: viene preparato dallo script ma **eseguito solo su via libera esplicita dell'utente**
(coerente con "Claude non pusha"). Il theory deck a 155 MB è pesante ma entro il limite GitHub (2 GB) — scelta
confermata dall'utente.

## 6. WS4 — Archiviazione del vecchio portale

- `git mv portal.html scripts/build_portal.py` → `_archive/legacy-portal/`.
- Aggiungere `_archive/legacy-portal/README.md` che spiega la supersessione da parte del sito Quarto.
- **Disattivare l'hook**: rimuovere l'entry `rebuild-portal.py` da `.claude/settings.json` (restano
  `md-to-html-math.py` e `remind-workshop-dist.py`). Lo script hook può essere lasciato o spostato in archivio.
- Verifica: nessun riferimento residuo a `portal.html`/`build_portal` in `scripts/`, `README`, `docs/` (verificato
  in ricognizione).

## 7. WS5 — Pulizie minori (default sensati, vetabili in review)

- **Coerenza minuti contatto:** i capitoli sommano **225 min**; allineare la prosa in `index.qmd`/`theory.qmd` a
  ~225 min di contenuto (mantenendo "10 ore / 1 CFU" come allocazione ufficiale). Smettere di stampare "≈240" come
  tempo di *contatto*; decidere `total_minutes_gross` (mantenere 240 come lordo con overhead, oppure portarlo a 225).
- **Igiene manifest:** popolare i flag `objectives:`/`subunits:` in `_manifest.yml` per riflettere il disco.
- **README:** riformulare la riga sui prerequisiti ("stated on each module page, pulled from workshop READMEs").
- **Archivio riproducibile:** `git add _archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv`.
- **Copy hook:** `remind-workshop-dist.py` → aggiornare il messaggio da `/mlt-dist` a `/mlt-build`.
- *(Solo su disco, opzionale)* ripulire i residui gitignored (`dev/*.png` QA, `.qa-screenshots/`).

## 8. Assunzioni (decise; vetabili in spec review)

- **A1** — I syllabus descrivono il corso *realmente erogato*; i blurb ufficiali datati **non** vengono copiati
  (l'header usa i fatti amministrativi ufficiali).
- **A2** — L'assessment di Basic/Advanced è dichiarato come modello pratico/formativo in aula (campo ufficiale vuoto).
- **A3** — "10 ore / 1 CFU" mostrato come allocazione ufficiale; il contenuto erogato (~4h workshop / ~225 min
  teoria) è mostrato separatamente.
- **A4** — Bibliografia limitata alle opere effettivamente usate nel corso.

## 9. Sequenza, build & verifica

1. Modifiche codice/contenuti: WS1 (generatore + `meta.yml` + test), WS2 (3 syllabus), WS4 (archivio portale +
   hook), WS5 (pulizie).
2. `python scripts/build_site.py` → rigenera `site/_generated/*` + `docs/`.
3. `pytest` (nuovo test `workshop_steps`).
4. **Verifica visiva (obbligatoria):** aprire `docs/{schedule,theory,basic,advanced,downloads}.html` in
   chrome-devtools — timeline + syllabus resi, matematica corretta, link risolti.
5. WS3: upload Release (su via libera) + HEAD-check dei 3 URL deck.
6. **Commit:** un cambiamento logico per commit (generatore+meta / syllabus / archivio portale / pulizie), con il
   rebuild di `docs/` accanto alla sua modifica sorgente. Commit locali proposti per approvazione; **push
   all'utente**.

## 10. Out of scope

Contenuti didattici core (slide, item valutativi, rubriche, dataset, numeri), la pipeline build/release, la
narrative spine inter-modulo, lo slimming del theory deck da 155 MB (solo segnalato), la migrazione/refactor dei
deck. Nessun nuovo capitolo o step.

## 11. File toccati (sintesi)

- **Nuovi:** `course/_global/syllabus.md`, `workshops/mlt-r-basic/syllabus.md`,
  `workshops/mlt-r-advanced/syllabus.md`, `_archive/legacy-portal/README.md`, test per `workshop_steps`.
- **Modificati:** `scripts/site_content.py`, `scripts/build_site.py`, gli 11 `_authoring/<step>/meta.yml`,
  `course/_manifest.yml`, `site/index.qmd`, `site/theory.qmd`, `README.md`, `.claude/settings.json`,
  `.claude/hooks/remind-workshop-dist.py`.
- **Spostati:** `portal.html`, `scripts/build_portal.py` → `_archive/legacy-portal/`.
- **Tracciati:** `_archive/legacy-xaringan/data/PubMed_Timeline_Results_by_Year.csv`.
- **Rigenerati (output):** `site/_generated/*`, `docs/*`.
- **Esterno (gated):** upload dei 3 deck su Release `coorte-2026`.

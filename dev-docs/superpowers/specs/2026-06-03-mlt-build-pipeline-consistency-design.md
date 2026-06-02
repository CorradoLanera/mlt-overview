# Spec — Consistency della pipeline build/release MLT (W1)

**Data:** 2026-06-03 · **Stato:** design approvato, pronto per writing-plans · **Branch atteso:** dedicato (no push).

Note di design in italiano; identificatori/percorsi/stringhe studente in inglese.

## 1. Contesto e problema

La migrazione "fragment-build" (motore `dev/mltbuild/`) ha spostato la fonte di verità dei
workshop in `workshops/<slug>/_authoring/` e reso **gitignored** gli alberi generati
(`steps/ full/ _solved/`, lock per-step inclusi — root `.gitignore:43-46`). Ma la migrazione
**non ha raggiunto i deliverable consumabili**:

- Il packager `scripts/build_workshop_zip.py` seleziona i file con **`git ls-files`**, che per
  definizione **non vede** gli alberi gitignored. Non è solo "ZIP stantio": rilanciando il
  packaging oggi, lo ZIP uscirebbe con `steps/` **vuoto**. È un'incompatibilità di modello.
- `dev/release-assets/mlt-r-basic.zip` (e la copia byte-identica in `dist/`) contiene ancora il
  layout pre-migrazione: step `.qmd` (non `.R`), `renv.lock` singolo di root (non i per-step),
  `_solved.R` di root, `yourturn-*.R`, `steps/_template/`. Gli step `.R` + lock 01-05 +
  `_solved/*.html` esistono su disco ma **non spediscono mai**.
- Nessun comando incatena `rebuild.R → render deck → zip → release → site`: ogni stadio si fida
  di un artefatto a monte ormai stantio. `scripts/build_release.py` **copia e basta** gli ZIP da
  `dist/` (solo `WARNING` se mancano); `scripts/build_site.py` non sa nulla del motore.
- Gli hook puntano a target sbagliati: `remind-workshop-dist.py` rimanda a `/mlt-dist` (non
  fragment-aware → seguirlo riproduce il bug); `rebuild-portal.py` ricostruisce la dashboard
  legacy `portal.html` (non il sito pubblico `docs/`) con uno schema-path slide stantio.
- Non esiste alcun **bundle docente**: il motore produce `_solved/*.html` ma nessuno li spedisce;
  lo ZIP intanto fa trapelare il vecchio `_solved.R` di root.

Il gap è già documentato in `dev/mltbuild/README.md` ("Known gaps / next") e nel vault; questo
spec lo chiude.

## 2. Obiettivo / Non-obiettivo

**Obiettivo (W1).** Una procedura **unica e idempotente** che rigeneri TUTTI gli artefatti
consumabili nell'ordine di dipendenza corretto, per i tre destinatari (docente/studente/dev), e
che renda il tooling Claude (command/hook) e la documentazione coerenti con essa.

**Non-obiettivo (esplicito).**
- **W2** — redesign del contenuto dei deck workshop (arco per-step intro→teoria→formative→
  go-to-code; formative integrati nel deck unico). Sessione dedicata, dopo W1.
- **W3** — migrazione del workshop Advanced al fragment-build. Sessione dedicata, dopo W1 (il
  prompt W3 assume l'entrypoint unico già esistente).
- Change non correlati già nel working tree (`data/PubMed_*.csv` cancellato,
  `course/10-best-practices/narrative.html`): non toccati.

W1 è **indipendente dal contenuto** dei deck: la pipeline renderizza qualunque sorgente, in modo
idempotente, così W2/W3 atterrano senza rework.

## 3. Architettura: un entrypoint idempotente

Orchestratore Python `scripts/build_all.py`, esposto come comando `/mlt-build`, che incatena il
DAG. Ogni stadio resta **invocabile da solo** (unità piccole, testabili); `build_all` aggiunge
solo ordine e gate di freschezza, importando gli altri script come moduli e shellando solo
`Rscript` (già il confine attuale del build R).

```
/mlt-build [slug]  →  scripts/build_all.py
  1. Rscript dev/mltbuild/rebuild.R [slug]            # steps/ full/ _solved/ + lock per-step + parity (strutturale)
  2. Rscript dev/mltbuild/check-masking.R [slug]      # gate numerico hoist-safety (salvo --skip-masking)
  3. quarto render  slides/slides.qmd + slides/workshops/<slug>/   # deck theory + workshop
  4. ZIP studente + bundle docente DA DISCO          # scripts/build_workshop_zip.py (riscritto)
  5. scripts/build_release.py                        # deck embed-resources + copia ZIP (con asserzione freschezza)
  6. scripts/build_site.py                           # docs/ + deck non-embed + pagina "Coding solutions"
```

**Perché Python e non estendere `rebuild.R`.** La logica dist/site/release è già Python
(quarto/zip/site); R sarebbe l'altitudine sbagliata per orchestrare (R→python→quarto è fragile).
`build_all.py` riusa il codice esistente come libreria.

**Flag.** `--workshop <slug>` (default: tutti i workshop con `.Rproj`), `--no-site`, `--release`
(produce anche gli asset embed + ZIP in `dev/release-assets/`), `--skip-masking`. Senza
`--release` la pipeline aggiorna gli alberi + `docs/`; con `--release` produce anche gli asset di
Release.

**Idempotenza.** Ogni stadio sovrascrive il proprio output; rilanci ripetuti convergono allo
stesso stato. Nessuno stadio dipende da stato residuo non rigenerato.

## 4. Packaging fragment-aware (il nodo critico)

`scripts/build_workshop_zip.py` smette di fidarsi di `git ls-files` per gli alberi generati.
**Rilevamento per-workshop:**

- **Workshop fragment-built** (`workshops/<slug>/_authoring/` esiste, es. Basic) → impacchetta
  l'albero generato **da disco** (cammina la directory, non l'indice git).
- **Workshop non migrato** (no `_authoring/`, es. Advanced oggi) → **fallback** all'attuale
  `git ls-files`. Così l'Advanced smette di essere stantio (deck fresco + ZIP dal sorgente
  tracciato) e si **auto-aggiorna** quando migrerà (W3), senza modifiche al packager.

### 4.1 Contenuto ZIP studente `<slug>.zip` (decisione utente)

Include (workshop fragment-built):

- `steps/00-05/` — `<NN>.R` per gli step append + `05-report/report.qmd` (transform-terminal),
  con `.here`, `data-raw/`, sottocartelle `R/ data/ output/` come prodotte dal motore.
- `steps/01-05/renv.lock` — lock cumulativi per-step (step `00-setup` non ha lock, by design:
  insegna `renv::init()`).
- `00-setup` incluso così com'è.
- `full/` — `full.R` + `full/renv.lock` + `.here` + `data-raw/` (riferimento all-solved).
- Scaffolding R-project tracciato: `R/`, `.Rprofile`, `renv/activate.R`, `renv/settings.json`,
  `renv/.gitignore`, `<slug>.Rproj`, `_manifest.yml`, `requirements.R`, `README.md`.
- Deck renderizzato iniettato sotto `<slug>/slides/` (come oggi).

Esclude: **`renv.lock` di root** (no — decisione), `_solved/`, `_solved.R` di root, `_authoring/`,
`CLAUDE.md`, `renv/library/` e altri gitignored di runtime.

> Nota implementazione: l'esclusione del root `renv.lock` va verificata contro il bootstrap renv
> (`.Rprofile`→`renv/activate.R`). Il modello fragment usa lock per-step + `.here` per step; se
> l'assenza del root lock rompe `renv::status()` all'apertura del progetto, valutare in fase di
> piano se (a) lasciare comunque assente il root lock e documentare il flusso "apri lo step", o
> (b) generare un root lock "neutro". La decisione di prodotto resta: **niente root lock nello
> ZIP**; il piano risolve solo la meccanica renv.

### 4.2 Bundle docente `<slug>-teacher.zip` (decisione: superset)

= **tutto l'albero studente (§4.1) + `_solved/`**. Un solo download completo per il docente.
Asset di Release **pubblico**. Solo per workshop fragment-built (Advanced ne avrà uno dopo W3).

### 4.3 Sorgente dei file

`build_workshop_zip.py` espone funzioni pure e separate:

- `student_payload(workshop_dir) -> list[(src_path, arc_path)]` — risolve include/exclude §4.1 da
  disco per i fragment-built, o via `git ls-files` per i non migrati.
- `teacher_payload(workshop_dir) -> list[...]` — `student_payload` + `_solved/`.
- `build_zip(payload, deck_dir, out_zip, slug)` — invariato nello spirito (single top-level
  `<slug>/`), ma riceve un payload esplicito invece di chiamare `git ls-files` al suo interno.

## 5. Portale "Coding solutions"

`scripts/build_site.py` (e/o `site_content.py`) assembla, per ogni workshop fragment-built, una
pagina Quarto `docs/<slug>-coding-solutions.html`:

- **Tabset esterno = uno step per tab** (`00-setup`…`05-report`); ogni tab incorpora il contenuto
  di `_solved/<NN>.html` (che è già un tabset interno *To fill / Solved*).
- Sorgente: una `.qmd` generata (es. `site/_generated/<slug>-coding-solutions.qmd` o pagina
  dedicata `site/<slug>-solutions.qmd`) che include/embedda gli `_solved/*.html`. Il meccanismo
  esatto (include diretto vs iframe vs estrazione del body) è dettaglio di piano; vincolo: una
  sola pagina, navigabile a tab, self-consistent.

**Tile workshop** in `site/basic.qmd` / `site/advanced.qmd` / `site/downloads.qmd`: aggiungere il
**4° pulsante "Coding solutions"** accanto a "Open the deck", "Download deck", "Download workshop
ZIP", linkato alla pagina. Comparire solo per workshop fragment-built.

**Trade-off (accettato).** Le soluzioni svolte diventano pubbliche. Coerente con un corso "applied
overview" dove il valore è il live-coding; documentato come scelta consapevole.

## 6. Gate di freschezza

- `scripts/build_release.py`: invece di *WARN-and-copy*, **asserisce** che lo ZIP in `dist/` sia
  più recente dell'albero `_authoring/` del workshop (per i fragment-built); fallisce rumorosamente
  se stantio, anziché copiare in silenzio. `build_all` garantisce l'ordine, quindi nel percorso
  felice non scatta. Aggiungere anche la copia del bundle docente in `dev/release-assets/`
  (`ZIP_ASSETS` esteso con `<slug>-teacher.zip`).
- `check-masking.R` promosso a **gate di release** (step 2 della pipeline), saltabile con
  `--skip-masking`. Resta numerico (equivalenza metriche finali interleaved↔hoisted) e oggi è
  hardcoded su Basic: per Advanced servirà il suo blocco (W3).

## 7. Hook + glue Claude (del repo toccato dalla pipeline)

- `.claude/hooks/remind-workshop-dist.py`: messaggio ripuntato all'entrypoint unico — "esegui
  `/mlt-build` prima di pubblicare una Release" (non più `/mlt-dist`). Trigger (glob su
  `workshops/**` ∨ `slides/workshops/**` ∨ `styles/_brand.scss`) già corretto: si cambia solo
  l'azione suggerita.
- `.claude/hooks/rebuild-portal.py`: **riallineato** — corregge lo schema-path stantio in
  `scripts/build_portal.py` (`EXTERNAL_ARTIFACTS` → `slides/chapters/{slug}.html`, che non esiste
  più nell'architettura a deck unico `slides/slides.qmd`): far puntare gli artefatti slide della
  dashboard agli ancoraggi del deck unico, o rimuovere i link rotti. La dashboard `portal.html`
  resta **author-only**; il sito pubblico `docs/` si rigenera via `/mlt-build` (build_site è
  pesante: non auto-lanciato a ogni edit).
- `.claude/commands/mlt-dist.md`: aggiornato per delegare all'entrypoint unico, oppure ritirato in
  favore di `/mlt-build` (decisione di piano: preferibile far sì che `/mlt-dist` esegua il
  fragment-build prima di zippare, o rimandi a `/mlt-build`). In ogni caso `/mlt-dist` NON deve più
  produrre uno ZIP non-fragment-aware.
- `.claude/commands/mlt-build.md`: **nuovo** command che invoca `scripts/build_all.py`.
- `.claude/settings.json`: audit che nessun hook/permesso punti a comandi/percorsi rimossi o
  rinominati durante la migrazione.

## 8. Documentazione (3 flussi)

- **README root**: nuova sezione "pipeline unica + tre flussi (docente/studente/dev)"; documenta
  `/mlt-build`, l'entrypoint, e il modello di authoring `_authoring/` + `dev/mltbuild/` (oggi del
  tutto assente dal README — un nuovo autore costruirebbe e spedirebbe il vecchio ZIP).
- **`dev/mltbuild/README.md`**: "Known gaps / next" → marca **CHIUSO** il gap release-pipeline,
  punta a `/mlt-build`; aggiorna il "manual workaround" con il nuovo flusso.
- **Vault** (`progetti/mlt-overview/`): aggiorna il tracking con la pipeline unica e i tre flussi.

## 9. Igiene prerequisito (commit separati, niente push)

Necessaria per render **riproducibili da clean checkout**:

- `git add` delle dir immagini untracked usate dai deck: `img/ecdc/`, `img/horst/`,
  `img/horststyle/`, `slides/workshops/_assets/` (~18 immagini) — commit a sé.
- commit dello stato corrente dei deck `.qmd` + `concept-graph.mmd` (oggi non committati, +738
  righe Basic) come "current workshop deck state (pre-W2)" — riproducibilità ora; W2 ci costruirà
  sopra.
- `git rm --cached workshops/mlt-r-basic/_solved.R` — rimuove il file soluzione di root
  pre-migrazione che altrimenti trapelerebbe nello ZIP.

Ogni voce = un commit logico distinto.

## 10. Verifica (FASE 4)

Rigenerare tutto da zero con `/mlt-build`, poi **dimostrare la consistenza**:

1. nuovo `dev/release-assets/mlt-r-basic.zip` con albero fragment-built: step `.R` + `05-report/
   report.qmd`, `renv.lock` per-step 01-05, niente `.qmd`/`steps/_template/`/`yourturn-*.R`,
   niente root `renv.lock`, niente `_solved/`;
2. `mlt-r-basic-teacher.zip` con `_solved/` presente;
3. `docs/` che riflette le slide correnti; pagina + pulsante "Coding solutions" presenti e
   navigabili a tab;
4. deck (theory + workshop) aggiornati;
5. l'Advanced (non migrato) ancora coerente col proprio sorgente via fallback `git ls-files`,
   deck fresco.

**Verifica visiva obbligatoria** via chrome-devtools su: pagina Coding solutions (tab navigabili,
matematica resa), tile workshop col 4° pulsante, un deck renderizzato. Gate dei workshop = parità
**strutturale** (non numerica).

## 11. Contratti / interfacce (riassunto per il piano)

| Unità | Input | Output | Dipende da |
|---|---|---|---|
| `scripts/build_all.py` (`/mlt-build`) | slug? + flag | orchestrazione idempotente | rebuild.R, build_workshop_zip, build_release, build_site |
| `build_workshop_zip.py` | workshop_dir, deck_dir, mode | `dist/<slug>.zip`, `dist/<slug>-teacher.zip` | albero su disco / git ls-files |
| `build_release.py` | dist/*.zip + slide src | `dev/release-assets/*` (+ asserzione freschezza) | build_workshop_zip, quarto |
| `build_site.py` | site/ + `_solved/` | `docs/` + pagina Coding solutions | quarto, _solved/ |
| `rebuild.R` / `check-masking.R` | `_authoring/` | alberi generati + gate | motore mltbuild |

## 12. Rischi

- **renv senza root lock** (§4.1 nota): da risolvere a livello di meccanica nel piano.
- **`_solved/*.html` → pagina unica**: gli `_solved` sono HTML standalone; combinarli in una pagina
  a tab può richiedere estrazione del body o iframe. Verifica visiva obbligatoria.
- **check-masking.R hardcoded su Basic**: per W1 gira solo su Basic; il gate per Advanced è W3.
- **Committare WIP dei deck dell'utente** (§9): commit locali, niente push; elencare esattamente i
  file prima di committare.

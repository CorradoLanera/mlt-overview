# MLT Course Renovation — Toolkit Design Spec

- **Data:** 2026-05-26
- **Branch:** `renovate-mlt-course-toolkit`
- **Repo:** `c:\Users\corra\github\cl\mlt-overview`
- **Autore:** Corrado Lanera (con Claude Code)
- **Stato:** bozza in revisione

> Questo documento è il *piano di creazione e utilizzo* degli strumenti per rinnovare il corso MLT.
> Non è il lavoro sul corso: è la mappa di cosa riusare, cosa costruire, come si concatena.
> L'implementazione (costruzione degli strumenti) avviene **dopo** l'approvazione di questo spec.

---

## 1. Contesto e obiettivo

`mlt-overview` è l'overview di Machine Learning per studenti biomedici/clinici (UBEP, UniPD), oggi in **xaringan** (`index.Rmd`, ~129 slide; `index-full.Rmd` versione estesa), in inglese, registro accademico, no-code, ricco di matematica (`$...$`) e di ~139 immagini.

L'obiettivo a regime, in due movimenti:

1. **Ridisegno didattico-narrativo** (lavoro immediato): per ogni sezione → obiettivi + esercizi sommativi duali → storia in 6 parole → 100 parole 3-atti → arco hook-sfida-risoluzione-payoff con pre-hook → (opz.) sotto-unità con esercizi formativi → storyboard 6 riquadri → item bank valutativi → syllabus → revisione POV-studente.
2. **Migrazione tecnica** (movimento successivo): da xaringan a **Quarto** revealjs modulare a capitoli attivabili da un indice, export PDF per studenti, verifica visiva.

L'ambito approvato è **end-to-end**, costruito in fasi (vedi §12).

## 2. Decisioni già prese (input dell'utente)

- **Lingua:** artefatti studenti in **inglese**; note docente / commenti di design / "voce del docente" in **italiano**.
- **Ambito:** end-to-end (contenuti + Quarto + PDF + verifica visiva).
- **Casa degli strumenti nuovi:** **project-local** in `mlt-overview/.claude/`, riusando le skill atomiche di `storia-companion`.
- **Tracking vault:** ibrido — `progetti/mlt-overview/` (cartella, `area: ubep`) per il lavoro di rinnovazione + nota evergreen `aree/ubep/didattica/corsi/mlt.md` per la materia ricorrente.
- **README del repo:** da creare e mantenere aggiornato.

## 3. Convenzioni (cucite nel `CLAUDE.md` del repo)

- **Lingua:** EN studenti / IT note docente (vedi §2).
- **Matematica:** ogni formula/pedice/overline in `$...$` (regola globale dell'utente). Implica: il renderer HTML **deve** supportare LaTeX (vedi §6.2).
- **Liste markdown:** riga vuota prima di ogni elenco (regola globale).
- **Naming item:** `item_<NN>_<slug>_<type>.md` + `.html` accanto; indice `items_valutativi.md` + `.html`. (Coincide con la convenzione di `storia-companion` v2.)
- **Rubriche:** 3 livelli **base / good / excellent** (EN), descrittori osservabili, soglia di sufficienza, bias di correzione.
- **Manifest come fonte di verità:** la struttura del corso vive in `course/_manifest.yml`, non sparsa nelle skill.
- **Verifica visiva obbligatoria:** nessun artefatto renderizzato è "pronto" prima dell'ispezione visiva (regola globale) — via `chrome-devtools` MCP.

## 4. Fonte di verità: il manifest modulare

```
course/
  _manifest.yml          # indice ordinato + toggle on/off + minuti + obiettivi
  _global/
    spine.md/.html       # 6-parole + 100-parole + arco globali
    syllabus.md/.html
    syllabus-revisione-studenti.md
  <NN-slug>/             # un capitolo = unità di apprendimento
    objectives.md/.html
    narrative.md/.html
    subunits.md/.html
    storyboard.md/.html
    items/ item_NN_<slug>_<type>.md/.html ... items_valutativi.md/.html
    rubriche/ rubrica_NN_<slug>.md
    slides.qmd            # generato in Fase B
```

Schema `_manifest.yml` (esempio):

```yaml
course:
  title: "Machine Learning — An Applied Overview"   # EN, student-facing
  slug: mlt-overview
  language: en
  total_minutes_gross: 240        # ~4h lorde, pause escluse a valle
  audience: "biomedical/clinical graduate students (UBEP)"
  global:                          # riempiti da mlt-narrative
    six_words:
    hundred_words:
    arc:
chapters:
  - slug: 01-introduction
    title: "What is Machine Learning?"
    include: true                  # toggle: false = escluso da generazione e build
    minutes: 25
    objectives: []                 # riempiti da mlt-objectives
    subunits: []                   # opzionale, riempiti da mlt-subunits
  - slug: 02-classifiers
    title: "Classifiers"
    include: true
    minutes: 25
  # ... 03-algorithm-examples, 04-model-selection, 05-deep-learning,
  #     06-unstructured-data, 07-llm-transformers, 08-chatgpt-usage,
  #     09-agents, 10-best-practices
```

Mappatura capitoli ← sezioni attuali di `index.Rmd` (verbatim, da raffinare con l'utente):
Introduction · Classifiers · Algorithm examples (kNN/SVM/kernel/RF/trees) · Model selection · Deep Learning · Unstructured data (CNN/RNN) · LLM/Transformers · ChatGPT usage · Agents · Best practices.

L'orchestratore `/mlt` itera **solo** i capitoli con `include: true`. Aggiungere/togliere un modulo = editare una riga e rilanciare la fase. Lo stesso manifest genera `_quarto.yml` in Fase B.

## 5. Inventario strumenti

### 5.1 Riuso da `storia-companion` **v2** (dopo verifica installazione, §11)

| Funzione (step utente) | Skill/Agent riusato | Note |
|---|---|---|
| Storyboard 6 riquadri (f) | `storyboard-lezione` | match esatto: funzioni Hook visivo/Contesto/Sfida-Dati/Nodo-Impatto/Metodo-Soluzione/Payoff-Domanda; colonne Funzione/Visual/Testo a video/Voce docente |
| Syllabus 7 sezioni + policy IA (i) | `syllabus-2p` | + revisione POV-studente |
| Revisione studente (j) | `studente-confuso` (sub-agent) | non riscrive: segnala |
| **Item bank + rubriche (g,h)** | **`itembank`** | v2 già: `item_NN_<slug>_<type>.md`, `items_valutativi.md`, rubrica 3 livelli, **workflow item-per-item con stop-and-confirm**, `assessment-reviewer` obbligatorio. Vedi §6.7 per i 3 delta |
| Atomi narrativi (dentro i loop) | `sei-parole`, `bing-bang-bongo`, `fonde-narrazioni`, `arco-narrativo-didattico` | invocati in batch da `mlt-narrative` |
| Ossatura globale del corso | `series-bible-didattica` | per la spine globale |
| Review item/obiettivi | `assessment-reviewer` (sub-agent) | |
| Scelta varianti narrative | `narratore-critico` (sub-agent) | |
| Verifica fonti (se bibliografia) | `bibliografo` (sub-agent) | |
| Anti-fake-references | hook `no-fake-references.py` | globale del plugin |

### 5.2 Riuso strumenti globali / MCP

| Strumento | Uso |
|---|---|
| skill globale `project-scaffold` | crea la nota progetto nel vault + aggancia `mlt-overview/.claude/settings.json` alla sottocartella del vault (`additionalDirectories` + permessi least-privilege). Meccanismo del tracking vault (§9) |
| skill globale `vault-add` | capture al volo in `_inbox/` durante il lavoro |
| MCP `chrome-devtools` | verifica visiva: screenshot 1080p + viewport stretto, overflow/taglio |
| MCP `context7` | doc aggiornate Quarto/revealjs durante `mlt-quarto-build` |
| skill `frontend-design` | tema SCSS / card HTML item |
| agent `feature-dev:code-reviewer` | review del codice delle nuove skill/script/hook |

### 5.3 Costruisco project-local in `mlt-overview/.claude/`

| # | Nuovo strumento | Tipo | Copre | Effort |
|---|---|---|---|---|
| 1 | `mlt-scaffold` | command | albero `course/` + `_manifest.yml` + `CLAUDE.md` repo + `README.md` skeleton | S |
| 2 | render-hook matematico (`md-to-html-math.py`) | hook PostToolUse + script | HTML self-contained **con KaTeX** per ogni `.md` del corso | S |
| 3 | `mlt-objectives` | skill | **(a)** obiettivi per sezione + esercizio **sommativo live duale** (presenza+remoto) | M |
| 4 | `mlt-narrative` | skill | **batch (b)(c)(d) + pre-hook ponte + spine globale** | M |
| 5 | `mlt-subunits` | skill | **(e)** sotto-unità con arco proprio + esercizio **formativo proposto→risolto** | M |
| 6 | `mlt-quarto-build` | skill | migrazione xaringan→Quarto + `_quarto.yml` da manifest + tema | L |
| 7 | `/mlt` | command | **orchestratore**: legge manifest, esegue fasi con gate; `--phase`, `--chapter`, rispetta toggle | M |

**NON si costruisce** un `mlt-itembank`: lo step (g)(h) usa `itembank` v2 con le convenzioni di corso fissate nel `CLAUDE.md` + il render-hook matematico.

## 6. Specifiche dei nuovi strumenti

### 6.1 `mlt-scaffold` (command)

Genera l'albero `course/` (§4), il `_manifest.yml` precompilato con le 10 sezioni attuali, il `CLAUDE.md` del repo (convenzioni §3), e uno skeleton di `README.md` (§10). Idempotente: non sovrascrive file esistenti, segnala cosa già c'è. Una tantum.

### 6.2 Render-hook matematico (`md-to-html-math.py`)

PostToolUse su `Write|Edit|MultiEdit` per `.md` dentro `course/`. Produce un `.html` self-contained accanto, **con rendering LaTeX** (KaTeX inline assets o MathJax CDN-fallback), TOC, dark mode, tabelle GFM. Modellato sull'hook `md-to-html.py` di storia-companion **ma con la matematica** (che quello esplicitamente non fa). Python stdlib; gli asset KaTeX inlinati per il self-contained. Disaccoppia il corso da storia-companion (funziona anche se il plugin è disinstallato) e copre item/narrativa/obiettivi pieni di formule.

### 6.3 `mlt-objectives` (skill) — gap (a)

Per ogni capitolo `include: true`: 2-4 **obiettivi osservabili** (verbo + contenuto) + **1 esercizio sommativo da svolgere live in aula duale**. Novità: la **matrice di modalità duale**, con per ogni esercizio:

| Campo | Contenuto |
|---|---|
| Obiettivo verificato | quale objective |
| Azione in presenza | cosa fanno i presenti (es. card alzate, gruppi al tavolo) |
| Equivalente remoto | come partecipano i remoti (poll, chat, doc condiviso, breakout) |
| Artefatto condiviso | cosa resta visibile a tutti (lavagna condivisa, slido, doc) |
| Timing | minuti + momento nell'arco |
| Criterio di riuscita | cosa segnala che l'obiettivo è centrato dal vivo |

Output: `course/<chapter>/objectives.md` (+.html); scrive gli obiettivi anche nel manifest. Invoca `assessment-reviewer` per la coerenza obiettivo↔esercizio.

### 6.4 `mlt-narrative` (skill) — batch (b)(c)(d) + pre-hook

Itera sui capitoli abilitati e, riusando gli atomi di storia-companion:

- **6 parole** (`sei-parole`) — per capitolo + 1 globale; sceglie la migliore con `narratore-critico`.
- **100 parole 3-atti** (`bing-bang-bongo`) — per capitolo + 1 globale.
- **Arco hook-sfida-risoluzione-payoff** (`arco-narrativo-didattico`) — per capitolo, **più un pre-hook esplicito** verso il capitolo abilitato successivo (calcolato dall'ordine del manifest); l'ultimo capitolo ha un pre-hook "verso ciò che seguirà".

Output: `course/_global/spine.md` (+.html) e `course/<chapter>/narrative.md` (+.html). È l'orchestrazione che a storia-companion manca (gli atomi lavorano un tema alla volta).

### 6.5 `mlt-subunits` (skill) — gap (e)

Opzionale per capitolo: lo divide in **sotto-unità di apprendimento**, ognuna con (1) mini-arco hook-sfida-risoluzione-payoff e (2) **coppia di esercizi formativi**: uno **proposto** all'inizio della sotto-unità, lo stesso **risolto** alla fine. Novità rispetto a storia-companion (che ha solo item sommativi). Output: `course/<chapter>/subunits.md` (+.html); aggiorna `subunits` nel manifest.

### 6.6 `mlt-quarto-build` (skill) — Fase B

Da `_manifest.yml`:

- genera `_quarto.yml` (revealjs per capitolo, solo `include: true`; opz. profilo "book/website" per la dispensa);
- **migra la sintassi xaringan→Quarto** per capitolo: `.orange[x]`→`[x]{.orange}`, `.pull-left/right`→`::: {.columns}`, classi `inverse`/`hide-count`, `xaringanExtra` (panelset/progress/scribble)→equivalenti Quarto o rimozione, chunk knitr→celle Quarto;
- porta le immagini, applica un **tema SCSS** derivato da `xaringan-themer.css` (palette rosso/viola/arancio/verde, font Noto Sans/Cabin/Source Code Pro);
- usa `context7` per i doc revealjs aggiornati.

Migrazione = il gap "alto" (nessun tool automatico): la skill codifica le regole + review manuale capitolo per capitolo, con verifica visiva via `chrome-devtools`.

### 6.7 Item bank — riuso di `itembank` v2 (NON nuovo strumento)

`itembank` v2 copre già g/h incluso il loop interattivo. I **3 delta** si chiudono via `CLAUDE.md` del repo, non con codice:

1. **Inglese:** istruzione fissa "items, options, expected answers, rubrics in English".
2. **Rileggi-dal-disco:** prima di passare al prossimo item, **rileggi `item_NN_*.md` dal disco** (l'utente può averlo editato a mano fuori turno) e aggiorna `.md`+`.html` in funzione del contenuto aggiornato + della sua risposta.
3. **HTML matematico:** il render-hook (§6.2) garantisce l'`.html` self-contained con formule, indipendentemente dalla cartella (l'hook di storia richiede `corso-*/` e non rende LaTeX).

Output sotto `course/<chapter>/items/` e `rubriche/`; consolidamento `items_valutativi.md`+`.html`; `assessment-reviewer` prima del rilascio.

### 6.8 `/mlt` (command) — orchestratore

Legge `_manifest.yml`; esegue le fasi in ordine con **gate di conferma** tra una e l'altra; modulare:

- `/mlt` → pipeline completa sui capitoli abilitati;
- `/mlt --phase narrative` → solo una fase;
- `/mlt --chapter 03-algorithm-examples` → un solo capitolo;
- rispetta i toggle `include`.

Aggiorna la **nota "Stato corrente" (LIFO)** nel vault a fine di ogni fase (§9).

## 7. Flusso e concatenazione

```
[Fase 0 setup] verifica storia v2 → project-scaffold (vault link) → mlt-scaffold (course/ + manifest + CLAUDE.md + README + render-hook)

[Fase A contenuti]  /mlt
   objectives (a) ──┐
   spine globale ───┤
                    ├─ per capitolo abilitato: narrative → subunits → storyboard → itembank(v2)
                    └─ syllabus → syllabus-review (studente-confuso)

[Fase B tecnica]  /mlt --phase quarto
   quarto-build (migrazione + _quarto.yml + tema) → verify (chrome-devtools) → PDF (chrome-headless-shell)
```

## 8. Revisori (i "controllori")

| Revisore | Su cosa | Quando |
|---|---|---|
| `assessment-reviewer` | item ↔ obiettivi, bias, distribuzione | dentro `itembank` + `mlt-objectives` |
| `narratore-critico` | varianti 6-parole/100-parole | dentro `mlt-narrative` |
| `studente-confuso` | syllabus, storyboard, chiarezza item | syllabus-review + opz. su storyboard |
| `bibliografo` | fonti/DOI | se si genera bibliografia |
| `chrome-devtools` (MCP) | resa visiva slide/HTML | Fase B + verifica HTML item |
| `feature-dev:code-reviewer` | codice nuove skill/script/hook | durante la costruzione |

## 9. Integrazione tracking vault (ibrido)

- **Progetto:** `progetti/mlt-overview/` con nota indice `mlt-overview.md` (`type: progetto`, `status: attiva`, `area: ubep`, `repo: ${USERPROFILE}/github/cl/mlt-overview`). Struttura a sezioni fissa del vault: Obiettivo → Repo operativo → (Milestone) → Prossime azioni (statica + query Tasks live) → **Stato corrente (LIFO)** → Riferimenti. Più `inventory.md` (snapshot del repo) e questo spec linkato.
- **Area:** nota evergreen `aree/ubep/didattica/corsi/mlt.md` (`type: corso`) per la materia ricorrente, che linka `[[mlt-overview]]`.
- **Wiring repo↔vault:** via `project-scaffold` (aggancia la sottocartella vault al repo via `additionalDirectories`, permessi least-privilege Modalità B). Da verificare il comportamento se la nota progetto esiste già (creata in questa sessione).
- **Aggiornamento:** `/mlt` aggiunge una voce in "Stato corrente" (in cima, LIFO) a fine di ogni fase.
- **Privacy:** il vault è privato; il repo del corso è condivisibile/Pages. Le note di pianificazione/decisione stanno nel vault, i contenuti del corso nel repo. Mai mescolare.

## 10. README del repo

`README.md` in radice: cos'è il corso (overview MLT, audience, durata), come è strutturato (manifest a capitoli modulari), come si rigenera/builda (Quarto, toggle capitoli da `_manifest.yml`), come si esporta PDF, dove stanno gli artefatti didattici (`course/`). Mantenuto aggiornato a ogni fase. È artefatto di repo, distinto dalla nota vault.

## 11. Setup infrastrutturale

1. **`storia-companion` v2 attivo:** verificare che la skill invocabile sia `itembank` (non `itembank-bloom`). Se è installata la v1, aggiornare: `/plugin marketplace add c:/Users/corra/github/cordata/workshop-trieste` + reinstall/update di `storia-companion@storia-trieste-local`.
2. **Export PDF:** `quarto install chrome-headless-shell` (oggi mancante → export PDF bloccato).
3. **Tema:** SCSS derivato da `xaringan-themer.css` (palette + font), condiviso slide↔item↔syllabus.
4. **KaTeX:** asset per il render-hook self-contained (inline).

## 12. Sequenza di costruzione (con checkpoint)

- **Fase 0 — setup:** §11.1, project-scaffold (vault), `mlt-scaffold` (#1), render-hook (#2). Checkpoint: albero + manifest + HTML matematico funzionante (test su un `.md` con `$...$`).
- **Fase A — contenuti:** `mlt-objectives` (#3) → `mlt-narrative` (#4) → `mlt-subunits` (#5) → `/mlt` (#7, prima versione: fasi contenuti). Checkpoint: pipeline su 1 capitolo pilota (`01-introduction`) end-to-end fino agli item.
- **Fase B — tecnica:** `mlt-quarto-build` (#6) → estensione `/mlt` con la fase quarto → setup PDF → verifica visiva. Checkpoint: 1 capitolo renderizzato in revealjs + PDF + screenshot QA.

Ogni nuovo script/skill passa da `feature-dev:code-reviewer`. TDD dove ha senso (render-hook: test su `.md` con formule, tabelle, code fence).

## 13. Fuori scope / rimandato

- Generazione `.docx/.pptx/.xlsx` (markdown/Quarto-first; export Office solo su richiesta).
- Pubblicazione su GitHub Pages (decisione separata; il vault resta privato in ogni caso).
- Localizzazione completa IT degli artefatti studenti (sono EN per scelta §2).
- Riscrittura dei contenuti tecnici datati (sezione LLM/ChatGPT) oltre il necessario alla migrazione — è lavoro di contenuto, non di toolkit.

## 14. Decisioni confermate (2026-05-26)

1. **Capitoli:** si parte dalle 10 sezioni di `index.Rmd` (§4), ma **non è una decisione hard**: l'orchestratore/scaffold può proporre una divisione migliore se emerge in corso d'opera.
2. **Base:** `index.Rmd` (corrente, insegnato). `index-full.Rmd` (più lungo ma più vecchio) viene **"minato"** per recuperare contenuti tagliati, da riproporre come **moduli opzionali** (`include: false`) — coerente con la filosofia modulare. Diff dei due da fare in Fase 0.
3. **`mlt-subunits`:** attivabile **per-capitolo on-demand**, non obbligatorio ovunque.
4. **Tema:** si parte dalla palette `xaringan-themer.css` (continuità), **liberi di variare**; **l'arancione è preferito** dal docente → accento dominante candidato.
5. **Sezione Agents:** da **ampliare in modo proporzionato** usando la sorgente preservata `dev-docs/sources/agents-from-storia-workshop.md` (modello 2×2→2×3 con la colonna agentica: Apprendista Stregone / Demiurgo Digitale; meccaniche "come funzionano gli agenti"). Resta una overview: il "come" applicativo è materia dei workshop di proseguimento → candidato **pre-hook** verso quei workshop. Spunto, non vincolo.

---

## Appendice A — Prompt finale ottimizzato

Vedi file separato `2026-05-26-mlt-run-prompt.md` (pensato per essere incollato in una nuova sessione, dopo che gli strumenti sono stati costruiti).

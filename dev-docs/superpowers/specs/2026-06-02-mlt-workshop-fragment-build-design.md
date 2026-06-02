# MLT workshops — fragment-based build (design)

> Data: 2026-06-02 · Stato: **DRAFT in review** · Autore: Corrado Lanera (con Claude)
> Riferimenti: [[2026-05-31-unified-course-architecture-design]],
> `workshops/mlt-r-basic/`, `workshops/mlt-r-advanced/`.
> Fonda la decisione su un'indagine read-only verificata adversarialmente (workflow
> `mlt-fragment-build-investigation`, 8 agenti, 2026-06-02).

Lingua: note di design in **italiano**; nomi file/codice/termini tecnici in **inglese**
(coerente con la convenzione di progetto).

---

## 1. Problema e obiettivo

I due workshop R (`mlt-r-basic`, `mlt-r-advanced`) sono oggi una sequenza di cartelle-step
**cumulative**: ogni `steps/NN-slug/` è uno snapshot completo del progetto fino a quello step.
Conseguenza misurata: forte **duplicazione** mantenuta a mano (il solo blocco *wrangle*
compare **8 volte** inline tra i due workshop; `nn-modules.R` è copiato byte-per-byte in 3
cartelle; ogni `yourturn-*.R` è replicato in avanti; un HTML *solved* era già rimasto orfano).
Mantenere N snapshot cumulativi coerenti a mano è una fabbrica di drift.

Obiettivo: un **build a frammenti** dove si autora **una sola volta** ogni "beat" di uno step,
e un tool **genera** tutti gli artefatti (cartelle-step cumulative, progetto finale, script
studente, HTML docente, `renv.lock` per-step), con verifica adversariale degli invarianti.
Bersaglio: **drift zero**, ri-erogabile per coorte, identico per tutti.

Non-obiettivo: cambiare i *contenuti* didattici (analisi, dataset, arco narrativo). Questo
spec riguarda **come** gli artefatti sono prodotti e mantenuti, non *cosa* insegnano.

---

## 2. Modello d'aula (il contratto d'interazione)

Per **ogni step** il ritmo è (confermato col docente — opzione "live-code del solo beat nuovo"):

1. **Teoria** (slide): astratto del goal → pacchetti/concetti → divisore di step con gli
   obiettivi *di coding* (vedi §9).
2. Il docente passa al **codice** e "copia" dal vivo il **beat nuovo CON i buchi `___` e
   SENZA eseguirlo**, spiegandolo.
3. Gli studenti (≈1 min) riempiono i buchi nel **loro** script dello step N, che hanno già
   pronto col pregresso risolto.
4. Breve **discussione** sulle soluzioni.
5. Il docente implementa la soluzione corretta, **la esegue**, mostra che funziona e commenta.
6. Si torna alle slide per il blocco di teoria successivo.

Conseguenze di design:

- Gli **studenti lavorano solo su `.R` normali** per tutti gli step incrementali. Non vedono
  `.qmd` finché non è *il concetto da insegnare*: Quarto-report nel terminale di Basic
  (`05-report`), pipeline `targets` (con report come nodo) nel terminale di Advanced
  (`04-targets`). Prima di lì, nessun preambolo YAML, nessun `.qmd`.
- Il **docente** tiene su un secondo schermo gli **HTML risolti** (uno per step, vedi §8),
  aperti in schede ordinate: chiude la scheda corrente a fine step e trova già la successiva.
- **Rete anti-fall-behind, per tutti**: a inizio step N si apre la cartella N, che contiene il
  pregresso già risolto e standardizzato. Chi resta indietro non perde il filo: riparte dalla
  cartella pronta. La *soluzione* dei buchi dello step N ricompare come *given* nella cartella N+1.

---

## 3. Architettura: fonte = frammenti, output = generati

**Ribaltamento chiave.** La fonte di verità **non** è il progetto finale rifattorizzato (da cui
si dovrebbero *de-rifattorizzare all'indietro* gli step — direzione fragile: 8 forme inline con
whitespace diversi, rename di variabili, semantica di closure da preservare). La fonte è la
**sequenza ordinata di frammenti-beat**; il progetto "full" finale e tutte le cartelle-step sono
**generati** assemblando in avanti.

```
workshops/<slug>/                      # cartella del workshop
  _authoring/                          # ── FONTE DI VERITÀ (si autora qui; COMMITTATA)
    workshop.yml                       #    ordine step, metadati globali, dataset
    00-<slug>/  beat.R   meta.yml      #    un frammento per step
    01-<slug>/  beat.R   meta.yml  [R/…]
    05-report/  beat.qmd meta.yml prose.md     # transform (terminale)
    …
  data-raw/                            # dati seed (COMMITTATI)
        │  /mlt-workshop-build <slug>   →  assembla in avanti
        ▼
  steps/NN-slug/                       # ── GENERATO (gitignored, build on-demand)
    NN-slug.R                          #    studente: solved 00..N-1 + beat N coi ___
    renv.lock                          #    cumulativo 00..N-1  (ASSENTE allo step 00)
    data-raw/  .here  [R/…]            #    progetto self-contained
  full/                                # ── GENERATO: progetto finale (tutto chiuso)
  _solved/NN-slug.html                 # ── GENERATO: HTML docente a tab (To fill / Solved)
```

Il blocco *wrangle* è autorato **una volta** (nel suo beat) e ricompare in tutte le cartelle a
valle **per generazione** — niente più 8 copie a mano. Questo è il cuore della tenuta nel tempo.

---

## 4. Tipi di frammento

Non tutti gli step sono "append". L'indagine ne ha isolati tre comportamenti; il build li tratta
diversamente (campo `type` in `meta.yml`):

| type | step | operazione del build |
|---|---|---|
| **append** | Basic 00–04, Adv 00–03 | concatena il `beat.R` (solved) allo script cumulativo; l'ultimo beat porta i buchi |
| **transform-terminal** | Basic `05-report`, Adv `04-targets` | NON concatena: prende gli oggetti/codice accumulati e li re-impacchetta in un artefatto diverso (documento literate / pipeline) da **template autorato** |
| **extract** (operazione *dentro* un beat) | Adv `04-targets` | il beat dichiara che certi blocchi inline diventano funzioni self-contained in `R/*.R` (con possibile trasformazione di logica, es. `vip()`→`vi()`, plot→tibble) |

### 4.1 append

`beat.R` contiene **solo** il codice nuovo dello step, in forma *solved*, con i buchi marcati
(§5). Lo studente-`.R` della cartella N = `assemble(beat 00 … beat N-1)` (tutto risolto) + `beat N`
(coi buchi). Banner `# Section ----`, stile dal `CLAUDE.md` del workshop.

### 4.2 transform-terminal

Sono artefatti di classe diversa, **non derivabili per concatenazione**:

- **Basic `05-report`** = documento Quarto literate, **self-contained e spedibile**: esegue l'intera
  analisi al render (split→recipe→tune→finalize→`last_fit`), interlacciata con prosa e inline-`r ...`.
  Un collega che riceve `report.qmd` + `data-raw/` (+ `renv.lock`) lo ri-renderizza e riottiene tutte
  le analisi **senza errori né blocchi**. Punti vincolanti:
  - **tutto il codice è scritto per esteso nel `.qmd`** — niente `#| include`/child-doc (concetto
    avanzato, e dipendenza da file esterni che si vuole evitare): si **insegna Quarto "normale"**.
    Per non duplicare a mano nella *sorgente*, è il **build** a sostituire il codice canonico dei beat
    nel template del report; ma **l'output spedito ha il codice inline, nessun `include` a runtime**.
    La coerenza è garantita dalla parità con l'oracolo (§11), non da un include.
  - YAML report-class (`embed-resources`, `toc`, `code-fold`, `date: today`); **niente** `plan()`/
    `verbose=TRUE`/`library(future)` né `saveRDS` ereditati dal beat 04 (render sequenziale, pulito);
  - è **solved-only** (nessun buco): la versione studente coincide con la solved.

- **Adv `04-targets`** = ri-architettura in pipeline `targets`, **non** append. Modello (coerente con
  ".R per gli studenti"): si scrive `_targets.R` (script R — la *pipeline*, l'esercizio coi buchi sulle
  definizioni dei `tar_target`), si esegue `tar_make()`, e **la pipeline stessa produce l'HTML** del
  report (`report.qmd` è un *nodo* via `tar_quarto(report,…)` che legge gli oggetti con `tar_read()`).
  Artefatti dello step:
  - `_targets.R` (DAG), `R/pipeline-fns.R` (funzioni estratte self-contained, §4.3), `report.qmd`
    (nodo di report — qui si insegna Quarto-dentro-una-pipeline; gli studenti conoscono già Quarto da Basic-05);
  - l'**ispezione interattiva** (`tar_visnetwork()`, `tar_read()`, `tar_outdated()`, la prova
    "seconda run = skip") è **live-coded** dal docente in console — **non** un documento a parte.
    **Si elimina il `04-targets.qmd` "demo" attuale** (sparisce anche il rischio re-entrancy);
  - **spedibilità a livello di progetto**: un collega riceve il progetto (`_targets.R`, `R/`,
    `data-raw/`, `renv.lock`), fa `tar_make()` e riottiene store + report. `report.qmd` da solo dipende
    dallo store — è il punto: l'unità riproducibile è la *pipeline*, non il singolo documento;
  - il build esegue `tar_make()` **una volta** (popola lo store non-clone-portable e produce l'HTML del
    report = deliverable); il report è renderizzato **come nodo** della pipeline, mai standalone.

### 4.3 extract (self-contained)

Quando un beat estrae logica inline in `R/<file>.R`:

- le funzioni si scrivono **self-contained**: `pkg::fun()` ovunque (`hardhat::extract_workflow()`,
  `rio::import()`, `janitor::clean_names()`, `vip::vi()`, …) e per i **generici S3** (es. `predict()`
  su un workflow → `predict.workflow` in `workflows`) un `requireNamespace("workflows")` in testa.
  Il file **dichiara i propri bisogni**, non li prende in prestito da `tar_option_set(packages=)`.
  (Correzione esplicita rispetto allo stato attuale, che si appoggiava all'attach del worker.)
- la forma **inline-early** vive nel beat dello step dove appare inline (autorata una volta, generata
  a valle); la forma **extracted-late** vive nel beat che estrae (autorata una volta). Non si deriva
  l'una dall'altra: si **verifica l'equivalenza comportamentale** (es. `load_cohort(file)` produce
  lo stesso tibble del wrangle inline canonico) con un check del verificatore (§10). L'estrazione
  avviene in **un solo punto** (Adv 04), quindi la duplicazione intenzionale è minima e sorvegliata.

---

## 5. Formato dei buchi

Un buco è una **regione con doppia resa**: `solved` (codice vero) e `blank` (ciò che vede lo
studente). Il build genera lo studente-`.R` (rese `blank`) e l'HTML solved (rese `solved`).
Devono essere supportati **7 tipi** (rilevati nell'indagine):

1. **token singolo** — `select(-time)` → `select(-___)`
2. **espressione** — `truth = outcome, .pred_died` → `… ___`
3. **riga intera** — una riga sostituita da `___`
4. **regione multi-riga** — più righe da scrivere
5. **skeleton non eseguito** — il blocco esercizio mostrato verbatim, mai eseguito (perché `___`
   non è R parsabile)
6. **Parsons / riordino** — righe date scombinate da riordinare
7. **prosa senza `___`** — consegna concettuale senza blank letterale

Requisiti: **buchi multipli e indipendenti** nello stesso beat; step **senza** buchi (00, demo);
ogni buco ha un `id` per tracciabilità e per gli `#| include` cross-beat.

Sintassi proposta (da finalizzare nel piano) — marcatori a commento, due rese affiancate:

```r
# >>> hole id=drop-time  prompt="drop the leaky follow-up column"
  select(-time) |>         #@solved
  select(-___)  |>         #@blank
# <<< hole
```

Per Parsons: `#@blank-parsons` con le righe da scombinare. Per prosa: `#@blank-prose: "…"`.
Il generatore: resa solved = tiene le righe `#@solved` (spoglia i marcatori); resa blank = tiene
`#@blank`/`#@blank-*`. Lo skeleton non-eseguito è semplicemente la resa blank emessa come blocco di
testo (mai come chunk R eseguito).

---

## 6. Contratto della cartella-step generata

Ogni `workshops/<slug>/steps/NN-slug/` è un **progetto R self-contained**:

- `NN-slug.R` — script studente (pregresso solved + beat N coi buchi). **Nessun `.qmd`** negli step
  append. (Allo step 00 il pregresso è vuoto: c'è **solo il primo formative** coi `___`.)
- `renv.lock` — **cumulativo 00..N-1**, **assente allo step 00** (che fa `renv::init()`); vedi §7.
- `data-raw/` — i dati necessari fino a N.
- `.here` — sentinel: **deve viaggiare con ogni cartella**, altrimenti `here('R',…)` risolve al
  `R/` di root sbagliato. Invariante verificato (§10).
- `R/` — **solo** funzioni vere/asset trasportati (mai i `yourturn` come helper). Distinto dal `R/`
  di root (`seed-data.R`, `_dependencies.R`).
- Asset **carry-forward** (`nn-modules.R`, asset `.rds`, `hf_notes.csv`, …): trasportati dal build
  perché lo snapshot è completo, **non** sorgenti dello step (non `source()`-ati, non scansionati per
  dedurre dipendenze). Con fonte=frammenti questo è esplicito e non più un pericolo.

`full/` = stessa struttura con tutti i beat chiusi (nessun buco) — generato, paradossalmente non
necessario all'aula ma utile come **riferimento strutturale** del progetto finito. (L'oracolo di
*parità comportamentale* è invece l'insieme degli HTML solved di riferimento, §11.)

---

## 7. `renv` per-step

- Ogni cartella-step ha il **proprio `renv.lock`**, pari all'unione cumulativa dei pacchetti dei beat
  **00..N-1** — lo *stato di partenza* dello step N (campo `packages` in `meta.yml`). I pacchetti
  **nuovi** dello step N **non** sono ancora nel lock: lo studente li aggiunge **durante** lo step
  (`renv::install()` + `renv::snapshot()`) come momento d'insegnamento — ed è esattamente il lock che
  troverà già pronto, completo fino a N, nella cartella N+1.
- **Ciclo `renv` insegnato lungo il corso**: step **00** = `renv::init()` (avvio progetto da zero,
  nessun lock di partenza, cartella con solo `data-raw/`); step **01+** = `renv::restore()` (ripristino
  del lock pinnato); a **ogni nuovo pacchetto** introdotto da un beat = `renv::install()` +
  `renv::snapshot()`. Lifecycle completo e corretto, distribuito sugli step.
- Repo pinnato a **Posit Public Package Manager** con snapshot datato (oggi:
  `https://packagemanager.posit.co/cran/2026-06-01`) → **binari Windows già compilati** per la R del
  workshop. (Già applicato al Basic: lock completato + pin.)
- Cadenza didattica: lo studente apre la cartella N e fa `renv::restore()` (veloce — i pacchetti
  già scaricati sono link dalla cache globale renv). Quando un beat **introduce un nuovo pacchetto**,
  il beat include il momento d'insegnamento `renv::install()` + `renv::snapshot()` ("serve un
  pacchetto → lo aggiungo come si deve"). La cartella N+1 canonica ha già il lock aggiornato.
- Nota operativa: il restore-per-step è economico grazie alla cache; non è un collo di bottiglia.

---

## 8. HTML docente a tab (un file per step)

Feature nativa Quarto: **`::: {.panel-tabset}`** (non serve `exams`, che è generazione d'esami).
Il build genera, per ogni step append, **un** `_solved/NN-slug.html` con due schede:

- **To fill** — lo studente-`.R` (rese blank) come blocco **non eseguito** (verbatim);
- **Solved** — il codice (rese solved) **eseguito**, con output/tabelle/plot.

Per gli step **transform-terminal** l'HTML è il documento renderizzato (solved-only): per Basic il
**report** Quarto self-contained; per Advanced l'**HTML prodotto dalla pipeline** (`tar_make()` che
renderizza `report.qmd` come nodo finale). `embed-resources: true`, self-contained, apribili offline.

---

## 9. Slide: ordine e gobbo

### 9.1 Riordino per-step: astratto → teoria → step

Pattern per ogni step:

1. **Astratto / goal** — *cosa* dobbiamo ottenere (1 slide motivazionale, niente dettaglio di codice);
2. **Teoria** — i pacchetti e i concetti per farlo;
3. **Divisore di step** (`# Step NN · <slug>`) con gli **obiettivi di coding** → "andiamo al code".

Così gli obiettivi (che sono di coding) stanno **dopo** la teoria che li abilita — niente più
inversione "annuncio gli obiettivi prima di insegnarli". Avvertenze dall'indagine:

- i divisori `# Step NN` sono **content-bearing** (obiettivi + commento-timing): il riordino è
  **editoriale**, non un semplice scambio di slide; l'astratto va estratto/riscritto come opener;
- casi non uniformi: step senza slide di teoria (no-op), divisori non-step (`# Build and validate…`,
  `# Hyperparameters…`), classe `.center` incoerente, e nell'Advanced l'opener ha le `notes` *prima*
  del corpo. Gestione caso-per-caso, non regex cieca.

### 9.2 Gobbo telegrafico

Riscrivere i `::: {.notes}` come **cue d'azione brevi** (è già la regola del docente: gobbo
telegrafico, mai prosa). ~39 blocchi totali (22 Basic + 17 Advanced), ~31–35 da riscrivere.

- **Togliere**: minutaggi, `feedback #N`, meta-note tipo `{rio}` vs `rio`, asintoti di produzione,
  riferimenti a studenti-persona ("Stretch Davide"), enumerazioni di distrattori MCQ, echo dei
  bullet già a slide.
- **Preservare** i cue *load-bearing*: live-check GREEN/RED, convenzione EVENT-FIRST, regola di
  onestà sull'eccezione etichettata, e **fatti correttivi** (es. la direzione **corretta** di
  `rbf_sigma` in kernlab) — tenuti come fatto, non come "CORREZIONE rispetto a…".

(9.1 e 9.2 sono in-scope ma separabili in una fase a sé: vedi §11, F4.)

---

## 10. Invarianti e verifica adversariale

Il valore di ultracode/workflow qui: dopo ogni build, un **sub-agent verificatore** controlla gli
invarianti e **fallisce rumorosamente**. Checklist (dai landmine dell'indagine):

1. **Ogni step renderizza** davvero (lo studente-`.R` gira; la solved esegue senza errori).
2. **`.here` presente** in ogni cartella-step (echo/`here()` risolvono al `R/` locale, non a root).
3. **Parità comportamentale extract↔inline**: `load_cohort()` ecc. producono lo stesso oggetto del
   beat canonico inline.
4. **`pipeline-fns.R` self-contained**: si `source()`-a in isolamento e risolve (`pkg::`/`requireNamespace`).
5. **Targets**: `tar_make()` eseguito una volta popola lo store e produce l'HTML del report (nodo
   finale); `report.qmd` **non** renderizzato standalone; **nessun** `04-targets.qmd` demo separato.
6. **Advanced self-seeding**: `00-recap` ricostruisce il modello da `data-raw/heart_failure.csv` con
   `set.seed` — **nessuna** dipendenza da `final_fit.rds` copiato (vedi §11). Nessun `readRDS` cross-workshop.
7. **Carry-forward corretto**: gli asset trasportati ci sono ma non sono `source()`-ati né innescano
   dipendenze spurie (es. `nn-modules.R`/torch non entra nei requisiti della pipeline).
8. **`renv.lock` per-step coerente** con i pacchetti cumulativi dei beat fino a N.
9. **Buchi**: ogni `id` ha resa solved e blank; nessun `___` finisce in un chunk eseguito.
10. **Parità con l'oracolo** (§11): la solved generata riproduce l'HTML solved di riferimento.

---

## 11. Migrazione e oracolo di parità

Abbiamo già compilato e ispezionato visivamente gli **HTML solved del Basic** (6 step, R 4.6, env
pinnato PPM). Questi diventano l'**oracolo di parità** della migrazione: la prima implementazione del
build deve rigenerare il Basic e produrre solved **equivalenti** (stesse tabelle/curve/numeri, modulo
seed). Fasi (dettaglio nel piano):

- **F1 — tooling su Basic**: estrarre i beat dai `.qmd` attuali → `workshops/mlt-r-basic/_authoring/`;
  scrivere `/mlt-workshop-build`; generare `workshops/mlt-r-basic/{steps,full,_solved}` e verificare
  parità con l'oracolo.
- **F2 — Advanced**: beat 00–03 + self-seeding (00-recap) + transform `04-targets` (`_targets.R` +
  `report.qmd` come nodo, `tar_make()` produce l'HTML, extract self-contained); verifica invarianti.
- **F3 — verificatore**: il sub-agent adversariale come gate del build (anche in CI).
- **F4 — slide**: riordino astratto→teoria→step + gobbo telegrafico (separabile).

---

## 12. Tooling che possiede tutto a lungo termine

- **Command `/mlt-workshop-build <slug>`** — assembla i frammenti → albero workshop generato
  (cartelle-step + `full` + `renv.lock` per-step + studente-`.R` + HTML docente a tab). Idempotente.
- **Sub-agent verificatore adversariale** — esegue la checklist §10 dopo ogni build; gate rumoroso.
- **Skill di authoring-frammento** — scaffolda/edita un beat (sceglie `type` append/transform/extract,
  marca i buchi, dichiara `packages`/`carry`) in modo coerente.

Eventuale follow-on (fuori scope qui): estrazione di queste tecniche nel plugin `teachtogether`
(vedi spec architettura). *Metodo ora, plugin dopo.*

---

## 13. Decisioni prese / fuori scope

**Decise (2026-06-02):**

- **Sorgente sotto il workshop**: `workshops/<slug>/_authoring/` (committata).
- **Output generato**: `workshops/<slug>/{steps,full,_solved}` sono **build on-demand e gitignored**
  (non committati); lo ZIP di distribuzione si costruisce dal generato.
- **`00-setup`**: parte da cartella con **solo** `data-raw/` (+ `.here`), **niente `renv.lock`**; lo
  step insegna `renv::init()` e il `00-setup.R` è il **primo formative non risolto** (coi `___`). Da
  lì in poi gli step hanno un `renv.lock` e usano `renv::restore()` → ciclo renv completo (§7).

**Aperte / fuori scope:**

- Sintassi **esatta** dei marcatori-buco (§5) — finalizzare nel piano.
- Posit Cloud per-workshop (distribuzione alternativa allo ZIP).

---

## 14. Criteri di successo

- Modificare **un** frammento e **rigenerare** tutto a valle (step + full + studente-`.R` + HTML +
  `renv.lock`) **senza ritocchi a mano** → drift zero.
- Ogni step generato **renderizza**; l'HTML docente ha le due schede (append) o il documento (transform).
- Advanced **self-seeding**: nessun artefatto copiato da Basic; ogni workshop riproducibile da solo.
- `renv.lock` per-step corretti; binari Windows da PPM.
- Deck: pattern **astratto → teoria → step**; gobbo **telegrafico** coi cue load-bearing preservati.
- Il verificatore adversariale passa tutti gli invarianti §10; parità con l'oracolo §11.

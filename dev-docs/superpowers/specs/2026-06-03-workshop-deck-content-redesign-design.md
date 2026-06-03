# MLT — Ridisegno del CONTENUTO dei deck workshop (Basic + Advanced) — Design Spec

- **Data:** 2026-06-03
- **Branch:** `workshop-deck-redesign`
- **Repo:** `c:\Users\corra\github\cl\mlt-overview`
- **Autore:** Corrado Lanera (con Claude Code)
- **Stato:** bozza in revisione
- **Spec collegati:** [`2026-05-30-mlt-r-workshops-design.md`](2026-05-30-mlt-r-workshops-design.md) (pedagogia T3 dei workshop — fonte degli obiettivi, concept graph, mappa formative), [`2026-05-31-unified-course-architecture-design.md`](2026-05-31-unified-course-architecture-design.md) (convenzioni di deck, distribuzione, stile)

> Questo è lavoro di **puro authoring di contenuto** sui due deck unici dei workshop R. La pipeline build/release
> unificata (W1) è già fatta e mergiata: l'entrypoint `/mlt-build` → `scripts/build_all.py` renderizza e spedisce
> qualunque sorgente deck, idempotente. Quindi: **zero rework di pipeline** — basta ri-lanciare `/mlt-build` alla
> fine. Non si tocca la narrative spine inter-modulo, né i driver `steps/NN/*.qmd`, né i dataset/numeri.

---

## 1. Contesto e problema

I due deck workshop (`slides/workshops/mlt-r-basic/00-basic-deck.qmd`,
`slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`) sono **deck unici** revealjs, autorati a mano per T3.
Oggi soffrono di tre problemi verificati:

1. **Le formative NON sono nel deck.** Sono file `.md` separati (10 per Basic, 11 per Advanced) che il render di
   progetto (`quarto render slides/workshops/<slug>`) trasforma in **HTML revealjs standalone** (`min-NN-*_files/`,
   `min-NN-*.html`). Fragili a lezione (deck separati da aprire), e non è chiaro *quando* mostrarli. La mappa
   formativa→dopo-step→minuto→nodo esiste già in `slides/workshops/<slug>/formatives/README.md`.
2. **L'arco per-step intended non è implementato.** Oggi: divider `# Step NN` → slide di teoria → divider
   successivo. Manca l'arco "intro (cosa serve + PERCHÉ) → teoria (le funzioni/pacchetti R) → formativa → slide
   *go to code* che CHIUDE lo step".
3. **Le formative non sono slide di teoria.** Come `.md` standalone hanno preamboli "motivazione" e riferimenti
   alle personas (`Stretch (Davide)`), e manca la separazione *proietta domanda/opzioni* vs *rivela soluzione*.

**Obiettivo:** integrare ogni formativa **dentro il deck unico** al suo punto giusto, come coppia di slide di
teoria **Engage → Reveal**; ricostruire l'**arco per-step**; ritirare gli HTML formative standalone come
deliverable. **Basic per primo** (implementazione di riferimento), poi **Advanced eredita** lo stesso pattern.

## 2. Principi e vincoli (invariati)

- **Lingua:** artefatti studente (testo a slide) in **INGLESE**; note di design e voce-docente (speaker notes) in
  **ITALIANO**.
- **Matematica:** ogni formula/pedice/overline/simbolo stand-alone in `$...$` (mai combining-Unicode).
- **Liste markdown:** riga vuota prima di ogni elenco.
- **Delivery doctrine (§8 dello spec workshops):** tutto live-coded, **niente risultato pre-cotto mostrato come
  live**. L'"invito a promptare il codice" significa invitare lo studente a **scriverlo al prompt R** (`>`) durante
  il your-turn — **nessun LLM/chatbot/agent coinvolto**. La doctrine resta intatta.
- **Verifica visiva obbligatoria:** nessun deck è "pronto" senza ispezione `chrome-devtools` a 1080p + viewport
  stretto.
- **Build:** zero modifiche a `scripts/`, hook, `_quarto.yml`. A fine lavoro `/mlt-build` rigenera deck + ZIP +
  portale.

## 3. Il per-step arc (pattern di riferimento)

Ogni step del deck adotta questo arco:

- **Intro** = il divider `# Step NN · Title {.center}` **riscritto per guidare col PERCHÉ** (che problema risolve
  lo step, cosa serve), non con un elenco asettico di obiettivi. Resta la slide-titolo dello step.
- **Mini-cicli interlacciati** `[teoria → formativa]`: teoria (le funzioni e i pacchetti R per implementare lo
  step) e formative si **alternano** ai confini naturali di chunk (cadenza T3 ~ogni 10–15 min). Non un blocco
  rigido "tutta teoria poi tutte le formative".
- **Go to code** = **UNA** slide di chiusura per step, con accento visivo distinto, che manda al progetto:
  *"open `steps/NN-slug/`, type it, run it; behind? copy the next folder"* + bridge al prossimo step. Per gli step
  **demo** (Basic 00/05; Advanced 00/04) il taglio è *"follow along → `steps/NN`"*.

Vincolo: **un solo intro e un solo go-to-code per step**.

## 4. Formative-as-slides (anatomia: 2 slide Engage → Reveal)

Ogni formativa diventa una coppia di slide di teoria **integrate nel deck**:

- **Engage** (proietta / your-turn): il **problema** (domanda MCQ · task your-turn · 3 check live-check ·
  predizione predict-output · righe da riordinare Parsons) + le **opzioni** (MCQ) oppure **spazio + `{countdown}`**
  (your-turn) + l'**invito esplicito a scriverlo al prompt R** ("your turn — type it"). È il momento di
  *commitment* (vota/prova prima di vedere la risposta).
- **Reveal** (soluzione): la **soluzione** + il **perché ogni distrattore è errato** (MCQ) / soluzione-codice +
  perché (your-turn) / GREEN atteso + fix (live-check) / ordinamento corretto + vincoli di forma (Parsons). Più,
  **solo dove aggiunge valore**, una nota **"Going further"** de-personalizzata in fondo (la ex-profondità
  `Stretch`, senza nome di persona).

Convenzioni:

- Testo studente in EN. Il razionale "misconception → distrattore" e la voce-docente vanno nelle **speaker notes
  IT** (`::: {.notes}`), non a slide.
- Tipi coperti: `live-check`, `mcq`, `your-turn`, `predict-output`, `parsons` (solo Advanced min-80).
- Le slide formative sono **slide di teoria** del deck unico (non più deck separati): seguono lo stesso tema/brand,
  senza un tipo-slide speciale (eventuale micro-accento visivo per segnalarle come "check" è opzionale, deciso in
  build con verifica visiva).

## 5. Cosa si ritira / rimuove

- **HTML formative standalone**: si **eliminano** i file sorgente `slides/workshops/<slug>/formatives/min-*.md`
  (10 Basic + 11 Advanced) e i loro output `min-*.html` / `min-*_files/`. Sparito il sorgente, il render di
  progetto emette **solo** il deck unico → niente più deck-formativa separati. *Questo è il fix del problema #1
  senza toccare la pipeline.*
- **Riferimenti alle personas** (Sara / Marco / Lucia / Davide; etichette `Stretch (Davide)`) rimossi ovunque nei
  deck. La profondità extra sopravvive come "Going further" de-personalizzata (§4).
- **Preamboli "motivazione"** delle formative: assorbiti nel flusso del deck (l'intro dello step fa già da
  motivazione).

## 6. Cosa si preserva

- **Slide module-level** (non sono formative né per-step): apertura (title · find-me · credits · day-overview ·
  clinical question · variables) e chiusura (concept map · "Next: Advanced" pre-hook · further reading · thanks).
- **`formatives/README.md`** come **mappa aggiornata** formativa→dopo-step→minuto→nodo (single source della
  mappatura; resta il documento di tracciamento anche dopo che il contenuto vive nel deck).
- Brand/theme SCSS (`styles/_brand.scss` + `theme.scss`), doctrine live-coding §8, meccanica checkpoint
  `steps/NN-slug/`, concept graph già validati.

## 7. Mappa concreta del nuovo deck Basic

```
[opening] title · find-me · credits · day-overview · clinical question · variables

# Step 00 · Setup  [INTRO: ambiente sano = precondizione di tutto]
  theory: renv / here / rio
  formative min-09 live-check        (Engage: 3 checks → Reveal: GREEN + fix)
  GO TO CODE → steps/00-setup (follow along)

# Step 01 · Import & wrangle  [INTRO: i dati grezzi ingannano → tidy + evita il leakage]
  theory: tidyverse → native pipe |>
  formative min-31 MCQ pipe/verbi    (Engage → Reveal)
  theory: verbi (select/mutate/filter/across…) → tidy data + leakage trap
  formative min-30 your-turn wrangle (Engage: task + countdown → Reveal: code + why; Going further: perché time è leakage)
  GO TO CODE → steps/01-import

# Step 02 · Clinical EDA  [INTRO: descrivi la coorte, leggine la forma]
  theory: gtsummary Table 1 → ggplot grammar → learning paradigms
  formative min-50 MCQ due metriche  (Engage → Reveal)
  GO TO CODE → steps/02-eda

# Step 03 · Logistic spine  [INTRO: una spina riusabile, glm come ancora]
  theory: tidymodels spine → object-map (mermaid) → 5 packages + funzioni
  formative min-72 your-turn glm = workflow  (Engage → Reveal; Going further: cosa compra recipe+workflow)
  formative min-88 MCQ engine-swap           (Engage → Reveal)
  GO TO CODE → steps/03-logistic
[BREAK]

# Step 04 · The zoo, tuned & validated  [INTRO: assorbe "Hyperparameters" — iperparametro vs parametro; 4 famiglie, una gara equa]
  theory "the knobs": pen-logistic (penalty/mixture) · kNN (neighbors) · SVM (cost/rbf_sigma) · RF (mtry/min_n/trees)
  formative min-118 MCQ kNN bias-variance    (Engage → Reveal)
  theory "tune at scale": workflow_set/workflow_map · vfold_cv · two metrics & why one split lies
  formative min-150 your-turn culminating    (Engage → Reveal; Going further: 1-SE rule, 5° engine in one line)
  formative min-165 predict-output 3 AUCs    (Engage → Reveal)
  GO TO CODE → steps/04-zoo

# Step 05 · Reproducible report  [INTRO: spedisci il deliverable, riproducibile perché gira]
  theory: why "one render" is reproducibility
  formative min-175 MCQ riproducibilità      (Engage → Reveal)
  GO TO CODE → steps/05-report (follow along)

[closing] concept map · Next: open the model — Advanced (pre-hook) · further reading · thanks
```

**Decisioni di collocazione interlacciata (Step 01 e 04)** — pedagogiche, soggette a tweak in build:

- **Step 01:** `min-31` (semantica pipe/verbi) subito dopo la teoria del pipe; `min-30` (wrangle integrativo) dopo
  `tidy data + leakage`, perché integra tutti i verbi + il drop di `time`.
- **Step 04:** la sezione divider `# Hyperparameters, one algorithm at a time` si **dissolve** nell'intro+teoria
  dello Step 04; `min-118` chiude il chunk "the knobs", `min-150`+`min-165` chiudono il chunk "tune at scale".

**Impatto deck Basic:** ≈ +20 slide formative (10×2) + 6 go-to-code − 1 divider "Hyperparameters" assorbito. Le
slide module-level e l'ordine teoria restano; cambia l'inserimento di formative + go-to-code e la riscrittura degli
intro col PERCHÉ.

## 8. Advanced eredita

Stesso pattern su `00-advanced-deck.qmd`, applicato **dopo** Basic (Basic = riferimento). Specificità da
rispettare:

- Concetti per step (recap → interpretability → deep learning → ellmer → targets) e relativi numeri reali già nel
  deck.
- **Honesty rule:** la slide "The honesty rule — one labeled exception" e la loss-curve opzione B restano slide di
  **contenuto** (non formative); la formativa `min-92` la *verifica*.
- 11 formative integrate: `min-10` live-check, `min-24` MCQ VIMP, `min-38` predict SHAP↔coef, `min-46` MCQ SHAP
  knob, `min-60` MCQ MLP overfit, `min-66` your-turn SHAP-su-MLP, `min-80` **Parsons** forward() rete fusa, `min-92`
  MCQ honesty, `min-112` predict type_object, `min-124` MCQ temperature, `min-138` predict capstone.
- 5 step → 5 intro col PERCHÉ + 5 go-to-code; stesse rimozioni (standalone HTML, personas, preamboli motivazione).

## 9. Authoring & build mechanics

- Engage/Reveal scritte **inline** nel deck `.qmd` (coerente §7 dello spec architettura: i deck workshop si
  autorano a mano, niente storyboard/`mlt-quarto-build`).
- Eliminazione dei `.md` formative + relativi `.html`/`_files` (Basic e Advanced); aggiornamento di
  `formatives/README.md` come mappa.
- A fine lavoro: **`/mlt-build`** → ri-render dei deck embed-resources + `build_workshop_zip.py` per workshop +
  portale. Nessun cambiamento a `_quarto.yml`, hook o script.
- **Verifica visiva** (`chrome-devtools`, 1080p + viewport stretto) su **entrambi** i deck renderizzati: scorrere
  almeno gli intro, ogni coppia Engage→Reveal, le slide go-to-code, le tabelle parametro, il mermaid object-map e i
  concept graph; correggere overflow/sovrapposizioni/contrasto prima di dichiarare "pronto".

## 10. Coerenza col deck teorico (overview)

I deck workshop riusano già apertura/chiusura dell'overview (loghi cover, find-me, credits, further-reading,
procione di chiusura — vedi memoria `workshop-decks-scaffold`). Il nuovo arco per-step non tocca queste slide
gemelle: il workshop resta T3 backward-design (summative-first + formative), l'overview resta storyboard
hook-sfida-risoluzione-payoff. La spina narrativa inter-modulo (Overview cap.10 → Basic → Advanced) e i pre-hook
restano invariati.

## 11. Sequenza di costruzione

1. **Basic — arco + formative inline.** Riscrivi gli intro col PERCHÉ; inserisci le 10 coppie Engage→Reveal ai
   punti §7; aggiungi le 6 slide go-to-code; assorbi "Hyperparameters" nello Step 04; rimuovi personas/preamboli.
2. **Basic — ritiro standalone.** Elimina `formatives/min-*.md` + output; aggiorna `formatives/README.md`.
3. **Basic — verifica visiva + render** (`quarto render` del solo deck o `/mlt-build`), iterazione fino a pulito.
4. **Advanced — eredita.** Applica 1–3 a `00-advanced-deck.qmd` + 11 formative (incl. Parsons) + honesty rule.
5. **`/mlt-build` finale** → deck + ZIP + portale rigenerati; verifica visiva finale di entrambi.

Implementazione via `subagent-driven-development` sul branch `workshop-deck-redesign`, dopo la review del piano
(`writing-plans`). NON fare `git push` (pusha l'utente).

## 12. Fuori scope (YAGNI)

- Modifiche a pipeline build/release, hook, `_quarto.yml`, `scripts/`.
- Contenuto dei driver `steps/NN-slug/*.qmd` (codice R del workshop).
- Nuovi dataset, nuovi numeri/benchmark, nuove formative oltre quelle mappate.
- Cambi alla narrative spine inter-modulo e ai pre-hook.
- Pubblicazione GitHub Pages dei deck.
- Estrazione del plugin `teachtogether` (follow-on separato).

## 13. Domande aperte (da risolvere in build)

1. Micro-accento visivo per le slide formative (sì/no, quale) — deciso in build con verifica visiva.
2. Forma esatta della slide "Go to code" (testo + eventuale icona/colore) — prototipata su Step 01, poi
   propagata.
3. Collocazione fine delle formative interlacciate in Step 01/04 (§7) — confermata o aggiustata alla prima
   ispezione visiva del flusso.

# MLT Advanced — ridisegno sezione 02 "Deep learning"

> Design spec. Note di design in italiano; artefatti studente (slide, codice, titoli) in inglese.
> Banco di prova del processo per-sezione (vedi sez. 00/01): allinea forma+contenuto, non grafica.
> L'implementazione segue via `writing-plans` → `subagent-driven-development`.

**Goal.** Sostituire l'attuale sez.02 (loss curve inventata + CNN/RNN/fused "scritte-non-allenate") con
reti **davvero addestrate dal vivo** (CNN 2D e RNN, con curve train/val a U reali), rendere esplicito il
**confine `brulee`/tidymodels ↔ `torch`/`luz`**, e fare del costo di training reale il **setup della
sez.04 `targets`** ("se le ipotesi non cambiano, non riallena").

**Architettura della sezione.** Un solo step folder `02-deep-learning` (cresce a pezzo centrale del
workshop). Apertura tabellare in tidymodels (MLP `brulee` + SHAP) → due strati di teoria minima
(loss-vs-metriche, loop di training reso concreto) → il confine → **CNN 2D reale** → **RNN reale** →
**fused = demo architetturale** (non allenata) → cenno XAI-sulle-reti → nota onesta GPU-vs-CPU → go-to-code.

**Stack.** `torch` + `luz` (+ `coro` per i dataloader) per le reti su misura; `brulee` (engine parsnip
torch-backed) per la sola MLP tabellare; `torchvision` per il caricamento immagini; `kernelshap`/`shapviz`
per SHAP sulla MLP; `yardstick` per le metriche da entrambi i lati del confine. Tutti già pinnati nel
`renv.lock` dell'Advanced — **nessun delta renv bloccante**.

---

## 1. Decisioni fissate nel brainstorming (2026-06-12)

1. **Training dal vivo, sempre.** Lo step code addestra le reti reali (epoche, forward/backward, curve
   train/val). Il parity-gate paga il costo a ogni build; è accettato perché per lo studente è one-shot e
   perché alimenta il guadagno di `targets` in sez.04.
2. **Dati committati, fetch mostrato-ma-guardato.** Scarico/converto/committo io i dataset ora; il deck e
   lo step mostrano il **codice di download** (da pacchetti/repo) come illustrativo non eseguito, e lo step
   **carica dal locale** (`here("data-raw", ...)`), pattern del primo workshop.
3. **`brulee` resta** per la MLP tabellare: è il ponte che fa vivere una rete *dentro* tidymodels (stessa
   API fit/predict, stesso `workflow_set`, stesse metriche) e ospita il callback SHAP della sez.01.
4. **Dataset:**
   - CNN 2D → **PneumoniaMNIST** (immagini mediche 28×28, binario normale/polmonite), pre-convertito in
     tensore `.rds` committato. Fallback se l'`.npz` fa storie: `torchvision::mnist_dataset` (cifre).
   - RNN → una **sequenza di vitali/ECG** ridotta (classificazione di un outcome), committata come tensore.
   - Fused → **riusa i tre tensori già visti** (tab = `heart_failure` del Basic, img = un esempio
     PneumoniaMNIST, seq = una sequenza vitali).
5. **Fused = demo architetturale, non allenata.** Si costruisce la rete a 3 rami e si fa un `forward()` su un
   esempio per ramo → output `[1, 2]`. Framing onesto: **è costruibile e gira, ma non la alleniamo** perché i
   tre dataset **non condividono i pazienti**; per allenarla davvero servirebbe una stessa coorte misurata in
   tutte e tre le modalità. Niente multi-output (al massimo una riga: "la testa si può allargare").
6. **XAI sulle reti = solo cenno.** SHAP resta sulla MLP tabellare; per immagini/sequenze si **nominano**
   saliency/occlusion/grad-CAM a parole, senza demo (`kernelshap` su migliaia di pixel non è leggibile).
7. **Teoria minima** (regola "spiega ciò che proponi", [[workshop-explain-all-theory]]): quasi tutto è
   **richiamo** all'overview; da spiegare da zero (minimo) solo due cose — vedi §2.
8. **Confronto fra reti.** Si confronta solo *sullo stesso dato/paziente*. CNN-su-immagini e RNN-su-sequenze
   **non** sono confrontabili tra loro; il fused sarebbe il modo di combinare modalità sullo stesso paziente,
   ma qui la coorte unica manca → lo si dice. La metrica `yardstick` si calcola comunque a mano sulle
   predizioni di una rete (stesso metro anche fuori dalla pipeline).

---

## 2. Prerequisiti di teoria (cosa è richiamo, cosa è da zero)

La teoria concettuale è già nell'overview → in sez.02 diventa **"recall ch. N" + lo strato computazionale**
(come si scrive e si allena davvero).

| concetto | dov'è già | in sez.02 |
|---|---|---|
| neurone = logistica generalizzata, forward pass, conteggio pesi | ch.5 Deep Learning | richiamo |
| passo di gradient descent | ch.5 | richiamo |
| convoluzione, weight-sharing (FC vs conv) | ch.6 Unstructured data | richiamo |
| RNN su sequenze, conteggio pesi RNN | ch.6 | richiamo |
| overfitting (curva train/val) | ch.4 Model selection | richiamo |
| **loss differenziabile vs metriche** | — | **da zero (minimo)** |
| **loop di training reso concreto** (epoca/batch, cosa fa `luz`, la U vista su dati veri) | — | **da zero (minimo)** |

---

## 3. Spina della sezione (beat per beat)

Legenda: **[T]** teoria minima · **[C]** codice live · **[Q]** your-turn/MCQ · **[D]** demo.

1. **Apertura · ponte tabellare** **[C][Q]** — *(tieni, sfrondato)*. MLP `brulee` live (≤30 ep, secondi) in
   tidymodels; MCQ overfit-knob → poi la stessa riga SHAP della sez.01 (model-agnostic). Messaggio: "il DL sta
   ancora in tidymodels". Sweep registro su queste slide (em-dash, `knob`→`setting`).
2. **Teoria · loss vs metriche** **[T]** — *(nuovo)*. Si ottimizza cross-entropy (differenziabile, richiamo
   passo-di-gradiente ch.5) ma si **riporta** accuracy/AUC; l'accuracy non può fare da loss perché è non
   differenziabile (gradiente nullo quasi ovunque, niente da seguire). Formula: $\mathcal{L}_{\text{CE}} =
   -\sum_k y_k \log \hat p_k$; metrica = conteggio a soglia.
3. **Teoria · il loop reso concreto** **[T]** — *(nuovo)*. epoca/batch; forward → loss → backward → step
   (richiamo ch.5); cosa fa `luz` sotto (il loop che chiama `forward()` epoca dopo epoca); la **curva
   train/val** e la **U** (richiamo overfit ch.4). Così `forward()` non è magia.
4. **Il confine** **[T]** — *(nuovo)*. `brulee`/tidymodels copre poche architetture standard e finisce qui;
   per CNN/RNN/fused si scende a `torch`+`luz` puri (niente `workflow_set`/`tune`); `yardstick` però segna le
   predizioni da entrambi i lati.
5. **CNN 2D reale** **[T][C]** — richiamo ch.6 (conv/weight-sharing) + `nn_conv2d` → mostro il fetch
   PneumoniaMNIST (guardato) → carico il tensore committato → costruisco la CNN → **train live + curve
   train/val (la U)** → predict → eval (`yardstick` sulle predizioni: ROC-AUC su held-out immagini).
6. **RNN reale** **[T][C]** — richiamo ch.6 (RNN/sequenze) + `nn_lstm`/indicizzazione dell'ultimo step →
   carico le sequenze vitali committate → costruisco → **train live + curve** → predict → eval.
7. **Fused · demo architetturale** **[D][Q]** — riuso i tre tensori (tab/img/seq) → rete a 3 rami → `forward()`
   su un esempio → output `[1, 2]`. **Parsons reorder** del `forward()` (il hole esistente, riusato qui).
   Framing onesto "costruibile, non allenata: serve una coorte unica multimodale". Una riga su multi-output.
8. **XAI sulle reti** **[T]** — *(nuovo, cenno)*. SHAP sta sulla MLP; per immagini/sequenze gli strumenti
   sono saliency/occlusion/grad-CAM (nominati, niente demo). Una slide.
9. **GPU-vs-CPU** **[T]** — *(nota onesta, sfrondata)*. Il training CPU reale è lento (lo si è appena visto
   dal vivo) → ecco perché la macchina d'aula ha CUDA. Niente teatro "kill the epoch", niente curva finta.
10. **Go-to-code** **[C]** — apri `steps/02-deep-learning/`: MLP+SHAP, CNN e RNN allenate dal vivo, fused
    costruita. Nota sul confronto (single-split, non confrontabile con la CV di Basic).

---

## 4. Modifiche al deck (slide-by-slide)

File: `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`, sezione `#sec-02-deep-learning` (L368–617).

**Taglia.**

- `## The honesty rule — one labeled exception` (L532) — l'eccezione non esiste più: nessun pre-cotto.
- `## Your turn — does the loss curve break the honesty rule?` (L560) — MCQ sulla curva finta, decade.
- `## The answer — A: one labeled exception` (L575) — reveal del MCQ, decade.
- La loss curve `optionB_loss` inventata (`beat.R` L26–34) e l'`if (FALSE)` luz write-only (L37–42).

**Riscrivi.**

- `## CNN / RNN / fused — written, not trained` (L469) → diventa la sequenza beat 5–7 (teoria-richiamo +
   train reale per CNN e RNN, demo per fused). Sparisce il framing "written, not trained".
- `## GPU payoff …` (L588) → sfrondata a una nota onesta (beat 9), senza "kill the epoch / option B".
- `## Go to code` (L605) → aggiorna (via "write don't train" e "one labeled exception").
- Divider `# Step 02 · Deep learning` + "Why this step" (L368–384) → aggiorna il why (train reale, confine,
   setup targets) e l'HTML-comment di sintesi.

**Tieni (con sweep registro: em-dash→`:`/`;`, `knob`→`setting`, niente honesty-vocab).**

- `## MLP hyperparameters …` (L387), `## Your turn — … which knob?` (L411, retitle), `## The answer — A:
   penalty ↑ …` (L427), `## Your turn — the same explainer …` (L440), `## My turn — model-agnostic …` (L456),
   `## Your turn — reorder the fused forward()` (L492) + `## The answer — branches first …` (L512) (questi
   due migrano al beat 7 fused-demo).

**Aggiungi.** Slide per i beat 2, 3, 4, 5 (teoria CNN + train+curva), 6 (teoria RNN + train+curva), 8.
Ogni tecnica nuova ha la sua slide di teoria minima con richiamo al capitolo overview pertinente.

---

## 5. Modifiche al codice authoring

Dir: `workshops/mlt-r-advanced/_authoring/02-deep-learning/`.

**`R/nn-modules.R`** (carry, già esistente).

- Aggiungi un `cnn2d_net` (`nn_conv2d` → ReLU → pool → flatten → linear → 2 logit) per le immagini 28×28.
- Tieni `rnn_branch`/`fused_net`; il `cnn_branch` 1D può restare come ramo del fused (segnale) o essere
   sostituito dal 2D nel ramo immagini del fused — da decidere nel piano (coerenza tensori del fused).

**`beat.R`.**

- Rimuovi la loss curve finta e l'`if (FALSE)`.
- Aggiungi: caricamento tensori committati; costruzione + **training reale via `luz`** della CNN 2D e della
   RNN (`luz::setup(loss, optimizer) |> fit(epochs=…, valid_data=…)`), con raccolta della **storia
   train/val** e plot della curva (ggplot, `geom_line` su train e valid); `predict` + `yardstick::roc_auc`
   su held-out. Per il fused: costruzione + `forward()` shape-check (riusa il Parsons hole).
- Il **codice di fetch** dei dataset entra come blocco *mostrato ma guardato* (commento/`if (FALSE)` o
   `#| eval: false` lato deck) con accanto il `here("data-raw", ...)` che carica il committato.

**`meta.yml`.**

- `title`: via "honestly" (es. `"Step 02 — Deep learning: train real nets"`); `packages`: aggiungi
   `torchvision` (immagini) se non già ereditato; `summary`: riscrivi (train reale CNN+RNN, fused demo);
   `check.kw`: aggiorna (`nn_conv2d`, `luz`, `roc_auc`, `fused_net`); `check.imgs`: alza al numero di curve
   prodotte (≥ 2: curva CNN, curva RNN).

**`data-raw/`** (workshop-level, copiato in ogni step).

- Aggiungi i tensori committati: es. `pneumoniamnist.rds`, `vitals_seq.rds`. Prep a authoring-time via uno
   script `dev/` (download `.npz`/sorgente → tensore → `saveRDS`), **non** eseguito nel build.

---

## 6. Build, parity e riproducibilità

- Il parity-gate (`dev/mltbuild/parity.R`) **esegue lo step dal vivo**: CNN+RNN si allenano a ogni build su
   CPU. Tenere il setup **piccolo ma reale** (dataset ridotti, rete modesta, abbastanza epoche da *vedere* la
   U): target indicativo ~30–90 s per rete. Misurare nel piano e, se serve, ridurre dataset/epoche.
- La **U** richiede di forzare un po' l'overfit (dataset piccolo + capacità adeguata + epoche sufficienti):
   è un setup didattico voluto, da tarare.
- Idempotenza: `set.seed(123)` come da stile; il caricamento è da tensore committato (niente rete nel gate).
- `renv`: torch/luz/coro/torchvision/brulee/kernelshap/shapviz già nel lock. Allineare `requirements.R`
   elencando esplicitamente `torchvision` (oggi assente dall'elenco pur essendo pinnato).
- Rebuild: `& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" dev/mltbuild/rebuild.R mlt-r-advanced`
   (R 4.6.0 obbligatorio), poi `python scripts/build_site.py` per i partial + deck + soluzioni.

---

## 7. Registro e linter

- Sweep `check_register.py` sulle slide sez.02 e su `meta.yml`/`beat.R`: em-dash → `:`/`;`, `knob`→`setting`,
   **vocabolario honesty rimosso** (titolo, "honesty rule", "Deep learning, honestly") — decisione già presa
   ([[honesty-vocabulary-sweep]]).
- A fine sezione: `python scripts/check_register.py` sui file toccati → 0 hit (triage dei falsi positivi).

---

## 8. Fuori scope / rimandato

- `_authoring/04-targets/report.qmd` dice ancora "reloaded" → si allinea quando si arriva alla sez.04.
- Verifica **globale** di registro (overview + Basic + Advanced) col linter: a fine workshop, dopo averlo
   servito ([[w2-w3-roadmap-and-deck-constraints]]).
- Eventuale demo reale di occlusion/saliency: esclusa (scelta "solo cenno").
- Multi-output sul fused: escluso (una riga di menzione al massimo).

---

## 9. Rischi

- **Sorgente PneumoniaMNIST.** Nessun loader R nativo (`.npz`). Mitigazione: conversione a authoring-time in
   `.rds` committato; fallback `torchvision::mnist_dataset`.
- **Tempo di build.** Tre training (anche se due reali) allungano il gate. Mitigazione: dataset/epoche
   minimi-ma-sufficienti; misurare e tarare nel piano.
- **U-shape non visibile.** Se la rete generalizza troppo bene non si vede l'overfit. Mitigazione: ridurre il
   dataset / aumentare capacità / epoche, come setup didattico dichiarato.
- **Coerenza tensori del fused.** I tre rami devono accettare le shape dei tre tensori riusati; allineare
   `nn-modules.R` di conseguenza (1D vs 2D nel ramo immagini).

---

## 10. Processo per-sezione (riuso 00/01)

Checklist: (a) spec → (b) piano → (c) implementazione subagent-driven con review spec+qualità → (d) rebuild
R 4.6.0 + `build_site.py` → (e) **verifica visiva** delle slide nuove (chrome-devtools): math, curve, niente
overflow → (f) `check_register.py` = 0 hit → (g) test `pytest` verdi → (h) commit atomici (un cambiamento
logico per commit) → (i) vault + memorie → (j) `finishing-a-development-branch`.

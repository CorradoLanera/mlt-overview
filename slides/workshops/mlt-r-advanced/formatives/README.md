# Formative — workshop Advanced (nota docente)

> **Nota (2026-06-03):** il *contenuto* di queste formative ora vive **inline nel deck unico**
> (`../00-advanced-deck.qmd`) come coppie di slide **Engage → Reveal**, integrate al loro punto
> dell'arco per-step (intro→teoria→formative→go-to-code). Questo file resta la **mappa**
> formativa→step→minuto→nodo (e il razionale dei distrattori). Gli HTML standalone delle
> formative sono stati ritirati come deliverable.

Le 11 formative del workshop **mlt-r-advanced**, una ogni ~10–15 min (metodo
*Teaching Tech Together*: check che fanno emergere i misconcetti dal vivo). Le MCQ
hanno **distrattori diagnostici** — ogni risposta sbagliata rivela un misconcetto
specifico da ri-spiegare. Testo rivolto agli studenti in **inglese**; queste note di
mappatura in **italiano**.

Ogni file è una formativa singola, nominata per **minuto + tipo**. La colonna "nodo"
rimanda al concept graph dello spec (§11.2) — vedi `../concept-graph.mmd`.

## Mappa formativa → minuto agenda → nodo concept-graph

| file | dopo step | min | tipo | nodo concept-graph | cosa verifica |
|---|---|---|---|---|---|
| `min-10-live-check.md` | 00 | 10 | live-check | `BASIC` / `PRED` / `WARM` | modello Basic ricaricato + `predict` 1 riga (no retrain) + `torch_tensor(1)` senza download (torch pre-caldo). GREEN/RED |
| `min-24-mcq-vimp.md` | 01 | 24 | MCQ | `VIMP` | VIMP = *reliance* del modello, non causazione né coefficiente con segno né p-value |
| `min-38-predict-shap-coef.md` | 01 | 38 | predict-output | `SHAP` / `ANCHOR` / `COEF` | SHAP su ancora logistica: forma attesa (segni e ordine concordano con i coefficienti) + ragione del sanity check prima di puntare la RF |
| `min-46-mcq-shap.md` | 01 | 46 | MCQ | `PARAMS_I` | knob kernelshap: dimensione `bg_X` + sforzo di campionamento = trade-off varianza-vs-costo |
| `min-60-mcq-mlp.md` | 02 | 60 | MCQ | `PARAMS_DL` / `BV` | MLP overfit → quale knob: `penalty`↑ / `hidden_units`↓; non più epoche, non learning-rate, non activation |
| `min-66-yourturn-shap-nn.md` | 02 | 66 | your-turn | `MLP` / `SHAP` / `HONESTY` | SHAP-callback sull'MLP con la **stessa riga** del blocco 01 (agnosticismo); stretch: perché lo stesso explainer vale su logistic/RF/NN |
| `min-80-parsons-fused.md` | 02 | 80 | Parsons | `FUSED` / `CNN` / `RNN` | riordina il `forward()` della rete fusa (3 branch → `torch_cat(dim=2)` → head); dimensione input head e output shape `[B, 2]` |
| `min-92-mcq-honesty.md` | 02 | 92 | MCQ | `HONESTY` / `OPTB` | honesty rule: unica eccezione = loss-curve etichettata; la CPU killata ERA live; distinzione da pre-cotto-finto e da cache targets |
| `min-112-predict-ellmer.md` | 03 | 112 | predict-output | `SCHEMA` / `ELLMER` | struttura record `type_object` (4 campi, tipi R); cosa restituisce l'enum se il campo è assente; sottigliezza integer/double per valori JSON interi |
| `min-124-mcq-temperature.md` | 03 | 124 | MCQ | `LLMPAR` / `BATCH` | temperature bassa = determinismo (ETL riproducibile) + `purrr::map` = iterazione elemento-per-elemento; non qualità, non GPU, non irrilevante con schema |
| `min-138-predict-capstone.md` | 04 | 138 | predict-output | `TARGETS` / `DAG` / `SKIP` | 2° `tar_make` = "skip" ovunque + ragione (hash degli input invariati = riproducibilità, non cache trick); stretch: quali target vanno stale al cambio dei parametri SHAP; perché il device GPU è input cieco al DAG |

## Ruolo nel design (load check §11.4)

Le 11 formative sono la **difesa strutturale primaria** contro il sovraccarico
cognitivo (28 nodi, 5 blocchi). Ogni reset svuota un *chunk* prima che il
successivo arrivi in working memory.

**Hotspot = blocco 02 (67 min, 9 chunk lordi):** concentra 4 delle 11 formative
(min 60, 66, 80, 92) per decomprimere il carico prima del break. Lo split
**scrivi-non-addestra** (CNN/RNN/fusa = Parsons, non train) collassa 3 nodi in uno
schema unificato ("modulo cablato da `forward()`"), riducendo il carico effettivo.

**Write-not-train collapse:** le architetture CNN/RNN/fusa e il batch `ellmer` sono
*scritti e letti*, mai addestrati live (eccetto l'MLP). Questo elimina il carico
d'attesa e di debugging, trasformando 5 chunk tecnici in 1 schema riconoscibile.

**Break dopo il blocco 02** — all'uscita dell'hotspot — è strutturale: senza break
a questo punto, il blocco 03 (`ellmer`) arriva con la working memory già satura.

**Distribuzione duale** (cfr. spec §7): in presenza via pad/alzata di mano;
da remoto via poll-doc. "Your turn" = compito + `{countdown}` → "My turn" = live-solve.

Vedi spec §11.2 (concept graph) e §11.3 (formative map) in
`dev-docs/superpowers/specs/2026-05-30-mlt-r-workshops-design.md`.

# Formative — workshop Basic (nota docente)

Le 10 formative del workshop **mlt-r-basic**, una ogni ~10–15 min (metodo
*Teaching Tech Together*: check che fanno emergere i misconcetti dal vivo). Le MCQ
hanno **distrattori diagnostici** — ogni risposta sbagliata rivela un misconcetto
specifico da ri-spiegare. Testo rivolto agli studenti in **inglese**; queste note di
mappatura in **italiano**.

Ogni file è una formativa singola, nominata per **minuto + tipo**. La colonna "nodo"
rimanda al concept graph dello spec (§10.2) — vedi `../concept-graph.mmd`.

## Mappa formativa → minuto agenda → nodo concept-graph

| file | dopo step | min | tipo | nodo concept-graph | cosa verifica |
|---|---|---|---|---|---|
| `min-09-live-check.md` | 00 | 9 | live-check | `PROJ` | ambiente sano: `.Rproj` aperto, `renv::status()` in sync, `here::here()` = root (GREEN/RED) |
| `min-30-yourturn-wrangle.md` | 01 | 30 | your-turn | `IMPORT` | `clean_names → select(7 col) → filter(NA age) → glimpse`; stretch: `high_risk` da mediana su train (leakage) |
| `min-31-mcq-pipe.md` | 01 | 31 | MCQ | `IMPORT` | semantica pipe/verbi: il tibble passa come 1° arg, ritorna copia nuova |
| `min-50-mcq-metric.md` | 02 | 50 | MCQ | `METRIC` (motivato da `OUT`) | perché ROC-AUC > accuracy: 13% eventi, "predici no" = 87% ma inutile |
| `min-72-yourturn-glm.md` | 03 | 72 | your-turn | `WF` / `GLM` / `METRIC` | `glm` vs workflow danno la stessa AUC; stretch: cosa compra recipe+workflow |
| `min-88-mcq-engine-swap.md` | 03 | 88 | MCQ | `ENGINE` / `MODEL` | engine-swap idiom (pre-break): cambia solo il model-spec |
| `min-118-mcq-knn.md` | 04 | 118 | MCQ | `PARAM` → `BV` | parametri → bias/variance (kNN `k`): k piccolo low-bias/high-var |
| `min-150-yourturn-culminating.md` | 04 | 150 | your-turn | `WFSET`→`TUNE`→`CV`→`COMPARE`→`BEST`→`LASTFIT`→`OPT` | **il culminating task** (§10.1); stretch: 5° engine + quando rank-by-mean inganna |
| `min-165-predict-output.md` | 04 | 165 | predict-output | `OPT` / `CV` / `LASTFIT` | ordinare 3 AUC (resubstitution ≥ CV ≳ test) prima del reveal |
| `min-175-mcq-repro.md` | 05 | 175 | MCQ | `REPORT` / `PROJ` | riproducibilità: `renv` + `here` + `set.seed` + report cache-ato |

## Ruolo nel design (load check, §10.4)

Le 10 formative sono la **valvola di sicurezza** del carico cognitivo: svuotano e
verificano un *chunk* prima di passare al successivo. Cadono attorno ai due picchi —
**step 03** (profondità: 7 oggetti dell'object-map) e **step 04** (ampiezza: 10
nodi), back-to-back con break in mezzo. Le MCQ con distrattori diagnostici servono a
far emergere il misconcetto *prima* che diventi un errore nel culminating task.

Distribuzione duale (cfr. spec §7): in presenza via pad/alzata di mano; da remoto via
poll-doc. "Your turn" = compito + `{countdown}` → "My turn" = live-solve.

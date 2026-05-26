# Sorgente — moduli opzionali "minabili" da index-full.Rmd

> Nota di lavoro (IT). Confronto strutturale `index.Rmd` (base, 124 slide) vs `index-full.Rmd` (148 slide), 2026-05-26.
> Le slide presenti solo in `index-full` sono approfondimenti tagliati dalla versione insegnata: candidati
> a diventare **moduli opzionali** (`include: false` nel manifest) da riattivare quando c'è tempo.

## Contenuti extra in index-full.Rmd (non in index.Rmd)

Raggruppati per capitolo del manifest a cui afferiscono:

- **03-algorithm-examples** — `Linear classifiers` (slide dedicata più estesa).
- **04-model-selection** — `Leave-one-out cross-validation` (variante CV oltre alla K-fold).
- **05-deep-learning** — `Fully connected network` (slide dedicata), `ML: optimized neurons' network`.
- **07-llm-transformers** — `Transformers` (intro estesa), `Multi-head self-attention`, `Embeddings & positional encoding`, `Let's see it ... with Attention!` (walk-through), `Chat GPT: Generative`, `Generators` / `Generators: potential usages`.
- **01-introduction** — `Learning: are cars "learning"?!` (esempio-hook aggiuntivo).

## Uso

In Fase A, per i capitoli sopra, valutare se aggiungere **sotto-unità opzionali** (`mlt-subunits`) o slide extra
marcando i relativi moduli `include: false` nel manifest, così restano fuori dai 240' di default ma riattivabili.
Recuperare il testo/le immagini direttamente da `index-full.Rmd` (la sintassi xaringan andrà migrata in Fase B).

## Metodo

`diff` delle intestazioni `^#{1,3}` dei due file. La lista è indicativa (markup `.orange[...]` da ripulire);
verificare slide per slide al momento del recupero.

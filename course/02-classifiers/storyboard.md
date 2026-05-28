# 02 — Classifiers · storyboard (6 frames)

> Visual plan for the chapter, built from its [arc](narrative.md) and [objectives](objectives.md). 20 min, dual classroom (in-person + remote). On-screen text in **English** (≤ 1 sentence/frame, 3-second readable); regia/voce docente in *italiano*. Feeds `mlt-quarto-build`.

> 🎨 La colonna **Visual** è la descrizione sintetica (per noi). I **prompt pronti per un generatore di immagini** — con lo stesso *style-anchor* condiviso del cap. 01, per coerenza di serie tra capitoli — stanno nella sezione **`## Prompt visivi`** in fondo.

| # | Funzione | Visual | Testo a video | Voce docente |
|---|---|---|---|---|
| 1 | Hook visivo | A scatter of patient dots in two colours; a single straight line slashes across it; a clinician's silhouette glances at it. | *"It decides with a single line."* | Elena chiede *come* decide il modello: la risposta è una sola linea sullo scatter dei pazienti, un lato *high-risk*. |
| 2 | Contesto (class vs regr) | Split panel: LEFT a scatter split into two coloured regions (classification); RIGHT the same dots with a trend line running *through* them (regression). | *"Two outputs: a label, or a number."* | Output discreto = **classificazione** (un'etichetta); output continuo = **regressione** (un numero). Questo capitolo è sul primo. |
| 3 | Sfida / Dati | A scatter where the two coloured clusters **overlap** in the middle; a line is drawn, and a few dots sit clearly on the wrong side, circled. | *"No line catches them all."* | Su pazienti reali le classi si sovrappongono: nessun confine le separa perfettamente, qualcuno resta sempre dal lato sbagliato. |
| 4 | Nodo / Impatto | The plane carved into two coloured **decision regions** by one boundary; every point takes the colour of its region; a label $f:\mathbb{R}^d\to\{1,\ldots,K\}$. | *"A classifier splits the space into regions."* | Formalmente il classificatore è una funzione $f:\mathbb{R}^d \to \{1,\ldots,K\}$ che taglia lo spazio in regioni: **il confine È il classificatore**. |
| 5 | Metodo / Soluzione | The same scatter + boundary; each misclassified point carries a small "cost" mark; a running total adds them up into one number. | *"Count the cost: risk = total loss."* | Si contano gli errori con la 0/1 loss e si sommano: è il **rischio** $\text{risk}(f)=\mathbb{E}[\mathfrak{L}(f(X),Y)]$. Qui gira l'esercizio "Draw the line, count the cost". |
| 6 | Payoff / Domanda finale | The lowest-risk boundary highlighted with a small "$2/10$" tag; behind it, faint icons of different methods (nearest dots, a straight cut, a little tree). | *"Cheapest mistake found. But who drew it?"* | Si sceglie il confine col rischio più basso (mai $0$ se le classi si sovrappongono); ma chi *trova* quella linea? Lo vediamo coi veri **algoritmi**. |

## Modalità duale — dove si attiva

Il riquadro **5** è il perno attivo: lì parte l'esercizio sommativo "Draw the boundary, count the cost" (vedi [objectives.md](objectives.md)). L'artefatto condiviso è **una sola scatter** su cui presenza e remoto disegnano il proprio confine; un poll raccoglie il rischio $0/10$…$n/10$ di ogni gruppo per il confronto immediato. Riquadri 1–4 espositivi (~10′), riquadro 5 ospita gli ~8′ di sommativo, riquadro 6 chiude e fa ponte (~2′).

## Prompt visivi

Prompt pronti per un generatore di immagini (Images 2.0 o simili). Lo **`style-anchor`** è definito *una volta* e va premesso a ogni prompt come un parametro; i riquadri scrivono solo `style-anchor + <soggetto>`, così tutte le tile (e i capitoli) restano coerenti. Mai testo dentro l'immagine.

**`style-anchor`** = *"Coherent image set, one shared visual identity: warm orange (#E8741E) as the single accent colour on a dark-slate background, soft cinematic lighting, 16:9, crisp and high quality, no text, letters or numbers rendered anywhere in the image."*

- **Riquadro 1 (Hook)**: `style-anchor` + *flat data-viz scatter of two-colour patient dots on a plane, a single straight dividing line slashing across, a faint clinician silhouette looking on.*
- **Riquadro 2 (Contesto)**: `style-anchor` + *split-panel infographic: left, a scatter divided into two solid colour regions; right, the same dots with a smooth trend line passing through them.*
- **Riquadro 3 (Sfida/Dati)**: `style-anchor` + *scatter where two colour clusters overlap in the middle, a straight boundary drawn, a few dots stranded on the wrong side and circled.*
- **Riquadro 4 (Nodo)**: `style-anchor` + *a 2D plane cleanly carved into two coloured decision regions by one curved boundary, each dot taking its region's colour; minimalist.*
- **Riquadro 5 (Metodo)**: `style-anchor` + *the same scatter and boundary, each misclassified dot tagged with a small coin-like cost marker, the markers gathering into a single stacked total.*
- **Riquadro 6 (Payoff)**: `style-anchor` + *one highlighted low-error boundary on the scatter, with three faint method icons behind it — a cluster of nearest dots, a straight cut, a small decision tree.*

## Verifica post-output (auto-check)

- [x] Riquadro 1 aggancia in 3 secondi? — sì: linea che taglia i pazienti + "decides with a single line".
- [x] Riquadro 3 il dato chiave è VISIBILE? — sì: la sovrapposizione delle classi e i punti dal lato sbagliato, non solo nominati.
- [x] Riquadro 4 il nodo è il concetto centrale? — sì: il classificatore come funzione che partiziona lo spazio (Obj. 2).
- [x] Riquadro 6 lascia una domanda-ponte? — sì: "But who drew it?" → algoritmi (cap. 03).
- [x] Solo i 6 riquadri (senza voce) raccontano l'arco? — sì: linea → label-vs-numero → le classi si sovrappongono → il confine è una funzione → conta il costo (rischio) → il confine più economico, ma chi lo trova?

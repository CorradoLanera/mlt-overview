# 01 — What is Machine Learning? · storyboard (6 frames)

> Visual plan for the chapter, built from its [arc](narrative.md) and [objectives](objectives.md). 25 min, dual classroom (in-person + remote). On-screen text in **English** (≤ 1 sentence/frame, 3-second readable); regia/voce docente in *italiano*. Feeds `mlt-quarto-build` (the slides are generated from this storyboard, not migrated from `index.Rmd`).

> 🎨 La colonna **Visual** è la descrizione sintetica (per noi). I **prompt pronti per un generatore di immagini** — con uno *style-anchor* condiviso che tiene coerenti tutte le tile — stanno nella sezione **`## Prompt visivi`** in fondo.

| # | Funzione | Visual | Testo a video | Voce docente |
|---|---|---|---|---|
| 1 | Hook visivo | A clinician at a workstation; a single red "DISCHARGE — high risk" flag glows on screen; the rest of the UI is a featureless dark panel (the black box). | *"The algorithm says discharge. It won't say why."* | Elena fissa un punteggio di rischio che le raccomanda una dimissione di cui dubita — e nessuno sa dirle *perché*. |
| 2 | Contesto (the swap) | Split diagram: LEFT "traditional program" = rules + data → answers; RIGHT "machine learning" = data + answers → rule. Same blocks, arrows reversed. | *"You write the rules. A learner finds them."* | Nel software classico le regole le scrivete voi; nel ML date dati e risposte e la *regola* ($Y \simeq f(X)$) ve la restituisce la macchina. |
| 3 | Sfida / Dati | A huge **95%** filling the frame, with a small caption-sized confusion-grid behind it showing almost every case predicted "negative"; one rare positive missed. | *"95% accurate — and clinically useless."* | Un modello può essere accuratissimo e inutile quando l'esito che vi importa è raro: l'accuracy da sola inganna. |
| 4 | Nodo / Impatto | Three labelled coordinates converging on one box marked "a learner": $T$ (a target/clipboard), $P$ (a gauge), $E$ (a stack of past records). | *"Task · Performance · Experience: that's the whole machine."* | Qualunque learner è descritto da tre coordinate — il compito ($T$), la misura di performance ($P$) e l'esperienza/dati ($E$) da cui ha imparato. |
| 5 | Metodo / Soluzione | One branching question — "Where do the labels come from?" — splitting into four cards: labelled / none / ask-an-expert / reward (supervised · unsupervised · active · reinforcement). | *"Where do the labels come from?"* | È la domanda che smista i quattro tipi di apprendimento: qui gira l'esercizio duale sui 4 scenari clinici. |
| 6 | Payoff / Domanda finale | Back to Elena's screen: the same red flag, but now three sticky notes beside it — "which task? · measured how? · learned from whom?". A thin line is being drawn across a scatter of points (teaser of a classifier). | *"You know what it is. But how does it decide?"* | Ora sapete cos'è e che tipo di apprendimento usa; ma *come* arriva al verdetto? Lo apriamo coi **classificatori**. |

## Modalità duale — dove si attiva

Il riquadro **5** è il perno didattico-attivo: lì parte l'esercizio sommativo "Turn a clinical problem into an ML problem" (banco di 4 scenari, vedi [objectives.md](objectives.md)). L'artefatto condiviso (tabella a 4 righe $T/P/E$ + tipo) resta proiettato sul riquadro 5 per presenza e remoto; il poll Slido sul tipo di apprendimento dà il segnale aggregato dai remoti. Riquadri 1–4 sono espositivi (~14′), riquadro 5 ospita gli 8′ di sommativo, riquadro 6 chiude e fa ponte (~3′).

## Prompt visivi

Prompt pronti per un generatore di immagini (Images 2.0 o simili). Lo **`style-anchor`** è definito *una volta* e va premesso a ogni prompt come fosse un parametro: i prompt dei riquadri scrivono solo `style-anchor + <soggetto>`, così tutte le tile condividono palette, luce e formato e restano coerenti tra loro. Mai testo dentro l'immagine (il testo sta nella colonna "Testo a video").

**`style-anchor`** = *"Coherent image set, one shared visual identity: warm orange (#E8741E) as the single accent colour on a dark-slate background, soft cinematic lighting, 16:9, crisp and high quality, no text, letters or numbers rendered anywhere in the image."*

(Lo style-anchor fissa ciò che deve restare costante tra le tile; ogni riquadro dichiara solo il proprio *medium* — foto vs schema — e il soggetto.)

- **Riquadro 1 (Hook)**: `style-anchor` + *photorealistic over-the-shoulder shot of a clinician facing a hospital monitor in a dim ward; one red alert badge glows on an otherwise blank, matte-black dashboard; tense, uncertain mood; shallow depth of field.*
- **Riquadro 2 (Contesto)**: `style-anchor` + *flat vector schematic: two mirrored flow diagrams side by side, simple blocks and arrows pointing in opposite directions to suggest an input/output swap.*
- **Riquadro 3 (Sfida/Dati)**: `style-anchor` + *bold data-viz poster: one enormous percentage figure dominating the frame, a faint confusion-matrix grid behind it with all the weight in one cell and a single isolated highlighted cell; high-contrast.*
- **Riquadro 4 (Nodo)**: `style-anchor` + *minimalist isometric concept diagram: three distinct icons (a target, a measuring gauge, a stack of records) connected by thin lines into a single central rounded box.*
- **Riquadro 5 (Metodo)**: `style-anchor` + *decision-tree infographic: one top node branching into four equal cards, each with a small distinct pictogram (a tag, a cluster of dots, a raised hand, a trophy).*
- **Riquadro 6 (Payoff)**: `style-anchor` + *photorealistic return to the same clinician's monitor, now with three small paper sticky notes beside the red badge and a faint scatter plot with a straight dividing line being drawn across it; hopeful, resolved mood.*

## Verifica post-output (auto-check)

- [x] Riquadro 1 aggancia in 3 secondi senza spiegazioni? — sì: punteggio rosso + "won't say why".
- [x] Riquadro 3 il dato chiave è VISIBILE? — sì: **95%** gigante + griglia che ne mostra l'inganno (non solo nominato).
- [x] Riquadro 4 il nodo è il concetto centrale? — sì: $T/P/E$ è la definizione operativa che regge tutto il capitolo.
- [x] Riquadro 6 lascia una domanda aperta-ponte? — sì: "how does it decide?" → classifiers (cap. 02).
- [x] Solo i 6 riquadri (senza voce) raccontano l'arco? — sì: box opaco → swap → trappola → 3 coordinate → 4 tipi → "ora so cosa, ma come decide?".

*Nota di regia:* niente riquadro duplica testo e immagine — es. nel riquadro 3 il testo dà il *giudizio* ("clinically useless"), l'immagine dà il *dato* (95% + griglia sbilanciata): collaborano, non si ripetono.

# 02 — Classifiers · narrative

> Chapter narrative, hanging off the course [spine](../_global/spine.md). Student-facing prose in **English**; design glosses in *italiano*. Six-word, 100-word, chapter arc, and an explicit pre-hook to the next chapter (`03-algorithm-examples`).

## Six words

> **Draw the line; count the cost.**

*Glossa:* scelto via `narratore-critico` su 4 varianti. È l'unica che copre *entrambe* le metà del capitolo — il classificatore che **partiziona** lo spazio (Obj. 2) e il **rischio** come costo da contare (Obj. 3) — in due imperativi; il punto e virgola crea l'asimmetria "tracci, poi paghi" che è la tensione della 0/1 loss. Riprende letteralmente il pre-hook del cap. 01 ("traccia una linea") e *estende*, e coincide col titolo dell'esercizio sommativo.

## 100 words (3 acts)

Elena finally saw how the model decided: it placed each patient as a point on a chart of two simple measurements and drew a single line, labelling everyone on one side as high-risk. She tried drawing the line herself. Wherever she put it, a few patients landed on the wrong side — there was no line that caught them all. Each misplaced patient, she realised, was a cost, and the model was judged by the total: its risk. The line was not the truth; it was the cheapest mistake. Now she could see exactly which patients her classifier would get wrong.

*Struttura:* Bing = Elena scopre che il modello decide tracciando una **linea** in uno spazio di due misure, e mette ogni paziente da un lato | Bang = prova a tracciarla lei: ovunque la metta, qualcuno cade dal lato sbagliato — **nessuna linea li prende tutti**; ogni errore è un **costo**, e il modello è giudicato dal totale, il suo **rischio** | Bongo = la linea non è la verità, è "l'errore più economico"; ora vede *quali* pazienti il suo classificatore sbaglierebbe. (100 parole esatte.)

## Chapter arc — Hook → Challenge → Resolution → Payoff

| Punto | Funzione | Contenuto |
|---|---|---|
| **Hook** | aggancio | Elena asks how the model actually *decides*, and finds it draws a single line on a chart of two measurements, putting each patient on one side. |
| **Challenge / Data** | problema concreto | The data are points in a feature space ($\mathbb{R}^d$), and a classifier is a function $f:\mathbb{R}^d \to \{1,\ldots,K\}$ that carves the space into regions — but *which* line? On real patients the classes overlap, so some always land on the wrong side. She needs a way to score one boundary against another. |
| **Resolution** | come si affronta | Count the mistakes with a 0/1 loss; the classifier's **risk** is its expected loss $\text{risk}(f)=\mathbb{E}[\mathfrak{L}(f(X), Y)]$ — its total cost — and the better classifier is the one with lower risk. She also separates **classification** (output is a discrete label) from **regression** (output is a continuous value). |
| **Payoff** | cosa resta | She can read any classifier as a boundary in feature space and judge it by its risk — and she accepts that, when classes overlap, even the best classifier has risk $> 0$. |

### Narrative version (prose)

For the first time Elena could see the decision itself. Her patients were points scattered across a chart — fasting glucose against BMI — and the model was simply a line: everyone on one side called high-risk, everyone on the other side cleared. So she tried to draw a better line. She quickly learned the hard truth of overlapping data: wherever she drew it, a handful of patients sat stubbornly on the wrong side, and no boundary caught them all. To compare her attempts she had to *count* — one unit of cost for every patient on the wrong side. That sum had a name: the classifier's risk, the total she was trying to make small. The line, she understood, was never going to be the truth; it was going to be the cheapest mistake she could find. And a classifier was just that: a function that splits the space, chosen because its risk is low.

## Versione didattica (objectives recap)

Gli obiettivi formali del capitolo vivono in [objectives.md](objectives.md). Il payoff narrativo li ricalca: **distinguere** classification/regression, **rappresentare** il classificatore come funzione che partiziona lo spazio, **applicare** la 0/1 loss e leggere il **rischio** come costo da minimizzare.

## Pre-hook → 03 Algorithm examples

> Elena can now *judge* a boundary by its risk — but she still drew hers by hand. How do real algorithms actually *find* a good line? Some look at the nearest patients, some fit a straight cut, some grow trees and vote. Those are the concrete classifiers — and they are next.

*Glossa:* il pre-hook chiude sul gancio "ok, so giudicare un confine, ma chi lo *trova*?" e introduce gli algoritmi concreti (kNN, lineari, alberi, ensemble) come risposta, ponte diretto al cap. `03-algorithm-examples` (via `manifest.next_enabled`).

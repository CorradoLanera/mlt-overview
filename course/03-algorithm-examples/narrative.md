# 03 — Algorithm examples · narrative

> Chapter narrative, hanging off the course [spine](../_global/spine.md). Student-facing prose in **English**; design glosses in *italiano*. Six-word, 100-word, chapter arc, and an explicit pre-hook to the next chapter (`04-model-selection`).

## Six words

> **Same data; three algorithms, three boundaries.**

*Glossa:* scelto via `narratore-critico` su 4 varianti. Mantiene lo *stesso ritmo a due clausole con punto e virgola* di cap. 01 ("Programs follow rules; learners find them.") e cap. 02 ("Draw the line; count the cost."), trasformando la coerenza tipografica in coerenza di serie. Riprende la parola-chiave **boundary** dal cap. 02 e la fa esplodere in tre — il cuore del capitolo è proprio la **contraddizione apparente** "stessi pazienti, decisioni diverse". E pianta il seme per il cap. 04 ("tre confini, ma quale vince?") senza risolverlo.

## 100 words (3 acts)

For the first time Elena saw not one classifier but three working on the same patients. The k-NN model traced a wiggly boundary that hugged every example. The SVM cut a single clean margin; when the classes interlocked, it warped the space first and cut there. The random forest sliced the plane into small rectangles and let many trees vote on each point. Same data; three different carvings. Each algorithm carried its own prior idea of what a sensible boundary looks like. All three looked reasonable on these twelve patients — but which one would hold on a patient never seen?

*Struttura:* Bing = Elena guarda **tre** algoritmi lavorare sullo stesso banco di pazienti | Bang = ognuno produce una forma di confine drammaticamente diversa — $k$NN si attorciglia attorno ai punti, SVM taglia con un margine pulito (e *piega lo spazio* col kernel quando serve), Random Forest accatasta rettangoli axis-aligned e li fa votare — perché ognuno ha un proprio *prior* su cosa sia un confine sensato | Bongo = sui 12 pazienti del banco tutti sembrano ragionevoli; ma su un paziente mai visto? — cliff-hanger aperto verso il cap. 04. (100 parole esatte.)

## Chapter arc — Hook → Challenge → Resolution → Payoff

| Punto | Funzione | Contenuto |
|---|---|---|
| **Hook** | aggancio | Elena watches three different algorithms tackle the same scatter of patients — and each one draws a strikingly different boundary. |
| **Challenge / Data** | problema concreto | She can now *judge* a boundary by its risk (ch. 02), but not yet how a machine actually *finds* one. The chapter walks through three families: **$k$-Nearest Neighbor** (the training data *is* the classifier — for a new point, look at the closest $k$ examples and take a majority vote); **linear / Support-Vector Machine** ($f(x) = \text{sgn}(w^\top x + b)$ — find the hyperplane with the widest margin between the classes, and when data are not linearly separable, apply a non-linear feature map $\phi:\mathbb{R}^d \to \mathbb{R}^D$ first — the **kernel trick** — and cut *there*); **ensembles / Random Forest** (train many weak tree classifiers on bootstrapped subsets, then combine their predictions by majority vote — the binomial vote tightens around the correct answer as long as each weak learner has accuracy $p > 0.5$). |
| **Resolution** | come si affronta | She learns to read each algorithm by the **shape of regions** it produces in the feature space — *data-defined neighbourhoods* for $k$NN, a *(possibly kernel-warped) max-margin hyperplane* for SVM, an *axis-aligned staircase voted by many trees* for RF — recognising each shape as **what kind of boundary that family is *capable* of producing** in the first place. The kernel trick is reframed operationally: not a new algorithm, but a re-coordinatisation that turns non-linearly-separable data into linearly-separable data without touching the linear classifier. |
| **Payoff** | cosa resta | Looking at a decision boundary alone, she can name the family of algorithm that produced it — and articulate the *prior* each family brings to the same patients. She also accepts that *three* algorithms on the *same* data are *three* legitimate carvings: the choice is not data-determined. |

### Narrative version (prose)

Elena had learned, in the previous chapter, how to score a boundary against another — counting the misclassified patients, paying for each one, calling the total the classifier's risk. But she had drawn the line herself. The natural next question was: *who* draws it, when there is no clinician with a pen? She watched three algorithms answer in turn. The first, $k$-Nearest Neighbor, did the simplest thing imaginable: it kept the training patients themselves and, for any new one, looked at the closest few and copied their label. The boundary it produced was wiggly, hugging every example, defined entirely by the data. The second, the Support-Vector Machine, looked instead for a single straight cut — the *widest* corridor between the two classes — and when the classes refused to be split by a line, it transformed the coordinates first (the famous *kernel trick*: $(y_1, y_2) \mapsto (y_1^2,\ y_2^2,\ \sqrt{2}\,y_1 y_2)$ and similar maps), separating the classes cleanly in the new space and projecting the cut back. The third, the random forest, gave up on any single boundary: it grew many small tree classifiers on bootstrapped slices of the data and let them vote — the majority vote, she saw on the binomial plot, beats any single one as long as each tree is even slightly better than chance ($p > 0.5$). On the same scatter, the three algorithms produced three unmistakable signatures: piecewise around the points; a smooth margin (curved if kernel-warped); axis-aligned rectangles. The data had not chosen any of them. Each algorithm had brought its own *prior* about what a boundary should look like, and that prior, more than the data, decided what she saw.

## Versione didattica (objectives recap)

Gli obiettivi formali del capitolo vivono in [objectives.md](objectives.md). In sintesi, il payoff narrativo li ricalca: **compare** le tre famiglie per *forma del confine che ciascuna può produrre* ($k$NN piecewise / SVM max-margin / RF vote-of-cuts); **explain** il kernel trick come feature map che cambia ciò che il classificatore vede senza cambiare il classificatore; **predict** la direzione di cambiamento del voto di maggioranza di $m$ classificatori deboli con accuratezza $p$, e il *perché* funzioni solo se $p > 0.5$.

## Pre-hook → 04 Model selection & validation

> Three algorithms, three different boundaries on the same twelve patients — and Elena has no way yet to tell *which* of them will hold up on a patient she has never seen. The $k$-NN boundary, in particular, hugs the training data so tightly that it never misclassifies a single example on the banco — and that very perfection, she will discover next, is exactly what dooms it on new patients. **Model selection** — the trick of separating *good fits* from *fakes* — comes next.

*Glossa:* il pre-hook regge sul cliff-hanger "tre confini ragionevoli, ma quale tiene fuori dal banco?" e nomina esplicitamente il **paradosso dell'iperaderenza** ($k$NN/$k=1$ ha errore zero sul training, ma è proprio quello a fregarlo): è il gancio operativo dell'**overfitting** (cap. 04). Ponte diretto a `04-model-selection` (via `manifest.next_enabled`). La parola "fake" è deliberata: anticipa il vocabolario clinico di "modello che sembra valido ma non lo è" che il cap. 04 svilupperà con train/validation/test e cross-validation.

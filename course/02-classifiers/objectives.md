# 02 — Classifiers · Learning objectives & summative exercise

> Chapter: **Classifiers** · 20 min · biomedical/clinical graduate students (UBEP).
> Student-facing text in English; teacher design notes (*nota docente*) in Italian.

## Learning objectives

By the end of this chapter, students can:

1. **Distinguish** a classification task from a regression task by the type of output it produces — a discrete class label vs a continuous value — and identify which one a given clinical task requires.
2. **Represent** a classifier geometrically as a function $f:\mathbb{R}^d \to \{1,\ldots,K\}$ that partitions the feature space into decision regions (one region per class).
3. **Apply** the 0/1 loss to a classifier's predictions and interpret its **risk** as the expected loss $\text{risk}(f) = \mathbb{E}[\mathfrak{L}(f(X), Y)]$ — the quantity that training seeks to minimise.

*Nota docente:* tre obiettivi per 20′. La sottigliezza notazionale del capitolo ("a classifier is a single model and cannot itself be *trained* — it is the ML process that produces new models replacing the previous ones") resta **voce docente**, non valutata: è un caveat di rigore, non una performance osservabile. L'arco aggancia il pre-hook del cap. 01 (la retta tracciata sui punti).

## Summative live exercise — "Draw the boundary, count the cost"

*Nota docente:* sommativo, gira negli **ultimi ~8′** (min 12–20), dopo aver visto spazio delle feature, classificatore-come-funzione e loss/rischio. Banco: **una scatter 2D di ~10 pazienti** su due misure cliniche (es. $x$ = fasting glucose, $y$ = BMI), ognuno marcato in **due classi** (es. *high-risk* / *low-risk*), scelti **volutamente non perfettamente separabili** (così il rischio minimo è > 0 e c'è un trade-off reale).

| Field | Content |
|---|---|
| Objective verified | Obj. 2 (classifier as a region-carving function), Obj. 3 (0/1 loss + risk), Obj. 1 (classification vs regression). |
| In-person action | Table groups get a printed 2D scatter of ~10 patients ($x$ = fasting glucose, $y$ = BMI), each marked as one of two classes. They: (i) **draw a single decision boundary** that splits the plane into two regions, one per class; (ii) **count** how many points fall on the wrong side → its **0/1 risk on this sample** $=\dfrac{\#\text{misclassified}}{\#\text{total}}$ (the average 0/1 loss over the patients); (iii) they are also handed a *twin* task on the same patients — "predict each patient's **HbA1c value**" — and must say which of the two tasks (the *class label* or the *HbA1c value*) this scatter represents, which is **classification** and which is **regression**, and why. |
| Remote equivalent | The same scatter on a shared slide / whiteboard with a drawing tool; remote groups draw their boundary on it — or, if the drawing channel is awkward, **describe it in words** (e.g. "vertical line at glucose = 110") — and type their misclassified count and their classification-vs-regression answer into their row of the shared doc. |
| Shared artifact | One shared board showing the scatter, on which **every group's boundary and its 0/1 risk on the sample** (e.g. $2/10$) are posted side by side — the whole class compares boundaries and risks at once. |
| Timing | 8 min, minutes 12–20 (end of chapter): ~2′ read & assign, ~4′ draw + count + task choice, ~2′ compare boundaries and risks. |
| Success criterion | Each group produces: (i) a boundary that is a **valid partition** — every point of the plane is assigned to exactly one class (a function: no gaps, no overlaps); (ii) a **correct misclassified count**, giving its 0/1 risk on the sample as a fraction; (iii) it picks the **class-label** task as the one shown on the scatter and labels it **classification** (discrete label), and the HbA1c task **regression** (continuous value), with the reason. **Live signal of mastery:** groups can rank their boundaries by their 0/1 risk on the sample and state that the lower-risk boundary is the better classifier — while noticing that, since the points are not perfectly separable, **no** boundary reaches risk $0$. |

*Nota docente — perché duale funziona qui:* l'unica **scatter condivisa** è l'artefatto comune; confrontare più confini *sullo stesso piano* rende visibile dal vivo che "minimizzare il rischio" è il criterio (Obj. 3) e che **il confine È il classificatore** (Obj. 2). Un poll raccoglie il rischio 0/1 sul banco di ciascun gruppo (un numero, es. $2/10$) per un confronto immediato anche dai remoti — **rendilo obbligatorio se i gruppi sono più di 4**, altrimenti i 2′ di confronto non bastano. Se i gruppi sono pochi, assegna a metà classe il vincolo "boundary rettilineo" e all'altra metà "boundary libero": il confronto mostra che una forma più flessibile abbassa il rischio *su questo banco* — ma **tieni aperta la domanda "vale anche su pazienti nuovi?"** (non concludere che il confine libero sia il migliore): è il gancio che riapriremo al cap. 04 (overfitting).

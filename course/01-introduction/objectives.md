# 01 — What is Machine Learning? · Learning objectives & summative exercise

> Chapter: **What is Machine Learning?** · 25 min · biomedical/clinical graduate students (UBEP).
> Student-facing text in English; teacher design notes (*nota docente*) in Italian.

## Learning objectives

By the end of this chapter, students can:

1. **Frame** an applied (clinical) problem as a machine-learning problem by specifying its Task ($T$), Performance measure ($P$), and Experience ($E$), following Mitchell's definition.
2. **Contrast** machine learning with traditional programming, stating for each what is provided as input and what is produced as output (in ML the algorithm is the *output*, learned from $\text{training data}$, modelling $Y \simeq f(X)$).
3. **Classify** a described scenario into the correct learning paradigm — *unsupervised*, *supervised*, *active*, or *reinforcement* — and justify the choice from the kind and availability of supervision/labels.

*Nota docente:* tre obiettivi (non quattro) per stare nei 25′ lasciando spazio a un sommativo vero. I "Basic components" (training/validation/test, modello, loss) restano contenuto espositivo, agganciato dentro l'obiettivo 1 (la $E$) ma non valutato qui: diventeranno oggetto di verifica nel cap. 04 (model selection).

## Summative live exercise — "Turn a clinical problem into an ML problem"

*Nota docente:* sommativo, non riscaldamento — gira negli **ultimi 8′** del capitolo (min 17–25), dopo aver visto T/P/E, ML-vs-tradizionale e i tipi di apprendimento. Si lavora su un **banco di 4 mini-scenari clinici**, uno per gruppo/breakout, scelti perché ciascuno ricade in un *paradigma diverso* — così l'obiettivo 3 è davvero discriminante e non collassa su "supervised" per tutti.

**Scenario bank** (distribute one per group):

- **A — 30-day readmission.** A hospital wants to flag at discharge which inpatients will be re-admitted within 30 days, from routinely collected EHR data. *(→ supervised classification; labels = readmitted yes/no.)*
- **B — Patient phenotypes.** From lab panels of diabetic patients, find data-driven subgroups with no predefined diagnosis labels. *(→ unsupervised clustering.)*
- **C — Adaptive insulin dosing.** A controller adjusts each insulin dose from the patient's glucose response over time, to keep glucose in range. *(→ reinforcement learning; reward = time-in-range.)*
- **D — Disease coding from free text.** A model classifies EHR notes by reported disease and asks a clinician to label only the cases it is most uncertain about. *(→ active learning; oracle = clinician.)*

| Field | Content |
|---|---|
| Objective verified | Obj. 1 ($T/P/E$), Obj. 2 (ML vs traditional), Obj. 3 (learning paradigm) — all three, per scenario. |
| In-person action | Table groups each draw one scenario **card**. On a shared **T/P/E poster** they write: (i) $T$, $P$, $E$ in three cells — $P$ must be a *quantitative* measure (e.g. accuracy, error rate, time-in-range), not a vague word; (ii) circle the learning type; (iii) complete the fixed-form sentence "*in traditional programming the input would have been … (hand-written rules); with ML the output is … (the model/rule), learned from …*" — the blanks force them to name input and output. A group member **photographs the poster as soon as a cell is filled** (not at the end) and drops it into the shared doc. Posters go on the board. |
| Remote equivalent | Each breakout room gets the same scenario on a slide and types the identical three fields into its row of a shared doc; the learning-type choice is also cast in a Slido/poll (4 options) so it is visible live. |
| Shared artifact | One shared **whiteboard/Google Doc** with a 4-row table (one row per scenario, $T$ / $P$ / $E$ / learning type / ML-vs-traditional) visible to in-person *and* remote at once: remote groups type directly, in-person posters are photographed and dropped in. |
| Timing | 8 min, minutes 17–25 (end of chapter): ~2′ read & assign, ~4′ group fill (poster photos uploaded *during* this phase so the doc is already populated), ~2′ instructor-led reveal. The reveal **spotlights the two counter-intuitive rows — C (reinforcement) and D (active)** — while A and B (canonical supervised/unsupervised) self-correct via the Slido poll without oral discussion. |
| Success criterion | For each scenario the class produces: (i) a $T/P/E$ triple where $P$ is a quantitative measure appropriate to $T$; (ii) the **correct** learning-type label with a justification that cites label availability / kind of supervision; (iii) a sentence that names the **input/output swap** — *traditional: hand-written rules are the input; ML: the model/rule is the output, learned from data* ($Y \simeq f(X)$). **Live signal of mastery:** ≥ 3 of the 4 rows correct on first pass, and any mis-labelled paradigm is corrected by the group during the reveal when challenged ("where do the labels come from?"). |

*Nota docente — perché duale funziona qui:* l'artefatto condiviso è **uno solo** (la tabella a 4 righe), quindi remoto e in presenza convergono sullo stesso oggetto invece di lavorare in canali separati; il poll Slido sul tipo di apprendimento dà al docente un segnale *aggregato e immediato* (objective 3) anche dai remoti, che altrimenti resterebbero muti. Se la classe è piccola (< 4 gruppi) assegna A, B, C e tieni D come scenario di reveal fatto insieme.

*Nota docente — reveal scenario C (reinforcement):* in RL l'$E$ **non** è un dataset di training etichettato ma lo *stream* di interazioni $\text{stato} \to \text{dose} \to \text{risposta}$. Accetta come corretta la cella $E$ se lo studente nomina l'interazione/feedback sequenziale con l'ambiente; non pretendere un "training set" statico, e non marcarlo "wrong" se manca. Il framing T/P/E regge (T = glucosio in range, P = time-in-range, E = sequenza di interazioni), ma è il caso più sottile: anticipa l'obiezione invece di subirla.

*Nota docente — reveal scenario D (active):* il modello *è* un classificatore supervisionato; l'active learning è la *strategia di acquisizione delle label* (uncertainty sampling sull'oracolo-clinico). Se un gruppo cerchia "supervised" non sbaglia del tutto: la risposta più precisa è "active" perché ciò che distingue lo scenario è la **richiesta selettiva di label all'oracolo**. Usa questo per insegnare la distinzione, non per penalizzare.

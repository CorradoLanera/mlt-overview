# Item 03 — RNN weight count and independence from sequence length

**ID**: IB-06-unstructured-data-03
**Learning objective**: Describe the recurrent operation $a^{<t>} = g(W_{aa}\, a^{<t-1>} + W_{ax}\, x^{<t>} + b_a)$ and explain that the **same matrices $W_{aa}, W_{ax}, W_{ya}$ are reused at every position $t$**, so the parameter count is **independent of the sequence length $T_x$** (Obj. 3).
**Category**: Application
**Type**: MCQ (scenarizzato)
**Difficulty**: medium
**Chapter**: 06-unstructured-data

## Question

You are training a Recurrent Neural Network to flag early signs of cardiac arrhythmia from a multi-channel bedside monitor. At every time step $t = 1, \ldots, T_x$:

- the input is a $4$-dimensional reading: $x^{<t>} \in \mathbb{R}^{4}$ (heart rate, blood pressure, SpO2, temperature);
- the hidden state is $20$-dimensional: $a^{<t>} \in \mathbb{R}^{20}$;
- the output is a $3$-dimensional probability vector: $y^{<t>} \in \mathbb{R}^{3}$ (*no-event* / *pre-arrhythmia* / *arrhythmia*).

The recurrent update is $a^{<t>} = g(W_{aa}\, a^{<t-1>} + W_{ax}\, x^{<t>} + b_a)$ and the per-step output is $y^{<t>} = g'(W_{ya}\, a^{<t>} + b_y)$. **Ignore biases for this item.** A typical patient session yields $T_x = 2\,000$ time steps.

**How many weights does the network have to learn, and does this count depend on $T_x$?**

## Options

- A) **$80$ weights**, and the count **depends on $T_x$** (each time step has its own copy of the weights, so the total grows with the length of the session).
- B) **$80$ weights**, and the count **does NOT depend on $T_x$** (the same weights are reused at every time step).
- C) **$540$ weights**, and the count **does NOT depend on $T_x$** (the same matrices $W_{aa}, W_{ax}, W_{ya}$ are reused at every time step).
- D) **$540 \times 2\,000 = 1\,080\,000$ weights**, and the count **depends on $T_x$** (the network is fully unrolled over the $2\,000$ time steps and has independent weights at each step).

## Expected answer

**Correct: C.** Decomposition of the weight count, matrix by matrix:

$$|W_{aa}| = 20 \times 20 = 400, \qquad |W_{ax}| = 20 \times 4 = 80, \qquad |W_{ya}| = 3 \times 20 = 60.$$

Total: $400 + 80 + 60 = 540$ weights. The count is **independent of $T_x$** because the chapter's central dispositive for sequences — **weight sharing across time** — says exactly that the *same* three matrices $W_{aa}, W_{ax}, W_{ya}$ are reused at every position $t$. The recurrence unrolls in time, but the *parameters* do not. A patient session of $T_x = 2\,000$ and a session of $T_x = 10\,000$ are processed by the *same* $540$ weights.

Why the distractors are plausible but wrong:

The four options form a **$2 \times 2$ matrix of misconceptions** along two axes: *which matrices were counted* (only $W_{ax}$, $80$ weights — vs all three matrices, $540$ weights) × *what $T_x$ does to the count* (multiplies it — vs does not).

- **A** *(80 weights, depends on $T_x$)* combines **both** misconceptions: counted only $W_{ax}$ (input → hidden), forgot the recurrent matrix $W_{aa}$ (hidden → hidden) and the output matrix $W_{ya}$ (hidden → output), *and* assumed every time step has its own copy. A student who lands on A has not seen Obj. 3 at all; they are reading the RNN as if it were a sequence of unrelated input layers.
- **B** *(80 weights, does NOT depend on $T_x$)* gets the **scaling concept right** but the **count wrong**: it correctly applies *"the same matrices are reused at every $t$"* (Obj. 3's punchline) but counts only $W_{ax}$, missing $W_{aa}$ and $W_{ya}$. In a closed MCQ this misconception is scored as *incorrect* like the others — **but** the *Nota docente* below flags it as the response to look at in the asynchronous debrief: a student who picked B is much closer to mastery than a student who picked A or D, and that signal is worth re-using in the next class or the next item set.
- **D** *(1,080,000 weights, depends on $T_x$)* is the **unrolled-MLP fallacy**: the student has correctly identified all three matrices ($400 + 80 + 60 = 540$) and then multiplied by $T_x = 2\,000$, as if every time step were a separate copy of the network. This is exactly the *wrong* mental model the chapter is built to dispel. The student has done the matrix arithmetic correctly but has not internalised the *purpose* of the recurrent architecture — namely, that the recurrence reuses *the same* matrices, *that is what makes it recurrent*. The number $1\,080\,000$ is also the number a *naïve unrolling without weight sharing* would yield — which is precisely the parameter explosion the RNN was designed to avoid.

The single discriminator is **both axes simultaneously right**: enumerate all three matrices ($W_{aa}, W_{ax}, W_{ya}$) *and* recognise that they are shared across time. Only C does both.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*Nota docente — design dei distrattori in matrice $2 \times 2$.* Pattern speculare a ch. $05$ item $03$ (matrice $2 \times 2$ sign × $\eta$ sulla discesa del gradiente). Qui le due assi sono *quante matrici* (B/A vs C/D) × *che cosa fa $T_x$* (A/D vs B/C). C è l'unica casella corretta su entrambi gli assi. **B è il distrattore pedagogicamente più ricco**: nel reveal il docente può aprire la conversazione su *"hai capito il principio (weight sharing) ma hai dimenticato due delle tre matrici — quali sono e dove vivono nel grafo della rete?"*. Lo studente che è arrivato a B è *vicino* al modello mentale corretto e va recuperato; lo studente che è arrivato a D ha il modello mentale *opposto* a quello del capitolo.

*Nota docente — scelta dei numeri.* Le dimensioni $(4, 20, 3)$ sono **diverse** dal formative *solved* di SU 3 — lì le dimensioni erano $(5, 10, 2)$ e il totale $170$. Qui sono $(4, 20, 3)$ e il totale $540$. Numeri diversi → l'item misura *processo* (saper enumerare $W_{aa}, W_{ax}, W_{ya}$ e fare i tre conti), non *memoria* del totale di SU 3. $T_x = 2\,000$ è clinicamente plausibile per una sessione di monitoraggio bedside ($\sim 4$ minuti a $\sim 8$ Hz oppure $\sim 30$ min a $\sim 1$ Hz). Le dimensioni del hidden state ($20$) e dell'output ($3$) sono appropriate per il task clinico (3 classi: no-event / pre-arrhythmia / arrhythmia).

*Nota docente — anti-leakage rispettata.* Niente vocabolario ch. $07+$. L'item resta dentro ch. $06$ (formula $a^{<t>}$ + tre matrici + weight sharing nel tempo).

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

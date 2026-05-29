# 06 — Unstructured data (CNN/RNN) · Sub-learning-units

> Chapter: **Unstructured data (CNN/RNN)** · 20 min · biomedical/clinical graduate students (UBEP).
> Student-facing text in English; teacher design notes (*nota docente*) in Italian.

*Nota docente — perché tre sub-unità.* Il capitolo ha **due meccanismi** (CNN, RNN) ma **un solo principio architetturale** (*weight sharing*: riusare gli stessi pesi lungo una struttura del dato — lo spazio per le immagini, il tempo per le sequenze). Esporre i due meccanismi *senza* prima nominare il principio comune rischia di far percepire CNN e RNN come due tecnologie scollegate. SU 1 ($\sim 3$′) fissa il principio; SU 2 ($\sim 4$–$5$′) e SU 3 ($\sim 4$–$5$′) lo applicano ai due assi. Tempo totale di esposizione $\sim 12$′ + sommativo $\sim 8$′ = $20$′ di capitolo. Le tre SU si mappano $1:1$ ai tre obiettivi del capitolo (SU 1 ↔ Obj. 1; SU 2 ↔ Obj. 2; SU 3 ↔ Obj. 3).

---

## Sub-unit 1 — Why architecture matters: the data dictates the network

*Time:* ~3 min · *Maps to:* Obj. 1 (data type → architecture choice).

### Mini-arc

**Hook.** You already know fully-connected networks from ch 05 — a stack of generalised non-linear logistic units. So *why* invent CNNs and RNNs at all? Take a single $1\,000 \times 1\,000$ chest X-ray. A single fully-connected neuron over it has $10^6$ weights. Stack ten such hidden layers and you have blown past clinical-scale datasets before the first epoch — the network has learned *nothing* about images, just memorised pixels.

**Challenge / Data.** Two unstructured-data types break the MLP for two *different* reasons. **(a) Spatial single-information** (chest X-ray, CT slice, histology tile) — the *same* edge or lesion can appear at different positions; an MLP has no built-in reason to call those instances similar and must re-learn each one. **(b) Sequential single-information** (ECG trace, clinical note, heart-rate stream) — the position $t$ in the sequence carries meaning; an MLP that takes the sequence as a flat vector has *no notion* of *before* and *after*.

**Resolution.** Two architectural ideas, both built around **one common trick — weight sharing**: reuse the same small set of weights across the structure of the data. **CNN** shares weights across **space** (one kernel, slid everywhere). **RNN** shares weights across **time** (one update rule, applied at every position $t$). The number of weights stops growing with the size of the data and starts being governed by the *prior* you encoded into the architecture.

**Payoff.** Once you see weight sharing as the *common* engineering choice, CNN and RNN stop looking like two separate technologies and start looking like *the same idea applied to two different axes of the data*. The rest of the chapter is just spelling out each axis.

### Formative exercise pair (not graded)

**Proposed** (at sub-unit start, $\sim 30$″): For a $224 \times 224$ grayscale image, write down (a) how many weights a single fully-connected layer with $100$ hidden units would need on the raw pixels, and (b) one sentence on why that number feels wrong for clinical applications.

**Solved** (at sub-unit end, $\sim 30$″): $224 \times 224 = 50\,176$ inputs $\times \,100$ hidden units $= 5\,017\,600$ weights — *for the first layer alone*. That is **more parameters than the dataset has examples** in essentially every clinical imaging study. The MLP has no choice but to memorise; it cannot generalise. *That* is the constraint CNN was designed to break — and it is the same flavour of constraint (parameter explosion grows with the data axis) that, on the *time* axis, motivates the RNN.

*Nota docente.* Questa SU è *quasi tutta narrativa* — l'obiettivo è far *sentire* allo studente lo sproporzionato costo dell'MLP sui dati non-strutturati, non insegnargli formule. Il calcolo dei $5$ milioni di pesi nel formative *solved* è la *prova viva* che giustifica perché serve un altro dispositivo: senza questo numero davanti agli occhi, le SU 2 e SU 3 arrivano come *soluzione a un problema mai posto*.

---

## Sub-unit 2 — Convolutional networks: share weights across space

*Time:* ~5 min · *Maps to:* Obj. 2 (convolution + weight sharing across positions).

### Mini-arc

**Hook.** A chest X-ray of a $30$-year-old shows a consolidation in the lower-right lobe. A chest X-ray of a $65$-year-old shows the same consolidation in the upper-left lobe. To the radiologist, it is the *same* finding. To an MLP, two completely different vectors of pixels — and the MLP has *no* built-in reason to treat them similarly. We need an operator that says "an edge is an edge, a consolidation is a consolidation — *wherever in the image* it appears".

**Challenge / Data.** Concretely, define a **kernel** $K \in \mathbb{R}^{k \times k}$ — a small matrix of trainable weights (typically $k = 3$, so $9$ weights). Slide it over the input image $X$; at each position $(i, j)$, compute the **feature map**

$$F_{ij} = g\!\left(\sum_{u=1}^{k} \sum_{v=1}^{k} K_{uv} \, X_{i + u - 1,\, j + v - 1}\right).$$

The crucial point: the *same* $K$ — the *same* $9$ weights — is used at *every* position $(i, j)$. There is one kernel for the whole image, not one per pixel.

**Resolution.** Two operational consequences follow directly from this sharing.

- **Weight count.** The convolutional layer has $9$ weights (plus $1$ bias) for the whole layer, independent of image size — vs the $50\,176 \times \text{(hidden units)}$ of an MLP on the same input. The parameter explosion of SU 1 is killed at the root.
- **Translation invariance.** The kernel that learned to detect an edge will detect that edge *wherever* it appears, because the *same* operator is applied everywhere — the network's structure encodes the geometric prior that *position should not change "what".*

**Payoff.** The CNN is *not* a magical image-understander. It is *a fully-connected network in which the linear algebra has been constrained to encode two clinical priors: locality (the kernel is small, so it looks at neighbourhoods) and positional invariance (the same kernel is shared everywhere)*. Strip those two constraints out and you are back to the MLP — with all of its problems.

### Formative exercise pair (not graded)

**Proposed** (at sub-unit start, $\sim 30$″): A $3 \times 3$ kernel is slid over a $5 \times 5$ image with stride $1$ and *no padding*. (a) How big is the output feature map? (b) Write the operation that produces the central output pixel.

**Solved** (at sub-unit end, $\sim 1$′): (a) The output size is $\lfloor (n - k)/s \rfloor + 1 = (5 - 3)/1 + 1 = 3$, so the feature map is $3 \times 3$. (b) The central output pixel is at position $(2, 2)$ of the feature map and corresponds to the kernel applied to the central $3 \times 3$ patch of the input:

$$F_{22} = g\!\left(\sum_{u=1}^{3} \sum_{v=1}^{3} K_{uv} \, X_{1 + u,\, 1 + v}\right) = g\!\left(K \cdot X[2{:}4,\, 2{:}4]\right).$$

The whole layer has $9$ weights — *that is the headline number*. A clinician should walk away from this SU able to answer "why so few?" with a single phrase: **the same kernel is reused at every position**.

*Nota docente.* Il calcolo della dimensione output può sembrare un dettaglio ingegneristico, ma serve un'unica cosa: *materializzare* la convoluzione come *operazione locale ripetuta*. Lo studente che ha visto il formato output (e ha contato dove finisce il kernel a passi successivi) ha *vissuto* il dispositivo del weight sharing, non solo memorizzato la frase. **Voce docente — non valutato nelle SU**: stride, padding (`same` vs `valid`), max-pooling, numero di canali in/out — sono dettagli architetturali che vanno ben oltre i $5$′ di SU 2 e sono materia di un eventuale corso CNN-dedicato.

---

## Sub-unit 3 — Recurrent networks: share weights across time

*Time:* ~5 min · *Maps to:* Obj. 3 (recurrent update + weight sharing across time).

### Mini-arc

**Hook.** Take an ECG with $T_x = 5\,000$ samples. The clinical question — *is there atrial fibrillation?* — depends on *the pattern of irregular intervals over time*, not on the absolute value at any one sample. If you feed an MLP $5\,000$ scalars as a flat vector, you have erased the time axis: sample $1$ and sample $4\,999$ look interchangeable to it, because the MLP has no built-in notion of *which sample comes after which*.

**Challenge / Data.** We need an operator that *reads* one position at a time *and* keeps memory of what came before. Concretely, at each $t = 1, \ldots, T_x$, update a hidden state

$$a^{<t>} = g\!\left(W_{aa} \, a^{<t-1>} + W_{ax} \, x^{<t>} + b_a\right),$$

and, optionally, emit an output

$$y^{<t>} = g'\!\left(W_{ya} \, a^{<t>} + b_y\right).$$

The crucial point: the *same* three matrices $W_{aa}, W_{ax}, W_{ya}$ are used at *every* position $t$. There is **one** update rule for the whole sequence, applied recursively.

**Resolution.** Two operational consequences follow directly from this sharing across time.

- **Parameter count is independent of $T_x$.** The same $W$ matrices process a $5\,000$-sample ECG and a $500\,000$-sample one. The number of weights stops growing with the length of the sequence — the analogue, on the time axis, of what CNN did on the spatial axis.
- **Memory.** Because $a^{<t>}$ depends on $a^{<t-1>}$, which depends on $a^{<t-2>}$, and so on, the hidden state at position $t$ has — in principle — *access to the entire history* $x^{<1>}, \ldots, x^{<t>}$. This is what the RNN *adds* beyond the CNN: a *temporal* memory.

**Payoff.** The RNN is *not* a black box that "understands time". It is *a fully-connected network applied recursively to its own previous output, with weight sharing along the time axis*. Strip out the recursion and you are back to the MLP — once again.

### Formative exercise pair (not graded)

**Proposed** (at sub-unit start, $\sim 30$″): For an RNN with $5$-dimensional input ($x^{<t>} \in \mathbb{R}^5$), $10$-dimensional hidden state ($a^{<t>} \in \mathbb{R}^{10}$), and $2$-dimensional output ($y^{<t>} \in \mathbb{R}^2$), count the total number of weights (ignore biases). State whether this count depends on the sequence length $T_x$.

**Solved** (at sub-unit end, $\sim 1$′): The three matrices have shapes $W_{aa} \in \mathbb{R}^{10 \times 10}$, $W_{ax} \in \mathbb{R}^{10 \times 5}$, $W_{ya} \in \mathbb{R}^{2 \times 10}$. Counts:

$$|W_{aa}| = 10 \cdot 10 = 100, \quad |W_{ax}| = 10 \cdot 5 = 50, \quad |W_{ya}| = 2 \cdot 10 = 20.$$

Total $= 170$ weights. This count is **independent of $T_x$**: the same $170$ weights process a sequence of length $10$, $1\,000$, or $10\,000$ — *that* is what "weight sharing across time" buys you operationally. Contrast with the MLP that would need a fresh column of weights per sequence position: at $T_x = 5\,000$ on a $5$-dimensional input the first MLP layer alone would already need $5\,000 \cdot 5 \cdot 10 = 250\,000$ weights — three orders of magnitude more — *to read the same ECG*.

*Nota docente.* Il numero $170$ è basso *di proposito* — abbastanza basso da essere contato a mente in $30$″, abbastanza alto da non sembrare giocattolo. Il confronto $170$ vs $250\,000$ è la *frase finale* del capitolo: *la differenza fra "rispettare la struttura del dato" e "ignorarla" è di tre ordini di grandezza in pesi*, e i tre ordini di grandezza si traducono in *generalizzazione che funziona* vs *memorizzazione che esplode*. **Voce docente — non valutato nelle SU**: vanishing-gradient problem, LSTM/GRU, bidirectional RNN, encoder-decoder per sequence-to-sequence — sono motivazioni per *come* l'RNN classico viene sostituito (e ch 07 chiuderà il cerchio mostrando come il Transformer rimpiazzi del tutto la memoria sequenziale).

---

## Closing — how the three SU compose

*Nota docente.* Alla fine del capitolo, sulla *lavagna o sulla slide riassuntiva* va lasciato visibile questo specchietto, che è anche il legame fra le tre SU e il summative live exercise:

| Asse | Architettura | Dispositivo | Headline numerico |
|---|---|---|---|
| (nessuno) | MLP | nessuno | $5\,017\,600$ pesi su un'immagine $224 \times 224$ (SU 1) |
| Spazio | CNN | kernel condiviso | $9$ pesi per layer (SU 2) |
| Tempo | RNN | $W$ condivise nel tempo | $170$ pesi per processare $5\,000$ campioni (SU 3) |

Il summative *"Right tool for the wrong tensor"* (vedi `objectives.md`) verifica esattamente questa tabella: tre data cards, tre architetture diverse, e le due conte di pesi $50\,176$ vs $9$ (Card A, CNN) e l'equazione ricorrente su Card B (RNN). Le SU sono quindi *pre-cucinate per* il sommativo: chi ha seguito le tre SU porta dentro l'esercizio i tre numeri-faro.

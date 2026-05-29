# Item 04 — Critique a colleague's design: *"flatten the multi-channel signal and feed it to a fully-connected network"*

**ID**: IB-06-unstructured-data-04
**Learning objective**: Argue, on a clinical multi-channel time-series scenario, why a fully-connected (MLP) baseline on the flattened raw signal *fails on three fronts* — parameter count, loss of temporal order, and loss of multi-channel structure — and propose an architectural alternative grounded in the chapter's central dispositive of **weight sharing**. Verifies Obj. 1 (match data → architecture), Obj. 2 (CNN, weight sharing across space), and Obj. 3 (RNN, weight sharing across time).
**Category**: Argumentation / valutazione
**Type**: argomentativa (open critique, 2 sub-questions)
**Difficulty**: high
**Chapter**: 06-unstructured-data

## Question

A clinical-research colleague — methodical, well-read in classical statistics, new to deep learning — sends you the design of an ML pipeline for predicting *in-hospital mortality* within the next $24$ hours from continuous bedside-monitor data. Here is their design, verbatim:

> *"Each patient is monitored for $24$ hours. We record three signals — heart rate, mean arterial pressure, peripheral oxygen saturation — sampled at $1$ Hz, so each signal is a length-$86\,400$ time series. For each patient, I concatenate the three signals into a single flat vector of $86\,400 \times 3 = 259\,200$ scalar values, and I feed this vector to a fully-connected neural network with $100$ hidden units in the first layer and a single sigmoid output. The network is deep, so it should be able to find any pattern that matters. I will train it on our $5\,000$-patient cohort."*

Your colleague closes with: *"can you see any problem with this design?"*

### Sub-question (i) — Critique

Identify the **structural problems** of this design using the material of chapter $06$. A complete answer names **at least two** distinct problems (not symptoms or restatements of the same problem) and justifies each with one concrete number or one concrete reference to the chapter's principle. *Do not* invoke material the chapter has not covered (e.g. dropout, batch normalisation, regularisation).

### Sub-question (ii) — Proposal

Propose **an alternative architecture** that fixes the problems you have identified, and justify the alternative by naming the *prior* it encodes — i.e. *what structural property of the data the alternative respects that the colleague's MLP does not*. A complete proposal names the architecture, sketches what is shared and along which axis, and gives one order-of-magnitude estimate of the parameter count for the *first layer only* under your proposed architecture.

## Expected answer

### Sub-question (i) — Critique

A complete critique names **three distinct problems**, each grounded in one of the chapter's three objectives:

1. **Parameter explosion (Obj. 2).** The first fully-connected layer has $259\,200 \times 100 = 25\,920\,000$ weights — i.e. **roughly $5\,000\,\times$ more parameters than the cohort has training patients** ($25.9 \text{M} \,/\, 5\,000 \approx 5\,200$). No clinical dataset of this size can train a first layer with that many parameters; the network will *memorise* the training cohort rather than generalise. The colleague's *"the network is deep, so it should find any pattern that matters"* is exactly the assumption that the *parameter explosion* invalidates: capacity is not the same thing as generalisation.
2. **Loss of temporal order (Obj. 3).** The flattening into a single $259\,200$-vector erases the time axis. To the MLP, sample $1$ and sample $86\,400$ are *interchangeable columns of a spreadsheet*. But a pre-mortality blood-pressure trajectory is *a pattern over time* — a sustained drop, a loss of variability, an oscillation — and a model that does not know which sample came when *cannot* describe such a pattern. The MLP would have to *discover* the time axis from the data (at additional parameter cost, on a dataset that already cannot pay).
3. **Loss of multi-channel structure (Obj. 1).** Concatenating HR, BP, and SpO2 into a single flat vector treats the three physiologically-correlated signals as *unrelated columns*. The chapter's Obj. 1 rule (*"the architecture must respect the structure of the data"*) is violated twice: once by erasing the time axis (problem 2), and once by collapsing the three parallel channels into a single concatenation that hides the channel-axis structure.

The deeper diagnosis: the colleague has picked an architecture that *does not respect any of the data's two structural axes* (time, channel). The chapter's central message — *match the structure, share the weights* — is the principle the design violates.

### Sub-question (ii) — Proposal

A complete proposal names a **specific** architectural alternative and grounds it in the chapter's *weight sharing* dispositive. Two acceptable canonical answers:

- **(a) Recurrent Neural Network reading the multi-channel signal as a sequence of $3$-dimensional inputs.** At each $t = 1, \ldots, 86\,400$ the input is $x^{<t>} \in \mathbb{R}^{3}$ (the three channels at that time), the hidden state is — say — $a^{<t>} \in \mathbb{R}^{32}$, and the final $a^{<86\,400>}$ feeds a small classifier head. Weights to learn (no bias): $|W_{aa}| = 32 \cdot 32 = 1\,024$, $|W_{ax}| = 32 \cdot 3 = 96$, plus a small classifier head. Order of magnitude: **$\sim 10^{3}$ weights**, independent of $T_x$. This is **five orders of magnitude fewer parameters** than the colleague's $25.9\,M$ — and the architecture *encodes* the temporal order through the recurrent update, instead of asking the network to discover it.

- **(b) $1$D Convolutional Neural Network with multi-channel input.** Channels are treated as $3$ "feature channels" (as in RGB for images), and one or more $1$D kernels of size $k$ (say $k = 7$) are slid across time. A single $1$D kernel has $3 \cdot 7 = 21$ weights. Order of magnitude: $\sim 10^{1}$–$10^{2}$ weights for the first layer. Encodes *temporal local patterns* (the analogue, on the time axis, of CNN's translation invariance on the spatial axis) — appropriate if the *local shape* of the rhythm carries the diagnostic signal more than long-range dependence does.

Either answer is accepted as a *complete* response provided the student names:

- the architecture chosen,
- the axis along which weights are shared (time for both),
- a parameter-count order of magnitude for the first layer,
- the *prior* the alternative encodes that the MLP cannot.

A student who proposes a **hybrid** ($1$D-CNN feature extractor + RNN aggregator, or *vice versa*) and justifies it by naming both *local patterns* and *long-range structure* shows mastery and is rewarded as Excellent on this sub-question.

## Rubric

→ [rubriche/rubrica_04_critique-flatten-and-feed.md](rubriche/rubrica_04_critique-flatten-and-feed.md)

## Note di revisione

*Nota docente — perché un argomentativa.* I primi tre item (MCQ + applicativa + MCQ scenarizzato) misurano *componenti separate* dei tre obiettivi. Item $04$ è il *test di sintesi*: chi ha capito Obj. 1+2+3 deve essere in grado di criticare un design *che fallisce contemporaneamente su tutti e tre*, e proporre un'alternativa *che li rispetta contemporaneamente*. Un set di item senza Argumentation finale è una raccolta di esercizi; con l'item $04$ è una *valutazione del capitolo come unità didattica*.

*Nota docente — il design del collega è clinicamente plausibile.* Un epidemiologo o uno statistico medico abituato a dati tabular *davvero* costruirebbe questo tipo di pipeline come primo tentativo — il flatten è il riflesso *naturale* di chi ha sempre lavorato con un vettore di feature per paziente. L'item *non* sta criticando un design strawman: sta criticando il **default mentale** di un'intera categoria di colleghi (quella in cui molti studenti UBEP si troveranno a lavorare). L'ironia didattica funziona solo se non viene smascherata come parodia.

*Nota docente — bias-da-evitare critico nella correzione (vedi rubrica).* Il rischio principale è **dare ragione al collega su un dettaglio** (es. *"hai ragione, $1\,Hz$ è poco e potresti farlo a $0.1\,Hz$"*). Una concessione *praticamente sensata* ma **fuori scope di ch. $06$** — il capitolo non insegna *downsampling come strategia*, insegna *architetture che rispettano la struttura del dato*. Lo studente che propone *downsampling al posto* di un'architettura nuova ha *evitato* la domanda. Si valuta la critica *dentro lo scope del capitolo*.

*Nota docente — alternative accettate.* Sia RNN (canonical) sia $1$D-CNN (practical) sono accettate come risposte complete. Pattern speculare al trap del Poll 1 Card B del summative + al distrattore A dell'item $01$: l'item $04$ **chiude** la triade, premiando come Eccellente lo studente che propone un *hybrid* o che giustifica esplicitamente la scelta fra RNN e $1$D-CNN sulla base del *tipo di dipendenza* che pensa domini il segnale (locale vs lungo raggio).

*Nota docente — anti-leakage rispettata.* Niente vocabolario ch. $07+$. **Importante**: l'item NON deve invocare *attention*, *Transformer*, *self-attention* come alternativa "migliore di RNN su sequenze lunghe" — è esattamente la trap che il pre-hook a ch. $07$ pianta e che ch. $07$ risolverà. In ch. $06$ la canonical answer su sequenze è RNN, punto.

*Nota docente — versione del docente.* Ho iterato la formulazione del design del collega per assicurarmi che (a) il $T_x = 86\,400$ producesse un parameter count *chiaramente catastrofico* ($25.9M$, non $\sim 1M$ — la grandezza deve essere *non-ambigua*), (b) le tre signal HR/BP/SpO2 fossero clinicamente correlate (multi-channel structure è una vera proprietà del dato, non un'invenzione) e (c) il cohort size ($5\,000$ pazienti) fosse *plausibile* per un dataset clinico reale ma *insufficiente* per addestrare $25.9M$ pesi — così il parameter explosion è leggibile come *limite operativo concreto*, non come critica astratta.

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

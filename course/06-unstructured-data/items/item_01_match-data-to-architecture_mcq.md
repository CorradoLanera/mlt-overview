# Item 01 — Match the data structure to the right architecture

**ID**: IB-06-unstructured-data-01
**Learning objective**: Match an unstructured-data type to the right deep architecture and name the structural property the architecture preserves (Obj. 1) — *sequential single-information* → **Recurrent Neural Network** because the *order* of the elements carries information, encoded by propagating a hidden state from position to position.
**Category**: Comprehension
**Type**: MCQ
**Difficulty**: medium
**Chapter**: 06-unstructured-data

## Question

You are building a deep model to detect *atrial fibrillation* (AFib) from a single-lead electrocardiogram with $T_x = 5\,000$ samples. Which architecture is the **canonical choice** for this task as covered in this chapter, and **what is the reason**?

## Options

- A) **Convolutional Neural Network** — because the irregular RR-interval pattern is a *local* shape that can occur anywhere in the trace, and a kernel slid over the input would detect it at every position.
- B) **Recurrent Neural Network** — because the *order* of the samples carries clinical meaning (the rhythm *is* a pattern over time), and the recurrent update propagates a hidden state $a^{<t-1>} \to a^{<t>}$ that encodes order; the same matrices $W_{aa}, W_{ax}$ are reused at every position $t$.
- C) **Multi-Layer Perceptron on the flat $5\,000$-dimensional vector** — because an MLP can approximate any function of a vector input with enough hidden units, so with sufficient capacity it will learn the rhythm directly from the raw samples.
- D) **Multi-Layer Perceptron after Principal Component Analysis to $50$ components** — because reducing the dimensionality to $50$ scalars removes the time-axis problem and makes the input manageable for a standard fully-connected network.

## Expected answer

**Correct: B.** The chapter's Obj. 1 says: *sequential single-information* (the position $t$ carries meaning) → **RNN**, because the recurrent update $a^{<t>} = g(W_{aa}\, a^{<t-1>} + W_{ax}\, x^{<t>} + b_a)$ propagates a hidden state from $t-1$ to $t$ — and so the *order* of the samples is explicitly encoded in the architecture (the network *knows* that $x^{<1>}$ comes before $x^{<5000>}$). The same matrices are reused at every $t$, so the parameter count is independent of $T_x$. Atrial fibrillation is a *pattern over time* (irregular RR intervals over a window): the RNN is the canonical architecture because it is the one that respects this structural property.

Why the distractors are plausible but wrong:

- **A** is the *practical-answer trap*. Numerically, a $1$D-CNN often works well on short ECG segments — and the chapter's *Nota docente* on anti-trabocchetto explicitly recognises this. A student who picks A has noticed something correct (local pattern $+$ kernel-shared-across-positions does generalise to $1$D), and in the live summative this answer is *premiata nel reveal*. But it is **not the canonical answer of chapter $06$**, because $1$D-CNN does not introduce the *new dispositive* the chapter is teaching here — *memory across time via a hidden state*. CNN's prior is *positional invariance*; RNN's prior is *order*. The chapter teaches them on different axes because the *axes* are different — and for sequences, the canonical answer is the one that encodes the axis.
- **C** is the *"MLP universally approximates everything"* mistake. True in the limit (universal approximation), but ignores that an MLP on the flat $5\,000$-vector has *no built-in notion of order*: $x_1$ and $x_{5000}$ are columns of a spreadsheet with no temporal relation. The MLP would have to *discover* the time axis from training data — at a parameter cost that grows with the number of hidden units (e.g. a single FC layer with $100$ hidden units would need $5\,000 \times 100 = 500\,000$ weights, for *one* layer) and that no clinical dataset will pay. The chapter's Obj. 1 rules out this option precisely because *the architecture must respect the structure of the data*, not be forced to re-discover it.
- **D** is the *"preprocessing fixes the architecture problem"* mistake — and is in fact **worse than C**. PCA on a flat $5\,000$-vector is a *linear projection that mixes samples from different times into the same component*. The first principal component might be a weighted average of samples across the whole trace; the second might combine samples from $t = 100$ with samples from $t = 4{,}900$. The time axis is not *managed*: it is *erased*. A student who picks D has confused *dimensionality reduction* (fewer numbers to feed the model) with *structure preservation* (keeping the relations among those numbers). PCA does the first; it destroys the second.

The single discriminator is **which option encodes the *order* of the sequence into the architecture itself, rather than asking the network or the preprocessing to discover (or destroy) that order**. Only B does this.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*Nota docente — perché il **distrattore A è il più ricco**.* A non è un errore: è una *scelta praticamente competitiva* presentata come *risposta canonica del capitolo*. Nel reveal — o nella correzione asincrona di un esame scritto — lo studente che ha scelto A va trattato in due tempi: (a) **prima si riconosce la correttezza pratica della sua osservazione** ("ha ragione: una $1$D-CNN funziona spesso bene su ECG corti"); (b) **poi si chiarisce perché ch. $06$ chiede B**: il capitolo introduce il *dispositivo memoria via stato nascosto*, e la canonical answer è la *risposta architetturale che mostra il dispositivo nuovo*, non la *risposta che vince un benchmark Kaggle*. Lo studente bravo che sceglie A va premiato per l'osservazione e *poi* riportato alla domanda effettiva del capitolo. Nel set di item, A è esattamente lo *stesso* trap del Poll 1 di Card B nel summative (vedi [objectives.md](../objectives.md)) — coerenza voluta: il sommativo e l'item misurano lo *stesso* errore di livello pedagogico.

*Nota docente — anti-leakage rispettata.* L'item resta interamente dentro ch. $06$: no *attention*, no *Transformer*, no *encoder/decoder*, no riferimenti a LLM. Il pre-hook a ch. $07$ (long-range dependency su discharge letter) vive in `narrative.md`, non qui.

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

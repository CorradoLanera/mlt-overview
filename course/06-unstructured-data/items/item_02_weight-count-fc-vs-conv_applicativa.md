# Item 02 — Weight count: fully-connected vs convolutional, and how each scales

**ID**: IB-06-unstructured-data-02
**Learning objective**: Describe the convolution operation on a 2D input and explain *weight sharing across spatial positions* as the mechanism that makes the parameter count independent of input size (Obj. 2). The student counts weights, justifies the count, and shows what happens when the input image scales up.
**Category**: Application
**Type**: applicativa (open task, 3 sub-questions)
**Difficulty**: medium
**Chapter**: 06-unstructured-data

## Question

Consider a chest X-ray represented as a $64 \times 64$ grayscale image (so $X \in \mathbb{R}^{64 \times 64}$, $4\,096$ pixels). You are deciding between two ways to extract a first layer of features from this image:

- **Architecture A** — *one fully-connected output neuron* on the raw image, with **no bias**: $z_A = \sum_{i=1}^{64} \sum_{j=1}^{64} W^{(A)}_{ij} \, X_{ij}$, then $a_A = g(z_A)$.
- **Architecture B** — *one $3 \times 3$ convolutional kernel* slid across the raw image with stride $1$, **no padding**, **no bias**: at every valid spatial position $(i, j)$ the feature map cell is $F_{ij} = g(\sum_{u=1}^{3} \sum_{v=1}^{3} K_{uv} \, X_{i + u - 1,\, j + v - 1})$.

Answer the three sub-questions below; show the calculation in each case (do not give only the final number).

### Sub-question (i) — count weights, Architecture A

How many weights does Architecture A need to learn? Show the count.

### Sub-question (ii) — count weights, Architecture B

How many weights does Architecture B need to learn? Show the count, and **state in one sentence** why the count is *not* $9 \times (\text{number of spatial positions of the feature map})$.

### Sub-question (iii) — scaling to $1024 \times 1024$

Imagine the same chest X-ray were stored at full resolution $1024 \times 1024$ (so $1\,048\,576$ pixels). For each of the two architectures, write the new weight count. Then state, in one sentence, the operational consequence for clinical datasets.

## Expected answer

### Sub-question (i)

Architecture A has **one weight per pixel** of the input, because each input pixel $X_{ij}$ contributes its own coefficient $W^{(A)}_{ij}$ to the weighted sum. With $64 \times 64$ input pixels and no bias:

$$|W^{(A)}| \;=\; 64 \times 64 \;=\; 4\,096 \text{ weights.}$$

### Sub-question (ii)

Architecture B has **one weight per cell of the kernel**, because the *same* kernel $K \in \mathbb{R}^{3 \times 3}$ is reused at every spatial position. With a $3 \times 3$ kernel and no bias:

$$|W^{(B)}| \;=\; 3 \times 3 \;=\; 9 \text{ weights.}$$

The count is *not* $9 \times (\text{spatial positions})$ because the kernel is **shared across space**: the same nine numbers are used wherever the kernel lands, so the layer has nine trainable weights *total*, not nine per location. (This is *weight sharing across space* — the operational definition.)

### Sub-question (iii)

At resolution $1024 \times 1024$:

- **Architecture A**: $1024 \times 1024 = 1\,048\,576$ weights.
- **Architecture B**: still $9$ weights — *the kernel size is independent of the input image size*.

Operational consequence: Architecture A's weight count grows **quadratically** with the linear resolution of the image — going from a $64 \times 64$ thumbnail to a $1024 \times 1024$ full-resolution chest X-ray multiplies its parameter count by $(1024 / 64)^2 = 256$. Architecture B's weight count *does not grow at all*. On any clinical imaging dataset that does not have hundreds of thousands of labelled cases, Architecture A is simply not trainable; Architecture B is.

## Rubric

→ [rubriche/rubrica_02_weight-count-fc-vs-conv.md](rubriche/rubrica_02_weight-count-fc-vs-conv.md)

## Note di revisione

*Nota docente — sulla scelta dei numeri.* $64 \times 64$ è **diverso** dal summative ($224 \times 224 \to 50\,176$ pesi FC vs $9$ pesi conv) e dalla SU 1 ($224 \times 224 \times 100 \to 5\,017\,600$ pesi). Convenzione di ch. $04$/$05$ ribadita: *non* riproporre i numeri del summative negli item d'esame — un item che riusa $50\,176$ misura *memoria del numero*, non *processo di conta*. Qui $64 \times 64 = 4\,096$ è ancora computabile a mente ($64 \cdot 64$); $1024 \times 1024 = 1\,048\,576$ richiede di moltiplicare $1024 \cdot 1024$ (o riconoscere $2^{20}$) — è il *jump quantitativo* che rende il punto.

*Nota docente — bias-da-evitare nella correzione (vedi rubrica).* Il rischio principale è premiare *"$9$ pesi"* come risposta a (ii) **senza** la frase sul perché non sono $9 \times (\text{posizioni})$. La frase è la **prova** che lo studente ha capito il dispositivo *weight sharing*; il numero da solo è raggiungibile per memorizzazione, e questo item *non lo deve premiare*. Stessa logica di ch. $05$ item $02$ (conta dei pesi con decomposizione obbligatoria).

*Nota docente — anti-leakage rispettata.* Niente vocabolario ch. $07+$. La $1024 \times 1024$ in (iii) è la stessa risoluzione nominata nel pre-hook narrativo di ch. $05$ → ch. $06$ — coerenza intenzionale, *non* leakage (è ch. $06$ che usa la sua propria risoluzione canonica).

*Nota docente — coerenza con SU 1.* La sub-question (iii) sul jump da $64 \times 64$ a $1024 \times 1024$ ricalca esattamente la *prova viva* di SU 1 (formative *solved*): chi ha seguito la lezione ha già visto questo argomento con i numeri $224 \times 224 \to 5\,017\,600$ pesi. Qui lo applica a numeri nuovi — è il segnale che ha *capito il pattern di scala*, non memorizzato il caso particolare.

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

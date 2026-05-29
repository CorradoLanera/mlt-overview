# Item 02 — Long-range dependency on a clinical sentence: RNN traversal vs Transformer self-attention

**ID**: IB-07-llm-transformers-02
**Learning objective**: Contrast the Transformer's self-attention with the RNN's sequential hidden state on a sequence of length $T_x$ — identify a long-range dependency in a clinical sentence, quantify how many intermediate hidden states an RNN must traverse to propagate that dependency, and locate the *single* entry of the $Q K^{\top}$ attention matrix that captures the same dependency in one step (Obj. 2).

**Category**: Application
**Type**: applicativa
**Difficulty**: medium
**Chapter**: 07-llm-transformers

## Question

Consider the following clinical sentence, taken from a fictional discharge letter. The words have been numbered so you can refer to positions unambiguously.

> The$_{1}$ discharge$_{2}$ summary$_{3}$ explicitly$_{4}$ **rules**$_{5}$ **out**$_{6}$ atrial$_{7}$ fibrillation$_{8}$, although$_{9}$ the$_{10}$ 48-hour$_{11}$ Holter$_{12}$ recording$_{13}$ from$_{14}$ the$_{15}$ prior$_{16}$ week$_{17}$ — attached$_{18}$ as$_{19}$ appendix$_{20}$ C$_{21}$ and$_{22}$ reviewed$_{23}$ only$_{24}$ by$_{25}$ the$_{26}$ on-call$_{27}$ cardiologist$_{28}$ this$_{29}$ afternoon$_{30}$ — **demonstrates**$_{31}$ **paroxysmal**$_{32}$ episodes$_{33}$.

The sentence's total length, after this stylised word-level tokenisation, is $T_x = 33$ tokens. *(Em-dashes are punctuation and are not counted as tokens in this stylised scheme; the commas are also not separately tokenised.)* A clinician reads this sentence and asks the model the question: *"According to this letter, does the patient have atrial fibrillation, yes or no?"*

Answer the three sub-questions below in order.

### Sub-question 1 — identify the long-range dependency

State the **two words** (with their position indices) that the model must *connect* in order to answer the clinician's question correctly, and explain in **one sentence** why the connection between *those* two specific words is the one that matters — rather than, say, *atrial*$_{7}$ and *paroxysmal*$_{32}$.

### Sub-question 2 — RNN traversal cost

Assume the model is the RNN of [ch. 06](../../06-unstructured-data/objectives.md), with recurrence
$$a^{<t>} = g(W_{aa} \, a^{<t-1>} + W_{ax} \, x^{<t>} + b_a) \qquad \text{for } t = 1, \ldots, T_x.$$

Starting from the hidden state at the position of the *earlier* of the two words you identified in sub-question 1, **count exactly how many applications of the recurrence are needed** to propagate the dependency forward to the hidden state at the position of the *later* word. Show the calculation explicitly (the two positions, the subtraction, the result).

### Sub-question 3 — Transformer attention: the single matrix entry

Assume the model is the Transformer of this chapter, with self-attention
$$\text{attention}(Q, K, V) = \text{softmax}\!\left(\dfrac{Q K^{\top}}{\sqrt{d_k}}\right) V$$

where $Q, K, V \in \mathbb{R}^{T_x \times d}$ are matrices of *queries*, *keys* and *values*, one row per token of the sentence.

**State the single entry $(i, j)$ of the $T_x \times T_x$ matrix $Q K^{\top}$ that carries the long-range dependency you identified** (give both row and column indices, using the convention that row $i$ is the *query* of position $i$ and column $j$ is the *key* of position $j$). Then state, in **one sentence**, how many *operations* the dependency takes through the attention matrix — and **how that count changes** if the same two words were placed at the two extreme ends of a sentence of length $T_x = 1000$ instead of $T_x = 33$.

## Expected answer

### Sub-question 1

The two words are **rules$_{5}$** (or equivalently the bigram *rules out*$_{5\text{–}6}$, but a single position is sufficient) and **demonstrates$_{31}$** (or equivalently the bigram *demonstrates paroxysmal*$_{31\text{–}32}$).

*"Rules"* (position $5$) is the verb that says **no**: the discharge summary asserts *atrial fibrillation* is **excluded**. *"Demonstrates"* (position $31$) is the verb that says **yes**: the Holter recording, attached as appendix C, **contradicts** the discharge summary by showing paroxysmal episodes. The clinician's question is *"yes or no on atrial fibrillation?"*, and the correct answer requires the model to *connect* these two specific verbs and recognise that the later evidence *overrides* the earlier conclusion.

Why **not** *atrial*$_{7}$ and *paroxysmal*$_{32}$: these two words are semantically related at the *topic* level (both refer to a kind of cardiac rhythm disturbance), but they are *not* the words that carry the logical contradiction. A model that links *atrial*$_{7}$ to *paroxysmal*$_{32}$ has identified the *topic* of the sentence but has missed *who-contradicts-whom* — and would answer the clinician's question incorrectly.

(A response that names *rules out* / *contradicts*-style words — even using *out*$_{6}$ instead of *rules*$_{5}$, or *paroxysmal*$_{32}$ instead of *demonstrates*$_{31}$ — is acceptable, provided the *negation–assertion* asymmetry is correctly named.)

### Sub-question 2

The RNN's hidden state at position $5$ is $a^{<5>}$; the hidden state at position $31$ is $a^{<31>}$. To propagate the dependency forward from $a^{<5>}$ to $a^{<31>}$, the recurrence

$$a^{<t>} = g(W_{aa} \, a^{<t-1>} + W_{ax} \, x^{<t>} + b_a)$$

must be applied for every $t = 6, 7, 8, \ldots, 31$.

That is $31 - 5 = \mathbf{26}$ applications of the recurrence. (Equivalently: there are $25$ *intermediate* hidden states $a^{<6>}, a^{<7>}, \ldots, a^{<30>}$ strictly between $a^{<5>}$ and $a^{<31>}$, with $a^{<31>}$ as the final destination.)

The teachable beat: each of these $26$ applications is **one occasion for the signal of *rules out* to fade** as it is mixed with the contributions of the intervening words (*atrial*, *fibrillation*, *although*, *the*, *48-hour*, *Holter*, ..., *afternoon*). The longer the sentence, the more occasions for fade.

### Sub-question 3

The single entry of $Q K^{\top}$ that carries the long-range dependency is **$(Q K^{\top})_{31, 5}$**: row $31$ is the query of *demonstrates*, column $5$ is the key of *rules*. This entry is a scalar — a single inner product $\langle q_{31}, k_5 \rangle$ — and after the row-wise softmax + multiplication by $V$ it contributes directly to the representation at position $31$.

The symmetric entry $(Q K^{\top})_{5, 31}$ is also acceptable as the answer, since self-attention computes *all* pairwise inner products and either direction encodes the same pairing.

The dependency takes **one operation** through the attention matrix (one inner product / one matrix entry).

**Crucial sensitivity property:** if the same two words were placed at the two extreme ends of a sentence of length $T_x = 1000$ — i.e. at positions $1$ and $1000$ — the entry $(Q K^{\top})_{1000, 1}$ would still be **a single entry**, computed by a single inner product, in the same one operation. The RNN's count would explode from $26$ to $999$; the Transformer's count would stay at $1$. *That* is the chapter's central architectural claim — *the dependency between position $1$ and position $T_x$ is one operation away in the Transformer, regardless of how large $T_x$ is*.

## Rubric

See [rubrica_02_long-range-dependency.md](../rubriche/rubrica_02_long-range-dependency.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

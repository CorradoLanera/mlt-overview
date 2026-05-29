# Item bank — 06 Unstructured data (CNN/RNN)

> Chapter: `06-unstructured-data` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-29 (notte). Items student-facing in **English**; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED WITH FIXES** (2026-05-29 notte) — 2 critical + 3 should-fix applied: (1) item $04$ critique framing reworded from *"$5\,000$ pesi per paziente"* a *"$5\,000\times$ più parametri che pazienti"* (orders-of-magnitude framing è il segnale pedagogico più forte di C1); (2) item $01$ distrattore C: $500\,000$ pesi ora ancorato a un'ipotesi esplicita di $100$ hidden units, non più un numero pendente; (3) rubrica $02$ bias clause 3 riscritta come istruzione positiva (*"la 1-sentence sul weight sharing in (ii) È valutata, sempre"*) — eliminata l'auto-contraddizione segnalata dal reviewer; (4) item $03$ distrattore B *Nota docente*: la *margin-note* MCQ-inappropriata sostituita con una flag per il debrief asincrono; (5) rubrica $04$ C3: ordine di grandezza accettato ristretto da $10^{1}$–$10^{4}$ a *"$\sim 20$ (single kernel) → $\sim 10^{3}$ (small recurrent block); $10^{5}$+ = riprodotto FC mistake = sotto-Base"* — Base più diagnostica. **Verifiche superate dal reviewer:** (a) coverage $3/3$ obiettivi $\times$ $3$ categorie cognitive (no pure Knowledge); (b) anti-leakage ch. $07$+ pulito su testo student-facing (le menzioni di *attention*/*Transformer* nelle *Note docente* sono *meta-commentary* anti-trap, esattamente la clausola protettiva voluta); (c) correttezza numerica completa (item $02$: $4\,096$, $9$, $1\,048\,576$, ratio $256$; item $03$: $400 + 80 + 60 = 540$, $540 \times 2\,000 = 1\,080\,000$; item $04$: $259\,200 \times 100 = 25\,920\,000$; alternative RNN $\sim 10^3$, $1$D-CNN $3 \cdot 7 = 21$); (d) qualità distrattori (item $01$ tutti diagnostici, A è il *richest distractor*; item $03$ matrice $2 \times 2$ pulita su entrambe le assi); (e) **triade canonical-vs-practical** (item $01$ distrattore A → summative Poll $1$ → item $04$ accept) è genuinamente consistente sul principio (Obj. $1$ di chapter $06$); (f) rubriche con descrittori osservabili + soglia esplicita + clausola *"non dare ragione al collega su downsampling"* + clausola *"blocca chi invoca attention"* (entrambe pedagogicamente sane); (g) numeri degli item *diversi* da summative ($224 \times 224 \to 50\,176$ vs $9$, $T_x = 5\,000$) e da SU 1 ($5\,017\,600$) / SU 3 ($170$). 3 nice-to-have non bloccanti accettati come direzione futura (cue *"dataset size"* esplicito nella stem di item $02$-iii; etc.). **No must-fix residui.**

> **Set size note:** chapter $06$ closes at **4 items**, covering all three learning objectives with three distinct cognitive categories (Comprehension + Application × 2 + Argumentation). Unlike ch. $05$ (which closed at $3$ items, Argumentation dropped by the teacher's call), chapter $06$ *includes* the Argumentation item — Obj. $1$ + Obj. $2$ + Obj. $3$ are *jointly* testable on this chapter because the central message (*match the structure, share the weights*) collapses cleanly into one critique of a single bad-design scenario (item $04$). The Argumentation is genuinely a *synthesis* test, not a redundant Comprehension question.

> **Note on numbers:** the items use input shapes, hidden dimensions, and sequence lengths **different** from those in the chapter's summative exercise (chest X-ray $224 \times 224$ in *Card A*; ECG with $T_x = 5\,000$ in *Card B*; the FC-vs-conv comparison giving $50\,176$ vs $9$ weights — in [objectives.md](objectives.md)) and **different** from those in SU $1$ ($224 \times 224 \times 100 = 5\,017\,600$ pesi) and SU $3$ ($(5, 10, 2) \to 170$ pesi — in [subunits.md](subunits.md)). Item $02$ uses a $64 \times 64$ input (FC vs $3 \times 3$ conv); item $03$ uses an RNN with $(4, 20, 3)$ dimensions and $T_x = 2\,000$; item $04$ uses a clinical multi-channel signal at $86\,400$ samples × $3$ channels. The items measure the *procedure* — *can you count weights / write the recurrence / criticise a design from the structural principle?* — not the student's memory of any specific row of the summative or of the sub-units. Same convention as ch. $04$/$05$.

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — match an unstructured-data type to the right deep architecture; for a sequential single-information signal (ECG), name **RNN** as the canonical answer and the *order/memory* prior as the reason | Comprehension | MCQ | medium | [item_01_match-data-to-architecture_mcq.md](items/item_01_match-data-to-architecture_mcq.md) |
| 02 | Obj. 2 — describe the convolution operation on a $2$D input; count weights for a fully-connected layer on raw $64 \times 64$ ($4\,096$) vs a single $3 \times 3$ kernel ($9$); justify the convolutional count by naming **weight sharing across spatial positions**; predict how each count scales when the image resolution grows to $1024 \times 1024$ | Application | applicativa (open task, 3 sub-questions) | medium | [item_02_weight-count-fc-vs-conv_applicativa.md](items/item_02_weight-count-fc-vs-conv_applicativa.md) |
| 03 | Obj. 3 — apply the recurrent update $a^{<t>} = g(W_{aa}\, a^{<t-1>} + W_{ax}\, x^{<t>} + b_a)$: count weights of an RNN with $(4, 20, 3)$ dimensions ($540$ weights via $|W_{aa}| + |W_{ax}| + |W_{ya}|$), and recognise that the count is **independent of $T_x$** because **the same matrices are reused at every $t$** (weight sharing across time) | Application | MCQ (scenarizzato — $2 \times 2$ matrix of misconceptions: matrices counted × $T_x$-scaling) | medium | [item_03_rnn-weight-count_mcq.md](items/item_03_rnn-weight-count_mcq.md) |
| 04 | Obj. 1 + Obj. 2 + Obj. 3 (synthesis) — argue, on a clinical multi-channel time-series scenario, why a *flatten-and-feed-to-MLP* design fails on **three structural fronts** (parameter explosion, loss of temporal order, loss of multi-channel structure), and propose an alternative architecture (RNN, $1$D-CNN, or hybrid) grounded in the chapter's **weight sharing** dispositive | Argumentation / valutazione | argomentativa (open critique, 2 sub-questions) | high | [item_04_critique-flatten-and-feed_argomentativa.md](items/item_04_critique-flatten-and-feed_argomentativa.md) |

## Coverage

**By objective** (all three chapter objectives covered, *with the Argumentation item synthesising all three*):

- **Obj. 1** (match data → architecture): item $01$ (Comprehension, canonical ECG → RNN) + item $04$ (Argumentation, multi-channel signal critique).
- **Obj. 2** (convolution + weight sharing across space): item $02$ (Application, FC vs conv weight count + scaling) + item $04$ (Argumentation, parameter-explosion arm of the critique).
- **Obj. 3** (recurrent + weight sharing across time): item $03$ (Application, RNN weight count + $T_x$-independence) + item $04$ (Argumentation, alternative-architecture proposal arm).

Every objective is covered by **at least two items** — one in *isolation* (items $01$/$02$/$03$) and once again in *synthesis* (item $04$). This is the same pattern as ch. $04$ (where item $04$ argomentativa was *"the methodical colleague who thinks they're doing it right"*, a cross-technique CV trap that synthesised Obj. $1$+$2$).

**By cognitive category** (3 of 4 categories, no pure-recall item — appropriate for graduate level):

- Knowledge: $0$ *(deliberately absent — graduate-level set)*
- Comprehension: $1$ (item $01$)
- Application: $2$ (items $02$, $03$)
- Argumentation/valutazione: $1$ (item $04$)

## Rubrics

- [rubrica_02_weight-count-fc-vs-conv.md](rubriche/rubrica_02_weight-count-fc-vs-conv.md) — item $02$ (applicativa)
- [rubrica_04_critique-flatten-and-feed.md](rubriche/rubrica_04_critique-flatten-and-feed.md) — item $04$ (argomentativa)

*(Items $01$ and $03$ are MCQ — single correct option, no rubric.)*

## Internal coherence — the *canonical-vs-practical* triad

Items $01$, the summative (Poll $1$ on *Card B*), and item $04$ form a **deliberate triad** around the same pedagogical tension:

| Where | What happens | Treatment of "$1$D-CNN" |
|---|---|---|
| **Item $01$** (MCQ, exam) | The student picks RNN or CNN as the *canonical answer* for an ECG | A) **distractor** — wrong because CNN does not introduce the *memory dispositive* the chapter names |
| **Summative** (live, [objectives.md](objectives.md)) | The student picks an architecture for *Card B* (ECG) on a Slido poll | *"depends, can't tell"* is the *practical answer* — **rewarded in the reveal** as a correct observation, while RNN remains canonical |
| **Item $04$** (Argumentation, exam) | The student proposes an alternative architecture to the colleague's MLP | $1$D-CNN is **accepted as a complete answer** at *Good* on (C3), provided weight sharing across time is named — *not* penalised for "not picking RNN" |

The triad is *intentionally inconsistent on the surface* (item $01$ marks CNN wrong; item $04$ accepts $1$D-CNN as right) and *fully consistent on the principle*: the chapter teaches *the canonical answer* (RNN, because it introduces memory) **and** *the practical answer* ($1$D-CNN, because the kernel-shared-across-positions trick also encodes the time axis for short local patterns). Item $01$ measures the *canonical answer* (because that is what the *first* exam question on the chapter should pin down); item $04$ measures the *student's reasoning* (because by item $04$ they are expected to *choose* the architecture, not *receive* it). The summative bridges the two with the in-reveal teacher voice. **This triad is the principal *quality signal* of the ch. $06$ item set** — a student who reads all four items consistently has been trained to think in terms of *which dispositive the architecture encodes*, not in terms of *which acronym wins benchmarks*.

## Internal coherence — items $02$ + $03$ build the two-axis weight-sharing fluency

The two Application items are deliberately staged to give the student the **same kind of operational fluency on both axes** of weight sharing:

- **Item $02$** asks the student to *operate weight sharing across space*: count weights for a single output neuron on a $64 \times 64$ image (FC) vs a single $3 \times 3$ kernel (conv), and watch how each scales when the image grows to $1024 \times 1024$. The teachable beat is the *quadratic-vs-constant* scaling law — the same architectural decision yields different *asymptotic* behaviours.
- **Item $03$** asks the student to *operate weight sharing across time*: count weights for an RNN with $(4, 20, 3)$ dimensions ($540$ total via three matrices), and recognise that the count is **independent** of the sequence length $T_x$. The teachable beat is the *non-dependence on $T_x$* — same architectural decision, *constant* behaviour on the time axis as well.

Together, items $02$ and $03$ make the chapter's central message *operationally* concrete: *weight sharing is the same trick, with the same scaling consequence, applied to two different axes*. This is the SU $1$ frame ([subunits.md](subunits.md)) verified in two distinct numerical settings — appropriately, the SU $1$ message is delivered *narratively* in [narrative.md](narrative.md) and *visually* in frame $4$ of [storyboard.md](storyboard.md), and the items close the loop *operationally*.

## Anti-leakage — vocabulary boundary with ch. $07$+

The items stay strictly within ch. $06$ vocabulary: *image*, *sequence*, *tabular*, *MLP / fully-connected*, *kernel*, *convolution*, *feature map*, *weight sharing*, *recurrent*, *hidden state* $a^{<t>}$, *weight matrices* $W_{aa}, W_{ax}, W_{ya}$, *parameter count*, *positional invariance*, *order*, *memory*. They do **not** presuppose any concept from ch. $07$+ (*attention*, *Transformer*, *self-attention*, *encoder/decoder*, $Q$/$K$/$V$, *softmax*, *LLM*, *ChatGPT*, *agent*, *prompt design*, *API*, *token*, *pre-training*, *fine-tuning*, *transfer learning*, *SHAP*, *variable importance*, *data leakage* in the formal cross-validation-discipline sense). The rubric of item $04$ *actively protects* the boundary: a student who proposes attention or Transformer as the alternative is **blocked in correction** with a margin note (*"ottima curiosità, ma fuori dallo scope dell'esame su ch. $06$"*) — see rubric $04$'s "Bias da evitare in correzione" section.

The pre-hook to ch. $07$ (discharge letter, long-range dependency across positions $5$ and $42$) is staged in the chapter's [narrative](narrative.md) (*"only the rule of repetition does — one more time"*) and in [storyboard frame $6$](storyboard.md) (discharge letter on the back horizon with the fading dotted arrow), *not* inside the items.

## Bridges that DO appear in the items

The items make *backward* references where they earn the student's recognition:

- **Item $01$**'s distractor A explicitly names the $1$D-CNN as a *practical answer* (forward consistency to item $04$ and to the summative).
- **Item $02$**'s sub-question (iii) (jump $64 \to 1024$) replays SU $1$'s scaling argument on new numbers (*not* a citation of SU $1$, but the same intellectual move).
- **Item $03$**'s decomposition $|W_{aa}| + |W_{ax}| + |W_{ya}|$ replays SU $3$'s formative *solved* on new dimensions ($170$ → $540$).
- **Item $04$**'s critique uses the *summative's principle* (Obj. $1$: *the architecture must respect the structure of the data*) as the unifying frame — making explicit, in argumentative form, what the summative tests in operational form.

These backward references are *not* leakage: they are the *consistency* the chapter is designed to teach.

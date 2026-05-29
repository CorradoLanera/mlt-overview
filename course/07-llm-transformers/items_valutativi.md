# Item bank — 07 LLMs & Transformers

> Chapter: `07-llm-transformers` · MLT course (UBEP, biomedical/clinical graduate students).
> Generated 2026-05-29. Items student-facing in **English**; rubrics 3-level (Base/Good/Excellent).
> Review: `assessment-reviewer` ✓ **APPROVED** (2026-05-29) after applying two fixes: **SI-1** (high priority) — removed an orphan forward-reference to `ch. 08 Obj. 3` from the distractor-D paragraph of [item 03](items/item_03_transfer-learning-asymmetry_mcq.md) expected-answer, which violated the anti-leakage rule the index itself declares (no *channel taxonomy* vocabulary in ch. 07 items); the argumentative discrimination B-vs-D is preserved with self-contained wording. **SI-2** (cosmetic) — added an explicit clarification to [item 02](items/item_02_long-range-dependency_applicativa.md) that em-dashes and commas are *not* tokenised in the stylised word-level scheme used by the item, removing a possible ambiguity in the $T_x = 33$ count. Anti-leakage check from ch. 08+ (7-slot prompt, role/context/task/instructions/output/style/examples, competence rule, Web/Prompt design/API channel taxonomy, token cost, agent, tool, loop, trust boundary, reversibility, human-in-the-loop) held cleanly across all three items + the one rubric after fixes. Numerical verification on item 02 ($T_x = 33$, position 5 → 31 → $26$ recurrence applications, entry $(31, 5)$ of $Q K^{\top}$, sensitivity $T_x = 1000 \Rightarrow 999$ vs $1$) passed; clinical plausibility (AF excluded by discharge summary but paroxysmal episodes documented on $48$-hour Holter) confirmed. Distractor design on items 01 and 03 confirmed sound — each distractor maps to a *real misconception* (B = parametric vs pre-trained, C = guard-rail vs autoregressive sampling, D = fine-tune step vs Transformer architecture on item 01; A = train-from-scratch confusion, C = pre-train-asymmetry on the wrong axis, D = use-cheap-side-only on item 03). No further fixes required.

> **Set size note:** chapter 7 closes at **3 items**, following the same teacher's-call applied to [chapter 5](../05-deep-learning/items_valutativi.md): the Argumentation/evaluation item that would have completed a four-category bank was deliberately dropped, for two reasons. (i) The chapter's $25'$ budget is already carrying a dense conceptual load — *decode Chat-G-P-T*, *self-attention vs RNN with a concrete sentence*, *transfer-learning economics on a concrete project budget* — and a fourth open-ended item would dilute, not deepen. (ii) The Argumentation move most natural to this chapter — *"argue whether your group should fine-tune or use zero-shot for the ICD-coding task"* — is in fact already operationally tested by item 03's distractor analysis (option D), where the wrong choice is "realistic for the budget but for the wrong reason"; **the argumentation move is built into how the MCQ discriminates between B and D**, rather than being delegated to a separate open item. The Argumentation category is *intentionally absent* from this chapter's item bank; the chapter still verifies all three learning objectives across two distinct cognitive categories (Comprehension + Application).

> **Note on numbers and scenarios:** the items use **architectures, sentences, and budget figures different** from those of the chapter's summative exercise (Sentence S with *denies / contradicts*, the $4 \times 2$ Chat-G-P-T table, and the $\sim 10^4$ Poll 2 on pre-train/fine-tune cost ratio — see [objectives.md](objectives.md)). Item 01 uses a *new candidate decoding* of *Chat-G-P-T* with three distinct mis-decodings as distractors (T → Tuned, P → Parametric, G → Guard-railed) rather than the four-cell decode-table of the summative. Item 02 uses a **different clinical sentence** (atrial-fibrillation discharge summary with a $T_x = 33$, dependency between positions $5$ and $31$) with **explicit position indices** to make the RNN count $31 - 5 = 26$ and the $Q K^{\top}$ entry $(31, 5)$ procedurally derivable — not memorisable. Item 03 uses an **ICD-coding scenario** with concrete budget ($\$50\,000$), data ($2\,000$ letters), and *specific* cost figures ($\sim \$10^7$ pre-train, $\sim \$10^3$ fine-tune), distinct from the fragility-fracture audit on $200$ ED letters used in the summative. The items measure the *procedure* and the *concept*, never the recall of the summative's specific instances. Same convention as ch. 04 and ch. 05.

## Item ↔ objective map

| ID | Learning objective | Category | Type | Difficulty | File |
|---|---|---|---|---|---|
| 01 | Obj. 1 — decode the acronym *Chat-G-P-T* backwards, mapping each letter to its technical contribution: T = Transformer (self-attention architecture); P = Pre-trained (massive generic corpus before any user task); G = Generative (autoregressive sampling from $p(\text{token} \mid \text{prompt})$); Chat = multi-turn dialogue wrapper. Recognise that each letter sits at a *distinct layer of the system* — architecture / training regime / inference mechanism / interface | Comprehension | MCQ | low–medium | [item_01_chat-gpt-decoded_mcq.md](items/item_01_chat-gpt-decoded_mcq.md) |
| 02 | Obj. 2 — contrast Transformer self-attention with the RNN's sequential hidden state on a sequence of length $T_x$. Given a clinical sentence with explicit position indices, identify the long-range dependency, count the recurrence applications an RNN needs to propagate it, and locate the single entry of $Q K^{\top}$ that captures the same dependency in one step | Application | applicativa | medium | [item_02_long-range-dependency_applicativa.md](items/item_02_long-range-dependency_applicativa.md) |
| 03 | Obj. 3 — explain transfer learning as the operational meaning of "Pre-trained". Given a clinical-research scenario (ICD-coding from discharge letters, fixed budget, fixed corpus size, pre-trained LLM available via API), choose the option that uses **both halves** of the pre-train / fine-tune asymmetry — at the right cost order ($\$10^3$ adaptation of someone else's $\$10^7$ pre-training) and for the right reason (task-adaptation, not budget-fit alone) | Application | MCQ (scenario) | medium | [item_03_transfer-learning-asymmetry_mcq.md](items/item_03_transfer-learning-asymmetry_mcq.md) |

## Coverage

**By objective** (all three chapter objectives covered, one item per objective):

- **Obj. 1** (Chat-G-P-T decoded backwards): item 01 (Comprehension).
- **Obj. 2** (self-attention vs RNN on a sequence of length $T_x$ — long-range dependency + matrix entry): item 02 (Application, applicativa).
- **Obj. 3** (transfer learning as operational meaning of *Pre-trained* + cost asymmetry): item 03 (Application, MCQ scenario). The *budget-respecting-but-wrong* distractor (option D, zero-shot via API) discriminates students who use *only* the cheap side of the asymmetry from those who use *both* halves — the chapter's pedagogical point.

**By cognitive category** (2 of 4 categories, no pure-recall item; Argumentation absent by design — see set-size note above):

- Knowledge: 0
- Comprehension: 1
- Application: 2
- Argumentation/evaluation: 0

## Rubrics

- [rubrica_02_long-range-dependency.md](rubriche/rubrica_02_long-range-dependency.md) — item 02 (applicativa).

*(Items 01 and 03 are MCQ — single correct option, no rubric.)*

## Internal coherence — items 02 and 03 build the operational fluency the chapter requires

The two Application items are deliberately staged so the student must *operate* the two halves of the chapter's payoff:

- **Item 02** asks the student to *operate the architectural contrast* — given a concrete clinical sentence with explicit positions, derive *numerically* that the RNN must apply its recurrence $26$ times to propagate a dependency that the Transformer captures in **one** entry of $Q K^{\top}$. The teachable beat is the sensitivity question at the end: stretching the sentence to $T_x = 1000$ blows the RNN count to $999$ while leaving the Transformer count at $1$ — the *scale-independence* of the Transformer's path length is the architectural reason it replaced the RNN.
- **Item 03** asks the student to *operate the economic contrast* — given a real-looking clinical-research budget and dataset size, pick the option that uses the $\sim 10^4$ pre-train / fine-tune asymmetry as *the* lever that makes biomedical LLM applications realistic. The teachable beat is the distractor analysis: option D (zero-shot via API) is *budget-respecting but for the wrong reason*, and a student who picks it has used the cheap inference cost of someone else's pre-training without using fine-tuning to *adapt* the model to the task at hand.

Together, items 02 and 03 cover both axes on which the chapter justifies why the Transformer replaced the RNN: the **architectural axis** (parallel matrix multiplication scales on GPUs in a way that the RNN's sequential loop cannot — item 02) and the **economic axis** (transfer learning makes biomedical applications feasible at a fraction of from-scratch cost — item 03). Item 01 then anchors the *naming* that lets both contrasts be discussed without ambiguity (T, P, G, Chat as distinct layers of the system).

## Anti-leakage — vocabulary boundary with ch. 08+

The items stay strictly within ch. 07 vocabulary: *Transformer*, *self-attention*, *query / key / value*, *$Q K^{\top}$*, *softmax*, *pre-trained*, *pre-training*, *fine-tuning*, *generative*, *autoregressive*, *Chat*, *RNN / recurrence* (the latter as recap from [ch. 06](../06-unstructured-data/objectives.md), not as new content). They do **not** presuppose any concept from ch. 08+ — no *7-slot prompt template*, no *role / context / task / instructions / output / style / examples*, no *competence rule*, no *Web / Prompt design / API* channel taxonomy, no *token cost rule of thumb*, no *agent*, no *tool*, no *loop*, no *trust boundary*, no *reversibility*, no *human-in-the-loop*, no *do stuff / ask for interaction / ask for sharing / autonomous search*. The chapter's pre-hook to ch. 08 (Monday morning, $200$ ED letters — *"how do you ask?"*) is staged in the chapter's [narrative](narrative.md) and [storyboard frame 6](storyboard.md), *not* inside the items.

## Pre-hook to ch. 08 — left to the chapter, not embedded in items

Same convention as ch. 04 → ch. 05 and ch. 05 → ch. 06: the items measure what *this* chapter has taught, with no forward references; the *narrative* and *storyboard* of the chapter carry the bridge to the next one. A student who has mastered the three items has *named* the four letters of *Chat-G-P-T*, *operated* the serial-vs-parallel contrast on a concrete sentence, and *picked* the right transfer-learning option on a concrete budget — and is exactly the student that ch. 08 will then teach to *use* the box on Monday morning.

# Item 01 — Chat-G-P-T decoded backwards

**ID**: IB-07-llm-transformers-01
**Learning objective**: Decode the acronym *Chat-G-P-T* backwards, naming for each letter the **technical contribution** that letter encodes — **T** = Transformer (the architecture built around self-attention, in which every token's representation is computed as a weighted combination of every other token in the input, in parallel); **P** = Pre-trained (the model has already learned a general statistical model of language by reading a massive generic corpus, *before* it sees any user task); **G** = Generative (at inference the model produces the next token by sampling from $p(\text{token} \mid \text{prompt})$ and feeding that token back as input — *autoregressive*); **Chat** = the multi-turn dialogue wrapper (Obj. 1).

**Category**: Comprehension
**Type**: MCQ
**Difficulty**: low–medium
**Chapter**: 07-llm-transformers

## Question

A clinical colleague at a journal club says: *"OK so it's Chat-G-P-T — four letters. Walk me through them, backwards, and tell me what each one actually means."* Among the four decodings below, **which one correctly maps each letter of *Chat-G-P-T* to the technical contribution that letter encodes**, as introduced in this chapter?

## Options

- A) **T** = *Transformer*: a stack of self-attention blocks in which every token attends every other token in parallel. **P** = *Pre-trained*: the model has already learned a general statistical model of language by reading a massive corpus, *before* it sees any user task. **G** = *Generative*: at inference, the model produces the next token by sampling from $p(\text{token} \mid \text{prompt})$ and feeds that token back as input — autoregressive generation, one token at a time. **Chat** = the multi-turn dialogue wrapper that keeps the conversation as part of the prompt.
- B) **T** = *Transformer*: a stack of self-attention blocks (every token attends every other in parallel). **P** = *Parametric*: the model is parametric — it has billions of learnable parameters, in contrast to non-parametric methods such as $k$-nearest-neighbours. **G** = *Generative*: autoregressive sampling from $p(\text{token} \mid \text{prompt})$. **Chat** = the multi-turn dialogue wrapper.
- C) **T** = *Transformer*: a stack of self-attention blocks. **P** = *Pre-trained* on a massive corpus. **G** = *Guard-railed*: the model has built-in safety filters that prevent it from producing harmful or off-policy outputs. **Chat** = the multi-turn dialogue wrapper.
- D) **T** = *Tuned*: the model has been fine-tuned to follow user instructions. **P** = *Pre-trained*: the model was first pre-trained on a generic corpus, then tuned. **G** = *Generative*: autoregressive next-token sampling. **Chat** = the multi-turn dialogue wrapper.

## Expected answer

**Correct: A.** The chapter decodes *Chat-G-P-T* backwards as a stack of **three engineering choices** (T → Transformer architecture; P → Pre-training on a massive generic corpus; G → autoregressive generative sampling) **wrapped in one UI choice** (Chat → multi-turn dialogue protocol). Each of the four contributions is *operationally distinct* and is named in the chapter's [arc](../narrative.md) and [Obj. 1 of objectives.md](../objectives.md). A is the only option that maps each letter correctly.

Why the distractors are plausible but wrong:

- **B** is wrong on the **P**. Calling the model "Parametric" is *true* of the model — every neural network has parameters — but it is **not what the letter encodes**. The "P" of *GPT* refers to **Pre-training** as a *temporal/economic* concept: the model has been *trained on a corpus before any user task arrives*. That temporal "pre-" is what makes **transfer learning** (Obj. 3) realistic — a fine-tuning step on a small task-specific dataset adapts the already-pre-trained model at a fraction of the cost. Conflating *parametric* with *pre-trained* loses the chapter's core economic insight (the $\sim 10^4$ pre-training/fine-tuning asymmetry).
- **C** is wrong on the **G**. *Guard-railing* (RLHF / instruction-tuning to refuse certain outputs) is a real, important *post-hoc safety intervention* that several deployed LLMs receive — but it is **not what the letter encodes**. The "G" of *GPT* refers to **Generative**, i.e. the model produces output by *autoregressive sampling* from $p(\text{token} \mid \text{prompt})$. A student who picks C has confused a *product-level safety feature* with the *architectural mechanism* of generation. The chapter is explicit about this: the autoregressive token-by-token cascade is *how* the box generates; guard-rails are *which* generations are kept.
- **D** is wrong on the **T**. Calling T = "Tuned" *swaps* the architectural meaning of T (Transformer) for an *operational* meaning that does not fit. *Fine-tuning* is real (it is exactly Obj. 3), but it does not belong inside the four letters — the letter "T" refers to the **2017 *"Attention is all you need"* architecture** built around self-attention. A student who picks D has lost the distinction between the *architecture* (what kind of object the model is) and the *training stage* (how it was prepared). In particular: the same Transformer architecture can be used with no fine-tuning at all (pre-trained-only models), so "T" cannot mean *tuned*.

The single discriminator is whether **each letter is mapped to the right technical layer of the system**: architecture (T), training regime (P), inference mechanism (G), interface (Chat). Only A holds all four at the right layer.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

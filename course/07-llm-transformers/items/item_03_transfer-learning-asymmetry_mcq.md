# Item 03 — Transfer learning asymmetry: which option is realistic, and *for the right reason*?

**ID**: IB-07-llm-transformers-03
**Learning objective**: Explain transfer learning as the operational meaning of "Pre-trained" — a single expensive pre-training run on a massive generic corpus produces a model that already knows the general statistics of language; a much cheaper fine-tuning step adapts this model to a specific task using a *small* task-specific dataset. State the cost/benefit clearly: fine-tuning needs orders of magnitude less data and compute than training from scratch, and that asymmetry is what makes biomedical applications of LLMs realistic at all (Obj. 3).

**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 07-llm-transformers

## Question

A research group at a teaching hospital wants to build a model that **auto-codes ICD-10 diagnoses from free-text discharge letters**, to feed a quality-improvement audit. They have:

- a corpus of **$N = 2\,000$** manually-coded discharge letters from their EHR (one diagnosis label per letter, validated by senior coders);
- a research grant of **$\$50\,000$** in total;
- access to a state-of-the-art **pre-trained $7$ B-parameter LLM** via a commercial API (the API supports both zero-shot inference and fine-tuning on a custom dataset).

For order-of-magnitude reasoning, take **typical compute costs** as: pre-training a $7$ B LLM *from scratch* on a generic corpus $\sim \$10^7$; fine-tuning the same already-pre-trained $7$ B LLM on a small task-specific dataset $\sim \$10^3$.

Among the four options below, **which one uses the chapter's pre-train / fine-tune asymmetry to deliver task-specific quality within budget — *and for the right reason*?**

## Options

- A) **Train the $7$ B LLM from scratch** on the $2\,000$ discharge letters: the group would own the model end-to-end, and the resulting model would be perfectly specialised on their data.
- B) **Fine-tune the pre-trained $7$ B LLM** on the $2\,000$ discharge letters: the pre-trained model already encodes general language statistics; fine-tuning *adapts* that model to the ICD-coding task using a small task-specific dataset, at a fraction of the cost of training from scratch.
- C) **Pre-train a smaller custom $100$ M LLM from scratch** on the $2\,000$ discharge letters, then fine-tune it on the same letters: a smaller model from scratch will both fit the budget *and* be specialised on the group's own data, side-stepping the dependence on the commercial provider.
- D) **Use the pre-trained $7$ B LLM zero-shot** via the API, with no fine-tuning: the model has already seen vast amounts of text including some biomedical writing, so zero-shot performance on ICD coding should be acceptable, and the cost stays minimal.

## Expected answer

**Correct: B.** The chapter's central economic claim about LLMs is the **asymmetry between pre-training and fine-tuning**: pre-training costs are on the order of $\$10^7$ (or larger, for frontier models), while fine-tuning costs are on the order of $\$10^3$ — a ratio of about $10^4$, *four orders of magnitude*. This asymmetry is *what makes biomedical applications of LLMs realistic at all*: no clinical research group will pre-train its own LLM, but a clinical research group with a small task-specific corpus can plausibly *fine-tune* one.

Option B uses both halves of the asymmetry: it benefits from someone else's expensive pre-training (the commercial provider has already spent the $\$10^7$ for them) **and** spends the cheap $\$10^3$ to adapt the model to the specific ICD-coding task. The pre-trained model encodes the *general statistics of language*; fine-tuning *adapts* that to the *specific* mapping from discharge-letter text to ICD codes. The full $\$50\,000$ budget covers fine-tuning many times over, leaving headroom for API inference at deployment.

Why the distractors are plausible but wrong:

- **A** is wrong on **cost**, but also wrong on *what the cost is for*. Training a $7$ B LLM from scratch on $2\,000$ letters would (i) blow the $\$50\,000$ budget by roughly **$200\times$** (over two orders of magnitude — $\sim \$10^7$ versus $\sim \$5 \cdot 10^4$); (ii) produce a **catastrophically under-trained** model — $2\,000$ letters is *vastly* too small a corpus to teach a $7$ B-parameter network the statistics of language from scratch (pre-training corpora are measured in trillions of tokens, not thousands of letters). The student who picks A has missed *why* pre-training exists in the first place: to absorb language structure from a corpus orders of magnitude larger than any single task could provide.
- **C** is wrong because it **defeats the asymmetry entirely**. Pre-training a custom $100$ M model from scratch on $2\,000$ letters has the same disease as A — the corpus is wildly too small for from-scratch language modelling — only at a different scale of waste. The whole **point** of transfer learning is that *you do not pre-train; you reuse someone else's pre-training*. Choosing C signals that the student has *heard* the words "pre-train" and "fine-tune" but has not internalised that the asymmetry is between *reusing* a pre-trained model and *training one from scratch*, not between *two sizes* of from-scratch training.
- **D** is the **trickiest distractor** because it is *budget-respecting and not obviously wrong*. Zero-shot use of a strong pre-trained LLM via API is a real, sometimes appropriate choice for *one-off ad-hoc queries* — but it is **orthogonal** to building a *structured task-specific* pipeline like ICD-10 coding. For structured task-specific work, zero-shot performance is typically *mediocre* — the model has read about ICD codes in passing during pre-training but has not been *adapted* to the specific mapping of *this hospital's* discharge-letter style to *its* coding conventions. Fine-tuning closes precisely that adaptation gap. The student who picks D has *used the cheap side* of the asymmetry but has *left task adaptation on the table* — and "uses the chapter's asymmetry" requires using *both* halves (cheap fine-tuning *of* an expensive pre-trained model), not just the cheap inference of an unadapted model. **D is "realistic for the budget, but for the wrong reason."**

The single discriminator is whether the student recognises that **the pre-train / fine-tune asymmetry is what makes B distinctive** — not budget-fit alone, not data-ownership, not zero-shot convenience. Only B uses both halves of the asymmetry as the chapter introduces it.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

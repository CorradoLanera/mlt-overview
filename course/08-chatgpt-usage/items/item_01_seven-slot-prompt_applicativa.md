# Item 01 — Build a 7-slot prompt: surgical-procedure extraction from operative notes

**ID**: IB-08-chatgpt-usage-01
**Learning objective**: Construct a structured prompt for a given clinical task using the **7-slot template** — *role*, *context*, *task*, *instructions*, *output*, *style*, *examples* — and justify, for each slot used, which failure mode is suppressed by that slot. Operate the construction on a clinical scenario different from the chapter's summative, and reason about which slots are *most* and *least* load-bearing for the specific task (Obj. 1).

**Category**: Application
**Type**: applicativa
**Difficulty**: medium
**Chapter**: 08-chatgpt-usage

## Question

A clinical research team at your hospital has a corpus of approximately **$100$ surgical operative notes** (average length $\sim 350$ words each, free-text, written by surgeons of varying styles). They want to extract, from *each* note, the **primary surgical procedure** — a single short label, e.g. *"laparoscopic cholecystectomy"*, *"open right hemicolectomy"*, *"emergency exploratory laparotomy"*. The output will feed an internal quality-improvement audit.

You are asked to write the **prompt** that the team will use. (Channel choice and token cost are not asked here — only the prompt itself.)

Answer the three sub-questions below in order.

### Sub-question 1 — fill the 7-slot prompt

Construct a prompt for this task using **all seven slots** of the template. Write each slot on its own line, labelled, in the form *"slot-name: content of that slot"*. The content of each slot must be **specific to this task** — generic boilerplate that would apply to *any* clinical task does not count.

The seven slots are:

- **role** — who the model is impersonating
- **context** — the situation the task lives in
- **task** — the *one* verb the model must perform
- **instructions** — the procedure to follow
- **output** — the exact shape of the deliverable
- **style** — constraints on tone, format, and *what not to add*
- **examples** — one or two short worked input/output pairs

### Sub-question 2 — justify the slots the chapter's summative does *not* focus on

The chapter's summative exercise focuses on the *task* and *output* slots as the two most load-bearing for the *trauma vs non-trauma* triage. For **this** item (procedure extraction), justify in **one sentence each** which **specific failure mode** is suppressed by each of the following three slots:

- **role**
- **style**
- **examples**

A "failure mode" is a *concrete, namable wrong behaviour* the model would exhibit if that slot were absent (e.g. *"the model would return a paragraph instead of a single phrase"*, *"the model would invent a procedure not actually named in the note"*). Vague justifications (*"makes the answer better"*, *"clarifies the request"*) do not count.

### Sub-question 3 — most and least load-bearing slots for *this* task

Among your seven slots, identify:

- **(a)** the **one slot** that, **if removed**, would degrade the model's output the **most** on this surgical-procedure-extraction task. State which slot and justify in one sentence — naming the *specific* failure mode that removal would cause.
- **(b)** the **one slot** that, if removed, would degrade the model's output the **least** on this same task. State which slot and justify in one sentence — naming why this task happens to *not* depend strongly on that slot.

A defensible answer to (b) is **task-dependent**: a slot that is least load-bearing here may be highly load-bearing in another task. Your justification must be tied to the specifics of *procedure extraction from operative notes*, not to a generic ranking of the slots.

## Expected answer

### Sub-question 1 — model 7-slot prompt

A defensible filling of the seven slots looks like this (variants in wording are acceptable provided each slot is *specific* to the surgical task):

- **role**: *"You are a clinical-coding assistant for an internal hospital quality-improvement audit on surgical activity."*
- **context**: *"You are reading anonymised operative notes written by surgeons of a single tertiary hospital; the audit aggregates procedure counts by type for internal reporting and is not patient-facing."*
- **task**: *"Extract the primary surgical procedure performed."*
- **instructions**: *"Read the operative note's *procedure performed* section and the *operative summary* paragraph; if a single primary procedure is named, return it. If multiple procedures are named, return the one listed first in the *procedure performed* heading. Do not infer the procedure from the indication or from the post-operative diagnosis."*
- **output**: *"Return a single short label in the form '<approach> <procedure>' — e.g. 'laparoscopic cholecystectomy', 'open right hemicolectomy'. If the operative note does not contain a clearly named procedure, return the literal token 'UNCLEAR'."*
- **style**: *"No explanation, no caveats, no qualifications, no preamble. Only the label or 'UNCLEAR'. Do not invent abbreviations not used by the surgeon."*
- **examples**: two short pairs, e.g. *Input: "...procedure performed: laparoscopic cholecystectomy. Operative summary: ..."* → *Output: "laparoscopic cholecystectomy"*; *Input: "...converted to open right hemicolectomy after extensive adhesions..."* → *Output: "open right hemicolectomy"*.

A response that fills all seven slots with task-specific content (not generic boilerplate, not a re-wording of the slot's own definition) is at *Base*; a response that nails *output* with the **'UNCLEAR' literal escape token** is at *Good* (the escape is what stops the model from inventing a procedure when the note doesn't name one); a response that includes in *instructions* the **disambiguation rule for multi-procedure notes** (*"return the one listed first in the heading"*, or any equivalent priority rule) is at *Excellent* (this rule is what stops two correctors from disagreeing on the same note).

### Sub-question 2 — failure-mode justifications for *role*, *style*, *examples*

- **role**: without *role*, the model's voice would default to **conversational helpfulness** — it would write "*The procedure performed in this note appears to be a laparoscopic cholecystectomy.*" instead of returning the bare label, *or* it would add caveats ("*based on what is described, it seems...*") that an audit script cannot parse. Naming the role as a *clinical-coding assistant* forces the laconic, label-only voice of a structured-data extraction task.
- **style**: without *style*, the model would, on most operative notes, *explain its choice* — adding a one-sentence justification after the label, or wrapping the label in a markdown header, or adding a confidence qualifier ("*likely*"). For an audit that expects *one row per note, one cell per row*, these additions break downstream parsing silently. The style slot kills the explain-along-the-way reflex.
- **examples**: without *examples*, the model would handle the clean cases correctly but **drift on the structurally ambiguous cases** — converted procedures (*"started laparoscopic, converted to open"*), staged procedures (*"first stage ileostomy creation, second stage planned"*), or notes that name the surgical *approach* in one sentence and the *procedure* in another. The two worked examples anchor the disambiguation rule of *instructions* in a concrete pair the model can pattern-match against — without the pair, the rule is parsed but not necessarily applied.

### Sub-question 3 — most and least load-bearing slots for this task

**Most load-bearing: *output*.** The task is a *structured-data extraction*, and the audit depends on every single response being a parseable label (or the literal 'UNCLEAR' escape). Without *output*, the model would produce **prose** rather than a label on the majority of notes — and prose, even when correct, is unusable for the audit's downstream aggregation. Removing *output* would break the workflow on every note, not just the hard ones. (A response naming *task* as most load-bearing is *also defensible* — the verb "extract" is what makes this a structured task in the first place — and should be accepted at *Base* with a one-sentence justification.)

**Least load-bearing: *role*** (for *this* task). The task is sufficiently *structured* by the combination of *task*, *output* and *examples* that the model would produce parseable labels even without an explicit role tag. The *role* slot is a *style amplifier* here — it makes the voice more reliably laconic — but the labels would still be extractable from a model that received the other six slots. Note that **role is highly load-bearing in other tasks** (e.g. patient-facing leaflet writing, where without the role the model would not know whether to address a clinician or a patient) — the answer here is *specifically* about procedure extraction.

A defensible *alternative* answer for least load-bearing is **context** — for the same reason — provided the student names what *context* would add for a different task (e.g. discriminating between research and clinical use of the output). What is *not* defensible is naming *output* or *task* as least load-bearing — those are the spine of any extraction task.

## Rubric

See [rubrica_01_seven-slot-prompt.md](../rubriche/rubrica_01_seven-slot-prompt.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

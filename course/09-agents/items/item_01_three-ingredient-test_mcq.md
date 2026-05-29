# Item 01 — Agent or not-agent: the three-ingredient test

**ID**: IB-09-agents-01
**Learning objective**: Distinguish an *agent* from a plain *chat-LLM* by applying the three operational ingredients introduced in the chapter — **tools** the model can invoke, a **control loop** that picks the next tool after every model reply, and **decision points** at which the agent enters one of the four interaction modes (*autonomous search* / *ask for interaction* / *ask for sharing* / *do stuff*). Recognise the operational consequence: in a chat, *every output reaches a human before it becomes an action*; in an agent, *some outputs become actions without a human reading them first* (Obj. 1).

**Category**: Comprehension
**Type**: MCQ
**Difficulty**: medium
**Chapter**: 09-agents

## Question

A clinician on your research team has been browsing AI-assisted tools that other colleagues have set up over the last few months. She wants to know which of the four setups below counts as an **agent**, by the chapter's three-ingredient definition (*tools + control loop + decision points*, such that *some outputs become actions without a human reading them first*).

Among the four setups below, **which one is an agent**?

## Options

- A) A chat-LLM running in a browser tab. The user types each query, the model responds, and the user copies the response into a Word document. The model has access to a built-in web-search tool, but the model only invokes it when the user explicitly types `search:` at the start of the query.
- B) A clinical-note autocomplete integrated in the EHR's note-editor. As the clinician writes the note, the model suggests the next sentence based on what has been written so far; the clinician accepts, rejects, or edits each suggestion before it appears in the note. The model has no other capability beyond producing the next-sentence suggestion.
- C) A research helper configured as follows: the user types a goal in natural language (e.g., *"summarise the latest delirium-screening guidelines and email the one-page summary to me"*); the system then calls a search tool, reads results, calls a summariser, drafts an email, and sends it — each step picked by the model itself after reading the previous step's output, with no human input between steps until completion.
- D) A scheduled job that, every Monday at $9$ AM, queries the EHR data warehouse for the previous week's incident reports, calls an LLM once to write a short summary paragraph, assembles the paragraph into a PDF template, and uploads the PDF to the team's shared drive. The sequence of steps is fixed by the script; the LLM is invoked exactly once, to produce the summary text.

## Expected answer

**Correct: C.** Setup C is the only one that carries all three of the chapter's defining ingredients:

- **Tools**: the system can invoke a search tool, a summariser, a drafter, and a mail client.
- **Control loop**: after every model reply, the model itself picks which tool to call next (or whether to stop) — the loop is the model's loop, not a human's and not a script's.
- **Decision points**: at several points the agent is in *autonomous search* (gathering information on its own), and at the final step it is in *do stuff* mode (sending the email — an action with external effect).

The operational test confirms the diagnosis: **some outputs become actions without a human reading them first** — specifically, the email's body is drafted and sent before any human has read it. That is the boundary the chapter draws around the agent category.

Why the distractors are plausible but wrong:

- **A** is wrong because **only the first ingredient (tools) is present**: the web-search tool exists, but the *control loop* and the *decision points* are still entirely human-driven (the user types each query; the user types `search:` to invoke the tool; the user copies the answer; *every* output reaches the user before it becomes anything). A student who picks A has read *"has tools"* as sufficient for agency, missing that the chapter's definition requires **all three** ingredients together. The operational test — *do any outputs become actions without a human reading them first?* — returns **no** for setup A: nothing the model produces leaves the chat window without the user reading it.
- **B** is wrong on **two ingredients**: the autocomplete has *no tools* (it produces text only) and *no control loop* (each suggestion is independent — there is no model-driven sequence). The clinician's hand-on-the-keyboard sits *between* every model output and any consequence of that output (the note is updated only if the clinician accepts the suggestion). A student who picks B has confused *"the model is doing something on its own continuously"* (it is generating predictions) with *"the model is taking actions on the world"* (it is not). The operational test — *do any outputs become actions without a human reading them first?* — returns **no** for setup B: the clinician is in the loop on every suggestion.
- **D** is the **subtlest distractor**, because the setup *looks like* an agent at first glance — a scheduled pipeline that runs autonomously, uses tools (database, file write, shared drive), calls an LLM, and produces an external artefact (the PDF on a shared drive) without a human reading the summary first. But the chapter's definition is *operationally specific* about what counts as the loop: **the loop is the policy that, after every model reply, picks the next tool to invoke or stops** — that is, the *model* picks the next step based on what it just produced. In setup D, the *cron script* picks every step in a fixed order, regardless of what the model says; the LLM is invoked **exactly once**, as a single text-generation step embedded in a deterministic pipeline. This is **automation with an LLM inside**, not an agent. The model never decides anything — it returns one paragraph, and the script does the rest. A student who picks D has confused *"the pipeline runs without me"* (automation) with *"the model decides what runs next"* (agency). **Important precision:** the chapter's *operational consequence* (*some outputs become actions without a human reading them first*) does technically *describe* D — the PDF reaches the shared drive without anyone reading it — but the chapter presents this consequence as the **diagnostic test of agency**, not as its **definition**. The three-ingredient definition (*tools $\wedge$ loop $\wedge$ decision-points*, with the loop being the **model's** loop) is the **gating criterion**; the operational consequence is what *follows* from satisfying all three. D satisfies the consequence by *accident* (a scheduled script with an LLM call inside also produces external effects without human reading) but fails the *loop* ingredient — and so D is *automation*, not an *agent*. The distinction is the same one as between a self-driving car (the *car* does not read the road; the *driving model* does — a model-driven loop) and a Roomba on a timer (no model, just a schedule — a script-driven loop). Both run without human reading; only one is an agent.

The single discriminator across A/B/C/D is whether the student reads the chapter's definition **conjunctively** (*all three* ingredients required, *and* the loop must be the model's loop) — which selects C — or **partially** (any one ingredient suffices, *or* "the model produces text autonomously" is enough) — which leads to A, B, or D depending on which ingredient the student over-weighs. Only C passes the full three-ingredient test.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

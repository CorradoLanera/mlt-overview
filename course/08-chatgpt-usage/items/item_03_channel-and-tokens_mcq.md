# Item 03 — Channel choice and token cost: a recurring ophthalmology classification

**ID**: IB-08-chatgpt-usage-03
**Learning objective**: Choose the right access mode (Web chat / Prompt design in chat / API) for a given workflow and estimate its token cost using the rule of thumb $1$ token $\approx \dfrac{3}{4}$ word. Recognise that channel choice depends not only on per-run volume but also on **recurrence and integration** — a workflow that fits prompt-design-in-chat on a *one-shot* per-run basis still flips to API once it must be repeated on a schedule and feed downstream automation (Obj. 3).

**Category**: Application
**Type**: MCQ (scenario)
**Difficulty**: medium
**Chapter**: 08-chatgpt-usage

## Question

A clinical research team in ophthalmology wants to classify **consultation notes** as *"diabetic retinopathy mentioned"* vs *"diabetic retinopathy not mentioned"*. The notes are free-text, average $\sim 250$ words each. The classification will run as follows:

- per run: **$40$ new consultation notes**;
- recurrence: **once per month**, for the next **$6$ months**, as new notes accumulate in the EHR export;
- destination: the output (one label per note) feeds a research database that already has a monthly import script expecting a CSV with two columns (`note_id`, `label`).

For an estimate to within $\sim \pm 20\%$, use the chapter's rule of thumb $1$ token $\approx \dfrac{3}{4}$ word.

Among the four options below, **which option is the correct channel choice for this workflow — and roughly what is the input-token cost per run?**

## Options

- A) **Web chat**, $\sim 7\,500$ input tokens per run. *(Reasoning: $40$ notes is a manageable copy-paste session; the team can re-do it monthly.)*
- B) **Prompt design in chat**, $\sim 13\,300$ input tokens per run. *(Reasoning: $40$ notes is at the low-volume end where a structured prompt delivered by hand through the chat UI is most efficient — well below the threshold at which API integration becomes worthwhile.)*
- C) **API**, $\sim 13\,300$ input tokens per run. *(Reasoning: the workflow is **recurring monthly** and feeds a **downstream import script** — these two properties together require programmatic delivery, regardless of the fact that any **single** run's volume of $40$ items would otherwise fall in the prompt-design range.)*
- D) **Do it by hand without an LLM**, $0$ tokens. *(Reasoning: $40$ notes per month is a small enough batch that a trained reviewer can label them all in an afternoon; the LLM adds operational overhead without enough volume to justify it.)*

## Expected answer

**Correct: C.** The chapter's rule for channel choice is: *Web* for one-shot ad-hoc questions, *Prompt design in chat* for a small batch of repeated structured tasks done *by hand*, *API* for any workflow that must be **repeatable**, **integrated** into other software, or **applied at volume** ($\gtrsim 100$ items per run). This workflow satisfies **two** of those three triggers — *repeatable* (six monthly runs) and *integrated* (feeds a CSV-consuming import script) — so the channel must be **API**, *even though a single $40$-item run would otherwise sit in the prompt-design range*.

The token estimate follows the chapter's rule of thumb:

$$40 \text{ notes} \times 250 \text{ words} = 10\,000 \text{ words} \quad \Longrightarrow \quad 10\,000 \times \dfrac{4}{3} \approx 13\,300 \text{ tokens of input}$$

per run, plus a negligible $40$ tokens of output (one short label per note). Over $6$ runs: $\sim 80\,000$ tokens of input total, which on current commercial API pricing is well below the cost of an espresso.

Why the distractors are plausible but wrong:

- **A** is wrong on **both axes**: the token estimate (\$7\,500$) is a *parole-vs-token* error — the student has reported $40 \times 250 \times \dfrac{3}{4} \approx 7\,500$, which inverts the conversion factor (multiplying by $\dfrac{3}{4}$ instead of $\dfrac{4}{3}$, treating tokens as *shorter* than words by the same ratio that they are actually *longer*). The channel is also wrong: Web chat is the ad-hoc one-shot channel; a workflow that runs monthly for half a year and produces structured output is *categorically* not ad-hoc. A student who picks A has not yet metabolised the token-unit convention *or* the *repeatable* trigger.
- **B** is the **subtlest distractor** because it is *partially right*: the token estimate $\sim 13\,300$ is correct, *and* a one-shot $40$-item batch would indeed fit prompt-design-in-chat. The student who picks B has correctly metabolised the *volume* trigger but has **missed the *recurrence* and *integration* triggers**. The chapter's rule names *three* conditions for the API channel — volume, repeatability, integration — and a workflow satisfies the API criterion if **any** of the three holds, not only if all three do. Picking B reveals that the student is reading the rule conjunctively ("API only if ALL three") when the chapter states it disjunctively ("API if ANY of the three"). This is the discriminator the item is designed to surface.
- **D** is a **principled answer** that the chapter explicitly encourages students to consider — *"do it by hand without an LLM"* is the right call for $20$-letter batches, and the chapter notes ([objectives.md](../objectives.md), nota docente *anti-trabocchetto*) that students who give this answer should be **rewarded** for the cost-sense. But here the volume is *$40$ per month for $6$ months* = $240$ classifications total; combined with the audit-level expectation of *consistency* across runs (the EHR export shifts month to month, the human reviewer's calibration drifts), the LLM-with-API is the better tool. Picking D shows good *judgement* on the cost-of-LLM question but **misses that the recurrence multiplies the human effort while the API does not**. The right response, in correction, is to *praise the question being asked* (good students ask "do I even need an LLM here?") while pointing out that *this* scenario has the recurrence dimension D's reasoning silently ignores.

The single discriminator across A/B/C/D is whether the student reads the chapter's API-trigger rule **disjunctively** (volume **or** repeatability **or** integration) — which is the only reading that flips this scenario from B to C — or **conjunctively** (volume **and** repeatability **and** integration) — which would freeze the scenario on B. Only C reads the rule correctly.

## Rubric

N/A (MCQ — single correct option).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

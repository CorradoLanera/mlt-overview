# Item 02 — Apply the competence rule to two clinical scenarios

**ID**: IB-08-chatgpt-usage-02
**Learning objective**: State and apply the competence rule — *only delegate to an LLM tasks whose answer you can independently judge as correct or wrong*. Given a candidate clinical-research task, identify (a) a *plausible-looking* failure mode the model could produce, (b) the expertise the user must already have to **catch** that failure, and (c) the verdict (delegable or not), with a justification that names *why* — including the special case in which the task is **not delegable regardless of the user's expertise** (Obj. 2).

**Category**: Application
**Type**: applicativa
**Difficulty**: medium
**Chapter**: 08-chatgpt-usage

## Question

Two distinct clinical-research tasks are described below. For **each** of them, apply the competence rule of this chapter.

> **Scenario A — Oncology trial summarisation.** Your group has just received a $14$-page peer-reviewed paper reporting a Phase II randomised trial of a novel KRAS-G12C inhibitor in advanced lung adenocarcinoma. The PI asks you to use an LLM to produce a **five-bullet abstract** suitable for tumour-board prep — primary endpoint, control arm, effect size on the primary endpoint, the most important subgroup finding, and any toxicity that altered protocol. You are an oncology fellow in your second year, with formal training in clinical-trials methodology.
>
> **Scenario B — Drug–drug interaction screening.** A junior colleague is reviewing the medication list of a patient who is **on long-term warfarin** (for prosthetic mitral valve, INR-stable) and has just been *newly prescribed* **oral amiodarone** for paroxysmal atrial fibrillation. The colleague asks an LLM: *"Given this patient's full medication list of eight drugs, is there any clinically significant drug–drug interaction I should flag before the patient leaves the clinic?"* The colleague is an internal-medicine resident in their first year.

Answer the three sub-questions below in order. For each sub-question, give a **separate answer** for Scenario A and Scenario B.

### Sub-question 1 — plausible-looking failure mode

For each scenario, **name one plausible-looking failure mode** the LLM could produce — i.e. an output that is *clinically plausible at first read* but materially wrong. The failure mode must be **concrete and namable**, not the generic "the model could hallucinate".

### Sub-question 2 — expertise needed to catch the failure

For each scenario, **name the specific expertise** the user must already possess to *catch* the failure mode you described in sub-question 1. State the expertise as a *capability*, not as a credential (e.g. "ability to distinguish hazard ratio from relative risk" rather than "an MD degree").

### Sub-question 3 — verdict (delegable or not) + justification

For each scenario, give a **verdict** — *delegable* or *not delegable* — and justify in one sentence. The justification must follow the chapter's rule: *delegable iff the user can independently judge the answer*.

**Pay attention to the special case** in which a task is **not delegable regardless of the user's expertise**, because the only way to *check* the LLM's output is to consult a different authoritative source that the user could have consulted *instead of* the LLM in the first place. In such a case, the rule's verdict is *not delegable* — *even if the user happens to know the topic well*. Name this case explicitly if one of the two scenarios is an instance of it.

## Expected answer

### Sub-question 1 — failure modes

**Scenario A.** A plausible-looking failure mode is: **the LLM reports the *response rate* as the primary endpoint when the actual primary endpoint of the trial was *progression-free survival***, and gives a numerically plausible effect-size figure ("*hazard ratio $0.68$, $95\%$ CI $0.51$–$0.91$*") that is in fact the *secondary* endpoint's effect size, not the primary's. The bullet reads correctly to a non-trialist — clinical terms, plausible numbers, internally coherent — but materially misrepresents what the trial concluded. A variant: the LLM correctly identifies *progression-free survival* as the primary endpoint but **conflates *hazard ratio* with *relative risk***, citing the HR figure as if it were a relative-risk reduction. Either variant is acceptable.

**Scenario B.** A plausible-looking failure mode is: **the LLM reports "no clinically significant interaction" or lists *minor* interactions while *missing* the major amiodarone–warfarin interaction** (amiodarone inhibits CYP2C9 and P-glycoprotein, potentiating warfarin's anticoagulant effect, with INR rising significantly over $1$–$3$ weeks — a *well-known, guideline-level* interaction that requires INR re-checking and warfarin dose reduction). The output looks reassuringly clean — *"reviewed; no major interactions noted"* — and a clinician who trusted it would discharge the patient without the INR-monitoring schedule the interaction demands.

### Sub-question 2 — expertise needed to catch

**Scenario A.** The expertise needed to catch the failure is **clinical-trials methodology** — specifically, the ability to (i) locate and read the *primary endpoint* statement in the methods section, (ii) distinguish *hazard ratio* from *relative risk* and from *odds ratio*, and (iii) match each reported effect size in the LLM's bullets back to the table/figure of the paper that produced it. **Oncology expertise alone is not sufficient** — a clinician who knows lung adenocarcinoma but does not read trials methodologically can be misled by a plausibly-worded summary that misattributes effect size.

**Scenario B.** The expertise needed to catch the failure is **knowledge of the specific amiodarone–warfarin interaction**, or more generally **the discipline of cross-checking every LLM drug-interaction output against a maintained drug-interaction reference (UpToDate, Lexicomp, BNF, the EMA SmPC)**. Either capability is sufficient *to catch the failure*, but only the second is sufficient *to know whether the failure has been caught* (the LLM might also miss interactions the clinician does not happen to remember).

### Sub-question 3 — verdicts

**Scenario A: *delegable* — with the stated expertise.** You are an oncology fellow with formal clinical-trials methodology training. You can read the primary-endpoint statement, distinguish HR from RR, and match each LLM-produced bullet back to the source table. The delegation rule is satisfied: you can independently judge the output. The LLM saves you the *first pass* of reading and structuring the paper; you spend the saved time on the *checking* pass — which is the pass that needs your expertise anyway.

**Scenario B: *not delegable, regardless of expertise* — and this is the special case the chapter wants named.** *Even if* the junior colleague happened to know the amiodarone–warfarin interaction (some internal-medicine first-year residents do), the only way to **verify** that the LLM has not missed *any* of the other interactions in an $8$-drug list is to **consult a maintained drug-interaction database** — i.e. the source the colleague *should have consulted instead of the LLM* in the first place. The competence-rule check (*"can the user **independently** judge?"*) is yes *for the one failure mode the user happens to know about*, but the rule asks whether the user can judge **the output as a whole** — and that requires excluding *every* missed interaction in the $8$-drug list, not just the one the user remembers. So the *delegation* fails operationally because the *verification step* is *the same effort as the original task*. **A task is not delegable when the only honest way to check the LLM's answer is to *re*-do the task with the authoritative source.** Drug-interaction screening on a multi-drug patient is the textbook instance of this special case. The correct workflow is the database, not the chatbot — *even if the chatbot happens to get it right*.

(A student who concludes Scenario B is *delegable* on the grounds that an experienced clinician would catch the failure is missing the chapter's deeper rule: *delegating well* is not the same as *getting lucky and catching the error*. The chapter's last paragraph of [the narrative](../narrative.md) makes exactly this distinction — "*delegating well is not delegating everything*".)

## Rubric

See [rubrica_02_competence-rule-two-scenarios.md](../rubriche/rubrica_02_competence-rule-two-scenarios.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

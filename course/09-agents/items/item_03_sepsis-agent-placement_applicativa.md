# Item 03 — Place the gates: a sepsis early-warning agent

**ID**: IB-09-agents-03
**Learning objective**: Apply the chapter's reversibility + human-in-the-loop test to each step of a multi-step clinical agent workflow, classify each step as *safe-by-default* or *dangerous-by-default*, and **propose a gate placement that adds a guard exactly where reversibility fails — and nowhere else**. Justify each gate with the chapter's operational rule (*ask before any irreversible action*) and explain why over-gating (a gate before a reversible step) is not required (Obj. 3).

**Category**: Application
**Type**: applicativa (open-format short answer)
**Difficulty**: medium–high
**Chapter**: 09-agents

## Question

A clinical-safety team has built an agent that monitors all post-operative patients on a surgical ward for early signs of sepsis. Once configured, every $5$ minutes the agent runs the following four steps on its own — **no human reads any output between steps**:

1. **Read** the latest vital signs and lab values for each patient from the EHR (read-only access; the EHR generates a standard query-log entry, as for every read by any system).
2. **Compute** the qSOFA score for each patient, in memory.
3. **Submit an HL7 alert message to the bedside monitoring system**, which immediately fires a buzz on the patient's nurse-call panel and posts a colour-coded alert on the central nurses-station dashboard (the buzz fires and the dashboard updates the moment the message is sent; even if the message is later retracted, the nurse has already heard the buzz and the alert has already appeared on the dashboard for anyone watching).
4. **Page the on-call physician via SMS** if any patient's qSOFA has crossed the alert threshold of $\geq 2$.

Answer the following **three** parts in order:

**(a) Reversibility + HITL table.** For each of the four steps, state whether it is **reversible** (*Y* / *N*) by the chapter's $\sim 30$-second test, whether it is **human-in-the-loop** (*Y* / *N*) as the workflow is currently described, and whether it is **safe-by-default** or **dangerous-by-default**. Give *one to two sentences* of justification for each row — keep steps $1$ and $2$ short; for steps $3$ and $4$ name precisely what makes the action fail the $30$-second test.

**(b) Gate placement.** Propose where you would place the gate(s) to make the agent safely usable. State the *number* of gates and the *exact* position of each (e.g., *"before step $X$"*).

**(c) Justification.** Write **one sentence per gate** explaining why each gate is needed (citing the chapter's rule), and **one sentence** explaining why no gate is needed before the reversible steps (citing the chapter's caveat against over-gating).

## Expected answer

**(a) Reversibility + HITL table.**

| Step | Reversible? | HITL? | Verdict | One-sentence justification |
|---|---|---|---|---|
| 1 — Read EHR | Y | N | safe-by-default | The agent's action is *reading*; the EHR is unchanged by a read, and the query-log entry is a side-effect of the EHR's record-keeping, not an action the agent took on the world. |
| 2 — Compute qSOFA | Y | N | safe-by-default | In-memory computation; no external state is changed by the calculation. |
| 3 — HL7 alert to bedside | N | N | **dangerous-by-default** | The HL7 message broadcasts to bedside hardware the moment it is sent — the buzz fires on the nurse-call panel and the central dashboard updates simultaneously; retracting the message does not undo the buzz that has sounded or the alert that has appeared — the $30$-second test fails. |
| 4 — Page on-call | N | N | **dangerous-by-default** | The SMS notification has already reached the on-call's phone the moment the page is sent; deletion at the agent's end does not recall the page. |

**(b) Gate placement.** **Two gates: one before step $3$, one before step $4$.** No gate before steps $1$ or $2$.

**(c) Justification.**

- *Gate before step $3$ is needed because the HL7 alert is irreversible the moment it is sent (the buzz has fired on the nurse-call panel, the dashboard has updated — neither can be recalled in $\sim 30$ seconds), and at this point no human has read the qSOFA or the underlying vital signs — irreversible $\wedge$ no-HITL = dangerous-by-default, and the chapter's rule is **ask before any irreversible action**.*
- *Gate before step $4$ is needed because the SMS page is irreversible (the page has already buzzed the on-call's phone the moment it is sent), and at this point no human has reviewed which patient is being flagged or why — same dangerous quadrant, same rule.*
- *No gate is needed before steps $1$ or $2$ because both are reversible (read-only EHR access; in-memory computation), and the chapter's rule asks for a gate where reversibility **fails**, not at every step — adding gates before reversible steps would paralyse the agent without reducing risk (the rule is **ask before any irreversible action**, not **ask before every action**).*

A complete answer applies the chapter's rule **disjunctively** (safe-by-default if reversible *or* HITL) and **once per irreversibility**, not once per step. The structure of the answer mirrors the structure of the rule: identify reversibility on each step, identify HITL on each step, mark the dangerous quadrant, place exactly the gates the dangerous quadrant requires.

A typical wrong answer over-gates: a student gating *all four* steps has read the safe-by-default rule conjunctively (mistakenly requiring *both* reversibility *and* HITL to be safe) and has reproduced the *paralyzingly conservative* placement the chapter's pre-hook from cap. $8$ explicitly warns against. Another typical wrong answer under-gates: a student gating *only* step $4$ has identified the SMS as the most "noisy" action but has missed that the EHR write is irreversible too (the *visible vs consequential* distinction in reverse — the EHR write is *less audibly noisy* than an SMS but *more clinically consequential*, since it enters the patient's permanent record).

## Associated rubric

[rubrica_03_sepsis-agent-placement.md](../rubriche/rubrica_03_sepsis-agent-placement.md) — 3 criteria × 3 levels (Base / Good / Excellent).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

# Item 04 — Critique a mis-gated agent: the trial-coordination agent

**ID**: IB-09-agents-04
**Learning objective**: Synthesise the chapter's three objectives on a single colleague-built agent design that *appears* responsible but applies the wrong axis to gate placement. Identify (i) which axis the colleague has substituted for the chapter's *reversibility* axis (Obj. 2), (ii) which steps are *safe-by-default* and which *dangerous-by-default* in the colleague's design (Obj. 1 + Obj. 2), and (iii) the *corrected* gate placement with one-sentence justifications citing the chapter's operational rule (Obj. 3).

**Category**: Argumentation/evaluation
**Type**: argomentativa (open-format argumentative)
**Difficulty**: high
**Chapter**: 09-agents

## Question

A colleague on your team has built a **clinical-trial coordination agent** and is presenting the design at next week's lab meeting. Here is the colleague's setup.

**Workflow** (runs every Monday at $09{:}00$, fully automated, no human reads any output between steps):

1. **Read** the enrolled-patients list from the trial database.
2. **Generate** a weekly status report (text + tables) in memory.
3. **Save** the report as a PDF in the agent's local working directory on the team's analysis laptop, **overwriting** last week's file in the same directory. (The operating system keeps the previous version in the local Trash / Recycle Bin by default; restoring it is a two-click action.)
4. **Send** the PDF as an attachment via email to all $12$ centre coordinators of the multi-centre trial.
5. **Update** the patient-enrolment counter on the trial's *public registry website* — the public dashboard visible to any external visitor (the public, sponsors, regulators, journalists).

**Colleague's safety reasoning, verbatim**: *"I've designed this with safety in mind. I've put a confirmation gate before step $3$, because **overwriting** the previous week's PDF is destructive — if the new report is wrong, last week's data is gone. The other four steps run unattended; that's the whole point of using an agent."*

**Write a structured critique of this design** (target length $\sim 300$–$500$ words). Your critique must contain **three parts**:

**(1)** **Identify the conceptual error** in the colleague's safety reasoning — name the *axis* the colleague is using to decide where gates go, and contrast it with the *axis* the chapter teaches. *(Obj. 2 — what the $2 \times 2$ trust-boundary test measures, and what it does not.)*

**(2)** **Diagnose the operational consequences** of the colleague's design — for *each* of the five steps, classify it as *safe-by-default* or *dangerous-by-default* by the chapter's rule, and explicitly identify (a) which step the colleague's design **protects unnecessarily** (over-gated), and (b) which steps it **leaves exposed** (under-gated). *(Obj. 1 — three ingredients of an agent and what "do stuff" mode does to the trust boundary.)*

**(3)** **Propose a corrected gate placement**, with **one sentence per gate** justifying its position by citing the chapter's operational rule (*ask before any irreversible action*). State the number of gates you would keep, remove, and add. *(Obj. 3 — placement of the guard.)*

## Expected answer

A response that earns a passing mark on this item makes three argumentative moves, in this order.

**(1) Conceptual error — the wrong axis.** The colleague has substituted **destructiveness** (does this step delete or overwrite data?) for **reversibility** (can this action be undone in $\sim 30$ seconds by closing a tab, deleting a file, or rolling back a draft?). The chapter's $2 \times 2$ grid has only two axes — *reversibility* and *human-in-the-loop* — and *destructiveness* appears on neither. The substitution is plausible because destructive operations *are one kind* of irreversible action (deleting an unrecoverable file is both destructive and irreversible), but the two axes are *not* the same: a step can be *destructive but reversible* (overwriting a file in a local working directory where the operating system keeps the previous version in the Trash / Recycle Bin — a "rolling back a draft" case at the OS level), and a step can be *non-destructive but irreversible* (sending an email — nothing is "destroyed", yet the message cannot be recalled once notifications have fired). The colleague's reasoning works only for the small subset of cases where *destructiveness $\equiv$ irreversibility*; the chapter's rule covers the *full* operational space, including the case of *send* operations, *publish* operations, and *broadcast* operations, all of which can be irreversible without being destructive.

**(2) Operational diagnosis — step by step.**

- **Step 1** (DB read): *reversible* (a read leaves no external effect; the DB looks the same after as before), $no$-HITL → **safe-by-default**. The colleague's design correctly leaves it unattended.
- **Step 2** (in-memory generation): *reversible* (no external state changes), $no$-HITL → **safe-by-default**. Correctly unattended.
- **Step 3** (PDF overwrite in local working directory): **reversible** by the chapter's $30$-second test — the previous week's PDF goes to the laptop's local Trash / Recycle Bin when overwritten, and restoring it is a two-click action well within the $\sim 30$-second window (exactly the kind of action the chapter's *"rolling back a draft"* example covers — the new write *looks* destructive but its effect can be **rolled back** at the operating-system level). The colleague's gate gates a step that is **already safe-by-default**; the gate is **cosmetic and decelerative** — it slows the agent without reducing risk. **Over-gated**.
- **Step 4** (email to $12$ coordinators): **irreversible** — the email has already left the SMTP socket the moment it is sent; even where "recall" is supported, the notifications have pinged $12$ phones and previews may have been read on mobile. $no$-HITL by design → **dangerous-by-default**. The colleague's design **leaves this exposed**. *Under-gated*.
- **Step 5** (public registry update): **irreversible** in the strongest sense — the moment the counter updates on the *public* dashboard, *any external visitor* can see it (sponsors, regulators, journalists, the public). This is not just a write; it is a *broadcast to the world outside the trust boundary*. $no$-HITL by design → **dangerous-by-default**. The colleague's design **leaves this exposed**, and at the highest stakes in the workflow. *Under-gated*.

The colleague's design protects *exactly the wrong step* (step $3$, which is safe-by-default) and leaves *exactly the wrong two steps* unattended (steps $4$ and $5$, both dangerous-by-default). This is the operational consequence of the axis substitution in part (1).

**(3) Corrected placement.**

- **Remove** the gate before step $3$ — *step $3$ is reversible by the $30$-second test (the previous PDF lives in the local Trash / Recycle Bin and is two clicks away to restore — the chapter's "rolling back a draft" case in OS form), and the chapter's rule asks for a gate where reversibility fails, not where data is overwritten.*
- **Add** a gate before step $4$ — *email is irreversible the moment it leaves the SMTP socket; the chapter's rule **ask before any irreversible action** places the gate exactly here, so a human can read the report and the recipient list before $12$ coordinators receive it.*
- **Add** a gate before step $5$ — *a public-dashboard update cannot be un-published in any meaningful sense; this is the strongest irreversibility in the workflow (it crosses the trust boundary into the public world), and the gate is mandatory.*

Net: **$1$ gate removed, $2$ gates added**, total **$2$ gates** in the final design — both at the *do stuff* points that cross the trust boundary into the external world.

**At excellent level**, a response also makes a fourth argumentative move: the colleague's confusion is not just about *where the line goes* (placement) but about *what the line is for* (the trust boundary). The chapter teaches that the boundary marks where the agent's action *escapes the system the clinician controls* — and *escape*, not *destruction*, is the operational test. Email and public-registry updates escape; local file overwrites do not. A student who frames the critique in these terms has internalised the chapter's payoff: *an agent is not "smarter than a chat-LLM"; it is a chat-LLM with the ability to act — and the engineering question is which actions escape the trust boundary*.

A typical wrong critique under-corrects: a student who *adds* gates to steps $4$ and $5$ but *does not remove* the gate from step $3$ has fixed the under-gating problem but has missed the over-gating critique — they have not internalised the *exactly where reversibility fails* discipline. Another typical wrong critique gates *every* step *"to be doubly safe"* (the *paralyzingly conservative* placement the chapter explicitly warns against), reproducing the cap. $8$-to-cap. $9$ error in mirror form. Both miss the chapter's core: *gates go where reversibility fails, and only there*.

## Associated rubric

[rubrica_04_critique-mis-gated-agent.md](../rubriche/rubrica_04_critique-mis-gated-agent.md) — 3 criteria × 3 levels (Base / Good / Excellent).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

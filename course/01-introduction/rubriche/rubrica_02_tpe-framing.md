# Rubric — Item 02 (Frame a clinical task as T/P/E)

**Item**: IB-01-introduction-02
**Objective**: Frame a clinical problem as an ML problem ($T/P/E$) and reason about why a performance measure is or is not appropriate for the data.

| Criterion | Base | Good | Excellent |
|---|---|---|---|
| **C1 — $T/P/E$ decomposition** | Identifies all three ($T$, $P$, $E$), but one is vague or partly mislabelled | $T$ (binary prediction at admission), $P$ (balanced accuracy), and $E$ all correct and appropriate | As *Good*, and $E$ explicitly recognised as *supervised* (past admissions labelled with the outcome) |
| **C2 — The revealing computation** | States qualitatively that the trivial model scores high on plain accuracy but poorly on balanced accuracy | Gives the correct figures: **plain accuracy ≈ 96%**, **balanced accuracy = 50%** | As *Good*, and shows the working: balanced accuracy = (0% on sepsis + 100% on non-sepsis) / 2 |
| **C3 — Interpretation** | States that plain accuracy is misleading here | Explains *why*: plain accuracy is inflated by the 96% majority of negatives, so a useless model still scores ≈ 96% | As *Good*, and explains why balanced accuracy is better — it weighs both classes equally, so missing the rare class pulls it to chance level (50%) |

**Threshold (sufficiency)**: at least **Base** on all three criteria; **C2 and C3 at least Base are mandatory** — the revealing computation and its interpretation are the load-bearing points of the item.

**Bias da evitare in correzione** *(nota docente):* valutare il *ragionamento*, non il vocabolario — accettare formulazioni concettuali corrette anche senza i termini esatti; non penalizzare lessico imperfetto se il concetto è giusto; non premiare la lunghezza. La *balanced accuracy* è **definita nell'enunciato**: l'item non presuppone che sia stata introdotta prima.

# Item 02 — Partition the plane

**ID**: IB-02-classifiers-02
**Learning objective**: Represent a classifier geometrically as a function $f:\mathbb{R}^d \to \{1,\ldots,K\}$ that partitions the feature space into decision regions (one region per class) (Obj. 2).
**Category**: Application
**Type**: applicativa (open-ended applicative)
**Difficulty**: medium
**Chapter**: 02-classifiers

## Question

A clinical screening tool uses two patient features — *fasting glucose* $x$ (mg/dL) and *BMI* $y$ (kg/m²) — to flag patients as **high-risk** ($1$) or **low-risk** ($0$). The screening tool is the classifier $f:\mathbb{R}^2 \to \{0, 1\}$ defined by the rule

$$f(x, y) = \begin{cases} 1 & \text{if } x + 2y > 200 \\ 0 & \text{otherwise.} \end{cases}$$

Three new patients arrive:

| Patient | Fasting glucose $x$ | BMI $y$ |
|---|---|---|
| P1 | $100$ | $30$ |
| P2 | $140$ | $35$ |
| P3 | $90$ | $60$ |

Answer the three sub-questions:

1. **Compute** $f$ for each of P1, P2, P3 — i.e., assign each patient the label *high-risk* or *low-risk* — showing the arithmetic.
2. **Sketch or describe** the two **decision regions** of $f$ on the $(x, y)$ plane: draw the boundary line $x + 2y = 200$ and indicate which side is the *high-risk region* ($f = 1$) and which is the *low-risk region* ($f = 0$).
3. **Explain** why the two decision regions **together cover the entire plane $\mathbb{R}^2$ with no gaps and no overlaps**, and why this is a *necessary* property of any classifier $f:\mathbb{R}^2 \to \{0, 1\}$ — not a stylistic choice of how to draw it.

## Expected answer

1. Compute $x + 2y$ for each patient and compare with $200$:
   - **P1**: $100 + 2 \cdot 30 = 160 < 200$ → $f(\text{P1}) = 0$ → **low-risk**.
   - **P2**: $140 + 2 \cdot 35 = 210 > 200$ → $f(\text{P2}) = 1$ → **high-risk**.
   - **P3**: $90 + 2 \cdot 60 = 210 > 200$ → $f(\text{P3}) = 1$ → **high-risk**.

2. **Boundary:** the line $x + 2y = 200$ passes through $(200, 0)$ and $(0, 100)$. The plane splits into two half-planes:
   - **High-risk region ($f = 1$):** the half-plane *above-right* of the line, where $x + 2y > 200$. P2 and P3 fall here.
   - **Low-risk region ($f = 0$):** the half-plane *below-left* of the line, where $x + 2y < 200$. P1 falls here.
   - (The boundary line itself goes to $f = 0$, per the rule's strict inequality.)

3. The regions cover $\mathbb{R}^2$ with **no gaps, no overlaps** because $f$ is a **function**: by definition, for *every* input $(x, y) \in \mathbb{R}^2$, $f$ must return **exactly one** output in $\{0, 1\}$ — never *none* (which would be a gap, an input with no label) and never *two* (which would be an overlap, an input with conflicting labels). The two decision regions are exactly the **preimages** $f^{-1}(0) = \{(x,y) : f(x,y) = 0\}$ and $f^{-1}(1) = \{(x,y) : f(x,y) = 1\}$; their union is the whole plane, and their intersection is empty. Saying "$f$ is a classifier" *is* saying "the regions partition $\mathbb{R}^2$" — the geometric picture and the function definition are the same statement.

## Rubric

See [rubriche/rubrica_02_partition-the-plane.md](../rubriche/rubrica_02_partition-the-plane.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

# Item 02 — Apply the kernel trick

**ID**: IB-03-algorithm-examples-02
**Learning objective**: Explain the kernel trick operationally — a non-linear feature map $\phi$ can turn a non-linearly-separable dataset into a linearly-separable one *without changing* the linear classifier itself; only what the classifier sees changes (Obj. 2).
**Category**: Application
**Type**: applicativa (open-ended applicative)
**Difficulty**: medium
**Chapter**: 03-algorithm-examples

## Question

Eight patients are described in a 2D feature space with features $y_1$ and $y_2$. Their classes are:

| Patient | $y_1$ | $y_2$ | Class |
|---|---|---|---|
| A | $1$ | $0$ | red |
| B | $-1$ | $0$ | red |
| C | $0$ | $1$ | red |
| D | $0$ | $-1$ | red |
| E | $3$ | $0$ | blue |
| F | $-3$ | $0$ | blue |
| G | $0$ | $3$ | blue |
| H | $0$ | $-3$ | blue |

(Geometrically: the red patients lie on the unit circle $y_1^2 + y_2^2 = 1$, the blue patients on the circle $y_1^2 + y_2^2 = 9$ — *concentric* circles around the origin.)

A non-linear feature map is given:

$$\phi(y_1, y_2) = (y_1^2,\ y_2^2) = (X_1, X_2).$$

Answer the four sub-questions:

1. **Argue briefly (1–2 sentences)** why **no straight line** in the original $(y_1, y_2)$ plane can separate the red class from the blue class.
2. **Tabulate the transformed coordinates $(X_1, X_2) = \phi(y_1, y_2)$** for the 8 patients.
3. **State a linear decision rule** in the new $(X_1, X_2)$ space — i.e. a rule of the form *"red if $aX_1 + bX_2 < c$, blue otherwise"* with **specific values of $a$, $b$, $c$** — that separates the two classes **perfectly** on this sample. **Verify** your rule on one red point and one blue point.
4. The "classifier" (a single straight cut in feature space) **did not change** between the original space and the transformed space. **What did change**, and why is that enough to make linear separation possible? (1–3 sentences.)

## Expected answer

1. Red and blue are concentric: every direction from the origin contains both a red point (at distance $1$) and a blue point (at distance $3$). Any straight line in the $(y_1, y_2)$ plane has *both* classes on the same side of it (the only way to enclose red while excluding blue would be a closed curve, not a straight line).

2. Apply $\phi(y_1, y_2) = (y_1^2,\ y_2^2)$:

   | Patient | $(y_1, y_2)$ | $(X_1, X_2) = (y_1^2, y_2^2)$ | Class |
   |---|---|---|---|
   | A | $(1, 0)$ | $(1, 0)$ | red |
   | B | $(-1, 0)$ | $(1, 0)$ | red |
   | C | $(0, 1)$ | $(0, 1)$ | red |
   | D | $(0, -1)$ | $(0, 1)$ | red |
   | E | $(3, 0)$ | $(9, 0)$ | blue |
   | F | $(-3, 0)$ | $(9, 0)$ | blue |
   | G | $(0, 3)$ | $(0, 9)$ | blue |
   | H | $(0, -3)$ | $(0, 9)$ | blue |

   Note: all reds have $X_1 + X_2 = 1$; all blues have $X_1 + X_2 = 9$.

3. **Linear decision rule:** *"red if $X_1 + X_2 < 5$, blue otherwise"* (so $a = b = 1$, $c = 5$ — any $c$ strictly between $1$ and $9$ works). **Verification:**
   - Red **A**: $X_1 + X_2 = 1 + 0 = 1 < 5$ → labelled red ✓
   - Blue **E**: $X_1 + X_2 = 9 + 0 = 9 \ge 5$ → labelled blue ✓
   (The same check holds for all 8 patients.)

4. **What did change is the data** — the same eight patients have been re-coordinatised by $\phi$, so the *coordinates the classifier sees* now expose the distance-from-the-origin information that was hidden in the original $(y_1, y_2)$ representation. The classifier is still a *straight cut*; it now operates on $(X_1, X_2) = (y_1^2, y_2^2)$ instead of $(y_1, y_2)$. The decision rule $X_1 + X_2 < 5$ in $\phi$-space corresponds *exactly* to the boundary $y_1^2 + y_2^2 < 5$ in original space — a **circle** — which is the boundary the data actually wanted. The kernel trick is this re-coordinatisation: change what the linear classifier sees, not the classifier.

## Rubric

See [rubriche/rubrica_02_apply-the-kernel-trick.md](../rubriche/rubrica_02_apply-the-kernel-trick.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

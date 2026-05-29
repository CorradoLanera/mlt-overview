# Item 02 — Forward pass and weight count of a small fully-connected network

**ID**: IB-05-deep-learning-02
**Learning objective**: Compose the forward pass of a small fully-connected network — given an architecture spec, write the per-layer equations $a^{[l]} = g^{[l]}(W^{[l]} a^{[l-1]})$, identify the activation $g$ at each layer, count the total number of weights, and *operate* one forward pass numerically (Obj. 2).
**Category**: Application
**Type**: applicativa
**Difficulty**: medium
**Chapter**: 05-deep-learning

## Question

Consider the following fully-connected neural network, with no bias terms:

- Input layer: $3$ features, written as $a^{[0]} = (x_1, x_2, x_3) \in \mathbb{R}^3$.
- Hidden layer 1: $4$ neurons, activation $g^{[1]} = \text{ReLU}$, with $\text{ReLU}(z) = \max(0, z)$.
- Hidden layer 2: $2$ neurons, activation $g^{[2]} = \text{ReLU}$.
- Output layer: $1$ neuron, activation $g^{[3]} = \sigma$ (sigmoid), where $\sigma(z) = 1 / (1 + e^{-z})$.

Answer the three sub-questions below in order.

### Sub-question 1 — write the forward pass

Write the three forward-pass equations of this network in matrix form, $a^{[l]} = g^{[l]}(W^{[l]} a^{[l-1]})$, naming the activation $g^{[l]}$ at each layer. State the *dimensions* of each weight matrix $W^{[l]}$ explicitly (number of rows × number of columns).

### Sub-question 2 — count the weights

Compute the **total number of weights** that this network has to learn, showing the calculation **decomposed by layer** (one term per layer), not just the final number.

### Sub-question 3 — operate one forward pass

Given the concrete input vector
$$a^{[0]} = (1,\ 2,\ 0)$$
and the concrete weight matrix
$$W^{[1]} = \begin{pmatrix} 1 & 0 & -1 \\ 0 & 1 & 1 \\ -1 & 1 & 0 \\ 2 & -2 & 0 \end{pmatrix},$$
compute the **first hidden layer's output vector** $a^{[1]} = \text{ReLU}(W^{[1]} a^{[0]})$. Show the intermediate pre-activation vector $z^{[1]} = W^{[1]} a^{[0]}$ explicitly *before* applying ReLU.

## Expected answer

### Sub-question 1

The three forward-pass equations, with explicit matrix dimensions:

- $a^{[1]} = \text{ReLU}(W^{[1]} a^{[0]})$, with $W^{[1]} \in \mathbb{R}^{4 \times 3}$, so $a^{[1]} \in \mathbb{R}^4$.
- $a^{[2]} = \text{ReLU}(W^{[2]} a^{[1]})$, with $W^{[2]} \in \mathbb{R}^{2 \times 4}$, so $a^{[2]} \in \mathbb{R}^2$.
- $a^{[3]} = \sigma(W^{[3]} a^{[2]})$, with $W^{[3]} \in \mathbb{R}^{1 \times 2}$, so $a^{[3]} \in \mathbb{R}$ — this is the final scalar output $\hat{y}$.

A component-wise statement is also acceptable, e.g. $a^{[1]}_j = \text{ReLU}\!\left(\sum_{i=1}^{3} W^{[1]}_{ji} \, x_i\right)$ for $j = 1, \ldots, 4$. ReLU at the two hidden layers, sigmoid at the output, must be **named explicitly**.

### Sub-question 2

The decomposition by layer:

- Layer 1 ($3 \to 4$): $3 \cdot 4 = 12$ weights.
- Layer 2 ($4 \to 2$): $4 \cdot 2 = 8$ weights.
- Layer 3 ($2 \to 1$): $2 \cdot 1 = 2$ weights.

**Total**: $12 + 8 + 2 = \mathbf{22}$ weights.

(With no bias terms — as specified in the problem. If the problem had introduced biases, there would be $4 + 2 + 1 = 7$ additional bias parameters, for a total of $29$.)

### Sub-question 3

Compute the pre-activation vector $z^{[1]} = W^{[1]} a^{[0]}$ component by component:

- $z^{[1]}_1 = 1 \cdot 1 + 0 \cdot 2 + (-1) \cdot 0 = 1$
- $z^{[1]}_2 = 0 \cdot 1 + 1 \cdot 2 + 1 \cdot 0 = 2$
- $z^{[1]}_3 = (-1) \cdot 1 + 1 \cdot 2 + 0 \cdot 0 = 1$
- $z^{[1]}_4 = 2 \cdot 1 + (-2) \cdot 2 + 0 \cdot 0 = -2$

So $z^{[1]} = (1,\ 2,\ 1,\ -2)$.

Apply ReLU element-wise — $\text{ReLU}(z) = \max(0, z)$:

- $\text{ReLU}(1) = 1$
- $\text{ReLU}(2) = 2$
- $\text{ReLU}(1) = 1$
- $\text{ReLU}(-2) = 0$ ← the negative pre-activation is *killed* by the non-linearity.

Final: $a^{[1]} = (1,\ 2,\ 1,\ 0)$.

The **teachable beat** of this sub-question is the last component: the pre-activation is $-2$, the post-activation is $0$. This is the **non-linearity of $g^{[1]}$ doing actual work** — a student who writes $a^{[1]}_4 = -2$ has applied a linear function, not the ReLU specified in the architecture, and has implicitly turned the layer into a linear map (the very thing the chapter's requirement on $g$ rules out — see Obj. 3).

## Rubric

See [rubrica_02_forward-pass-and-weight-count.md](../rubriche/rubrica_02_forward-pass-and-weight-count.md).

## Note di revisione

*(da compilare dopo il check `assessment-reviewer` a fine set.)*

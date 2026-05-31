# Formative · min 80 · Parsons (after Step 02, fused network written)

- **Type:** Parsons (reorder the scrambled lines, then answer shape questions)
- **Concept-graph nodes checked:** `FUSED` — Fused 3-branch net: single forward / shape-check; `CNN` — 1D-CNN: kernel / stride / channels; `RNN` — RNN: hidden / sequence / LSTM-GRU

## Prompt

The `forward()` method of the fused network has been scrambled.
Reorder these six lines into the correct execution order:

```
(a)  self$head(torch_cat(list(t, c, r), dim = 2))
(b)  t <- self$tab(x_tab)
(c)  r <- self$rnn(x_seq)
(d)  torch_cat(list(t, c, r), dim = 2)
(e)  c <- self$cnn(x_sig)
(f)  forward = function(x_tab, x_sig, x_seq) {
```

Then answer:

1. The three branch outputs have widths 16, `sig_ch`, and `hidden` respectively.
   What must the **head's input dimension** equal?
2. The head outputs **2 logits** (alive / dead). What is the shape of the result
   for a mini-batch of $B = 5$ observations?

## Expected answer

**Correct order:** f → b → e → c → a  (build `t`, `c`, `r` in any order, then concat + head in one call)

```r
forward = function(x_tab, x_sig, x_seq) {
  t <- self$tab(x_tab)   # [B, 16]
  c <- self$cnn(x_sig)   # [B, sig_ch]
  r <- self$rnn(x_seq)   # [B, hidden]
  self$head(torch_cat(list(t, c, r), dim = 2))
}
```

**Head input dimension:** $16 + \text{sig\_ch} + \text{hidden}$.
`torch_cat(..., dim = 2)` concatenates along the feature axis; the head's first
linear layer must therefore accept exactly $16 + \text{sig\_ch} + \text{hidden}$
inputs. Any mismatch causes a shape error at the first forward pass.

**Output shape:** $[5,\, 2]$ — one row per observation in the batch, two logits
per row (one per class). In `luz`/`torch`, the batch dimension is always $\text{dim} = 1$.

## Diagnostic note (teacher)

Common wrong orders: placing `torch_cat` *before* all three branches are computed,
or placing `head` *before* `torch_cat`. Both cause shape errors that `torch` reports
at runtime — use this as a teaching moment: `torch` gives you the shape mismatch
immediately, which is why writing the `forward()` and running a single dummy batch
is the fastest way to verify an architecture before committing to training.

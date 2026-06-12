# Piano implementazione — sez.02 "Deep learning" (Advanced)

> **For agentic workers:** REQUIRED SUB-SKILL: usa `superpowers:subagent-driven-development` per eseguire
> questo piano task-per-task. Gli step usano checkbox (`- [ ]`). Spec di riferimento:
> `dev-docs/superpowers/specs/2026-06-12-mlt-advanced-02-deep-learning-redesign.md`.

**Goal.** Reti davvero addestrate dal vivo (CNN 2D + RNN con curve train/val), confine `brulee`/tidymodels
esplicito, fused = demo architetturale; taglio della loss curve finta e dell'impalcatura honesty.

**Architettura.** Un solo step folder `02-deep-learning`. Authoring in
`workshops/mlt-r-advanced/_authoring/02-deep-learning/` (`beat.R`, `meta.yml`, `R/nn-modules.R`) + dati
committati in `workshops/mlt-r-advanced/data-raw/`. Deck:
`slides/workshops/mlt-r-advanced/00-advanced-deck.qmd` (sezione `#sec-02-deep-learning`).

**Tech stack.** R 4.6.0; `torch`/`luz`/`coro`/`torchvision` (reti su misura), `brulee` (MLP in tidymodels),
`kernelshap`/`shapviz` (SHAP), `yardstick` (metriche). Rebuild via `dev/mltbuild/rebuild.R`, sito via
`scripts/build_site.py`. **Sempre** invocare Rscript di R 4.6.0:
`& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe"`.

**Contratto tensori** (output Task 1, consumato dalle task seguenti):

- immagini: `x_img` float `[N, 1, 28, 28]` in `[0,1]`; `y_img` long `[N]`, classi **1-based** `{1L, 2L}`.
- sequenze: `x_seq` float `[N, T, F]` (batch-first; per ECG5000 `T=140`, `F=1`); `y_seq` long `[N]`, classi `{1L, 2L}`.
- tabellare (per il fused): una riga `heart_failure` come float `[1, P]` (P = n. feature del `base_rec`).
- target `nn_cross_entropy_loss()` di R torch = indici long 1-based in `1..C`.

---

## Task 1 — Data-prep (il rischio numero uno; prima di tutto)

**Files:**
- Create: `dev/prep-dl-data.R` (script authoring-time, NON eseguito dal build)
- Create: `workshops/mlt-r-advanced/data-raw/pneumoniamnist.rds` (tensore committato)
- Create: `workshops/mlt-r-advanced/data-raw/ecg.rds` (tensore committato, ECG5000 reale)

**Ambiente.** Per eseguire R-con-torch serve una renv restaurata. Usare una build fresca dello step
(`rebuild.R mlt-r-advanced` ripopola) **oppure** eseguire `prep-dl-data.R` da una cartella step con
`renv::restore()`. Misurare e annotare a referto i tempi.

- [ ] **Step 1.1 — Scrivi `dev/prep-dl-data.R`.** Scarica e converte i dataset in tensori committati.
  PneumoniaMNIST primario; fallback MNIST-2-classi via `torchvision` se l'`.npz` non è raggiungibile.

```r
# dev/prep-dl-data.R — authoring-time data prep for Advanced step 02 (run once, NOT in the build).
# Produces committed tensors in workshops/mlt-r-advanced/data-raw/.
suppressMessages({
  library(torch)
  library(torchvision)
})
set.seed(123)
out_dir <- "workshops/mlt-r-advanced/data-raw"

# --- 2D images: PneumoniaMNIST (28x28, binary), with an MNIST fallback ----
prep_pneumonia <- function() {
  url <- "https://zenodo.org/records/10519652/files/pneumoniamnist.npz?download=1"
  dst <- tempfile(fileext = ".npz")
  ok <- tryCatch({
    utils::download.file(url, dst, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) return(NULL)
  npz <- reticulate::import("numpy")$load(dst)   # npz reader; reticulate is a torchvision dep on this box
  # MedMNIST npz keys: train_images [N,28,28] uint8, train_labels [N,1]
  xi <- npz[["train_images"]]
  yi <- npz[["train_labels"]]
  list(x = xi, y = as.integer(yi) + 1L)          # -> 1-based labels
}
prep_mnist_fallback <- function() {
  ds <- torchvision::mnist_dataset(tempdir(), train = TRUE, download = TRUE)
  keep <- which(ds$targets %in% c(0L, 1L))        # two classes only
  xi <- as.array(ds$data[keep, , ])               # [n,28,28] uint8
  yi <- ds$targets[keep] + 1L                     # -> {1,2}
  list(x = xi, y = yi)
}

img <- tryCatch(prep_pneumonia(), error = function(e) NULL)   # any failure (download/npz/reticulate) -> fallback
if (is.null(img)) {
  message("PneumoniaMNIST unavailable -> MNIST 2-class fallback")
  img <- prep_mnist_fallback()
}
# balanced subset small enough for a fast-but-real CPU train that still overfits
idx <- {
  per_class <- 400L
  c1 <- which(img$y == 1L); c2 <- which(img$y == 2L)
  c(sample(c1, min(per_class, length(c1))), sample(c2, min(per_class, length(c2))))
}
x_img <- torch_tensor(img$x[idx, , ], dtype = torch_float())$unsqueeze(2) / 255  # [N,1,28,28]
y_img <- torch_tensor(img$y[idx], dtype = torch_long())                          # [N]
saveRDS(list(x = x_img, y = y_img), file.path(out_dir, "pneumoniamnist.rds"))
cat("images:", paste(dim(x_img), collapse = "x"), "labels", paste(range(as.integer(y_img)), collapse = "-"), "\n")

# --- sequences: real ECG (ECG5000, binary normal/abnormal) from a stable public mirror ----
# The TF-hosted CSV is ECG5000: 5000 rows = 140 signal columns + a trailing label column (1=normal,0=abnormal).
ecg_url <- "http://storage.googleapis.com/download.tensorflow.org/data/ecg.csv"
ecg <- utils::read.csv(ecg_url, header = FALSE)
sig  <- as.matrix(ecg[ , 1:140])                       # [5000, 140]
lab  <- as.integer(ecg[ , 141] == 1) + 1L              # normal(1) -> class 2; abnormal(0) -> class 1  => {1,2}
set.seed(123)
keep <- {
  per_class <- 400L
  c1 <- which(lab == 1L); c2 <- which(lab == 2L)
  c(sample(c1, min(per_class, length(c1))), sample(c2, min(per_class, length(c2))))
}
sig <- scale(sig[keep, ])                              # z-score per time step across the cohort
x_seq <- torch_tensor(array(sig, dim = c(nrow(sig), 140, 1)), dtype = torch_float())  # [N,140,1]
y_seq <- torch_tensor(lab[keep], dtype = torch_long())                                # [N]
saveRDS(list(x = x_seq, y = y_seq), file.path(out_dir, "ecg.rds"))
cat("ecg:", paste(dim(x_seq), collapse = "x"), "labels", paste(sort(unique(as.integer(y_seq))), collapse = ","), "\n")
cat("PREP OK\n")
```

- [ ] **Step 1.2 — Esegui e verifica.** `& "...Rscript.exe" dev/prep-dl-data.R`. Atteso: stampa shapes
  immagini `[800,1,28,28]` (o sizes simili), ecg `[800,140,1]`, `PREP OK`; i due `.rds` esistono in
  `data-raw/`. Annota a referto: sorgente immagini usata (Pneumonia o fallback MNIST), tempo di prep.
- [ ] **Step 1.3 — Commit.** `git add dev/prep-dl-data.R workshops/mlt-r-advanced/data-raw/pneumoniamnist.rds
  workshops/mlt-r-advanced/data-raw/ecg.rds` →
  `data(advanced): committed DL tensors for step 02 (images + real ECG seq)`.

> NOTA per le task seguenti: se la sorgente immagini o le shape reali differiscono dal contratto, **adegua**
> il contratto e propaga a Task 2/3 (i reviewer lo verificano). ECG5000 ha shape fissa `[*,140,1]` dal mirror;
> se il mirror CSV fosse irraggiungibile, fallback documentato = archivio UCR ECG200 (`.tsv`).

---

## Task 2 — `nn-modules.R`: aggiungi la CNN 2D, allinea il fused

**Files:** Modify `workshops/mlt-r-advanced/_authoring/02-deep-learning/R/nn-modules.R`

- [ ] **Step 2.1 — Aggiungi `cnn2d_net`** (immagini 28×28 → 2 logit) e riallinea il `fused_net` perché il
  ramo immagini sia 2D (non più il `cnn_branch` 1D). Tieni `rnn_branch`. Codice:

```r
library(torch)

# 2D-CNN over a 28x28 image (e.g. a PneumoniaMNIST frame) ----
cnn2d_net <- nn_module(
  "cnn2d_net",
  initialize = function(ch = 8, n_class = 2) {
    self$conv1 <- nn_conv2d(1, ch, kernel_size = 3, padding = 1)
    self$conv2 <- nn_conv2d(ch, ch * 2, kernel_size = 3, padding = 1)
    self$pool  <- nn_max_pool2d(2)
    self$head  <- nn_linear(ch * 2 * 7 * 7, n_class)   # 28 -> 14 -> 7 after two pools
  },
  forward = function(x) {
    x <- self$pool(nnf_relu(self$conv1(x)))   # [B, ch, 14, 14]
    x <- self$pool(nnf_relu(self$conv2(x)))   # [B, 2ch, 7, 7]
    self$head(torch_flatten(x, start_dim = 2))
  },
)

# RNN over a vitals sequence (LSTM, last time step) ----
rnn_net <- nn_module(
  "rnn_net",
  initialize = function(in_size, hidden = 16, n_class = 2) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
    self$head <- nn_linear(hidden, n_class)
  },
  forward = function(x) {
    out <- self$lstm(x)
    last <- out[[1]][ , dim(out[[1]])[2], ]   # [B, hidden] — explicit last step
    self$head(last)
  },
)

# Branch versions (no head) for the fused demo ----
cnn2d_branch <- nn_module(
  "cnn2d_branch",
  initialize = function(ch = 8) {
    self$conv <- nn_conv2d(1, ch, kernel_size = 3, padding = 1)
    self$pool <- nn_adaptive_avg_pool2d(1)
  },
  forward = function(x) self$pool(nnf_relu(self$conv(x)))$squeeze(4)$squeeze(3),  # [B, ch]
)
rnn_branch <- nn_module(
  "rnn_branch",
  initialize = function(in_size, hidden = 16) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
  },
  forward = function(x) {
    out <- self$lstm(x)
    out[[1]][ , dim(out[[1]])[2], ]
  },
)

# Fused 3-branch net: tabular MLP + 2D-CNN (image) + RNN (sequence) -> concat -> head ----
fused_net <- nn_module(
  "fused_net",
  initialize = function(n_tab, img_ch = 8, seq_in, hidden = 16) {
    self$tab  <- nn_linear(n_tab, 16)
    self$cnn  <- cnn2d_branch(img_ch)
    self$rnn  <- rnn_branch(seq_in, hidden)
    self$head <- nn_linear(16 + img_ch + hidden, 2)
  },
  forward = function(x_tab, x_img, x_seq) {
    t <- self$tab(x_tab)   # [B, 16]
    c <- self$cnn(x_img)   # [B, img_ch]
    r <- self$rnn(x_seq)   # [B, hidden]
    self$head(torch_cat(list(t, c, r), dim = 2))   # -> [B, 2]
  },
)
```

- [ ] **Step 2.2 — Shape-check rapido** (scratch, non committato): costruisci `cnn2d_net()` su
  `torch_randn(4,1,28,28)` → `[4,2]`; `rnn_net(3)` su `torch_randn(4,12,3)` → `[4,2]`; `fused_net(n_tab=11,
  seq_in=3)` su `(randn(4,11), randn(4,1,28,28), randn(4,12,3))` → `[4,2]`.
- [ ] **Step 2.3 — Commit.** `feat(advanced): 2D-CNN + RNN modules for step 02, fused image branch is 2D`.

---

## Task 3 — `beat.R`: training reale CNN+RNN, fused demo, SHAP invariato

**Files:** Modify `workshops/mlt-r-advanced/_authoring/02-deep-learning/beat.R`

- [ ] **Step 3.1 — Riscrivi `beat.R`.** Rimuovi `optionB_loss` e l'`if (FALSE)` luz. Tieni l'MLP `brulee`
  live + SHAP. Aggiungi: load tensori committati; train reale via `luz` per CNN e RNN con `valid_data`;
  curva train/val; predict + `roc_auc`; fused build + `forward()` shape-check (Parsons hole). Il fetch resta
  mostrato-ma-guardato. Struttura:

```r
library(brulee)
library(torch)
library(luz)

# A live MLP — settings first, then train SMALL (in tidymodels via brulee) ----
set.seed(123)
mlp_spec <- mlp(hidden_units = 16, epochs = 30, penalty = 0.01, learn_rate = 0.05) |>
  set_engine("brulee") |>
  set_mode("classification")
mlp_fit <- fit(workflow() |> add_recipe(base_rec) |> add_model(mlp_spec), train)
augment(mlp_fit, test) |> roc_auc(truth = outcome, .pred_died)

# The same explainer, a new model (only the model object changed — now a neural net) ----
set.seed(3)
ks_mlp <- kernelshap(mlp_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_mlp) |> sv_waterfall()

# Beyond tidymodels: a real 2D-CNN trained live on images ----
source(here("R", "nn-modules.R"))

# How you would fetch the data (shown, not run here — we load the committed tensor) ----
if (FALSE) {
  # see dev/prep-dl-data.R: download PneumoniaMNIST (.npz) or torchvision::mnist_dataset(),
  # subset, scale to [0,1], save as data-raw/pneumoniamnist.rds
}
img <- readRDS(here("data-raw", "pneumoniamnist.rds"))
set.seed(123)
n   <- dim(img$x)[1]
ti  <- sample(n, floor(0.7 * n))
ds_tr <- tensor_dataset(img$x[ti, , , ], img$y[ti])
ds_va <- tensor_dataset(img$x[-ti, , , ], img$y[-ti])
dl_tr <- dataloader(ds_tr, batch_size = 32, shuffle = TRUE)
dl_va <- dataloader(ds_va, batch_size = 64)

cnn_fit <- cnn2d_net |>
  setup(loss = nn_cross_entropy_loss(), optimizer = optim_adam, metrics = list(luz_metric_accuracy())) |>
  set_hparams(ch = 8, n_class = 2) |>
  fit(dl_tr, epochs = 40, valid_data = dl_va)

plot(cnn_fit)   # the real train/val learning curve — the U lives here

# Predict + evaluate on the held-out images (yardstick, by hand) ----
cnn_prob <- as.numeric(nnf_softmax(predict(cnn_fit, dl_va), dim = 2)[ , 2])
tibble::tibble(truth = factor(as.integer(img$y[-ti]), levels = c(1, 2)), .pred = cnn_prob) |>
  yardstick::roc_auc(truth, .pred, event_level = "second")

# A real RNN trained live on ECG sequences (ECG5000) ----
seq <- readRDS(here("data-raw", "ecg.rds"))
set.seed(123)
ns  <- dim(seq$x)[1]
si  <- sample(ns, floor(0.7 * ns))
sdl_tr <- dataloader(tensor_dataset(seq$x[si, , ], seq$y[si]), batch_size = 32, shuffle = TRUE)
sdl_va <- dataloader(tensor_dataset(seq$x[-si, , ], seq$y[-si]), batch_size = 64)

rnn_fit <- rnn_net |>
  setup(loss = nn_cross_entropy_loss(), optimizer = optim_adam, metrics = list(luz_metric_accuracy())) |>
  set_hparams(in_size = dim(seq$x)[3], hidden = 16, n_class = 2) |>
  fit(sdl_tr, epochs = 40, valid_data = sdl_va)

plot(rnn_fit)

# Fused: constructible, NOT trained — three modalities, three unrelated cohorts ----
# We reuse one example per modality only to prove the wiring runs (not the same patient).
x_tab1 <- torch_tensor(matrix(0, 1, 11), dtype = torch_float())
x_img1 <- img$x[1, , , , drop = FALSE]
x_seq1 <- seq$x[1, , , drop = FALSE]
fused <- fused_net(n_tab = 11, img_ch = 8, seq_in = dim(seq$x)[3], hidden = 16)

# >>>hole id=fused-forward kind=parsons prompt=run the three branches, concat along dim=2, then the head
#   solved:
fused_forward <- function(self, x_tab, x_img, x_seq) {
  t <- self$tab(x_tab)
  c <- self$cnn(x_img)
  r <- self$rnn(x_seq)
  self$head(torch_cat(list(t, c, r), dim = 2))
}
# <<<hole
fused(x_tab1, x_img1, x_seq1)$shape   # expect [1, 2] — wiring proven, nothing trained
```

- [ ] **Step 3.2 — Rebuild + verifica.** `& "...Rscript.exe" dev/mltbuild/rebuild.R mlt-r-advanced`.
  Atteso: `BUILD OK` + `PARITY OK`; lo step `02` rende le tab To-fill/Solved con **due curve** (CNN, RNN) e i
  `roc_auc`. Misura e annota il **tempo di training** dello step (target ~30–90s/rete; se eccede, riduci
  `per_class`/`epochs` in Task 1/3 e ri-misura). Verifica che la curva mostri la **U** (val che risale); se
  non la mostra, aumenta epoche o capacità o riduci il dataset.
- [ ] **Step 3.3 — Commit.** `feat(advanced): step 02 trains CNN + RNN live with real train/val curves`.

---

## Task 4 — `meta.yml`

**Files:** Modify `workshops/mlt-r-advanced/_authoring/02-deep-learning/meta.yml`

- [ ] **Step 4.1 — Aggiorna.** Titolo senza "honestly"; `packages` con `torchvision`; summary, check:

```yaml
slug: 02-deep-learning
title: "Step 02 — Deep learning: train real nets"
minutes: 120
summary: "Train an MLP in tidymodels (brulee), then a real 2D-CNN and an RNN live with torch/luz (train/val curves), and wire a fused net."
packages: [brulee, luz, torchvision]
carry: [R/nn-modules.R]
check:
  kw: [brulee, kernelshap, nn_conv2d, luz, roc_auc, fused_net, torch_cat]
  imgs: 2
```

- [ ] **Step 4.2 — Commit.** `docs(advanced): step 02 meta — real-training title, torchvision, new checks`.

---

## Task 5 — Deck: taglia l'impalcatura honesty + la curva finta

**Files:** Modify `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`

- [ ] **Step 5.1 — Rimuovi** le slide `## The honesty rule — one labeled exception` (≈L532), `## Your turn —
  does the loss curve break the honesty rule?` (≈L560), `## The answer — A: one labeled exception` (≈L575),
  con le loro `::: {.notes}`.
- [ ] **Step 5.2 — Commit.** `refactor(deck): drop honesty-rule slides from step 02 (no faked curve left)`.

---

## Task 6 — Deck: slide di teoria nuove

**Files:** Modify `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`

- [ ] **Step 6.1 — Aggiungi `## Loss vs. metrics: why we optimise one, report the other` {.smaller}.**
  Contenuto (EN, math in `$...$`):

```markdown
## Loss vs. metrics: why we optimise one, report the other {.smaller}

Training follows a gradient, so the objective must be **differentiable**. Accuracy is not.

- We **optimise** cross-entropy: $\mathcal{L}_{\text{CE}} = -\sum_{k} y_k \log \hat p_k$ — smooth in the
  weights, so each step has a slope to follow (recall the gradient step, ch. 5).
- We **report** accuracy / ROC-AUC — what we actually care about, but **flat almost everywhere**: nudging a
  weight rarely flips a label, so the gradient is $0$ and there is nothing to descend.
- So the loss is a **differentiable stand-in** for the metric: minimise CE, then read the metric off the
  held-out predictions.

::: {.notes}
Voce docente (IT): la domanda dello studente "perché non usiamo direttamente l'accuracy?" — perché è a
gradini, gradiente nullo q.o.; la CE è la surrogata liscia. Una loss, anche sola; le metriche, anche più.
:::
```

- [ ] **Step 6.2 — Aggiungi `## The training loop, made concrete` {.smaller}.** Spiega epoca/batch/loop e la
  curva a U; richiama ch.5 (forward/gradiente) e ch.4 (overfit). Contenuto:

```markdown
## The training loop, made concrete {.smaller}

A net learns by repeating one cycle. `luz` runs it for us, but here is what it does each step:

1. **forward** — push a batch through `forward()` to get predictions (recall the forward pass, ch. 5).
2. **loss** — compare to the truth with cross-entropy.
3. **backward** — get the gradient of the loss w.r.t. every weight.
4. **step** — the optimiser nudges the weights downhill.

One pass over all batches is an **epoch**. We watch **two** curves: training loss and **validation** loss.
When training keeps dropping but validation turns up, that upturn is **overfitting** (recall ch. 4) — the
**U** we will see live.

::: {.notes}
Voce docente (IT): `forward()` non è magia — è il passo 1 del ciclo che ch.5 ha già introdotto; luz è solo
il loop. La U si vede dal vivo sui dati veri, non disegnata.
:::
```

- [ ] **Step 6.3 — Aggiungi `## Where tidymodels ends and torch begins` {.smaller}.** Il confine:

```markdown
## Where tidymodels ends and torch begins {.smaller}

`brulee` let the MLP live **inside** tidymodels — same `fit`/`predict`, same `workflow_set`, same metrics.
That bridge covers a few standard architectures and stops there.

- A bespoke **CNN / RNN / fused** net is **not** a parsnip model: no `workflow_set`, no `tune` — you write
  the `nn_module`, train it with `luz`, predict yourself.
- `yardstick` still scores it: it works on **predictions**, not on the model object. So the **same**
  `roc_auc()` measures both sides of the line.

::: {.notes}
Voce docente (IT): il confine è il cuore didattico. Dentro: confronto gratis. Fuori: train+eval a mano, ma
lo stesso metro (yardstick sulle predizioni).
:::
```

- [ ] **Step 6.4 — Aggiungi `## XAI beyond tabular: a note` {.smaller}.** Cenno XAI sulle reti:

```markdown
## XAI beyond tabular: a note {.smaller}

SHAP rode along onto the tabular MLP because `kernelshap` needs only a prediction function. On an image it
does not help — thousands of pixels, no readable attribution.

- **Images:** occlusion sensitivity, saliency, Grad-CAM — *which pixels move the prediction*.
- **Sequences:** attribution over time steps — *which moments mattered*.

We name them here; the tabular SHAP line stays our worked example.

::: {.notes}
Voce docente (IT): non facciamo la demo (scelta), ma lo strumento giusto per le immagini si nomina:
occlusion/saliency/grad-CAM. SHAP resta sull'esempio tabellare.
:::
```

- [ ] **Step 6.5 — Commit.** `feat(deck): step 02 theory slides (loss-vs-metrics, training loop, boundary, XAI note)`.

---

## Task 7 — Deck: riscrivi le slide pratiche CNN/RNN/fused + GPU + divider + go-to-code

**Files:** Modify `slides/workshops/mlt-r-advanced/00-advanced-deck.qmd`

- [ ] **Step 7.1 — Sostituisci `## CNN / RNN / fused — written, not trained`** con una sequenza che riflette
  il train reale: una slide CNN (richiamo ch.6 conv + `nn_conv2d` + "train live, watch the U"), una slide RNN
  (richiamo ch.6 + `nn_lstm`/ultimo step + train+eval), e tieni il Parsons `forward()` per il **fused demo**.
  La slide-tabella delle tre reti diventa "what each branch reads" senza "written-not-trained".
- [ ] **Step 7.2 — Aggiorna il Parsons fused** (`## Your turn — reorder the fused forward()` + `## The answer
  …`): il forward ora ha argomenti `(x_tab, x_img, x_seq)` e rami `tab/cnn(2D)/rnn`; output `[1, 2]` (un
  esempio, non un batch da 5). Framing: "costruibile, non allenata — coorti diverse, niente paziente comune".
- [ ] **Step 7.3 — Sfronda `## GPU payoff`** a una nota onesta: il train CPU reale è lento (appena visto) →
  la macchina d'aula ha CUDA; rimuovi "kill the epoch / option B / labeled exception".
- [ ] **Step 7.4 — Aggiorna il divider `# Step 02 · Deep learning`** (why + HTML-comment di sintesi) e
  `## Go to code` (via "write don't train" e "one labeled exception"; aggiungi "CNN+RNN trained live").
- [ ] **Step 7.5 — Commit.** `feat(deck): step 02 practical slides rewritten for live-trained CNN/RNN + fused demo`.

---

## Task 8 — Sweep registro

**Files:** Modify deck/meta/beat della sez.02 secondo i hit

- [ ] **Step 8.1 — Lancia il linter** sui file toccati:
  `& "...Rscript.exe"` non serve — è Python: `python scripts/check_register.py
  slides/workshops/mlt-r-advanced/00-advanced-deck.qmd
  workshops/mlt-r-advanced/_authoring/02-deep-learning/`.
- [ ] **Step 8.2 — Correggi** ogni hit nella sezione 02: em-dash `—` → `:` / `;` / riformulazione;
  `knob`/`knobs` → `setting`; residui honesty (`honest*`, "Deep learning, honestly", "honesty rule"). I hit
  fuori sez.02 (altre sezioni) si **lasciano** (deferred), ma annotali a referto.
- [ ] **Step 8.3 — Commit.** `style(advanced): register sweep of step 02 (em-dash, setting, honesty vocab)`.

---

## Task 9 — Rebuild, sito, verifica visiva

- [ ] **Step 9.1 — Rebuild.** `& "...Rscript.exe" dev/mltbuild/rebuild.R mlt-r-advanced` → `BUILD OK` +
  `PARITY OK`.
- [ ] **Step 9.2 — Sito.** `python scripts/build_site.py` → partial rigenerati + deck reso + soluzioni
  `docs/solutions/mlt-r-advanced/02-deep-learning.html` aggiornata.
- [ ] **Step 9.3 — Verifica visiva (chrome-devtools).** Apri il deck reso e ispeziona le slide nuove:
  math (`$\mathcal{L}_{\text{CE}}$` ecc.) resa, le **due curve** train/val leggibili e con la U visibile,
  nessun overflow laterale, niente residuo honesty. Itera i fix finché converge.
- [ ] **Step 9.4 — Commit.** `build(site): rebuild docs after step 02 deep-learning redesign`.

---

## Task 10 — Vault + memorie + test

- [ ] **Step 10.1 — Test.** `python -m pytest tests/ -q` → tutti verdi (il linter ha già i suoi test; se ho
  cambiato `check_register.py` aggiungo/aggiorno i test).
- [ ] **Step 10.2 — Vault.** Appendi una entry LIFO a "Stato corrente" di
  `obsidian-vault/progetti/mlt-overview/mlt-overview.md` (sez.02 ridisegnata, reti reali, fused demo).
- [ ] **Step 10.3 — Memorie.** Aggiorna `[[workshop2-section-alignment]]` (sez.02 ✅) e, se emergono fatti
  non ovvi (sorgente dataset usata, tempi di training, gotcha luz/torchvision), scrivi una memoria mirata.
- [ ] **Step 10.4 — Commit** (se il vault è nel repo git; le memorie sono fuori-repo).

---

## Self-review del piano

- **Copertura spec:** §3 spina → Task 5/6/7 (deck) + Task 2/3 (codice); §4 deck → Task 5/6/7; §5 codice →
  Task 2/3/4; §6 build → Task 1/3/9; §7 registro → Task 8; §1 dati → Task 1. OK.
- **Placeholder:** nessuno; l'unico punto adattivo è il contratto-tensori (Task 1 → propaga), dichiarato.
- **Coerenza tipi:** `cnn2d_net`/`rnn_net`/`fused_net` definiti in Task 2 e usati con quegli stessi nomi in
  Task 3; `tensor_dataset`/`dataloader`/`luz::fit(valid_data=)` coerenti; target long 1-based ovunque.
- **Rischio aperto:** sorgente immagini (Pneumonia vs MNIST) e tempi → misurati in Task 1/3, con fallback.

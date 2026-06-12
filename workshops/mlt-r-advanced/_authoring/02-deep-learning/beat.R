library(brulee)
library(torch)
library(luz)

# A live MLP: settings first, then train SMALL (in tidymodels via brulee) ----
set.seed(123)
mlp_spec <- mlp(hidden_units = 16, epochs = 30, penalty = 0.01, learn_rate = 0.05) |>
  set_engine("brulee") |>
  set_mode("classification")
mlp_fit <- fit(workflow() |> add_recipe(base_rec) |> add_model(mlp_spec), train)
augment(mlp_fit, test) |> roc_auc(truth = outcome, .pred_died)

# The same explainer, a new model (only the fitted model changed, now a neural net) ----
set.seed(3)
ks_mlp <- kernelshap(mlp_fit, X = bg[1, ], bg_X = bg, pred_fun = pred_fun)
shapviz(ks_mlp) |> sv_waterfall()

# Beyond tidymodels: bespoke nets written and trained in torch/luz ----
source(here("R", "nn-modules.R"))
torch_set_default_dtype(torch_float())   # brulee left the default as double; nets use float32 to match inputs

# How the committed tensors were fetched (shown, not run; full script in dev/prep-dl-data.R) ----
if (FALSE) {
  utils::download.file(
    "https://zenodo.org/records/10519652/files/pneumoniamnist.npz?download=1",
    "pneumoniamnist.npz",
    mode = "wb",
  )
  utils::download.file(
    "http://storage.googleapis.com/download.tensorflow.org/data/ecg.csv",
    "ecg.csv",
  )
  # the .npz is read with a tiny pure-R .npy reader (no Python); see dev/prep-dl-data.R
}

# A real 2D-CNN trained live on chest X-rays (PneumoniaMNIST) ----
img   <- readRDS(here("data-raw", "pneumoniamnist.rds"))   # plain arrays, committed
x_img <- torch_tensor(img$x, dtype = torch_float())
y_img <- torch_tensor(img$y, dtype = torch_long())
set.seed(123)
torch_manual_seed(123)
perm  <- sample(dim(x_img)[1])
tr    <- perm[1:100]                       # a deliberately small training slice: the overfit U becomes visible
va    <- perm[101:length(perm)]
dl_tr <- dataloader(tensor_dataset(x_img[tr, , , ], y_img[tr]), batch_size = 16, shuffle = TRUE)
dl_va <- dataloader(tensor_dataset(x_img[va, , , ], y_img[va]), batch_size = 64)

cnn_fit <- cnn2d_net |>
  setup(
    loss = nn_cross_entropy_loss(),
    optimizer = optim_adam,
    metrics = list(luz_metric_accuracy()),
  ) |>
  set_hparams(ch = 16, n_class = 2) |>
  set_opt_hparams(lr = 1e-3) |>
  fit(dl_tr, epochs = 80, valid_data = dl_va, verbose = FALSE)

plot(cnn_fit)   # the real learning curve: training loss keeps falling, validation loss turns up (the U)

# Evaluate on the held-out images (yardstick, on the predictions) ----
cnn_prob <- as.numeric(nnf_softmax(predict(cnn_fit, x_img[va, , , ]), dim = 2)[ , 2])
tibble(
  truth = factor(as.integer(img$y[va]), levels = c(1, 2)),
  .pred = cnn_prob,
) |>
  roc_auc(truth, .pred, event_level = "second")

# A real RNN trained live on ECG traces (ECG5000) ----
ecg   <- readRDS(here("data-raw", "ecg.rds"))
x_ecg <- torch_tensor(ecg$x, dtype = torch_float())
y_ecg <- torch_tensor(ecg$y, dtype = torch_long())
set.seed(123)
torch_manual_seed(123)
sp     <- sample(dim(x_ecg)[1])
e_tr   <- sp[1:100]
e_va   <- sp[101:length(sp)]
edl_tr <- dataloader(tensor_dataset(x_ecg[e_tr, , ], y_ecg[e_tr]), batch_size = 16, shuffle = TRUE)
edl_va <- dataloader(tensor_dataset(x_ecg[e_va, , ], y_ecg[e_va]), batch_size = 64)

rnn_fit <- rnn_net |>
  setup(
    loss = nn_cross_entropy_loss(),
    optimizer = optim_adam,
    metrics = list(luz_metric_accuracy()),
  ) |>
  set_hparams(in_size = dim(x_ecg)[3], hidden = 24, n_class = 2) |>
  set_opt_hparams(lr = 1e-3) |>
  fit(edl_tr, epochs = 80, valid_data = edl_va, verbose = FALSE)

plot(rnn_fit)

ecg_prob <- as.numeric(nnf_softmax(predict(rnn_fit, x_ecg[e_va, , ]), dim = 2)[ , 2])
tibble(
  truth = factor(as.integer(ecg$y[e_va]), levels = c(1, 2)),
  .pred = ecg_prob,
) |>
  roc_auc(truth, .pred, event_level = "second")

# Fused net: constructible, NOT trained, three modalities from three unrelated cohorts ----
# One example per modality (a heart_failure row, one X-ray, one ECG) only proves the wiring.
x_tab_all <- bake(prep(base_rec), new_data = train) |>
  dplyr::select(-outcome) |>
  as.matrix()
x_tab1 <- torch_tensor(x_tab_all[1, , drop = FALSE], dtype = torch_float())
x_img1 <- x_img[1, , , , drop = FALSE]
x_ecg1 <- x_ecg[1, , , drop = FALSE]
fused  <- fused_net(n_tab = ncol(x_tab_all), img_ch = 8, seq_in = dim(x_ecg)[3], hidden = 16)

# >>>hole id=fused-forward kind=parsons prompt=run the three branches, concat along dim=2, then the head
#   solved:
fused_forward <- function(self, x_tab, x_img, x_seq) {
  t <- self$tab(x_tab)
  c <- self$cnn(x_img)
  r <- self$rnn(x_seq)
  self$head(torch_cat(list(t, c, r), dim = 2))
}
# <<<hole
fused(x_tab1, x_img1, x_ecg1)$shape   # expect [1, 2]: wiring proven, nothing trained

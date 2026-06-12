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

# Beyond tidymodels: bespoke nets in torch/luz. brulee fits in double and leaves
# the torch default dtype as double; pin it to float32 so the nets match the inputs ----
torch_set_default_dtype(torch_float())

# How the committed tensors were fetched (shown, not run; full script in prep-dl-data.R (in the workshop folder)) ----
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
  # the .npz is read with a tiny pure-R .npy reader (no Python); see prep-dl-data.R (in the workshop folder)
}

# A real 2D-CNN on chest X-rays (PneumoniaMNIST) ----
# Define the architecture inline so every layer is on screen: two conv+pool blocks, then a head.
cnn2d_net <- nn_module(
  "cnn2d_net",
  initialize = function(ch = 16, n_class = 2) {
    self$conv1 <- nn_conv2d(1, ch, kernel_size = 3, padding = 1)
    self$conv2 <- nn_conv2d(ch, ch * 2, kernel_size = 3, padding = 1)
    self$pool  <- nn_max_pool2d(2)
    self$head  <- nn_linear(ch * 2 * 7 * 7, n_class)   # 28 -> 14 -> 7 after two 2x2 pools
  },
  forward = function(x) {
    x <- self$pool(nnf_relu(self$conv1(x)))   # [B, ch, 14, 14]
    x <- self$pool(nnf_relu(self$conv2(x)))   # [B, 2ch, 7, 7]
    self$head(torch_flatten(x, start_dim = 2))
  },
)
cnn2d_net(ch = 16, n_class = 2)   # inspect the architecture: layers + parameter count

img   <- read_rds(here("data-raw", "pneumoniamnist.rds"))   # a list: x = images, y = labels
x_img <- torch_tensor(img$x, dtype = torch_float())
y_img <- torch_tensor(img$y, dtype = torch_long())

# See the data: one X-ray per class, first as raw pixels, then as an image ----
img$x[which(img$y == 1)[1], 1, 1:5, 1:5]   # a 5x5 corner of one image, pixels in [0, 1]
img_show <- dplyr::bind_rows(
  tidyr::expand_grid(col = 1:28, row = 1:28) |>   # col-major order matches as.numeric(matrix)
    dplyr::mutate(pixel = as.numeric(img$x[which(img$y == 1)[1], 1, , ]), class = "normal"),
  tidyr::expand_grid(col = 1:28, row = 1:28) |>
    dplyr::mutate(pixel = as.numeric(img$x[which(img$y == 2)[1], 1, , ]), class = "pneumonia"),
)
ggplot(img_show, aes(col, row, fill = pixel)) +
  geom_raster() +
  facet_wrap(~ class) +
  scale_y_reverse() +
  scale_fill_gradient(low = "black", high = "white") +
  coord_fixed() +
  theme_void()

# Split with rsample, the same discipline as the rest of the course: train / validation / test,
# stratified by class. torch only ever sees the row indices; the split itself stays tidymodels.
img_ids   <- tibble(row = seq_len(dim(x_img)[1]), class = factor(img$y))
set.seed(123)
img_split <- initial_validation_split(img_ids, prop = c(0.125, 0.25), strata = class)
tr <- training(img_split)$row     # deliberately small training slice: the overfit U becomes visible
va <- validation(img_split)$row   # early stopping watches this set (keep best valid_loss)
te <- testing(img_split)$row      # held out, scored once at the very end

# A dataloader serves the images to the loop in shuffled mini-batches ----
set.seed(123)
torch_manual_seed(123)
dl_tr <- dataloader(tensor_dataset(x_img[tr, , , ], y_img[tr]), batch_size = 16, shuffle = TRUE)
dl_va <- dataloader(tensor_dataset(x_img[va, , , ], y_img[va]), batch_size = 64)

# Train 150 epochs to SEE the overfit, but keep the best-validation checkpoint (early stopping) ----
cnn_fit <- cnn2d_net |>
  setup(
    loss = nn_cross_entropy_loss(),
    optimizer = optim_adam,
    metrics = list(luz_metric_accuracy()),
  ) |>
  set_hparams(ch = 16, n_class = 2) |>
  set_opt_hparams(lr = 1e-3) |>
  fit(
    dl_tr,
    epochs = 150,
    valid_data = dl_va,
    verbose = FALSE,
    callbacks = list(luz_callback_keep_best_model(monitor = "valid_loss")),
  )

plot(cnn_fit)   # training loss keeps falling, validation loss turns up (the U); we kept the best epoch

# Score on the held-out TEST set: never used for training or early stopping ----
cnn_prob <- predict(cnn_fit, x_img[te, , , ]) |>   # logits, one column per class
  nnf_softmax(dim = 2) |>                            # turn logits into probabilities
  as.array()                                         # bring it back to R as a matrix [N, 2]
tibble(truth = factor(img$y[te], levels = c(1, 2)), .pred = cnn_prob[ , 2]) |>
  roc_auc(truth, .pred, event_level = "second")

# A real RNN on ECG traces (ECG5000) ----
rnn_net <- nn_module(
  "rnn_net",
  initialize = function(in_size, hidden = 24, n_class = 2) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
    self$head <- nn_linear(hidden, n_class)
  },
  forward = function(x) {
    out  <- self$lstm(x)
    last <- out[[1]][ , dim(out[[1]])[2], ]   # the LAST time step -> [B, hidden]
    self$head(last)
  },
)
rnn_net(in_size = 1)   # inspect the architecture

ecg   <- read_rds(here("data-raw", "ecg.rds"))   # a list: x = traces [N, 140, 1], y = labels
x_ecg <- torch_tensor(ecg$x, dtype = torch_float())
y_ecg <- torch_tensor(ecg$y, dtype = torch_long())

# See the data: one ECG trace per class, over the 140 time steps ----
ecg_show <- dplyr::bind_rows(
  tibble(t = 1:140, value = as.numeric(ecg$x[which(ecg$y == 1)[1], , 1]), class = "abnormal"),
  tibble(t = 1:140, value = as.numeric(ecg$x[which(ecg$y == 2)[1], , 1]), class = "normal"),
)
ggplot(ecg_show, aes(t, value)) +
  geom_line() +
  facet_wrap(~ class, ncol = 1) +
  theme_minimal()

# Same rsample split, stratified by class: train / validation / test ----
ecg_ids   <- tibble(row = seq_len(dim(x_ecg)[1]), class = factor(ecg$y))
set.seed(123)
ecg_split <- initial_validation_split(ecg_ids, prop = c(0.125, 0.25), strata = class)
e_tr <- training(ecg_split)$row
e_va <- validation(ecg_split)$row
e_te <- testing(ecg_split)$row

set.seed(123)
torch_manual_seed(123)
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
  fit(
    edl_tr,
    epochs = 50,     # the LSTM on ECG overfits sooner than the CNN: 50 epochs already show the U
    valid_data = edl_va,
    verbose = FALSE,
    callbacks = list(luz_callback_keep_best_model(monitor = "valid_loss")),
  )

plot(rnn_fit)

ecg_prob <- predict(rnn_fit, x_ecg[e_te, , ]) |>   # score on the held-out TEST set
  nnf_softmax(dim = 2) |>
  as.array()
tibble(truth = factor(ecg$y[e_te], levels = c(1, 2)), .pred = ecg_prob[ , 2]) |>
  roc_auc(truth, .pred, event_level = "second")

# Fused net: three modalities, one head ----
# We build it, run one forward pass, then train it on INVENTED labels just to drive the loop
# end-to-end. The three cohorts share no patient, so nothing here can generalise. One head-less
# branch per modality, concatenated into a shared head.
cnn2d_branch <- nn_module(
  "cnn2d_branch",
  initialize = function(ch = 8) {
    self$conv <- nn_conv2d(1, ch, kernel_size = 3, padding = 1)
    self$pool <- nn_adaptive_avg_pool2d(1)
  },
  forward = function(x) self$pool(nnf_relu(self$conv(x)))$squeeze(4)$squeeze(3),   # [B, ch]
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
fused_net <- nn_module(
  "fused_net",
  initialize = function(n_tab, img_ch = 8, seq_in, hidden = 16) {
    self$tab  <- nn_linear(n_tab, 16)
    self$cnn  <- cnn2d_branch(img_ch)
    self$rnn  <- rnn_branch(seq_in, hidden)
    self$head <- nn_linear(16 + img_ch + hidden, 2)
  },
  forward = function(x_tab, x_img, x_seq) {
    # >>>hole id=fused-forward kind=parsons prompt=run the three branches, concat along dim=2, then the head
    #   solved:
    t <- self$tab(x_tab)
    c <- self$cnn(x_img)
    r <- self$rnn(x_seq)
    self$head(torch_cat(list(t, c, r), dim = 2))
    # <<<hole
  },
)

# Wiring check: one example per modality (a heart_failure row, one X-ray, one ECG) returns [1, 2] ----
x_tab_all <- bake(prep(base_rec), new_data = train) |>
  dplyr::select(-outcome) |>
  as.matrix()
set.seed(123)
torch_manual_seed(123)
fused <- fused_net(n_tab = ncol(x_tab_all), img_ch = 8, seq_in = dim(x_ecg)[3], hidden = 16)
fused(
  torch_tensor(x_tab_all[1, , drop = FALSE], dtype = torch_float()),
  x_img[1, , , , drop = FALSE],
  x_ecg[1, , , drop = FALSE]
)$shape   # expect [1, 2]: the forward is wired correctly

# Line up the three cohorts arbitrarily and draw INVENTED labels (pure noise) ----
# No patient is shared, so any pairing is arbitrary and the labels carry no signal: the net can
# only memorise. The point is to SEE the same machinery run on a bespoke multi-input model.
n_fuse <- min(nrow(x_tab_all), dim(x_img)[1], dim(x_ecg)[1])
set.seed(123)
xtab_f <- torch_tensor(x_tab_all[sample(nrow(x_tab_all), n_fuse), ], dtype = torch_float())
ximg_f <- x_img[sample(dim(x_img)[1], n_fuse), , , ]
xseq_f <- x_ecg[sample(dim(x_ecg)[1], n_fuse), , ]
y_fuse <- sample(c(1L, 2L), n_fuse, replace = TRUE)

# Same rsample split as the CNN and RNN: train / validation / test, stratified ----
f_ids   <- tibble(row = seq_len(n_fuse), class = factor(y_fuse))
set.seed(123)
f_split <- initial_validation_split(f_ids, prop = c(0.125, 0.25), strata = class)
f_tr <- training(f_split)$row
f_va <- validation(f_split)$row
f_te <- testing(f_split)$row

# The training loop the section described, written out by hand (luz hides it for the CNN/RNN) ----
opt     <- optim_adam(fused$parameters, lr = 1e-3)
loss_fn <- nn_cross_entropy_loss()
y_tr <- torch_tensor(y_fuse[f_tr], dtype = torch_long())
y_va <- torch_tensor(y_fuse[f_va], dtype = torch_long())
hist <- data.frame(epoch = integer(0), train = double(0), valid = double(0))
for (epoch in seq_len(120)) {
  fused$train()
  opt$zero_grad()
  loss <- loss_fn(fused(xtab_f[f_tr, ], ximg_f[f_tr, , , ], xseq_f[f_tr, , ]), y_tr)
  loss$backward()
  opt$step()
  fused$eval()
  v <- with_no_grad(loss_fn(fused(xtab_f[f_va, ], ximg_f[f_va, , , ], xseq_f[f_va, , ]), y_va))
  hist <- rbind(hist, data.frame(epoch = epoch, train = loss$item(), valid = v$item()))
}

# The same train/val U as the CNN and RNN, drawn by hand: training loss falls, validation turns up ----
ggplot(
  tidyr::pivot_longer(hist, c(train, valid), names_to = "set", values_to = "loss"),
  aes(epoch, loss, colour = set)
) +
  geom_line() +
  theme_minimal()

# Score on the held-out TEST set: the net memorised noise, so AUC sits at chance (~0.5) ----
fused$eval()
f_prob <- with_no_grad(nnf_softmax(fused(xtab_f[f_te, ], ximg_f[f_te, , , ], xseq_f[f_te, , ]), dim = 2)) |>
  as.array()
tibble(truth = factor(y_fuse[f_te], levels = c(1, 2)), .pred = f_prob[, 2]) |>
  roc_auc(truth, .pred, event_level = "second")

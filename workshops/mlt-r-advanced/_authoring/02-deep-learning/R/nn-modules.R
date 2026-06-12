library(torch)

# 2D-CNN over a 28x28 image (e.g. a PneumoniaMNIST chest X-ray) ----
cnn2d_net <- nn_module(
  "cnn2d_net",
  initialize = function(ch = 8, n_class = 2) {
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

# RNN over a sequence (LSTM, last time step) — e.g. an ECG trace ----
rnn_net <- nn_module(
  "rnn_net",
  initialize = function(in_size, hidden = 16, n_class = 2) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
    self$head <- nn_linear(hidden, n_class)
  },
  forward = function(x) {
    out  <- self$lstm(x)
    last <- out[[1]][ , dim(out[[1]])[2], ]   # explicitly index the LAST time step -> [B, hidden]
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
  forward = function(x) self$pool(nnf_relu(self$conv(x)))$squeeze(4)$squeeze(3),   # [B, ch]
)
rnn_branch <- nn_module(
  "rnn_branch",
  initialize = function(in_size, hidden = 16) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
  },
  forward = function(x) {
    out <- self$lstm(x)
    out[[1]][ , dim(out[[1]])[2], ]   # [B, hidden]
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
    # concat along the feature dim -> [B, 16 + img_ch + hidden], then head -> [B, 2]
    self$head(torch_cat(list(t, c, r), dim = 2))
  },
)

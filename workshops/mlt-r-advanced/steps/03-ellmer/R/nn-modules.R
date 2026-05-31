library(torch)

# 1D-CNN over a short signal (e.g. an ECG-like trace) ----
cnn_branch <- nn_module(
  "cnn_branch",
  initialize = function(ch = 8) {
    self$conv <- nn_conv1d(1, ch, kernel_size = 3)
    self$pool <- nn_adaptive_avg_pool1d(1)
  },
  forward = function(x) self$pool(nnf_relu(self$conv(x)))$squeeze(3),   # [B, sig_ch]
)

# RNN over a vitals sequence ----
rnn_branch <- nn_module(
  "rnn_branch",
  initialize = function(in_size, hidden = 16) {
    self$lstm <- nn_lstm(in_size, hidden, batch_first = TRUE)
  },
  forward = function(x) {
    out <- self$lstm(x)
    out[[1]][ , dim(out[[1]])[2], ]   # explicitly index the LAST time step -> [B, hidden]
  },
)

# Fused 3-branch net: tabular MLP + CNN + RNN -> concat -> head ----
fused_net <- nn_module(
  "fused_net",
  initialize = function(n_tab, sig_ch = 8, seq_in, hidden = 16) {
    self$tab  <- nn_linear(n_tab, 16)
    self$cnn  <- cnn_branch(sig_ch)
    self$rnn  <- rnn_branch(seq_in, hidden)
    self$head <- nn_linear(16 + sig_ch + hidden, 2)
  },
  forward = function(x_tab, x_sig, x_seq) {
    t <- self$tab(x_tab)   # [B, 16]
    c <- self$cnn(x_sig)   # [B, sig_ch]
    r <- self$rnn(x_seq)   # [B, hidden]
    # concat along the feature dim -> [B, 16 + sig_ch + hidden], then head -> [B, 2]
    self$head(torch_cat(list(t, c, r), dim = 2))
  },
)

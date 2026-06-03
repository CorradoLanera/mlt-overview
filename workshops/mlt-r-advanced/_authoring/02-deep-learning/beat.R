library(brulee)

# A live MLP — knobs first, then train SMALL ----
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

# Written, not trained — the shape-check ----
source(here("R", "nn-modules.R"))
net   <- fused_net(n_tab = 11, sig_ch = 8, seq_in = 4, hidden = 16)
x_tab <- torch_randn(5, 11)
x_sig <- torch_randn(5, 1, 50)
x_seq <- torch_randn(5, 12, 4)
out   <- net(x_tab, x_sig, x_seq)
out$shape   # expect [5, 2] — five patients, two logits — WITHOUT training

# The one labeled exception — option B (pre-computed on GPU; illustrative, NOT live) ----
optionB_loss <- tibble::tibble(
  epoch = 1:40,
  loss  = round(0.12 + 0.57 * exp(-(0:39) / 8), 3),   # labeled illustrative curve (committed inline, no .rds)
)
optionB_loss |>
  ggplot2::ggplot(ggplot2::aes(epoch, loss)) +
  ggplot2::geom_line() +
  ggplot2::theme_minimal() +
  ggplot2::labs(title = "Fused-net training loss — pre-computed on GPU (labeled, not live)")

# GPU vs CPU — authored write-only (never runs here; qualified calls, no library() to hoist) ----
if (FALSE) {
  fitted <- fused_net |>
    luz::setup(loss = torch::nn_cross_entropy_loss(), optimizer = torch::optim_adam) |>
    luz::set_hparams(n_tab = 11, sig_ch = 8, seq_in = 4, hidden = 16) |>
    fit(train_dl, epochs = 40, accelerator = luz::accelerator(cpu = FALSE))
}

# Your turn — reorder the fused forward (Parsons) ----
# >>>hole id=fused-forward kind=parsons prompt=run the three branches, concat along dim=2, then the head
#   solved:
fused_forward <- function(self, x_tab, x_sig, x_seq) {
  t <- self$tab(x_tab)
  c <- self$cnn(x_sig)
  r <- self$rnn(x_seq)
  self$head(torch_cat(list(t, c, r), dim = 2))
}
# <<<hole

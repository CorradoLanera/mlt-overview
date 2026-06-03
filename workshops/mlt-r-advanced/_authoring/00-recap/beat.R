# Sanity-check the reloaded Basic model — one-row probability prediction (no retraining) ----
fitted_wf <- extract_workflow(final_fit)
predict(fitted_wf, hf[1, ], type = "prob")

# Pre-warm torch so deep learning is instant later ----
library(torch)
torch_tensor(1)             # forces the LibTorch backend to load now, not mid-demo
torch::cuda_is_available()  # FALSE on this CPU build box; TRUE on the classroom GPU machine

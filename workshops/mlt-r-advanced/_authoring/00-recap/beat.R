# The validated random-forest workflow, extracted once and reused by the explainers in step 01 ----
rf_wf <- extract_workflow(final_fit)
predict(rf_wf, hf[1, ], type = "prob")   # sanity-check: a one-row probability from the workflow

# Pre-warm torch so deep learning is instant later ----
library(torch)
torch_tensor(1)             # forces the LibTorch backend to load now, not mid-demo
torch::cuda_is_available()  # FALSE on this CPU build box; TRUE on the classroom GPU machine

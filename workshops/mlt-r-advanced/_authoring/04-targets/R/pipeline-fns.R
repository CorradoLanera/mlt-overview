# Pipeline functions for the targets capstone. Paths come from format="file" targets,
# resolved by targets relative to its project root (this step folder) — do NOT use here().
# Self-contained per spec §4.3: pkg::fun() throughout; S3 generics need their namespace loaded.
# This DAG re-runs the WHOLE workshop live (no shortcuts): rebuild cohort -> explore -> compare the
# base techniques -> recipe -> random forest -> VIMP + agnostic SHAP -> a deep-net learning curve ->
# typed LLM extraction. One tar_make() reproduces the entire arc; change one input and only its
# downstream targets recompute.
requireNamespace("workflows", quietly = TRUE)   # supplies predict.workflow / the workflow S3 methods
requireNamespace("parsnip",   quietly = TRUE)
requireNamespace("recipes",   quietly = TRUE)
requireNamespace("rsample",   quietly = TRUE)

# Rebuild the modelling cohort exactly as in the Basic workshop (clean_names first) ----
load_cohort <- function(cohort_file) {
  rio::import(cohort_file, setclass = "tibble") |>
    janitor::clean_names() |>
    dplyr::select(-time) |>
    dplyr::mutate(
      outcome = factor(
        dplyr::if_else(death_event == 1, "died", "survived"),
        levels = c("died", "survived"),
      ),
    ) |>
    dplyr::select(-death_event) |>
    dplyr::mutate(
      dplyr::across(c(anaemia, diabetes, high_blood_pressure, sex, smoking), factor),
    )
}

# Exploration: class balance + how strongly each numeric predictor separates the two outcomes ----
# (standardised group means, so every variable sits on one comparable z-axis).
explore_cohort <- function(cohort) {
  balance <- dplyr::count(cohort, outcome, name = "n")
  separation <- cohort |>
    dplyr::select(outcome, dplyr::where(is.numeric)) |>
    tidyr::pivot_longer(-outcome, names_to = "variable", values_to = "value") |>
    dplyr::group_by(variable) |>
    dplyr::mutate(z = as.numeric(scale(value))) |>
    dplyr::group_by(variable, outcome) |>
    dplyr::summarise(mean_z = mean(z), .groups = "drop")
  list(balance = balance, separation = separation)
}

# A held-out split (the same convention as Basic) ----
split_cohort <- function(cohort) {
  set.seed(123)
  rsample::initial_split(cohort, prop = 0.75, strata = outcome)
}

# The preprocessing recipe (no imputation; dummy + zv + normalize) ----
make_recipe <- function(split) {
  recipes::recipe(outcome ~ ., data = rsample::training(split)) |>
    recipes::step_dummy(recipes::all_nominal_predictors()) |>
    recipes::step_zv(recipes::all_predictors()) |>
    recipes::step_normalize(recipes::all_numeric_predictors())
}

# Confronto tecniche base: the four Basic learners (penalised logistic, kNN, SVM, random forest),
# 5-fold CV ROC-AUC on the training split, fixed hyperparameters (we compare families, not tune) ----
compare_models <- function(split, recipe) {
  set.seed(123)
  folds <- rsample::vfold_cv(rsample::training(split), v = 5, strata = outcome)
  specs <- list(
    penlog = parsnip::logistic_reg(penalty = 0.01, mixture = 1) |>
      parsnip::set_engine("glmnet"),
    knn = parsnip::nearest_neighbor(neighbors = 7) |>
      parsnip::set_engine("kknn") |>
      parsnip::set_mode("classification"),
    svm = parsnip::svm_rbf() |>
      parsnip::set_engine("kernlab") |>
      parsnip::set_mode("classification"),
    rf = parsnip::rand_forest() |>
      parsnip::set_engine("ranger") |>
      parsnip::set_mode("classification")
  )
  res <- workflowsets::workflow_set(preproc = list(rec = recipe), models = specs) |>
    workflowsets::workflow_map(
      fn        = "fit_resamples",
      resamples = folds,
      metrics   = yardstick::metric_set(yardstick::roc_auc, yardstick::pr_auc),
      seed      = 123,
      verbose   = FALSE,
    )
  workflowsets::rank_results(res, rank_metric = "roc_auc", select_best = TRUE) |>
    dplyr::filter(.metric == "roc_auc") |>
    dplyr::transmute(
      model = sub("^rec_", "", wflow_id),
      roc_auc = mean,
      std_err = std_err,
      rank,
    )
}

# Train the random forest workflow on the training split (the Basic winner) ----
fit_rf <- function(split, recipe) {
  spec <- parsnip::rand_forest() |>
    parsnip::set_engine("ranger") |>
    parsnip::set_mode("classification")
  wf <- workflows::workflow() |>
    workflows::add_recipe(recipe) |>
    workflows::add_model(spec)
  parsnip::fit(wf, data = rsample::training(split))
}

# The bridge: explain the trained forest with permutation VIMP (a serializable tibble) ----
# vip unwraps the workflow and hands the bare engine to pred_wrapper, so the closure routes
# the prediction through the captured `model` workflow. vip::vi() (not vip()) keeps the target
# value a plain tibble so tar_read()/downstream targets stay reliable.
explain_model <- function(model, cohort) {
  pred_wrapper <- function(object, newdata) predict(model, newdata, type = "prob")$.pred_died
  set.seed(1)
  vip::vi(
    model,
    method       = "permute",
    train        = cohort,
    target       = "outcome",
    metric       = "roc_auc",
    pred_wrapper = pred_wrapper,
    nsim         = 10,
    event_level  = "first",
  )
}

# Agnostic SHAP on the same forest (kernelshap + shapviz), the §01 recipe: a generic pred_fun the
# explainer hands `object` verbatim, a small fixed background, a handful of rows to explain ----
shap_explain <- function(model, split) {
  feats <- function(d) dplyr::select(d, -outcome)
  bg <- rsample::training(split)
  set.seed(1)
  bg_small <- dplyr::slice_sample(bg, n = 40) |> feats()
  X        <- dplyr::slice_sample(bg, n = 30) |> feats()
  pred_fun <- function(object, X, ...) predict(object, X, type = "prob")$.pred_died
  ks <- kernelshap::kernelshap(model, X = X, bg_X = bg_small, pred_fun = pred_fun, verbose = FALSE)
  shapviz::shapviz(ks)
}

# A live deep-net learning curve: a brulee MLP on the tabular cohort, the per-epoch validation loss ----
# brulee fits in torch with early stopping (the §02 idea): training halts a few epochs after the
# validation loss stops improving, so the curve is the clean descent to the best epoch — no runaway
# divergence on this small cohort. Returns a plain tibble for the report.
learning_curve <- function(split, recipe) {
  prepped <- recipes::prep(recipe)
  train_baked <- recipes::bake(prepped, new_data = rsample::training(split))
  set.seed(123)
  fit <- brulee::brulee_mlp(
    outcome ~ .,
    data         = train_baked,
    hidden_units = 16,
    epochs       = 100,
    penalty      = 0.01,
    learn_rate   = 0.01,
    validation   = 0.2,
    stop_iter    = 5L,
  )
  tibble::tibble(epoch = seq_along(fit$loss), valid_loss = fit$loss)
}

# Typed LLM extraction (the §03 ETL), live when a key is present, a labeled example otherwise ----
extract_notes <- function(notes_file) {
  notes <- rio::import(notes_file, setclass = "tibble")
  note_type <- ellmer::type_object(
    age               = ellmer::type_integer("patient age in years"),
    ejection_fraction = ellmer::type_number("ejection fraction as a percentage; NA if not stated"),
    on_betablocker    = ellmer::type_boolean("TRUE if a beta-blocker is given or continued"),
    primary_dx        = ellmer::type_enum(
      c("ischemic", "hypertensive", "valvular", "other"),
      "primary cardiac diagnosis",
    ),
    serum_creatinine  = ellmer::type_number("serum creatinine in mg/dL; NA if not stated"),
  )
  if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    chat <- ellmer::chat_openai(
      model  = "gpt-5.4-nano",
      params = ellmer::params(temperature = 0),
      echo   = "none",
    )
    ellmer::parallel_chat_structured(chat, as.list(notes$text), type = note_type)
  } else {
    tibble::tibble(
      age               = c(78L, 65L, 60L),
      ejection_fraction = c(30, 45, 30),
      on_betablocker    = c(TRUE, FALSE, TRUE),
      primary_dx        = c("ischemic", "hypertensive", "ischemic"),
      serum_creatinine  = c(1.8, 1.2, 2.1),
    )
  }
}

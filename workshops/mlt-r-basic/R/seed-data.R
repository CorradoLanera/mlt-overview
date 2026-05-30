# Seed the committed clinical dataset. Run once at build.
# Heart failure clinical records (Chicco & Jurman 2020, BMC Med Inform Decis Mak; UCI).
# 299 patients, outcome DEATH_EVENT. The follow-up column `time` is KEPT in the raw
# bundle but DROPPED in step 01 (it leaks the outcome) — that exclusion is a teaching beat.
library(here)
library(rio)

url <- "https://raw.githubusercontent.com/dimikara/heart-failure-prediction/master/heart_failure_clinical_records_dataset.csv"
heart_failure <- import(url, setclass = "tibble")
export(heart_failure, here("data-raw", "heart_failure.csv"))

cat(
  "rows:", nrow(heart_failure),
  "cols:", ncol(heart_failure),
  "event rate:", round(mean(heart_failure$DEATH_EVENT == 1), 3), "\n"
)

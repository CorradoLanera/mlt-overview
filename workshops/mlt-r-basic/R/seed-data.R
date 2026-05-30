library(here)
library(rio)
indo_rct <- medicaldata::indo_rct
export(indo_rct, here("data-raw", "indo_rct.csv"))
cat("rows:", nrow(indo_rct), "event rate:", round(mean(indo_rct$outcome == "1_yes"), 3), "\n")

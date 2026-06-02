# Setup ----
library(here)
library(rio)

# >>>hole id=load kind=fill prompt=load the clinical CSV with rio + here
#   solved:
hf_raw <- import(here("data-raw", "heart_failure.csv"), setclass = "tibble")
#   blank:
hf_raw <- import(here("data-raw", "___"), setclass = "tibble")
# <<<hole
dim(hf_raw)

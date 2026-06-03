library(ellmer)

notes <- rio::import(here("data-raw", "hf_notes.csv"), setclass = "tibble")

# A typed schema is the contract that turns an LLM into an ETL (not a chat) ----
# (ellmer 0.4.1: type_enum(values, description) — values first, description second.)
note_type <- type_object(
  age               = type_integer("patient age in years"),
  ejection_fraction = type_number("ejection fraction as a percentage; NA if not stated"),
  on_betablocker    = type_boolean("TRUE if a beta-blocker is given or continued"),
  primary_dx        = type_enum(
    c("ischemic", "hypertensive", "valvular", "other"),
    "primary cardiac diagnosis",
  ),
)

# Key from the workshop-root .Renviron (gitignored), env only — .here anchors here() to THIS step ----
renviron_path <- here("..", "..", ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

# ONE live extraction; labeled INLINE fallback when no key (honesty doctrine, no shipped cache) ----
if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  chat <- chat_openai(model = "gpt-5.4-nano", echo = "none")
  chat$chat_structured(notes$text[[1]], type = note_type)
} else {
  cat("[No API key set — showing a LABELED example of an earlier live extraction.]\n")
  list(age = 78L, ejection_fraction = 30, on_betablocker = TRUE, primary_dx = "ischemic")
}

# The batch — WRITTEN, NOT RUN (it would call the API once per note) ----
# Low temperature => deterministic ETL; map iterates note-by-note into a typed tibble.
if (FALSE) {
  extract_one <- function(txt) {
    chat_openai(model = "gpt-5.4-nano", params = params(temperature = 0))$chat_structured(txt, type = note_type)
  }
  notes |>
    dplyr::mutate(parsed = purrr::map(text, extract_one)) |>
    tidyr::unnest_wider(parsed)
}

# Your turn — extend the schema ----
# >>>hole id=schema-field kind=fill prompt=add a serum_creatinine field (a number in mg/dL, NA if not stated)
#   solved:
serum_creatinine <- type_number("serum creatinine in mg/dL; NA if not stated")
serum_creatinine
#   blank:
serum_creatinine <- type_number(___)
serum_creatinine
# <<<hole

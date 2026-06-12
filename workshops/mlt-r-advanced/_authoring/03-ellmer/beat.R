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
  # >>>hole id=schema-field kind=fill prompt=add a serum_creatinine field: a number in mg/dL, NA if not stated
  #   solved:
  serum_creatinine  = type_number("serum creatinine in mg/dL; NA if not stated"),
  #   blank:
  serum_creatinine  = type_number(___),
  # <<<hole
)

# Key from the workshop-root .Renviron (gitignored), env only — .here anchors here() to THIS step ----
renviron_path <- here("..", "..", ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

# ONE live extraction; labeled INLINE fallback when no key (honesty doctrine, no shipped cache) ----
if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  chat <- chat_openai(model = "gpt-5.4-nano", echo = "none")
  record <- chat$chat_structured(notes$text[[1]], type = note_type)
} else {
  cat("[No API key set: showing a LABELED example of an earlier live extraction.]\n")
  record <- list(age = 78L, ejection_fraction = 30, on_betablocker = TRUE,
                 primary_dx = "ischemic", serum_creatinine = 1.8)
}
record   # name the object to print it: ellmer's structured calls return invisibly

# Scale to EVERY note at once: parallel_chat_structured fires the requests concurrently and returns
# a typed tibble, one row per note, so the answer comes back now. Same chat, same schema. ----
if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  chat <- chat_openai(model = "gpt-5.4-nano", params = params(temperature = 0), echo = "none")
  records <- parallel_chat_structured(chat, as.list(notes$text), type = note_type)
} else {
  cat("[No API key set: showing a LABELED example of an earlier parallel extraction.]\n")
  records <- tibble::tibble(
    age               = c(78L, 65L, 60L),
    ejection_fraction = c(30, 45, 30),
    on_betablocker    = c(TRUE, FALSE, TRUE),
    primary_dx        = c("ischemic", "hypertensive", "ischemic"),
    serum_creatinine  = c(1.8, 1.2, 2.1),
  )
}
records   # likewise named, so the tibble prints: one validated row per note

# The provider's cheaper Batch API is the SAME call with one word changed: batch_chat_structured in
# place of parallel_chat_structured (plus a path to resume the job). It trades immediacy for ~50%
# lower cost, polling until the whole batch returns: right for large offline jobs, not a live class. ----
# chat <- chat_openai(model = "gpt-5.4-nano", params = params(temperature = 0), echo = "none")
# batch_chat_structured(chat, as.list(notes$text), path = here("hf_notes_batch.json"), type = note_type)

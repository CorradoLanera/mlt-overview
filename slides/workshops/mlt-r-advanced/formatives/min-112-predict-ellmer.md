# Formative · min 112 · predict-output (after Step 03, type_object schema)

- **Type:** predict-output (predict before the reveal)
- **Concept-graph nodes checked:** `SCHEMA` — type_object typed schema; `ELLMER` — LLM as typed reproducible ETL

## Prompt

We defined this `type_object()` schema for extracting structured data from heart-failure
clinical notes (the same schema as Step 03):

```r
schema <- type_object(
  age                = type_integer("patient age in years"),
  ejection_fraction  = type_number("ejection fraction as a percentage; NA if not stated"),
  on_betablocker     = type_boolean("TRUE if a beta-blocker is given or continued"),
  primary_dx         = type_enum(
    c("ischemic", "hypertensive", "valvular", "other"),
    "primary cardiac diagnosis"
  )
)
```

Before running the extraction:

1. How many **fields** does this record have, and what are their **R types** after
   parsing?
2. A note reads *"60-year-old male, EF 30%, no medications listed."*
   The `primary_dx` field is **absent** from the note. What does `ellmer` return
   for that field?

## Expected answer

**Fields and R types:**

- `age` → `integer` (whole number of years)
- `ejection_fraction` → declared `type_number`; arrives as R **integer** for a whole-number JSON value (e.g. 30) or **double** if the JSON has a decimal — see the subtlety below.
- `on_betablocker` → `logical` (`TRUE` / `FALSE`)
- `primary_dx` → `character` (one of the four enum values, or `NULL` / `NA` if absent)

Four fields total.

**Subtlety — integer vs double:** JSON does not distinguish integer from floating-point
for whole numbers. A note giving `EF = 30` produces a JSON value `30` (no decimal).
`ellmer` parses a `type_number` field from a whole-number JSON value as R `integer`,
not `double`. Strict type-checked code will catch this: for example,
`stopifnot(is.double(rec$ejection_fraction))` would **fail** on the integer value 30.
Coerce explicitly when downstream code requires a double:
`as.double(result$ejection_fraction)`.

**Absent enum field:** when the note contains no indication of `primary_dx`,
`ellmer` returns `NULL` (or `NA` after coercion to character) for that field.
The schema does **not** raise an error — the typed schema defines what to look for,
not a hard requirement that the field must be present in the source text. This
graceful handling is what makes the approach robust for messy real-world notes.

## Diagnostic note (teacher)

The integer-vs-double subtlety often surprises students who expect `type_number`
to always yield a `double`. Use this moment to distinguish: `type_integer` signals
to the LLM "extract a whole number"; `type_number` signals "extract any numeric
value" — but what arrives in R is determined by the JSON representation the LLM
produces, not by the R type annotation alone.

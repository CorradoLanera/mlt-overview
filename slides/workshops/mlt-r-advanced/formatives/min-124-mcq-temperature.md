# Formative · min 124 · MCQ (after Step 03, LLM parameter slide)

- **Type:** MCQ (diagnostic distractors)
- **Concept-graph nodes checked:** `LLMPAR` — LLM params: model / temperature / typing; `BATCH` — purrr::map batch written not run

## Prompt

We set `temperature = 0` and wrap the extraction call in `purrr::map()`.
What do these two choices achieve together?

## Options

- **A. ✓ (correct)** **`temperature = 0` gives determinism** — the LLM always
  produces the same structured output for the same input, making the extraction
  pipeline a **reproducible ETL**, not a stochastic chat. **`purrr::map()`** applies
  the extraction function **element-by-element** over the list of notes, producing
  one structured record per note.
- **B.** A **lower temperature improves answer quality**: the LLM is more careful and
  accurate at temperature 0, so setting it low is always the right choice for any
  task.
- **C.** Setting a **high temperature and using `map()`** runs the extractions on the
  GPU: `map()` parallelises calls across cores, and high temperature enables
  sampling-based GPU acceleration.
- **D.** **Temperature is irrelevant for structured extraction**: because we supply
  a `type_object()` schema, the LLM is constrained to return valid JSON regardless
  of temperature, so the setting has no practical effect.

## Misconception each distractor reveals

- **B → "temperature = quality."** Conflates sampling diversity with accuracy:
  temperature controls randomness, not capability. For extraction tasks we want
  **zero randomness** (determinism), not "more careful" — the LLM's reasoning
  ability is not affected by temperature.
- **C → "high temperature + map = GPU."** Invents a connection between temperature,
  `purrr::map()`, and hardware that does not exist. `map()` iterates sequentially
  (or in parallel via `furrr`); neither it nor temperature has any relationship with
  GPU execution.
- **D → "temperature is irrelevant for typed extraction."** Even with a typed schema,
  temperature controls whether the LLM samples the *same* highest-probability token
  sequence every time. At `temperature > 0`, two calls on the same note may produce
  different field values; at `temperature = 0` the output is deterministic (greedy
  decoding).

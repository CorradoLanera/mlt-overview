# Seed bundled artifacts (run once at build). The Advanced workshop is a standalone
# distributable: it carries the Basic-validated model + the cohort it explains.
library(here)
library(rio)

# 1) the validated Basic model (heart-failure random forest) + its cohort
basic <- here("..", "mlt-r-basic")
file.copy(file.path(basic, "steps", "04-zoo", "output", "final_fit.rds"),
          here("model", "final_fit.rds"), overwrite = TRUE)
# NOTE: raw CSV has DEATH_EVENT (uppercase, UCI original); downstream steps apply
#       janitor::clean_names() -> death_event, the name used in all step scripts.
file.copy(file.path(basic, "data-raw", "heart_failure.csv"),
          here("data-raw", "heart_failure.csv"), overwrite = TRUE)

# 2) ~12 SYNTHETIC, de-identified clinical notes for the ellmer typed-ETL block.
#    No PHI — fabricated, illustrative. Fields to extract: age, ejection_fraction,
#    on_betablocker (bool), primary_dx (enum: ischemic/hypertensive/valvular/other).
#
#    Coverage matrix (for unit tests in step 03):
#      primary_dx     : ischemic x4, hypertensive x4, valvular x2, other x2
#      on_betablocker : TRUE x8, FALSE x3, NA x1  (edge: N11 — beta-blocker not mentioned)
#      ejection_fraction : present x11, NA x1  (edge: N08 — no echo this admission)
notes <- tibble::tibble(
  note_id = sprintf("N%02d", 1:12),
  text = c(
    # N01 — ischemic, EF present, BB TRUE
    "78-year-old woman admitted for decompensated heart failure secondary to ischemic cardiomyopathy; LVEF 30%; bisoprolol 5 mg continued.",
    # N02 — ischemic, EF present, BB FALSE (explicit)
    "Male, 62, with known ischemic cardiomyopathy and ejection fraction of 25 percent; not on a beta-blocker due to reactive airway disease.",
    # N03 — hypertensive, EF present, BB TRUE
    "Patient aged 55 with hypertensive heart disease; echocardiography shows EF preserved at 58%; carvedilol 6.25 mg twice daily continued.",
    # N04 — hypertensive, EF present, BB TRUE
    "A 70 yo man with long-standing hypertensive cardiomyopathy, LVEF of 40%, started on metoprolol succinate 25 mg at discharge.",
    # N05 — valvular, EF present, BB TRUE
    "64-year-old female with severe aortic stenosis and concomitant atrial fibrillation; EF 45%, nebivolol 5 mg daily initiated for rate control.",
    # N06 — valvular, EF present, BB FALSE (explicit)
    "Male patient, 71, admitted with acute decompensated heart failure from mitral regurgitation, EF 35%; beta-blocker withheld pending haemodynamic stabilisation.",
    # N07 — ischemic, EF present, BB TRUE
    "A 67-year-old man with prior MI and ischemic cardiomyopathy; repeat echo confirms LVEF 22%; bisoprolol uptitrated to 10 mg.",
    # N08 — hypertensive, EF MISSING (edge case: no EF stated), BB TRUE
    "Elderly woman, 80, with hypertensive heart disease presenting with flash pulmonary oedema; carvedilol restarted after diuresis; no echocardiogram obtained during this admission.",
    # N09 — other (dilated/idiopathic), EF present, BB TRUE
    "42-year-old woman with newly diagnosed idiopathic dilated cardiomyopathy; ejection fraction 20%; metoprolol succinate 12.5 mg commenced.",
    # N10 — other (non-ischemic/non-hypertensive: Takotsubo), EF present, BB FALSE (explicit)
    "A 58 yo woman with Takotsubo cardiomyopathy, EF transiently reduced to 38%; beta-blocker not prescribed at this time.",
    # N11 — ischemic, EF present, BB NA (ambiguous: BB not mentioned at all — edge case)
    "Male, 75, with multi-vessel coronary artery disease and ischemic cardiomyopathy; echocardiography shows LVEF 28%; discharge medications pending cardiology review.",
    # N12 — hypertensive, EF present, BB TRUE
    "53-year-old man with hypertensive cardiomyopathy; EF 50% on latest echo; on bisoprolol 2.5 mg once daily as outpatient."
  )
)
export(notes, here("data-raw", "hf_notes.csv"))
cat("seeded: final_fit.rds, heart_failure.csv,", nrow(notes), "synthetic notes\n")

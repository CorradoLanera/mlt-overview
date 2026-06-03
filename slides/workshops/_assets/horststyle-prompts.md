# Illustration assets — workshop theory slides

Questo file è la **fonte di verità** per le illustrazioni delle slide di teoria dei
workshop R (Basic e Advanced). Tre fonti, tutte citate nei credits dei deck:

1. **Allison Horst** — arte CC BY 4.0 scaricata in `img/horst/` (vedi inventario sotto).
2. **Corso ECDC UBEP (2023)** — screenshot/diagrammi tuoi riusati, in `img/ecdc/`.
3. **Images2.0** — illustrazioni mancanti (soprattutto i pacchetti tidymodels) da
   generare con lo *style anchor* qui sotto e i prompt per-immagine. Salvale in
   `img/horststyle/` con il **nome file indicato**: sulla slide corrispondente c'è già
   un commento `<!-- … -->` con la riga `<img>` pronta da scommentare.

> Nota copyright: i prompt Images2.0 chiedono uno **stile ispirato** alle illustrazioni
> amichevoli/“mostriciattoli” della data-science (acquerello, sfondo bianco), con
> **personaggi originali** — non riprodurre i personaggi specifici di Horst. Così
> l'arte generata è nostra e citabile senza ambiguità.

---

## Style anchor (da incollare come prompt di sistema / immagine di riferimento)

> Friendly, hand-painted **watercolor & gouache** illustration in the style of
> open-source data-science teaching art: soft, warm pastel palette, **rounded fuzzy
> creatures** with simple dot eyes and gentle smiles, **clean white background**,
> generous negative space, a few **hand-lettered labels** only where essential, light
> pencil outlines, no gradients-from-a-computer look, no photorealism, no dense text,
> no logos, no copyrighted characters. Square-ish or 4:3 framing, print-clean at small
> size. Original characters. Cheerful, encouraging mood for absolute beginners.

Usa lo style anchor **in testa a ogni prompt** per-immagine qui sotto.

---

## Prompt per-immagine (concetti senza arte Horst)

Per ognuno: **file** = nome con cui salvare in `img/horststyle/`; **dove** = slide;
**alt** = testo alternativo; **prompt** = soggetto (dopo lo style anchor).

### 1. `rsample.png` — train/test split
- **dove:** Basic, "The tidymodels spine".
- **alt:** A dataset creature being split into a big training pile and a small sealed test box.
- **prompt:** a friendly pile of little data-point creatures being gently sorted by a
  smiling helper into a **large "train" basket** and a **small "test" box with a lock**;
  a hand-lettered "75 / 25" tag; the test box is set aside, untouched.

### 2. `recipes.png` — preprocessing recipe
- **dove:** Basic, "The five packages & the functions we call".
- **alt:** A recipe card turning raw columns into model-ready ingredients.
- **prompt:** a cozy kitchen scene where a chef-creature follows a **recipe card** to
  turn raw mismatched vegetables (columns) into neat, equal-sized prepped pieces;
  three little hand-lettered steps: "dummy", "drop zero-variance", "normalize".

### 3. `workflows.png` — bundle recipe + model
- **dove:** Basic, "The five packages & the functions we call".
- **alt:** A recipe card and a model creature being clipped together into one bundle.
- **prompt:** a **recipe card** and a small **model creature** being clipped together
  into a single tidy lunchbox labeled "workflow", so nothing can leak out or get lost.

### 4. `yardstick.png` — scoring predictions
- **dove:** Basic, "The five packages & the functions we call" / "Two metrics".
- **alt:** A friendly ruler measuring how good predictions are, with two gauges.
- **prompt:** a cheerful **measuring-tape creature** holding up two round gauges labeled
  "ROC" and "PR", checking predictions against the truth; a small bullseye in the corner.

### 5. `gtsummary.png` — clinical Table 1
- **dove:** Basic, "gtsummary — a clinical Table 1".
- **alt:** A tidy summary table being assembled, split by outcome.
- **prompt:** a tidy **"Table 1"** being assembled by small helpers, with two columns
  labeled "died" and "survived"; rows of neat little numbers; a magnifying glass.

### 6. `crossval.png` — k-fold cross-validation (optional; repo already has grid_search_cross_validation.png)
- **dove:** Basic, "Tuning machinery" (alternativa al diagramma scikit-learn).
- **alt:** Five rotating folds, each taking a turn as the validation slice.
- **prompt:** five horizontal **folds/strips** of data creatures; in five little frames
  one strip at a time is highlighted as the "check" slice while the rest are "learn";
  a circular arrow suggesting rotation; hand-lettered "5-fold".

### 7. `workflowset.png` — the tuned model zoo
- **dove:** Basic, "Step 04 · The model zoo".
- **alt:** Four different little model creatures competing on a shared course.
- **prompt:** **four distinct friendly creatures** (a straight-line one, a
  nearest-neighbours huddle, a margin-with-a-fence one, a little forest of trees) lined
  up at the start of the **same** race track labeled "5-fold CV"; one shared whistle.

### 8. `reproducible-report.png` — one render, honest numbers
- **dove:** Basic, "Step 05 · Reproducible report".
- **alt:** A document whose numbers are wired to the code that produced them.
- **prompt:** a friendly **report document** whose printed numbers are connected by tiny
  visible wires to the code and data that made them, so they can never disagree; a small
  padlock labeled "renv" and a compass labeled "here".

---

## Inventario immagini reali già in repo (no generazione)

| file | concetto | fonte / attribuzione |
|---|---|---|
| `img/horst/here.png` | here:: stable paths | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/cracked_setwd.png` | perché non `setwd()` | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/tidyverse_celestial.png` | il tidyverse | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/dplyr_wrangling.png` | dplyr wrangling | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/dplyr_filter.jpg` | filter() | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/tidydata_3.jpg` | tidy data | Lowndes & Horst, Openscapes (CC BY 4.0) |
| `img/horst/ggplot2_masterpiece.png` | ggplot2 | Artwork by Allison Horst (CC BY 4.0) |
| `img/horst/parsnip.png` | parsnip `set_engine()` / engine-swap | Artwork by Allison Horst (CC BY 4.0) |

> Horst **non ha** arte per janitor, forcats, né per i pacchetti tidymodels
> (rsample/recipes/workflows/yardstick/tune): quelle vanno generate con Images2.0
> (prompt sopra). `parsnip.png` (le macchinine "set_engine()") copre l'idea engine-swap.
| `img/ecdc/rstudio-native-pipe.png` | il pipe `|>` | UBEP ECDC R course (2023) |
| `img/ecdc/rio-formats.png` | rio import() | UBEP ECDC R course (2023) |
| `img/ecdc/renv-workflow.png` | renv restore/snapshot | UBEP ECDC R course (2023) |
| `img/ecdc/ggplot-layers.png` | grammatica a layer | UBEP ECDC R course (2023) — verificare origine diagramma |
| `img/grid_search_cross_validation.png` | k-fold CV | scikit-learn docs |
| `img/tree.jpg`, `img/knn.jpg` | RF / kNN intuizione | overview (già in repo) |

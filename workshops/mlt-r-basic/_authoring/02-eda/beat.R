library(gtsummary)

# Stratified summary table ----
hf |>
  tbl_summary(
    by = outcome,
    include = c(
      age, sex, ejection_fraction, serum_creatinine, serum_sodium,
      creatinine_phosphokinase, platelets, anaemia, diabetes,
      high_blood_pressure, smoking,
    ),
  )

# Ejection fraction by outcome ----
ef_plot <- hf |>
  ggplot(aes(x = outcome, y = ejection_fraction, fill = outcome)) +
  geom_boxplot() +
  theme_minimal()

ef_plot

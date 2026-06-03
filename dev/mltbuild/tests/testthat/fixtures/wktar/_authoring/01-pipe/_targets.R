library(targets)
source("R/pipeline-fns.R")
list(
  # >>>hole id=t kind=fill prompt=make x a target
  #   solved:
  tar_target(x, make_x()),
  #   blank:
  tar_target(x, ___()),
  # <<<hole
)

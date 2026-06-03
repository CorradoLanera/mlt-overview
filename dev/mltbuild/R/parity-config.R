# Per-workshop structural-parity expectations, read from each step's meta$check.
parity_checks <- function(wk) {
  out <- list()
  for (st in wk$steps) {
    ck <- st$meta$check
    if (is.null(ck)) next
    out[[st$slug]] <- list(kw = as.character(ck$kw %||% character(0)),
                           imgs = as.integer(ck$imgs %||% 0L))
  }
  out
}

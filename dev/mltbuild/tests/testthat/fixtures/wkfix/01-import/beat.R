# Wrangle ----
# >>>hole id=clean kind=fill prompt=clean the names
#   solved:
toy <- janitor::clean_names(toy)
#   blank:
toy <- janitor::___(toy)
# <<<hole
# (fixture-only: this frag duplicates the hole solved on purpose; real beats capture a distinct block)
# >>>frag id=clean-call
toy <- janitor::clean_names(toy)
# <<<frag

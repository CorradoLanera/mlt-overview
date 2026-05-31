# _dependencies.R — renv dependency hint only; never source()d during the workshop.
# ranger is referenced only as an engine string inside the saved workflow object,
# so renv's static scanner would miss it without this explicit library() call.
library(ranger)

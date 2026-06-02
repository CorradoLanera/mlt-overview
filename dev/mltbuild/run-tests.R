# Source the engine and run the testthat suite. Usage: Rscript dev/mltbuild/run-tests.R
here_dir <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)))
for (f in list.files(file.path(here_dir, "R"), pattern = "[.]R$", full.names = TRUE)) source(f)
testthat::test_dir(file.path(here_dir, "tests", "testthat"), stop_on_failure = TRUE)

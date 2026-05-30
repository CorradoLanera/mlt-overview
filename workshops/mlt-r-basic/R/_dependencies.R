# _dependencies.R — NOT executed; exists so {renv} captures packages that are
# referenced only via parsnip set_engine("...") STRINGS (which renv's static
# dependency scanner cannot see). Keep in sync with the engines used in steps/04-zoo.
library(glmnet)   # penalized logistic (penalty/mixture)
library(kknn)     # k-nearest neighbors
library(kernlab)  # SVM (RBF)
library(ranger)   # random forest

# Contract of every shipped dataset: columns, their types, and the columns
# that together identify one observation (the key).
dataset_contract <- list(
  breakpoints = list(
    columns = c(variable = "factor", frequency = "factor", percentile = "factor",
                period = "character", value = "numeric"),
    key = c("variable", "frequency", "percentile", "period")),
  factors = list(
    columns = c(region = "factor", frequency = "factor", factor = "character",
                period = "character", value = "numeric"),
    key = c("region", "frequency", "factor", "period")),
  portfolios_univariate = list(
    columns = c(region = "factor", frequency = "factor", `sort variable` = "factor",
                dividend = "factor", weights = "factor", portfolio = "character",
                field = "factor", period = "character", value = "numeric"),
    key = c("region", "frequency", "sort variable", "dividend", "weights",
            "portfolio", "field", "period")),
  portfolios_bivariate = list(
    columns = c(region = "factor", frequency = "factor", `sort variable 1` = "factor",
                `sort variable 2` = "factor", dividend = "factor", weights = "factor",
                portfolio = "character", field = "factor", period = "character",
                value = "numeric"),
    key = c("region", "frequency", "sort variable 1", "sort variable 2", "dividend",
            "weights", "portfolio", "field", "period")),
  portfolios_trivariate = list(
    columns = c(region = "factor", frequency = "factor", `sort variable 1` = "factor",
                `sort variable 2` = "factor", `sort variable 3` = "factor",
                dividend = "factor", weights = "factor", portfolio = "character",
                field = "factor", period = "character", value = "numeric"),
    key = c("region", "frequency", "sort variable 1", "sort variable 2",
            "sort variable 3", "dividend", "weights", "portfolio", "field", "period")),
  portfolios_industries = list(
    columns = c(region = "factor", frequency = "factor", dividend = "factor",
                weights = "factor", portfolio = "character", field = "factor",
                period = "character", value = "numeric"),
    key = c("region", "frequency", "dividend", "weights", "portfolio", "field", "period")),
  variables = list(
    columns = c(name = "character", symbol = "character", description = "character"),
    key = "name",
    # "value weight average of ..." fields are derived and have no symbol.
    nullable = "symbol")
)

# Datasets are cached so every test shares one copy: testthat's expectations
# keep each test's environment alive, and separate loads of the 1.7 GiB
# bivariate table would overlap and exhaust the 3 GB container. Tests only
# read the datasets.
dataset_cache <- new.env(parent = emptyenv())

load_dataset <- function(name) {
  if (!exists(name, envir = dataset_cache, inherits = FALSE)) {
    gc()
    env <- new.env()
    utils::data(list = name, package = "FFresearch", envir = env)
    assign(name, get(name, envir = env), envir = dataset_cache)
  }
  get(name, envir = dataset_cache)
}

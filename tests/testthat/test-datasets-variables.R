# `variables` describes the other datasets' fields: every name they use must
# have a row (spec #3, story 6), and derived rows keep a missing symbol
# (story 25). Datasets are loaded one at a time: the bivariate is about 2 GB.

test_that("`variables` covers every field used in the other datasets", {
  variables <- load_dataset("variables")
  check <- function(name, columns) {
    x <- load_dataset(name)
    used <- unlist(lapply(columns, function(column) {
      values <- x[[column]]
      if (is.factor(values)) levels(values) else unique(values)
    }), use.names = FALSE)
    rm(x); gc()
    missing <- setdiff(used, variables$name)
    expect_identical(missing, character(0), info = paste("names used in", name))
  }
  check("portfolios_univariate", c("sort variable", "field"))
  check("portfolios_bivariate", c("sort variable 1", "sort variable 2", "field"))
  check("portfolios_trivariate", c("sort variable 1", "sort variable 2", "sort variable 3", "field"))
  check("portfolios_industries", "field")
  check("breakpoints", "variable")
  check("factors", "factor")
})

test_that("`variables` derived rows keep a missing symbol", {
  variables <- load_dataset("variables")
  derived <- variables[grepl("^(value|equal) weight average of ", variables$name), ]
  expect_gt(nrow(derived), 0L)
  expect_true(all(is.na(derived$symbol)))
})

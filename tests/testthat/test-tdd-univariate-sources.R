test_that("univariate_sources maps one row per library file", {
  sources <- univariate_sources()

  expect_s3_class(sources, "data.table")
  expect_named(sources, c("file", "region", "sort variable", "dividend", "weights"))
  expect_equal(anyDuplicated(sources$file), 0L)
  expect_setequal(sources$region, "US")
})

test_that("univariate_sources covers every committed sort variable, dividend and weights level", {
  sources <- univariate_sources()
  committed <- load_dataset("portfolios_univariate")
  combinations <- function(x) unique(paste(x$`sort variable`, x$dividend))

  expect_setequal(sources$`sort variable`, levels(committed$`sort variable`))
  expect_setequal(sources$dividend, levels(committed$dividend))
  expect_setequal(unlist(sources$weights), levels(committed$weights))
  expect_setequal(combinations(sources), combinations(committed))
  expect_true(all(vapply(sources$weights, function(w) setequal(w, c("value", "equal")), logical(1))))
})

test_that("univariate_sources labels the prior-return sorts and dividends as the library does", {
  sources <- univariate_sources()

  expect_equal(source_label(sources, "10_Portfolios_Prior_12_2", "sort variable"), "momentum")
  expect_equal(source_label(sources, "10_Portfolios_Prior_1_0", "sort variable"), "short term reversal")
  expect_equal(source_label(sources, "10_Portfolios_Prior_60_13", "sort variable"), "long term reversal")
  expect_equal(source_label(sources, "Portfolios_Formed_on_ME", "dividend"), "Y")
  expect_equal(source_label(sources, "Portfolios_Formed_on_ME_Wout_Div", "dividend"), "N")
  expect_equal(source_label(sources, "Portfolios_Formed_on_ME_Daily", "dividend"), "Y")
})

test_that("every univariate library file exists in the live library", {
  expect_files_in_library(univariate_sources()$file)
})

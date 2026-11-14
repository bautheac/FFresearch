test_that("industries_sources maps one row per library file", {
  sources <- industries_sources()

  expect_s3_class(sources, "data.table")
  expect_named(sources, c("file", "region", "dividend", "classification", "weights"))
  expect_equal(anyDuplicated(sources$file), 0L)
  expect_setequal(sources$region, "US")
  expect_equal(nrow(sources), 24L)
})

test_that("industries_sources covers every committed dividend and weights level", {
  sources <- industries_sources()
  committed <- load_dataset("portfolios_industries")

  expect_setequal(sources$dividend, levels(committed$dividend))
  expect_setequal(unlist(sources$weights), levels(committed$weights))
  expect_setequal(sources$classification, c(5L, 10L, 12L, 17L, 30L, 38L, 48L, 49L))
  expect_true(all(vapply(sources$weights, function(w) setequal(w, c("value", "equal")), logical(1))))
})

test_that("industries_sources labels dividends and classifications as the library does", {
  sources <- industries_sources()

  expect_equal(source_label(sources, "49_Industry_Portfolios", "dividend"), "Y")
  expect_equal(source_label(sources, "49_Industry_Portfolios_Wout_Div", "dividend"), "N")
  expect_equal(source_label(sources, "49_Industry_Portfolios_daily", "dividend"), "Y")
  expect_equal(source_label(sources, "49_Industry_Portfolios", "classification"), 49L)
  expect_equal(source_label(sources, "5_Industry_Portfolios", "classification"), 5L)
})

test_that("industries_portfolios lists the committed portfolio labels", {
  committed <- load_dataset("portfolios_industries")

  expect_setequal(industries_portfolios(), unique(committed$portfolio))
  expect_equal(length(industries_portfolios()), 86L)
})

test_that("every industry library file exists in the live library", {
  expect_files_in_library(industries_sources()$file)
})

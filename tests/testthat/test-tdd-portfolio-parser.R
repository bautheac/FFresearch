# Expected long rows, in file order: portfolio, field, weights, period, value, frequency.
long_rows <- function(field, weights, frequency, portfolio, period, value) {
  data.table::data.table(portfolio = portfolio, field = field, weights = weights,
                         period = period, value = value, frequency = frequency)
}

test_that("PortfolioParser reads every industry section into exact long rows", {
  table <- PortfolioParser$new()$parse(fixture_lines("industry.csv"))

  # Rows follow the header order, then the file order within each portfolio
  # (the same layout FrenchParser's melt produces).
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month",
              rep(c("Agric", "Food"), each = 2L), rep(c("192607", "192608"), 2L),
              c(2.36, 2.23, 0.09, 2.71)),
    long_rows("return", "equal", "month",
              rep(c("Agric", "Food"), each = 2L), rep(c("192607", "192608"), 2L),
              c(2.64, 0.37, 0.69, 4.00)),
    long_rows("return", "value", "year",
              rep(c("Agric", "Food"), each = 2L), rep(c("1927", "1928"), 2L),
              c(26.26, 2.47, 41.95, 28.00)),
    long_rows("return", "equal", "year",
              rep(c("Agric", "Food"), each = 2L), rep(c("1927", "1928"), 2L),
              c(61.21, -3.09, 25.01, 31.70)),
    long_rows("number of firms", NA_character_, "month",
              rep(c("Agric", "Food", "Soda"), each = 2L), rep(c("192607", "192608"), 3L),
              c(3, 3, 40, 40, 0, 0)),
    long_rows("average firm size", NA_character_, "month",
              rep(c("Agric", "Food"), each = 2L), rep(c("192607", "192608"), 2L),
              c(99.80, 102.06, 31.19, 31.14)),
    long_rows("Sum of BE / Sum of ME", "value", "year",
              rep(c("Agric", "Food"), each = 2L), rep(c("1926", "1927"), 2L),
              c(0.77, 0.63, 0.63, 0.59)),
    long_rows("value weight average of BE/ME", "value", "year",
              rep(c("Agric", "Food"), each = 2L), rep(c("1926", "1927"), 2L),
              c(0.75, 0.63, 0.70, 0.55))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser reads a size-sorted file with Value Weight heading variants", {
  table <- PortfolioParser$new()$parse(fixture_lines("size.csv"))

  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month",
              rep(c("Lo 30", "2-Dec"), each = 2L), rep(c("192607", "192608"), 2L),
              c(0.06, 3.14, 0.57, 2.51)),
    long_rows("return", "equal", "month",
              rep(c("Lo 30", "2-Dec"), each = 2L), rep(c("192607", "192608"), 2L),
              c(-0.53, 3.79, 0.33, 2.55)),
    long_rows("return", "value", "year",
              rep(c("Lo 30", "2-Dec"), each = 2L), rep(c("1927", "1928"), 2L),
              c(35.71, 42.15, 33.22, 44.08)),
    long_rows("return", "equal", "year",
              rep(c("Lo 30", "2-Dec"), each = 2L), rep(c("1927", "1928"), 2L),
              c(31.68, 56.55, 31.48, 46.18)),
    long_rows("number of firms", NA_character_, "month",
              rep(c("<= 0", "Lo 30", "2-Dec"), each = 2L), rep(c("192607", "192608"), 3L),
              c(0, 0, 153, 153, 51, 51)),
    long_rows("average firm size", NA_character_, "month",
              rep(c("Lo 30", "2-Dec"), each = 2L), rep(c("192607", "192608"), 2L),
              c(3.26, 3.23, 3.36, 3.37))
  ))
  expect_equal(table, expected)
})

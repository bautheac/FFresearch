test_that("BreakpointsParser reads layout A (monthly, no header, one count) into the long shape", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-me.csv"), "size")

  expect_s3_class(table, "data.table")
  expect_equal(names(table), c("variable", "frequency", "percentile", "period", "value"))
  expect_equal(nrow(table), 42L)
  expect_setequal(table$period, c("192512", "192601"))
  expect_true(all(table$variable == "size"))
  expect_true(all(table$frequency == "month"))

  got <- table[period == "192512", .(percentile, value)]
  expected <- data.table::data.table(
    percentile = c("# positive", paste0(seq(5, 100, by = 5), "%")),
    value = c(488, 1.40, 2.38, 3.37, 4.96, 5.95, 7.40, 8.92, 10.81, 13.01,
              15.56, 18.50, 22.88, 29.55, 38.41, 49.93, 65.40, 92.72, 142.48,
              238.78, 1319.00))
  data.table::setkey(got, percentile)
  data.table::setkey(expected, percentile)
  expect_equal(got, expected)
})
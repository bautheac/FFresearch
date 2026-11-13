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

test_that("BreakpointsParser reads layout B (annual, header ',Count', one count)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-op.csv"), "operating profitability")

  expect_equal(nrow(table), 42L)
  expect_setequal(table$period, c("1963", "1964"))
  expect_true(all(table$variable == "operating profitability"))
  expect_true(all(table$frequency == "year"))

  got <- table[period == "1963", .(percentile, value)]
  expected <- data.table::data.table(
    percentile = c("# positive", paste0(seq(5, 100, by = 5), "%")),
    value = c(769, 7.76, 11.47, 14.54, 16.49, 18.14, 19.34, 21.12, 22.42, 24.09,
              25.80, 27.13, 28.48, 30.14, 31.26, 33.43, 35.61, 38.53, 42.14,
              50.67, 403.64))
  data.table::setkey(got, percentile)
  data.table::setkey(expected, percentile)
  expect_equal(got, expected)
})

test_that("BreakpointsParser reads layout C (annual, two counts '<= 0' and '>0')", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-beme.csv"), "book/market")

  expect_equal(nrow(table), 44L)
  expect_setequal(table$period, c("1926", "1927"))
  expect_true(all(table$variable == "book/market"))
  expect_true(all(table$frequency == "year"))
  expect_setequal(unique(table$percentile), c("# negative", "# positive", paste0(seq(5, 100, by = 5), "%")))

  got <- table[period == "1926", .(percentile, value)]
  expected <- data.table::data.table(
    percentile = c("# negative", "# positive", paste0(seq(5, 100, by = 5), "%")),
    value = c(3, 428, 0.296, 0.408, 0.506, 0.602, 0.662, 0.705, 0.792, 0.863,
              0.947, 1.032, 1.094, 1.266, 1.376, 1.550, 1.779, 2.027, 2.456,
              3.381, 5.851, 31.324))
  data.table::setkey(got, percentile)
  data.table::setkey(expected, percentile)
  expect_equal(got, expected)
})

test_that("BreakpointsParser reads layout D (June-only monthly, header '<= 0 ' with a stray space)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-dp.csv"), "dividend/price")

  expect_equal(nrow(table), 44L)
  expect_setequal(table$period, c("192606", "192706"))
  expect_true(all(table$variable == "dividend/price"))
  # One row per year, but the period width is 6, so the frequency is month.
  expect_true(all(table$frequency == "month"))

  got <- table[period == "192606", .(percentile, value)]
  expected <- data.table::data.table(
    percentile = c("# negative", "# positive", paste0(seq(5, 100, by = 5), "%")),
    value = c(225, 285, 2.568, 3.160, 3.571, 3.881, 4.181, 4.349, 4.511, 4.697,
              4.898, 5.175, 5.357, 5.644, 5.871, 6.178, 6.494, 6.767, 7.295,
              7.757, 9.480, 101.587))
  data.table::setkey(got, percentile)
  data.table::setkey(expected, percentile)
  expect_equal(got, expected)
})

test_that("BreakpointsParser handles a multi-line preamble and keeps negative percentiles (prior returns)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-prior.csv"), "pior returns")

  expect_equal(nrow(table), 42L)
  expect_setequal(table$period, c("192612", "192701"))
  expect_true(all(table$variable == "pior returns"))
  expect_true(all(table$frequency == "month"))

  got <- table[period == "192612", .(percentile, value)]
  expected <- data.table::data.table(
    percentile = c("# positive", paste0(seq(5, 100, by = 5), "%")),
    value = c(472, -54.00, -45.52, -36.51, -30.54, -23.42, -17.77, -14.62, -9.95,
              -5.95, -3.00, -1.21, 1.62, 6.21, 11.18, 14.60, 18.79, 23.75, 29.89,
              49.68, 197.67))
  data.table::setkey(got, percentile)
  data.table::setkey(expected, percentile)
  expect_equal(got, expected)
})

test_that("BreakpointsParser drops missing-value markers but keeps legitimate negative values", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-missing.csv"), "pior returns")

  # The fixture marks the 5% (-99.99) and 10% (-999) percentiles as missing.
  expect_equal(nrow(table), 19L)
  expect_false(any(table$value %in% c(-99.99, -999)))
  expect_false("5%" %in% table$percentile)
  expect_false("10%" %in% table$percentile)
  # -99.5 is a legitimate prior-return percentile, not a marker: it must survive.
  expect_equal(table[percentile == "15%"]$value, -99.5)
  expect_equal(table[percentile == "# positive"]$value, 472)
})

test_that("BreakpointsParser rejects input with no data rows", {
  # A missing header is valid (layout A), but a file with no data rows is not.
  expect_error(BreakpointsParser$new()$parse("nothing here", "size"), "No data rows")
  expect_error(
    BreakpointsParser$new()$parse(c("This file was created using the 202609 CRSP database.", "       ,Count", "text"), "size"),
    "No data rows")
})

test_that("BreakpointsParser rejects an unrecognised count header", {
  expect_error(
    BreakpointsParser$new()$parse(c("preamble", "  ,Banana", "1926, 1, 2"), "size"),
    "Unrecognised breakpoints header")
})

test_that("BreakpointsParser requires a variable label", {
  expect_error(BreakpointsParser$new()$parse(fixture_lines("breakpoints-me.csv")), "variable")
})

test_that("BreakpointsParser rejects data rows with the wrong number of columns", {
  short <- c("preamble", "192512, 488, 1.40, 2.38")
  expect_error(BreakpointsParser$new()$parse(short, "size"), "columns")
})
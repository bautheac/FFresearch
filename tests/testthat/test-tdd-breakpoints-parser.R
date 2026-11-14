# Assert the full long table (every period x every percentile) against literal
# values read from the fixture. `values` is the concatenation of each period's
# count(s) then its 20 percentiles, in fixture order.
expect_breakpoint_rows <- function(table, periods, counts, values) {
  labels <- c(counts, paste0(seq(5, 100, by = 5), "%"))
  expected <- data.table::data.table(
    period = rep(periods, each = length(labels)),
    percentile = rep(labels, times = length(periods)),
    value = values)
  got <- table[, .(period, percentile, value)]
  data.table::setkey(got, period, percentile)
  data.table::setkey(expected, period, percentile)
  expect_equal(got, expected)
}

test_that("BreakpointsParser reads layout A (monthly, no header, one count) into the long shape", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-me.csv"), "size")

  expect_s3_class(table, "data.table")
  expect_equal(names(table), c("variable", "frequency", "percentile", "period", "value"))
  expect_equal(nrow(table), 42L)
  expect_true(all(table$variable == "size"))
  expect_true(all(table$frequency == "month"))
  expect_breakpoint_rows(table, c("192512", "192601"), "# positive", c(
    488, 1.40, 2.38, 3.37, 4.96, 5.95, 7.40, 8.92, 10.81, 13.01, 15.56, 18.50,
    22.88, 29.55, 38.41, 49.93, 65.40, 92.72, 142.48, 238.78, 1319.00,
    492, 1.38, 2.54, 3.76, 4.84, 5.94, 7.50, 9.28, 10.94, 12.69, 15.81, 17.75,
    23.20, 30.40, 38.99, 50.85, 66.82, 94.70, 139.18, 235.20, 1331.71))
})

test_that("BreakpointsParser reads layout B (annual, header ',Count', one count)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-op.csv"), "operating profitability")

  expect_equal(nrow(table), 42L)
  expect_true(all(table$variable == "operating profitability"))
  expect_true(all(table$frequency == "year"))
  expect_breakpoint_rows(table, c("1963", "1964"), "# positive", c(
    769, 7.76, 11.47, 14.54, 16.49, 18.14, 19.34, 21.12, 22.42, 24.09, 25.80,
    27.13, 28.48, 30.14, 31.26, 33.43, 35.61, 38.53, 42.14, 50.67, 403.64,
    798, 7.49, 11.37, 15.18, 17.10, 18.62, 19.96, 21.05, 22.30, 23.45, 25.24,
    26.25, 27.68, 29.46, 30.90, 32.54, 35.21, 37.61, 42.81, 51.04, 336.91))
})

test_that("BreakpointsParser reads layout C (annual, two counts '<= 0' and '>0')", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-beme.csv"), "book/market")

  expect_equal(nrow(table), 44L)
  expect_true(all(table$variable == "book/market"))
  expect_true(all(table$frequency == "year"))
  expect_setequal(unique(table$percentile), c("# negative", "# positive", paste0(seq(5, 100, by = 5), "%")))
  expect_breakpoint_rows(table, c("1926", "1927"), c("# negative", "# positive"), c(
    3, 428, 0.296, 0.408, 0.506, 0.602, 0.662, 0.705, 0.792, 0.863, 0.947,
    1.032, 1.094, 1.266, 1.376, 1.550, 1.779, 2.027, 2.456, 3.381, 5.851, 31.324,
    1, 464, 0.320, 0.427, 0.537, 0.628, 0.682, 0.783, 0.866, 0.933, 0.986,
    1.061, 1.146, 1.234, 1.363, 1.554, 1.829, 2.205, 2.693, 3.483, 5.011, 53.103))
})

test_that("BreakpointsParser reads layout D (June-only monthly, header '<= 0 ' with a stray space)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-dp.csv"), "dividend/price")

  expect_equal(nrow(table), 44L)
  expect_true(all(table$variable == "dividend/price"))
  # One row per year, but the period width is 6, so the frequency is month.
  expect_true(all(table$frequency == "month"))
  expect_breakpoint_rows(table, c("192606", "192706"), c("# negative", "# positive"), c(
    225, 285, 2.568, 3.160, 3.571, 3.881, 4.181, 4.349, 4.511, 4.697, 4.898,
    5.175, 5.357, 5.644, 5.871, 6.178, 6.494, 6.767, 7.295, 7.757, 9.480, 101.587,
    196, 351, 2.240, 2.995, 3.352, 3.744, 4.082, 4.396, 4.659, 5.039, 5.390,
    5.731, 5.948, 6.250, 6.582, 7.054, 7.565, 8.000, 8.683, 9.821, 11.268, 160.000))
})

test_that("BreakpointsParser handles a multi-line preamble and keeps negative percentiles (prior returns)", {
  table <- BreakpointsParser$new()$parse(fixture_lines("breakpoints-prior.csv"), "pior returns")

  expect_equal(nrow(table), 42L)
  expect_true(all(table$variable == "pior returns"))
  expect_true(all(table$frequency == "month"))
  expect_breakpoint_rows(table, c("192612", "192701"), "# positive", c(
    472, -54.00, -45.52, -36.51, -30.54, -23.42, -17.77, -14.62, -9.95, -5.95,
    -3.00, -1.21, 1.62, 6.21, 11.18, 14.60, 18.79, 23.75, 29.89, 49.68, 197.67,
    476, -57.14, -45.00, -34.00, -29.32, -21.90, -17.14, -13.08, -9.77, -5.59,
    -1.47, 1.53, 4.58, 8.25, 11.69, 14.60, 18.00, 22.05, 30.61, 45.30, 197.44))
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

test_that("BreakpointsParser rejects non-numeric values", {
  lines <- fixture_lines("breakpoints-me.csv")
  lines[3] <- sub("1.40", "abc", lines[3])
  expect_error(BreakpointsParser$new()$parse(lines, "size"), "numeric")
})
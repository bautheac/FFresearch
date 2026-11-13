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

test_that("PortfolioParser maps the BE-ME heading variants to the committed fields", {
  table <- PortfolioParser$new()$parse(fixture_lines("beme.csv"))

  portfolios <- rep(c("<= 0", "Lo 30", "Hi 10"), each = 2L)
  months <- rep(c("192607", "192608"), 3L)
  years <- rep(c("1927", "1928"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month", portfolios, months,
              c(12.07, -9.73, 5.55, 2.66, 0.56, 3.88)),
    long_rows("return", "equal", "month", portfolios, months,
              c(-6.29, 34.52, 2.65, 1.35, -0.15, 6.55)),
    long_rows("return", "value", "year", portfolios, years,
              c(13.99, 88.57, 43.94, 45.83, 48.19, 26.80)),
    long_rows("return", "equal", "year", portfolios, years,
              c(50.99, 88.57, 33.77, 39.93, 34.33, 61.98)),
    long_rows("number of firms", NA_character_, "month", portfolios, months,
              c(3, 3, 128, 128, 43, 43)),
    long_rows("average firm size", NA_character_, "month", portfolios, months,
              c(1.97, 2.21, 74.88, 78.92, 6.27, 6.31)),
    long_rows("Sum of BE / Sum of ME", "value", "year", portfolios, years,
              c(-2.9634, -1.9034, 0.4815, 0.3060, 3.7487, 3.8512)),
    long_rows("value weight average of BE/ME", "value", "year", portfolios, years,
              c(-3.9092, -2.3657, 0.5190, 0.3430, 5.6841, 4.4265))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser reads the no-Average heading family and trims portfolio labels", {
  table <- PortfolioParser$new()$parse(fixture_lines("ni.csv"))

  portfolios <- rep(c("< 0", "ZERO", "Dec 2"), each = 2L)
  months <- rep(c("196307", "196308"), 3L)
  years <- rep(c("1964", "1965"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month", portfolios, months,
              c(0.59, 5.55, 0.24, 4.16, 0.58, 4.66)),
    long_rows("return", "equal", "month", portfolios, months,
              c(-0.90, 4.35, -0.42, 3.52, -2.20, 5.48)),
    long_rows("return", "value", "year", portfolios, years,
              c(21.38, 14.68, 17.68, 16.96, 20.20, 19.43)),
    long_rows("return", "equal", "year", portfolios, years,
              c(19.40, 39.72, 24.28, 41.40, 21.35, 35.94)),
    long_rows("number of firms", NA_character_, "month", portfolios, months,
              c(203, 203, 319, 319, 55, 55)),
    long_rows("average firm size", NA_character_, "month", portfolios, months,
              c(195.19, 195.88, 161.27, 161.35, 442.26, 444.57)),
    long_rows("value weight average of NI", "value", "year",
              portfolios, rep(c("1963", "1964"), 3L),
              c(-0.787, -0.678, 0.000, 0.000, 0.069, 0.093))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser reads the Value Weight Average Returns word order", {
  table <- PortfolioParser$new()$parse(fixture_lines("me_ep.csv"))

  portfolios <- rep(c("SMALL LoEP", "ME1 EP2", "BIG HiEP"), each = 2L)
  months <- rep(c("195107", "195108"), 3L)
  years <- rep(c("1952", "1953"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month", portfolios, months,
              c(4.86, 5.51, 5.99, 6.00, 6.03, 6.72)),
    long_rows("return", "equal", "month", portfolios, months,
              c(4.21, 6.20, 5.57, 5.66, 8.90, 4.95)),
    long_rows("return", "value", "year", portfolios, years,
              c(1.42, -3.47, 6.16, -2.22, 20.90, -4.27)),
    long_rows("return", "equal", "year", portfolios, years,
              c(2.81, -0.68, 5.81, -3.64, 15.30, -4.04)),
    long_rows("number of firms", NA_character_, "month", portfolios, months,
              c(28, 28, 40, 40, 53, 53)),
    long_rows("average firm size", NA_character_, "month", portfolios, months,
              c(10.19, 10.64, 13.25, 14.02, 190.44, 201.78)),
    long_rows("value weight average of E/P", "value", "year",
              portfolios, rep(c("1951", "1952"), 3L),
              c(0.0838, 0.0829, 0.1528, 0.1257, 0.2224, 0.1831))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser maps the CF/P and D/P formation headings like E/P", {
  lines <- c("  Value Weight Average of CF/P when portfolio is formed", ",A",
             "  1951, 0.10", "  Value Weight Average of D/P when portfolio is formed", ",A",
             "  1951, 0.02")
  table <- PortfolioParser$new()$parse(lines)

  expect_equal(table, data.table::data.table(
    portfolio = c("A", "A"),
    field = c("value weight average of CF/P", "value weight average of D/P"),
    weights = c("value", "value"), period = c("1951", "1951"),
    value = c(0.10, 0.02), frequency = c("year", "year")))
})

test_that("PortfolioParser reads mixed heading families in a momentum file", {
  table <- PortfolioParser$new()$parse(fixture_lines("prior.csv"))

  portfolios <- rep(c("Lo PRIOR", "PRIOR 2", "Hi PRIOR"), each = 2L)
  months <- rep(c("192701", "192702"), 3L)
  years <- rep(c("1927", "1928"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month", portfolios, months,
              c(-3.32, 7.39, -4.54, 6.01, -0.24, 7.04)),
    long_rows("return", "equal", "month", portfolios, months,
              c(-0.47, 3.97, 0.88, 4.06, 1.30, 5.63)),
    long_rows("return", "value", "year", portfolios, years,
              c(13.05, 16.96, 8.26, 22.58, 66.00, 88.22)),
    long_rows("return", "equal", "year", portfolios, years,
              c(16.89, 34.88, 18.98, 35.85, 40.63, 84.97)),
    long_rows("number of firms", NA_character_, "month", portfolios, months,
              c(47, 48, 47, 47, 47, 48)),
    long_rows("average firm size", NA_character_, "month", portfolios, months,
              c(7.27, 3.53, 11.52, 16.45, 83.96, 86.43)),
    long_rows("value weight average of Prior Returns", "value", "year", portfolios, years,
              c(-39.55, -17.25, -19.07, -2.07, 115.07, 135.06))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser maps every derived single-line heading to its committed field", {
  # Exact library strings, including trailing and internal padding spaces.
  headings <- c(
    "  Value Weight Average of OP   ",
    "  Value Weight Average of Natural Log of INV   ",
    "  Value Weight Average of E      / ME",
    "  Value Weight Average of CF     / ME",
    "  Value-Weighted Average of ACCR ",
    "  Value-Weighted Average of Prior Beta ",
    "  Value-Weighted Average of Past Return Variance"
  )
  fields <- c(
    "value weight average of OP",
    "value weight average of Natural Log of INV",
    "value weight average of E/ME",
    "value weight average of CF/ME",
    "value weight average of ACCR",
    "value weight average of Prior Beta",
    "value weight average of Past Return Variance"
  )
  lines <- unlist(lapply(headings, function(h) c(h, ",A", "  1927, 0.5")))
  table <- PortfolioParser$new()$parse(lines)

  expect_equal(table, data.table::data.table(
    portfolio = rep("A", 7L), field = fields, weights = rep("value", 7L),
    period = rep("1927", 7L), value = rep(0.5, 7L), frequency = rep("year", 7L)))
})

test_that("PortfolioParser reads multi-line heading blocks and Average Market Cap", {
  table <- PortfolioParser$new()$parse(fixture_lines("portfolios_2x3.csv"))

  portfolios <- rep(c("SMALL LoBM", "ME1 BM2", "BIG HiBM"), each = 2L)
  early <- rep(c("192607", "192608"), 3L)
  late <- rep(c("196307", "196308"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "month", portfolios, early,
              c(1.0866, 0.7831, 0.9068, 1.1829, 1.4225, 6.3196)),
    long_rows("return", "equal", "month", portfolios, early,
              c(1.5534, 0.5543, -0.0573, 0.6581, 2.3334, 6.7548)),
    long_rows("number of firms", NA_character_, "month", portfolios, early,
              c(44, 44, 68, 68, 34, 34)),
    long_rows("average firm size", NA_character_, "month", portfolios, early,
              c(7.83, 7.91, 6.84, 6.89, 40.50, 41.04)),
    long_rows("value weight average of BE/ME", "value", "month", portfolios, early,
              c(0.5070, 0.5044, 1.0709, 1.0697, 2.3095, 2.2964)),
    long_rows("value weight average of BE_FYt-1/ME_June t", "value", "month", portfolios, early,
              c(0.7749, 0.7695, 1.2143, 1.2121, 2.3729, 2.3631)),
    long_rows("value weight average of OP", "value", "month", portfolios, late,
              c(0.1082, 0.0599, 0.2091, 0.2096, 0.1392, 0.1397)),
    long_rows("value weight average of investment (rate of growth of assets)", "value",
              "month", portfolios, late,
              c(0.1305, 0.1301, 0.0635, 0.0640, 0.0204, 0.0205))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser splits lone CR separators inside heading blocks", {
  path <- testthat::test_path("fixtures", "portfolios_2x3.csv")
  raw <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  from_raw <- PortfolioParser$new()$parse(raw)

  expect_equal(from_raw, PortfolioParser$new()$parse(fixture_lines("portfolios_2x3.csv")))
})

test_that("PortfolioParser reads regional daily files with ruler lines and BO labels", {
  table <- PortfolioParser$new()$parse(fixture_lines("regional_daily.csv"))

  portfolios <- rep(c("SMALL LoBO", "ME1 BO2", "BIG HiBO"), each = 2L)
  days <- rep(c("19900702", "19900703"), 3L)
  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "day", portfolios, days,
              c(0.27, 0.14, 0.35, 0.14, 0.70, 0.20)),
    long_rows("return", "equal", "day", portfolios, days,
              c(0.78, 0.18, 0.50, 0.16, 0.71, 0.49))
  ))
  expect_equal(table, expected)
})

test_that("PortfolioParser pads ragged rows with NA without misaligning the other values", {
  table <- PortfolioParser$new()$parse(fixture_lines("ni_5x5.csv"))

  # 35 portfolios for 196307 (returns), 196307 (Net Share Issues), 201106 and
  # 201207 (Accruals); only 34 for the ragged 201107 and 201108 Accruals rows.
  expect_equal(nrow(table), 208L)
  expect_false(anyNA(table$value))

  accruals <- table[field == "value weight average of Accruals"]
  expect_equal(accruals[portfolio == "BIG HiNI", .(period, value)],
               data.table::data.table(period = c("201106", "201207"),
                                      value = c(2.7803, 3.1174)))
  expect_equal(nrow(accruals[period == "201107"]), 34L)
  expect_equal(nrow(accruals[period == "201108"]), 34L)
  # Values stay aligned with their portfolios despite the missing last column.
  expect_equal(accruals[period == "201107" & portfolio == "SMALL NegNI", value], 1.2880)
  expect_equal(accruals[period == "201107" & portfolio == "ME4 NegNI", value], 137.0067)
  expect_equal(accruals[period == "201107" & portfolio == "ME5 NI4", value], -0.8648)

  issues <- table[field == "value weight average of Net Share Issues"]
  expect_equal(nrow(issues), 35L)
  expect_equal(issues[portfolio == "SMALL NegNI", value], -2.3732)
})

test_that("PortfolioParser rejects rows with more values than portfolios", {
  lines <- c("  Average Value Weighted Returns -- Monthly", ",A,B", "192607,1,2,3")

  expect_error(PortfolioParser$new()$parse(lines), "more values")
})

test_that("PortfolioParser drops every missing marker but keeps real extreme returns", {
  lines <- c("  Average Value Weighted Returns -- Monthly", ",A,B,C,D,E",
             "192607,-99.99,-999,-9999,-100.00,1.5")
  table <- PortfolioParser$new()$parse(lines)

  expect_equal(table, data.table::data.table(
    portfolio = c("D", "E"), field = c("return", "return"),
    weights = c("value", "value"), period = c("192607", "192607"),
    value = c(-100.00, 1.5), frequency = c("month", "month")))
})

test_that("PortfolioParser maps the remaining Sum of headings", {
  lines <- c("  Sum of E      / Sum of ME", ",A", "  1927, 0.3",
             "  Sum of CF     / Sum of ME", ",A", "  1927, 0.4")
  table <- PortfolioParser$new()$parse(lines)

  expect_equal(table, data.table::data.table(
    portfolio = c("A", "A"),
    field = c("Sum of E / Sum of ME", "Sum of CF / Sum of ME"),
    weights = c("value", "value"), period = c("1927", "1927"),
    value = c(0.3, 0.4), frequency = c("year", "year")))
})

test_that("PortfolioParser names unknown section headings in its errors", {
  good <- c("  Average Value Weighted Returns -- Monthly", ",A", "192607,1")
  expect_error(PortfolioParser$new()$parse(c(good, "  Bogus Heading", ",A", "192608,2")),
               "Unknown section heading: 'Bogus Heading'")
  expect_error(PortfolioParser$new()$parse(c("preamble", "  Bogus First Heading", ",A", "192607,1")),
               "Unknown section heading: 'Bogus First Heading'")
})

test_that("PortfolioParser rejects malformed files", {
  parse <- function(lines) PortfolioParser$new()$parse(lines)
  expect_error(parse("nothing here"), "No section headings found")
  expect_error(parse("192607,1,2"), "Data row before any section heading")
  expect_error(parse(",A,B"), "Header line before any section heading")
  expect_error(parse(c("  Average Value Weighted Returns -- Monthly", "192607,1")),
               "No header line found for section")
  expect_error(parse(c("  Average Value Weighted Returns -- Monthly", ",A")),
               "No data rows found")
  expect_error(parse(c("  Average Value Weighted Returns -- Monthly", ",A", "19260,1")),
               "Cannot infer frequency from period '19260'")
})

test_that("PortfolioParser returns a data.table builders can tag with labels", {
  table <- PortfolioParser$new()$parse(fixture_lines("industry.csv"))

  expect_s3_class(table, "data.table")
  table[, region := "US"]
  expect_equal(table$region[[1L]], "US")
})

test_that("PortfolioParser reads the equally-weighted Prior Returns average", {
  table <- PortfolioParser$new()$parse(fixture_lines("me_prior.csv"))

  prior <- table[field == "equal weight average of Prior Returns"]
  expect_equal(unique(prior$weights), "equal")
  expect_equal(unique(prior$frequency), "month")
  expect_equal(prior[portfolio == "SMALL LoPRIOR" & period == "192701", value], -50.54)
  # The -99.99 marker in the 192702 row is dropped.
  expect_equal(nrow(prior[period == "192702"]), 2L)
})

test_that("PortfolioParser recognises headings whose indent the library dropped", {
  # 100_Portfolios_10x10_ME_INV_Wout_Div carries its equal-weighted annual
  # heading without the usual two-space indent.
  lines <- c(
    "This file was created using the 202609 CRSP database.",
    "",
    "  Average Value Weighted Returns -- Annual",
    ",SMALL LoINV,BIG HiINV",
    "  1964,  25.63,  14.03",
    "",
    "Average Equal Weighted Returns -- Annual",
    ",SMALL LoINV,BIG HiINV",
    "  1964,  26.62,  19.26",
    "",
    "Copyright 2026 Eugene F. Fama and Kenneth R. French")
  table <- PortfolioParser$new()$parse(lines)

  expected <- data.table::rbindlist(list(
    long_rows("return", "value", "year", c("SMALL LoINV", "BIG HiINV"),
              c("1964", "1964"), c(25.63, 14.03)),
    long_rows("return", "equal", "year", c("SMALL LoINV", "BIG HiINV"),
              c("1964", "1964"), c(26.62, 19.26))))
  expect_equal(table, expected)
})

test_that("PortfolioParser names the BE_FYt-1 block by its formula when the heading says BE/ME", {
  # 25_Portfolios_ME_VAR_5x5 and _RESVAR_ label both book-equity blocks
  # "BE/ME"; only the formula distinguishes ME(Dec t-1) from ME(Jun t).
  block <- function(formula) c(
    "  For portfolios formed in June of year t",
    "  Value Weight Average of BE/ME Calculated for June of t to June of t+1 as:",
    paste0("  ", formula),
    "  Where Mth is a month from June of t to June of t+1",
    ",SMALL LoBM,BIG HiBM",
    "192607,   0.50,   2.30")
  lines <- c(
    "This file was created using the 202609 CRSP database.",
    block("Sum[ME(Mth) * BE(Fiscal Year t-1) / ME(Dec t-1)] / Sum[ME(Mth)]"),
    "",
    block("Sum[ME(Mth) * BE(Fiscal Year t-1) / ME(Jun t)] / Sum[ME(Mth)]"),
    "",
    "Copyright 2026 Eugene F. Fama and Kenneth R. French")
  table <- PortfolioParser$new()$parse(lines)

  expect_equal(table$field, c("value weight average of BE/ME", "value weight average of BE/ME",
                              "value weight average of BE_FYt-1/ME_June t",
                              "value weight average of BE_FYt-1/ME_June t"))
  expect_equal(table$value, c(0.50, 2.30, 0.50, 2.30))
})

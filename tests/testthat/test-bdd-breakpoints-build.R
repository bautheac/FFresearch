describe("building the breakpoints dataset", {
  breakpoints <- BreakpointsBuilder$new(BreakpointsFixtureSource$new())$build()

  it("returns one row per period and percentile for every variable", {
    expect_named(breakpoints, c("variable", "frequency", "percentile", "period", "value"))
    expect_equal(nrow(breakpoints), 172L)
    expect_setequal(unique(breakpoints$variable),
                    c("size", "book/market", "operating profitability", "investment",
                      "earnings/price", "cash flow/price", "dividend/price", "pior returns"))
    # One spot value per variable, read from its fixture: proves the file mapping.
    expect_equal(breakpoints[variable == "size" & period == "197101" & percentile == "# positive"]$value, 492)
    expect_equal(breakpoints[variable == "book/market" & period == "1971" & percentile == "# negative"]$value, 1)
    expect_equal(breakpoints[variable == "operating profitability" & period == "1971" & percentile == "# positive"]$value, 798)
    expect_equal(breakpoints[variable == "investment" & period == "1971" & percentile == "5%"]$value, -4.10)
    expect_equal(breakpoints[variable == "earnings/price" & period == "1971" & percentile == "100%"]$value, 25.88)
    expect_equal(breakpoints[variable == "cash flow/price" & period == "1971" & percentile == "100%"]$value, 33.41)
    expect_equal(breakpoints[variable == "dividend/price" & period == "197106" & percentile == "# positive"]$value, 351)
    expect_equal(breakpoints[variable == "pior returns" & period == "197101" & percentile == "5%"]$value, -57.14)
    # Frequency follows the period width; the June-only dividend file is monthly.
    expect_true(all(breakpoints$frequency[breakpoints$variable %in% c("size", "pior returns", "dividend/price")] == "month"))
    expect_true(all(breakpoints$frequency[breakpoints$variable %in% c("book/market", "operating profitability", "investment", "earnings/price", "cash flow/price")] == "year"))
  })

  it("starts every series at the 1971 coverage start", {
    # Maintainer decision (2026-11-14, spec #3 follow-up): R's lazyload DB
    # cannot serialise objects above 2^31 - 1 bytes, so breakpoints and the
    # portfolio series start in 1971. The fixtures carry pre-1971 rows; the
    # build must drop them.
    expect_false(any(breakpoints$period < "1971"))
    expect_equal(min(breakpoints[frequency == "month"]$period), "197101")
    expect_equal(min(breakpoints[frequency == "year"]$period), "1971")
  })

  it("keeps the documented column types and factor levels", {
    expect_s3_class(breakpoints, "data.frame")
    expect_identical(unname(vapply(breakpoints, function(col) class(col)[[1L]], "")),
                     c("factor", "factor", "factor", "character", "numeric"))
    expect_identical(levels(breakpoints$variable),
                     c("size", "book/market", "operating profitability", "investment",
                       "earnings/price", "cash flow/price", "dividend/price", "pior returns"))
    expect_identical(levels(breakpoints$frequency), c("month", "year"))
    expect_identical(levels(breakpoints$percentile),
                     c("# positive", paste0(seq(5, 100, by = 5), "%"), "# negative"))
  })

  it("orders rows by variable, frequency, percentile and period", {
    ord <- do.call(order, breakpoints[, .(variable, frequency, percentile, period)])
    expect_equal(ord, seq_len(nrow(breakpoints)))
  })

  it("is wired by its factory", {
    builder <- BreakpointsBuilderFactory$new()$create(source = BreakpointsFixtureSource$new())
    expect_s3_class(builder, "BreakpointsBuilder")
  })
})
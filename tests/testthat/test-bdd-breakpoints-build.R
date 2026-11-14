describe("building the breakpoints dataset", {
  breakpoints <- BreakpointsBuilder$new(BreakpointsFixtureSource$new())$build()

  it("returns one row per period and percentile for every variable", {
    expect_named(breakpoints, c("variable", "frequency", "percentile", "period", "value"))
    expect_equal(nrow(breakpoints), 344L)
    expect_setequal(unique(breakpoints$variable),
                    c("size", "book/market", "operating profitability", "investment",
                      "earnings/price", "cash flow/price", "dividend/price", "pior returns"))
    # One spot value per variable, read from its fixture: proves the file mapping.
    expect_equal(breakpoints[variable == "size" & period == "192512" & percentile == "# positive"]$value, 488)
    expect_equal(breakpoints[variable == "book/market" & period == "1926" & percentile == "# negative"]$value, 3)
    expect_equal(breakpoints[variable == "operating profitability" & period == "1963" & percentile == "# positive"]$value, 769)
    expect_equal(breakpoints[variable == "investment" & period == "1963" & percentile == "5%"]$value, -4.52)
    expect_equal(breakpoints[variable == "earnings/price" & period == "1951" & percentile == "100%"]$value, 24.63)
    expect_equal(breakpoints[variable == "cash flow/price" & period == "1951" & percentile == "100%"]$value, 32.07)
    expect_equal(breakpoints[variable == "dividend/price" & period == "192606" & percentile == "# positive"]$value, 285)
    expect_equal(breakpoints[variable == "pior returns" & period == "192612" & percentile == "5%"]$value, -54.00)
    # Frequency follows the period width; the June-only dividend file is monthly.
    expect_true(all(breakpoints$frequency[breakpoints$variable %in% c("size", "pior returns", "dividend/price")] == "month"))
    expect_true(all(breakpoints$frequency[breakpoints$variable %in% c("book/market", "operating profitability", "investment", "earnings/price", "cash flow/price")] == "year"))
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

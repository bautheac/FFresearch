describe("building the factors dataset", {
  sources <- data.table::data.table(region = "US", file = c("ff5", "Mom"))
  factors <- FactorsBuilder$new(FixtureSource$new(), sources = sources)$build()

  it("derives the market return as excess return plus the risk free rate", {
    market <- factors[factors$factor == "market" & factors$period == "202601", ]
    expect_equal(market$value, 1.25)
  })

  it("uses the package's factor names", {
    expect_true("risk free rate" %in% factors$factor)
    expect_false(any(c("Mkt-RF", "RF") %in% factors$factor))
  })

  it("returns the documented columns, ordered", {
    expect_named(factors, c("region", "frequency", "factor", "period", "value"))
    expect_s3_class(factors$region, "factor")
    expect_false(is.unsorted(as.integer(factors$frequency[factors$factor == "Mom"])))
  })

  it("is wired by its factory", {
    builder <- FactorsBuilderFactory$new()$create(source = FixtureSource$new())
    expect_s3_class(builder, "FactorsBuilder")
  })
})

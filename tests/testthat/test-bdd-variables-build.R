describe("building the variables dataset", {
  inventories <- data.frame(
    dataset = c("portfolios_univariate", "portfolios_univariate", "portfolios_univariate",
                "portfolios_bivariate", "portfolios_bivariate", "breakpoints", "factors", "factors"),
    column = c("sort variable", "sort variable", "field",
               "field", "field", "variable", "factor", "factor"),
    name = c("market capitalization", "momentum", "return",
             "value weight average of BE/ME", "equal weight average of Prior Returns",
             "pior returns", "SMB", "ST_Rev"))
  variables <- VariablesBuilder$new(inventories)$build()

  it("returns the documented columns", {
    expect_s3_class(variables, "tbl_df")
    expect_named(variables, c("name", "symbol", "description"))
    expect_identical(unname(vapply(variables, function(col) class(col)[[1L]], "")),
                     rep("character", 3L))
  })

  it("gives every name used in the inventories a row", {
    expect_true(all(inventories$name %in% variables$name))
  })

  it("leaves derived fields without a symbol", {
    derived <- variables[grepl("^(value|equal) weight average of ", variables$name), ]
    expect_gt(nrow(derived), 0L)
    expect_true(all(is.na(derived$symbol)))
    expect_true(is.na(variables$symbol[variables$name == "return"]))
    expect_identical(variables$symbol[variables$name == "market capitalization"], "ME")
    expect_identical(variables$symbol[variables$name == "SMB"], "SMB")
  })

  it("keeps the committed descriptions verbatim", {
    description <- function(name) variables$description[variables$name == name]
    expect_identical(description("market capitalization"),
                     "Market equity (size) is price times shares outstanding. Price is from CRSP, shares outstanding are from Compustat (if available) or CRSP.")
    expect_identical(description("book/market"),
                     "The book-to-market ratio used to form portfolios in June of year t is book equity for the fiscal year ending in calendar year t-1, divided by market equity at the end of December of t-1.")
    expect_identical(description("univariate market beta"),
                     "\u03b2 for June of year t is estimated using the preceding five years (two minimum) of past monthly returns.")
  })

  it("refuses to build when a name has no definition", {
    undefined <- rbind(inventories, data.frame(dataset = "factors", column = "factor", name = "no such factor"))
    expect_error(VariablesBuilder$new(undefined)$build(), "no such factor")
  })

  it("rejects inventories without the documented columns", {
    expect_error(VariablesBuilder$new(data.frame(name = "return"))$build(), "inventories")
  })

  it("keeps the committed rows first, in their committed order, with unique names", {
    committed <- c("market capitalization", "book value", "book/market", "operating profitability",
                   "investment", "earnings/price", "cash flow/price", "dividend/price", "accruals",
                   "univariate market beta", "net share issues", "variance", "residual variance",
                   "short term reversal", "long term reversal", "value weight average of BE/ME",
                   "value weight average of BE_FYt-1/ME_June t", "value weight average of OP",
                   "value weight average of investment (rate of growth of assets)",
                   "value weight average of Net Share Issues", "value weight average of Accruals",
                   "value weight average of Prior Beta", "value weight average of Past Return Variance")
    expect_identical(variables$name[seq_along(committed)], committed)
    expect_identical(anyDuplicated(variables$name), 0L)
    expect_identical(variables, VariablesBuilder$new(inventories)$build())
  })

  it("is wired by its factory", {
    builder <- VariablesBuilderFactory$new()$create(inventories = inventories)
    expect_s3_class(builder, "VariablesBuilder")
    expect_identical(builder$build(), variables)
  })
})

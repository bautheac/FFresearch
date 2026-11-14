# In-memory source serving the trivariate fixtures: the US layout for the US
# stems, the regional layout for the Developed stem.
TrivariateFixtureSource <- R6::R6Class(
  "TrivariateFixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      name <- if (startsWith(file, "Developed_")) "trivariate_regional.csv" else "trivariate_us.csv"
      readLines(testthat::test_path("fixtures", name), warn = FALSE)
    }
  )
)

describe("building the trivariate portfolios dataset", {
  sources <- data.table::data.table(
    file = c("32_Portfolios_ME_BEME_OP_2x4x4",
             "32_Portfolios_ME_BEME_OP_2x4x4_Wout_Div",
             "Developed_32_Portfolios_ME_BE-ME_OP_2x4x4"),
    region = c("US", "US", "developed"),
    `sort variable 1` = "market capitalization",
    `sort variable 2` = "book/market",
    `sort variable 3` = "operating profitability",
    dividend = c("Y", "N", "Y"),
    weights = rep(list(c("value", "equal")), 3L))
  trivariate <- TrivariateBuilder$new(TrivariateFixtureSource$new(), sources = sources)$build()
  key <- c("region", "frequency", "sort variable 1", "sort variable 2", "sort variable 3",
           "dividend", "weights", "portfolio", "field", "period")
  row <- function(i) lapply(trivariate[i], function(col) if (is.factor(col)) as.character(col) else col)

  it("returns the documented columns and types", {
    expect_named(trivariate, c(key, "value"))
    factors <- c("region", "frequency", "sort variable 1", "sort variable 2",
                 "sort variable 3", "dividend", "weights", "field")
    for (column in factors) expect_s3_class(trivariate[[column]], "factor")
    expect_type(trivariate$portfolio, "character")
    expect_type(trivariate$period, "character")
    expect_type(trivariate$value, "double")
  })

  it("keeps the documented factor levels", {
    expect_equal(levels(trivariate$region),
                 c("US", "developed", "developed (ex US)", "Europe", "JP",
                   "Asia-Pacific (ex JP)", "North America"))
    expect_equal(levels(trivariate$frequency), c("month", "year"))
    expect_equal(levels(trivariate$`sort variable 1`), "market capitalization")
    expect_equal(levels(trivariate$`sort variable 2`), c("book/market", "operating profitability"))
    expect_equal(levels(trivariate$`sort variable 3`), c("operating profitability", "investment"))
    expect_equal(levels(trivariate$dividend), c("Y", "N"))
    expect_equal(levels(trivariate$weights), c("value", "equal"))
    expect_equal(levels(trivariate$field),
                 c("return", "value weight average of BE/ME",
                   "value weight average of BE_FYt-1/ME_June t", "value weight average of OP",
                   "value weight average of investment (rate of growth of assets)"))
  })

  it("joins the last two header tokens of each portfolio with a dot", {
    expect_setequal(unique(trivariate$portfolio),
                    c("BIG HiBM.HiOP", "ME1 BM1.OP2", "SMALL LoBM.LoOP", "ME1 BM1.HiOP"))
  })

  it("orders observations by the dataset key", {
    expect_equal(row(1), list(
      region = "US", frequency = "month", `sort variable 1` = "market capitalization",
      `sort variable 2` = "book/market", `sort variable 3` = "operating profitability",
      dividend = "Y", weights = "value", portfolio = "BIG HiBM.HiOP", field = "return",
      period = "196307", value = 2.71))
    expect_equal(row(nrow(trivariate)), list(
      region = "developed", frequency = "year", `sort variable 1` = "market capitalization",
      `sort variable 2` = "book/market", `sort variable 3` = "operating profitability",
      dividend = "Y", weights = "equal", portfolio = "SMALL LoBM.LoOP", field = "return",
      period = "1992", value = -2.75))
    ordered <- data.table::as.data.table(trivariate)
    ordered <- ordered[do.call(order, ordered[, key, with = FALSE])]
    expect_equal(trivariate, ordered)
  })

  it("reads returns and the derived value-weight averages, skipping counts and sizes", {
    # 35 rows per US file (one sentinel dropped) and 24 regional rows.
    expect_equal(nrow(trivariate), 94L)
    expect_setequal(unique(trivariate$field),
                    c("return", "value weight average of BE/ME", "value weight average of OP"))
    derived <- trivariate[trivariate$field != "return", ]
    expect_true(all(derived$region == "US" & derived$weights == "value" &
                      derived$frequency == "month"))
    expect_equal(derived$value[derived$dividend == "Y" & derived$portfolio == "BIG HiBM.HiOP" &
                                 derived$field == "value weight average of BE/ME" &
                                 derived$period == "196307"], 1.29)
  })

  it("drops missing-value markers", {
    expect_false(-99.99 %in% trivariate$value)
    dropped <- trivariate[trivariate$region == "US" & trivariate$dividend == "Y" &
                            trivariate$weights == "value" & trivariate$field == "return" &
                            trivariate$frequency == "month" &
                            trivariate$portfolio == "BIG HiBM.HiOP" &
                            trivariate$period == "196308", ]
    expect_equal(nrow(dropped), 0L)
  })

  it("labels dividends from the file and frequencies from the period width", {
    expect_setequal(as.character(trivariate$dividend[trivariate$region == "US"]), c("Y", "N"))
    expect_setequal(as.character(trivariate$dividend[trivariate$region == "developed"]), "Y")
    expect_setequal(as.character(trivariate$frequency), c("month", "year"))
    annual <- trivariate[trivariate$region == "developed" & trivariate$frequency == "year" &
                           trivariate$weights == "value" &
                           trivariate$portfolio == "SMALL LoBM.LoOP" &
                           trivariate$period == "1991", ]
    expect_equal(annual$value, 23.16)
  })

  it("has no duplicate observations", {
    expect_equal(anyDuplicated(data.table::as.data.table(trivariate), by = key), 0L)
  })

  it("is wired by its factory", {
    builder <- TrivariateBuilderFactory$new()$create(source = TrivariateFixtureSource$new())
    expect_s3_class(builder, "TrivariateBuilder")
  })
})
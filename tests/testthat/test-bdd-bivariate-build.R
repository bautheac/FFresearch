# In-memory source serving the bivariate fixtures, one per file family.
BivariateFixtureSource <- R6::R6Class(
  "BivariateFixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      fixtures <- c(
        "100_Portfolios_10x10" = "portfolios_2x3.csv",
        "100_Portfolios_10x10_Wout_Div" = "portfolios_2x3.csv",
        "100_Portfolios_10x10_Daily" = "us_daily.csv",
        "25_Portfolios_ME_Prior_12_2" = "me_prior.csv",
        "6_Portfolios_ME_EP_2x3" = "me_ep.csv",
        "Developed_25_Portfolios_ME_OP" = "regional_monthly.csv",
        "Developed_25_Portfolios_ME_OP_Daily" = "regional_daily.csv")
      readLines(testthat::test_path("fixtures", fixtures[[file]]), warn = FALSE)
    }
  )
)

describe("building the bivariate dataset", {
  sources <- data.table::data.table(
    file = c("100_Portfolios_10x10", "100_Portfolios_10x10_Wout_Div",
             "100_Portfolios_10x10_Daily", "25_Portfolios_ME_Prior_12_2",
             "6_Portfolios_ME_EP_2x3", "Developed_25_Portfolios_ME_OP",
             "Developed_25_Portfolios_ME_OP_Daily"),
    region = c(rep("US", 5L), rep("developed", 2L)),
    `sort variable 1` = "market capitalization",
    `sort variable 2` = c("book/market", "book/market", "book/market", "momentum",
                          "earnings/price", "operating profitability", "operating profitability"),
    dividend = c("Y", "N", "Y", "Y", "Y", "Y", "Y"),
    weights = rep(list(c("value", "equal")), 7L))
  bivariate <- BivariateBuilder$new(BivariateFixtureSource$new(), sources = sources)$build()
  key <- dataset_contract$portfolios_bivariate$key

  it("returns the documented columns and types", {
    contract <- dataset_contract$portfolios_bivariate
    expect_named(bivariate, names(contract$columns))
    expect_identical(unname(vapply(bivariate, function(col) class(col)[[1L]], "")),
                     unname(contract$columns))
    expect_setequal(levels(bivariate$region),
                    c("US", "developed", "developed (ex US)", "Europe", "JP",
                      "Asia-Pacific (ex JP)", "North America"))
    expect_setequal(levels(bivariate$frequency), c("day", "month", "year"))
  })

  it("tags dividends, sorts and regions from the mapping", {
    expect_setequal(bivariate$dividend, c("Y", "N"))
    wout <- bivariate[bivariate$dividend == "N", ]
    expect_true(all(wout$`sort variable 2` == "book/market"))
    expect_setequal(bivariate$region, c("US", "developed"))
    expect_setequal(bivariate$`sort variable 2`,
                    c("book/market", "momentum", "earnings/price", "operating profitability"))
  })

  it("keeps the committed fields and drops firm counts and sizes", {
    expect_false(any(c("number of firms", "average firm size") %in% bivariate$field))
    expect_true(all(c("value weight average of BE/ME", "value weight average of BE_FYt-1/ME_June t",
                      "value weight average of OP",
                      "value weight average of investment (rate of growth of assets)",
                      "value weight average of Prior Returns", "equal weight average of Prior Returns",
                      "value weight average of E/P") %in% bivariate$field))
    prior <- bivariate[bivariate$field == "equal weight average of Prior Returns", ]
    expect_true(all(prior$weights == "equal"))
    expect_true(all(prior$frequency == "month"))
    ep <- bivariate[bivariate$field == "value weight average of E/P", ]
    expect_true(all(ep$frequency == "year"))
    expect_true(all(ep$weights == "value"))
  })

  it("reads values, frequencies and sentinel-free data from every file family", {
    value <- function(region, frequency, sv2, dividend, weights, portfolio, field, period) {
      i <- which(bivariate$region == region & bivariate$frequency == frequency &
        bivariate$`sort variable 2` == sv2 & bivariate$dividend == dividend &
        bivariate$weights == weights & bivariate$portfolio == portfolio &
        bivariate$field == field & bivariate$period == period)
      bivariate$value[i]
    }
    expect_equal(value("US", "month", "book/market", "Y", "value", "SMALL LoBM", "return", "192607"), 1.0866)
    expect_equal(value("US", "month", "book/market", "N", "equal", "BIG HiBM", "return", "192608"), 6.7548)
    expect_equal(value("US", "day", "book/market", "Y", "value", "ME1 BM2", "return", "19260702"), 0.21)
    expect_equal(value("US", "month", "momentum", "Y", "equal", "ME1 PRIOR2", "return", "192607"), -0.05)
    expect_equal(value("US", "month", "momentum", "Y", "equal", "SMALL LoPRIOR",
                       "equal weight average of Prior Returns", "192701"), -50.54)
    expect_equal(value("US", "year", "earnings/price", "Y", "value", "BIG HiEP",
                       "value weight average of E/P", "1952"), 0.1831)
    expect_equal(value("developed", "month", "operating profitability", "Y", "value",
                       "BIG HiOP", "return", "199007"), 0.70)
    expect_equal(value("developed", "day", "operating profitability", "Y", "value",
                       "SMALL LoBO", "return", "19900702"), 0.27)
    # The -99.99 marker in the equal-weight Prior Returns section is dropped.
    expect_equal(length(value("US", "month", "momentum", "Y", "equal", "BIG HiPRIOR",
                              "equal weight average of Prior Returns", "192702")), 0L)
    expect_false(any(bivariate$value %in% c(-99.99, -999, -9999)))
  })

  it("keeps the library's regional daily BO labels alongside the monthly OP labels", {
    regional <- bivariate[bivariate$region == "developed", ]
    daily <- regional[regional$frequency == "day", ]
    monthly <- regional[regional$frequency == "month", ]
    expect_true("BIG HiBO" %in% daily$portfolio)
    expect_false("BIG HiOP" %in% daily$portfolio)
    expect_true("BIG HiOP" %in% monthly$portfolio)
  })

  it("orders rows by the contract key, without duplicates", {
    ordered <- bivariate[do.call(order, bivariate[, ..key])]
    expect_equal(bivariate, ordered)
    expect_equal(anyDuplicated(bivariate, by = key), 0L)
  })

  it("is wired by its factory", {
    builder <- BivariateBuilderFactory$new()$create(source = BivariateFixtureSource$new())
    expect_s3_class(builder, "BivariateBuilder")
  })
})

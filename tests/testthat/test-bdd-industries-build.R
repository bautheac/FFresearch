# In-memory source serving the industry fixtures under tests/testthat/fixtures.
IndustryFixtureSource <- R6::R6Class(
  "IndustryFixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      name <- switch(file,
        "5_Industry_Portfolios" = "industry_5.csv",
        "10_Industry_Portfolios" = "industry_10.csv",
        "5_Industry_Portfolios_Wout_Div" = "industry_5_wout_div.csv",
        "5_Industry_Portfolios_daily" = "industry_5_daily.csv",
        "unknown" = "industry_unknown.csv",
        stop("No fixture for file '", file, "'", call. = FALSE))
      readLines(testthat::test_path("fixtures", name), warn = FALSE)
    }
  )
)

describe("building the industries dataset", {
  # Coarser classification listed first: dedup must not rely on file order.
  sources <- data.table::data.table(
    file = c("5_Industry_Portfolios", "10_Industry_Portfolios",
             "5_Industry_Portfolios_Wout_Div", "5_Industry_Portfolios_daily"),
    region = "US",
    dividend = c("Y", "Y", "N", "Y"),
    classification = c(5L, 10L, 5L, 5L),
    weights = rep(list(c("value", "equal")), 4L))
  industries <- IndustriesBuilder$new(IndustryFixtureSource$new(), sources = sources)$build()

  it("keeps the finest classification for labels shared by several files", {
    shared <- industries[frequency == "month" & dividend == "Y" & weights == "value" &
                           field == "return" & period == "197101", ]
    expect_equal(shared$value[shared$portfolio == "Manuf"], 22.00)
    expect_equal(shared$value[shared$portfolio == "HiTec"], 33.00)
    expect_equal(shared$value[shared$portfolio == "Cnsmr"], 1.00)
  })

  it("keeps one observation per key", {
    key <- c("region", "frequency", "dividend", "weights", "portfolio", "field", "period")
    expect_equal(anyDuplicated(industries, by = key), 0L)
  })

  it("unions the portfolio labels across classifications", {
    expect_setequal(unique(industries$portfolio),
                    c("Cnsmr", "Manuf", "HiTec", "Hlth", "Other",
                      "NoDur", "Durbl", "Enrgy", "Telcm", "Shops", "Utils"))
  })

  it("drops missing-value markers and falls back to the next finest file", {
    expect_false(any(industries$value == -99.99))
    hlth <- industries[frequency == "month" & dividend == "Y" & weights == "value" &
                         field == "return" & period == "197102" & portfolio == "Hlth", ]
    expect_equal(nrow(hlth), 1L)
    expect_equal(hlth$value, 44.10)
  })

  it("keeps only the committed fields", {
    expect_setequal(levels(industries$field), c("return", "value weight average of BE/ME"))
    beme <- industries[field == "value weight average of BE/ME", ]
    expect_true(all(beme$frequency == "year"))
    expect_true(all(beme$weights == "value"))
  })

  it("labels dividends and frequencies from the file mapping", {
    n <- industries[dividend == "N", ]
    expect_true(all(n$frequency %in% c("month", "year")))
    cnsmr <- n[portfolio == "Cnsmr" & frequency == "month" & weights == "value" &
                 field == "return" & period == "197101", ]
    expect_equal(cnsmr$value, 0.50)
    day <- industries[frequency == "day", ]
    expect_true(all(day$dividend == "Y"))
    expect_setequal(as.character(day$field), "return")
  })

  it("uses the committed factor levels", {
    expect_equal(levels(industries$region), "US")
    expect_equal(levels(industries$frequency), c("month", "year", "day"))
    expect_equal(levels(industries$dividend), c("Y", "N"))
    expect_equal(levels(industries$weights), c("value", "equal"))
    expect_equal(levels(industries$field), c("return", "value weight average of BE/ME"))
  })

  it("orders rows by the dataset key", {
    ordered <- data.table::copy(industries)
    data.table::setorderv(ordered, c("region", "frequency", "dividend", "weights",
                                     "portfolio", "field", "period"))
    expect_equal(industries, ordered)
  })

  it("rejects portfolio labels outside the committed vocabulary", {
    sources <- data.table::data.table(file = "unknown", region = "US", dividend = "Y",
                                      classification = 5L, weights = list(c("value", "equal")))
    expect_error(
      IndustriesBuilder$new(IndustryFixtureSource$new(), sources = sources)$build(),
      "Unknown industry portfolio label in unknown: NewInd")
  })

  it("is wired by its factory", {
    builder <- IndustriesBuilderFactory$new()$create(source = IndustryFixtureSource$new())
    expect_s3_class(builder, "IndustriesBuilder")
    expect_equal(builder$name, "portfolios_industries")
  })

  it("returns the documented columns and types", {
    expect_named(industries, c("region", "frequency", "dividend", "weights",
                               "portfolio", "field", "period", "value"))
    expect_s3_class(industries$region, "factor")
    expect_s3_class(industries$frequency, "factor")
    expect_s3_class(industries$dividend, "factor")
    expect_s3_class(industries$weights, "factor")
    expect_type(industries$portfolio, "character")
    expect_s3_class(industries$field, "factor")
    expect_type(industries$period, "character")
    expect_type(industries$value, "double")
  })
})

# In-memory source serving the univariate fixtures under tests/testthat/fixtures.
UnivariateFixtureSource <- R6::R6Class(
  "UnivariateFixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      name <- switch(file,
        "Portfolios_Formed_on_ME" = "size.csv",
        "Portfolios_Formed_on_ME_Wout_Div" = "size.csv",
        "Portfolios_Formed_on_ME_Daily" = "me_daily.csv",
        "Portfolios_Formed_on_OP_Daily" = "me_daily.csv",
        "Portfolios_Formed_on_BE-ME" = "beme.csv",
        "Portfolios_Formed_on_NI" = "ni.csv",
        "Portfolios_Formed_on_VAR" = "var.csv",
        "10_Portfolios_Prior_12_2" = "prior.csv",
        "10_Portfolios_Prior_12_2_Daily" = "prior_daily.csv",
        stop("No fixture for library file '", file, "'", call. = FALSE))
      fixture_lines(name)
    }
  )
)

describe("building the portfolios_univariate dataset", {
  files <- c("Portfolios_Formed_on_ME", "Portfolios_Formed_on_ME_Wout_Div",
             "Portfolios_Formed_on_ME_Daily", "Portfolios_Formed_on_OP_Daily",
             "Portfolios_Formed_on_BE-ME", "Portfolios_Formed_on_NI",
             "Portfolios_Formed_on_VAR", "10_Portfolios_Prior_12_2",
             "10_Portfolios_Prior_12_2_Daily")
  sources <- univariate_sources()[file %in% files]
  committed <- load_dataset("portfolios_univariate")
  univariate <- UnivariateBuilder$new(UnivariateFixtureSource$new(), sources = sources)$build()

  it("returns the documented columns, types and factor levels", {
    expect_named(univariate, names(dataset_contract$portfolios_univariate$columns))
    expect_identical(unname(vapply(univariate, function(col) class(col)[[1L]], "")),
                     unname(dataset_contract$portfolios_univariate$columns))
    expect_equal(levels(univariate$region), "US")
    expect_equal(levels(univariate$frequency), c("day", "month", "year"))
    expect_equal(levels(univariate$`sort variable`), levels(committed$`sort variable`))
    expect_equal(levels(univariate$dividend), levels(committed$dividend))
    expect_equal(levels(univariate$weights), levels(committed$weights))
    expect_equal(levels(univariate$field), levels(committed$field))
  })

  it("uses the package's portfolio labels", {
    expect_true("Dec 2" %in% univariate$portfolio)
    expect_false(any(c("2-Dec", "<= 0", "< 0") %in% univariate$portfolio))
    expect_true(all(c("Negative", "X .0", "ZERO") %in% univariate$portfolio))
    # ME's `<= 0` column is all missing markers, so ME has no Negative portfolio.
    expect_false("Negative" %in% univariate[`sort variable` == "market capitalization"]$portfolio)
  })

  it("orders rows by the contract key", {
    ordered <- data.table::copy(data.table::as.data.table(univariate))
    data.table::setorderv(ordered, dataset_contract$portfolios_univariate$key)
    expect_equal(as.data.frame(univariate), as.data.frame(ordered))
  })

  it("reads the fixture values into the labelled rows", {
    pick <- function(freq, sv, div, wts, port, fld, per) {
      univariate[frequency == freq & `sort variable` == sv & dividend == div &
                   weights == wts & portfolio == port & field == fld &
                   period == per]$value
    }
    expect_equal(pick("month", "market capitalization", "Y", "value", "Dec 2", "return", "192607"), 0.57)
    expect_equal(pick("year", "book/market", "Y", "value", "Negative",
                      "value weight average of BE/ME", "1927"), -3.9092)
    expect_equal(pick("month", "net share issues", "Y", "equal", "X .0", "return", "196307"), -0.90)
    expect_equal(pick("day", "momentum", "Y", "value", "Lo PRIOR", "return", "19270103"), -0.52)
    expect_equal(pick("month", "variance", "Y", "value", "Hi 10",
                      "value weight average of Past Return Variance", "196307"), 11.837)
  })

  it("keeps the committed coverage", {
    day <- univariate[frequency == "day"]
    expect_setequal(day$`sort variable`, c("market capitalization", "momentum"))
    expect_setequal(day$dividend, "Y")
    expect_setequal(day$field, "return")
    derived <- univariate[field != "return"]
    expect_setequal(derived$weights, "value")
    expect_setequal(derived[field == "value weight average of Past Return Variance"]$frequency, "month")
    expect_setequal(derived[field == "value weight average of BE/ME"]$frequency, "year")
    expect_false(any(grepl("^(number of firms|average firm size|Sum of)", univariate$field)))
  })

  it("is wired by its factory", {
    builder <- UnivariateBuilderFactory$new()$create(source = UnivariateFixtureSource$new())
    expect_s3_class(builder, "UnivariateBuilder")
  })
})

# The committed dataset still carries the old region labels; the library (and
# the spec) renamed them. Relabel here, independently of the mapping.
relabel_regions <- function(region) {
  region <- as.character(region)
  region[region == "global"] <- "developed"
  region[region == "global (ex US)"] <- "developed (ex US)"
  region
}

test_that("bivariate_sources maps one row per library file", {
  sources <- bivariate_sources()

  expect_s3_class(sources, "data.table")
  expect_named(sources, c("file", "region", "sort variable 1", "sort variable 2",
                          "dividend", "weights"))
  expect_equal(anyDuplicated(sources$file), 0L)
  expect_true(all(vapply(sources$weights, function(w) setequal(w, c("value", "equal")), logical(1))))
})

test_that("bivariate_sources covers every committed sort variable, dividend and weights level", {
  sources <- bivariate_sources()
  committed <- load_dataset("portfolios_bivariate")
  combinations <- function(x) {
    unique(paste(relabel_regions(x$region), x$`sort variable 1`, x$`sort variable 2`, x$dividend))
  }

  expect_setequal(sources$`sort variable 1`, levels(committed$`sort variable 1`))
  expect_setequal(sources$`sort variable 2`, levels(committed$`sort variable 2`))
  expect_setequal(sources$dividend, levels(committed$dividend))
  expect_setequal(unlist(sources$weights), levels(committed$weights))
  expect_setequal(sources$region, relabel_regions(levels(committed$region)))
  expect_true(all(combinations(committed) %in% combinations(sources)))
})

test_that("bivariate_fields covers every committed field level", {
  committed <- load_dataset("portfolios_bivariate")

  expect_setequal(bivariate_fields(), levels(committed$field))
})

test_that("bivariate_sources labels the files as the library names them", {
  sources <- bivariate_sources()
  labelled <- function(file, column) sources[[column]][sources$file == file]

  # US size x book/market uses the 10x10 file, not the 6/25 ones.
  expect_equal(labelled("100_Portfolios_10x10", "sort variable 1"), "market capitalization")
  expect_equal(labelled("100_Portfolios_10x10", "sort variable 2"), "book/market")
  expect_equal(labelled("100_Portfolios_10x10", "dividend"), "Y")
  # The ex-dividend 10x10 stems put the sort before Wout_Div.
  expect_equal(labelled("100_Portfolios_10x10_ME_OP_Wout_Div", "sort variable 2"), "operating profitability")
  expect_equal(labelled("100_Portfolios_10x10_ME_OP_Wout_Div", "dividend"), "N")
  expect_equal(labelled("100_Portfolios_10x10_ME_INV_Wout_Div", "sort variable 2"), "investment")
  expect_equal(labelled("100_Portfolios_ME_OP_10x10_daily", "dividend"), "Y")
  # Regional files use the 25 variants and the current region names.
  expect_equal(labelled("Developed_25_Portfolios_ME_BE-ME", "region"), "developed")
  expect_equal(labelled("Developed_ex_US_25_Portfolios_ME_OP", "region"), "developed (ex US)")
  expect_equal(labelled("Japan_25_Portfolios_ME_INV", "region"), "JP")
  expect_equal(labelled("Asia_Pacific_ex_Japan_25_Portfolios_ME_BE-ME", "region"), "Asia-Pacific (ex JP)")
  # Regional momentum daily stems skip 20 trading days over 250.
  expect_equal(labelled("Developed_25_Portfolios_ME_Prior_250_20_daily", "sort variable 2"), "momentum")
  expect_equal(labelled("Europe_25_Portfolios_ME_Prior_12_2", "sort variable 2"), "momentum")
})

test_that("every bivariate library file exists in the live library", {
  skip_if(Sys.getenv("FFRESEARCH_NETWORK") != "true", "FFRESEARCH_NETWORK is not true")

  page <- tempfile(fileext = ".html")
  on.exit(unlink(page))
  utils::download.file("https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html",
                       page, quiet = TRUE)
  links <- readLines(page, warn = FALSE)
  archives <- unlist(regmatches(links, gregexpr("ftp/[^\"]+_CSV\\.zip", links)))
  stems <- sub("_CSV\\.zip$", "", sub("^ftp/", "", archives))

  expect_equal(setdiff(bivariate_sources()$file, stems), character(0))
})

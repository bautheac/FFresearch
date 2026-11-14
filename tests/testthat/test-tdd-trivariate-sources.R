test_that("trivariate_sources maps one row per library file", {
  sources <- trivariate_sources()

  expect_s3_class(sources, "data.table")
  expect_named(sources, c("file", "region", "sort variable 1", "sort variable 2",
                          "sort variable 3", "dividend", "weights"))
  expect_equal(anyDuplicated(sources$file), 0L)
  expect_equal(nrow(sources), 24L)
  expect_true(all(vapply(sources$weights, function(w) setequal(w, c("value", "equal")), logical(1))))
})

test_that("trivariate_sources covers every committed sort variable, dividend and weights level", {
  sources <- trivariate_sources()
  committed <- load_dataset("portfolios_trivariate")

  expect_setequal(sources$`sort variable 1`, levels(committed$`sort variable 1`))
  expect_setequal(sources$`sort variable 2`, levels(committed$`sort variable 2`))
  expect_setequal(sources$`sort variable 3`, levels(committed$`sort variable 3`))
  expect_setequal(sources$dividend, levels(committed$dividend))
  expect_setequal(unlist(sources$weights), levels(committed$weights))
})

test_that("trivariate_sources covers every committed region under the library vocabulary", {
  sources <- trivariate_sources()
  committed <- load_dataset("portfolios_trivariate")

  expect_setequal(sources$region, unique(relabel_regions(committed$region)))
})

test_that("trivariate_sources labels dividends and sorts as the library provides them", {
  sources <- trivariate_sources()
  labelled <- function(file, column) sources[[column]][sources$file == file]

  expect_equal(labelled("32_Portfolios_ME_BEME_OP_2x4x4", "dividend"), "Y")
  expect_equal(labelled("32_Portfolios_ME_BEME_OP_2x4x4_Wout_Div", "dividend"), "N")
  expect_equal(labelled("32_Portfolios_ME_BEME_INV_2x4x4", "sort variable 3"), "investment")
  expect_equal(labelled("32_Portfolios_ME_OP_INV_2x4x4", "sort variable 2"), "operating profitability")
  expect_equal(labelled("Japan_32_Portfolios_ME_BE-ME_INV(TA)_2x4x4", "sort variable 3"), "investment")
  expect_equal(labelled("Developed_32_Portfolios_ME_INV(TA)_OP_2x4x4", "sort variable 2"),
               "operating profitability")
  # The library has no regional ex-dividend trivariate files: every regional
  # sort includes dividends (the committed N labels are an old artefact).
  expect_setequal(sources$dividend[sources$region != "US"], "Y")
})

test_that("every trivariate library file exists in the live library", {
  skip_if(Sys.getenv("FFRESEARCH_NETWORK") != "true", "FFRESEARCH_NETWORK is not true")

  page <- tempfile(fileext = ".html")
  on.exit(unlink(page))
  utils::download.file("https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html",
                       page, quiet = TRUE)
  links <- readLines(page, warn = FALSE)
  archives <- unlist(regmatches(links, gregexpr("ftp/[^\"]+_CSV\\.zip", links)))
  stems <- sub("_CSV\\.zip$", "", sub("^ftp/", "", archives))

  expect_equal(setdiff(trivariate_sources()$file, stems), character(0))
})
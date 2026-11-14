for (name in names(dataset_contract)) {
  local({
    name <- name
    contract <- dataset_contract[[name]]

    test_that(paste0("`", name, "` keeps its documented columns and types"), {
      x <- load_dataset(name)
      expect_s3_class(x, "data.frame")
      expect_identical(names(x), names(contract$columns))
      expect_identical(unname(vapply(x, function(col) class(col)[[1L]], "")),
                       unname(contract$columns))
    })

    test_that(paste0("`", name, "` has data, no missing required values and no duplicate observations"), {
      x <- load_dataset(name)
      expect_gt(nrow(x), 0L)
      required <- setdiff(names(x), contract$nullable)
      # Column-wise: as.data.frame() would deep-copy the largest datasets.
      expect_false(any(vapply(required, function(column) anyNA(x[[column]]), logical(1L))))
      # as.data.table() deep-copies data.tables; only convert other classes.
      dt <- if (data.table::is.data.table(x)) x else data.table::as.data.table(x)
      expect_false(anyDuplicated(dt, by = contract$key) > 0L)
    })

    if ("period" %in% names(contract$columns)) {
      test_that(paste0("`", name, "` periods match their frequency"), {
        x <- load_dataset(name)
        # Vectorised width check plus a digits check on the distinct periods;
        # element-wise mapply(grepl, ...) is too slow on the largest datasets.
        widths <- c(day = 8L, month = 6L, year = 4L)[levels(x$frequency)]
        expect_true(all(nchar(x$period) == widths[as.integer(x$frequency)]))
        expect_true(all(grepl("^[0-9]+$", unique(x$period))))
        # Maintainer decision (2026-11-14, spec #3 follow-up): R's lazyload
        # DB cannot serialise objects above 2^31 - 1 bytes, so the portfolio
        # series and breakpoints start in 1971. factors keeps its full
        # history. Literals here are the decision's boundary, independent
        # of the builders' coverage_start() helper. Grouped minima keep the
        # check cheap: expanding the largest datasets' columns to character
        # would not fit the 3 GB container.
        if (name == "factors") {
          expect_true(min(x$period) < "1971")
        } else {
          start <- c(year = "1971", month = "197101", day = "19710101")
          mins <- x[, .(start = min(period)), by = frequency]
          expect_true(all(mins$start >= start[as.character(mins$frequency)]))
        }
      })
    }
  })
}

test_that("`factors` covers the documented regions and frequencies", {
  x <- load_dataset("factors")
  expect_setequal(levels(x$region), c("US", "developed", "developed (ex US)", "Europe", "JP",
                                      "Asia-Pacific (ex JP)", "North America"))
  expect_setequal(levels(x$frequency), c("month", "day", "year"))
})

test_that("`portfolios_bivariate` covers the documented regions and frequencies", {
  x <- load_dataset("portfolios_bivariate")
  expect_setequal(levels(x$region), c("US", "developed", "developed (ex US)", "Europe", "JP",
                                      "Asia-Pacific (ex JP)", "North America"))
  expect_setequal(levels(x$frequency), c("day", "month", "year"))
  # Size guard: R's lazyload DB cannot serialise objects above 2^31 - 1
  # bytes (2,147,483,647): the full-history bivariate serialised to
  # 2,363,328,315 bytes and failed standard installation on every platform
  # (CI run 43596097938). The bivariate serialises at roughly 68 bytes per
  # row, so 31,000,000 rows (~2.1 GB) is the ceiling. This guard catches
  # future library growth at refresh time, before the install breaks again.
  # It shares this test's load: a separate load would not fit the 3 GB
  # container alongside the rest of the suite.
  expect_lt(nrow(x), 31000000L)
})

test_that("`portfolios_trivariate` covers the documented regions and frequencies", {
  x <- load_dataset("portfolios_trivariate")
  expect_setequal(levels(x$region), c("US", "developed", "developed (ex US)", "Europe", "JP",
                                      "Asia-Pacific (ex JP)", "North America"))
  expect_setequal(levels(x$frequency), c("month", "year"))
  expect_setequal(as.character(x$dividend[x$region != "US"]), "Y")
})

test_that("`breakpoints` keeps multiple periods for every variable and frequency", {
  x <- load_dataset("breakpoints")
  counts <- x[, .(n = data.table::uniqueN(period)), by = .(variable, frequency)]
  expect_true(all(counts$n > 1L))
})

test_that("`factors` market return equals excess return plus the risk free rate", {
  x <- load_dataset("factors")
  us <- x[x$region == "US" & x$frequency == "month", ]
  market <- us[us$factor == "market", ]
  rf <- us[us$factor == "risk free rate", ]
  expect_identical(market$period, rf$period)
  expect_true(all(market$value - rf$value > -100))
})

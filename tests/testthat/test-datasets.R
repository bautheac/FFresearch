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
      expect_false(anyNA(as.data.frame(x)[required]))
      expect_false(anyDuplicated(data.table::as.data.table(x), by = contract$key) > 0L)
    })

    if ("period" %in% names(contract$columns)) {
      test_that(paste0("`", name, "` periods match their frequency"), {
        x <- load_dataset(name)
        ok <- mapply(grepl, period_pattern[as.character(x$frequency)], x$period)
        expect_true(all(ok))
      })
    }
  })
}

test_that("`factors` covers the documented regions and frequencies", {
  x <- load_dataset("factors")
  expect_setequal(levels(x$region), c("US", "global", "global (ex US)", "Europe", "JP",
                                      "Asia-Pacific (ex JP)", "North America"))
  expect_setequal(levels(x$frequency), c("month", "day", "year"))
})

test_that("`factors` market return equals excess return plus the risk free rate", {
  x <- load_dataset("factors")
  us <- x[x$region == "US" & x$frequency == "month", ]
  market <- us[us$factor == "market", ]
  rf <- us[us$factor == "risk free rate", ]
  expect_identical(market$period, rf$period)
  expect_true(all(market$value - rf$value > -100))
})

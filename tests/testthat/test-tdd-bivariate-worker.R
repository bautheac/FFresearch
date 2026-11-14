# A failing parse worker must name its cause, not just an exit status:
# CI runs have no other window into the worker process (spec #3 follow-up).
test_that("a failing parse worker reports its cause and library state", {
  GarbageSource <- R6::R6Class(
    "GarbageSource",
    inherit = LinesSource,
    public = list(read_lines = function(file) "this is not a library file")
  )
  sources <- data.table::data.table(
    file = "100_Portfolios_10x10", region = "US",
    `sort variable 1` = "market capitalization", `sort variable 2` = "book/market",
    dividend = "Y", weights = list(c("value", "equal")))
  builder <- BivariateBuilder$new(GarbageSource$new(), sources = sources)
  expect_error(builder$build(), "worker exit status")
  expect_error(builder$build(), "No section headings found")
  expect_error(builder$build(), "worker libPaths")
})
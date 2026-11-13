test_that("FrenchParser reads every section and infers the frequency from the period width", {
  table <- FrenchParser$new()$parse(fixture_lines("mom.csv"))

  expect_setequal(table$frequency, c("month", "year"))
  expect_equal(table[period == "1927"]$value, 3)
})

test_that("FrenchParser drops missing-value markers", {
  table <- FrenchParser$new()$parse(fixture_lines("mom.csv"))

  expect_false("192702" %in% table$period)
  expect_equal(nrow(table), 3L)
})

test_that("FrenchParser rejects files without a header or data rows", {
  expect_error(FrenchParser$new()$parse("nothing here"), "No header line")
  expect_error(FrenchParser$new()$parse(c(",Mom", "text")), "No data rows")
})

# Tiny in-memory frames shaped like a dataset: key columns, period, value.
tiny_frame <- function(region, period, value) {
  data.table::data.table(region = region, period = period, value = value)
}
tiny_key <- c("region", "period")

test_that("compare_dataset reports keys present only in the committed data", {
  old <- tiny_frame(c("A", "B"), "202601", c(1, 2))
  rebuilt <- tiny_frame("A", "202601", 1)

  result <- compare_dataset("factors", rebuilt, tiny_key, old = old)

  expect_equal(result$only_old, data.table::data.table(region = "B", period = "202601"))
})

test_that("compare_dataset reports keys present only in the rebuilt data", {
  old <- tiny_frame("A", "202601", 1)
  rebuilt <- tiny_frame(c("A", "C"), "202601", c(1, 3))

  result <- compare_dataset("factors", rebuilt, tiny_key, old = old)

  expect_equal(result$only_new, data.table::data.table(region = "C", period = "202601"))
})

test_that("compare_dataset reports the largest absolute difference over shared keys", {
  old <- tiny_frame(c("A", "B"), "202601", c(1, 2))
  rebuilt <- tiny_frame(c("A", "B"), "202601", c(1.5, -1))

  result <- compare_dataset("factors", rebuilt, tiny_key, old = old)

  expect_equal(result$max_abs_difference, 3)
})

test_that("compare_dataset ignores periods missing from either side", {
  old <- tiny_frame(c("A", "B"), c("202601", "202512"), c(1, 2))
  rebuilt <- tiny_frame(c("A", "C"), c("202601", "202602"), c(1, 3))

  result <- compare_dataset("factors", rebuilt, tiny_key, old = old)

  empty <- data.table::data.table(region = character(), period = character())
  expect_equal(result$only_old, empty)
  expect_equal(result$only_new, empty)
  expect_equal(result$max_abs_difference, 0)
})

test_that("compare_dataset compares all rows when the dataset has no period", {
  old <- data.table::data.table(name = c("alpha", "beta"), value = c(1, 2))
  rebuilt <- data.table::data.table(name = "alpha", value = 1.5)

  result <- compare_dataset("variables", rebuilt, "name", old = old)

  expect_equal(result$only_old, data.table::data.table(name = "beta"))
  expect_equal(result$max_abs_difference, 0.5)
})

test_that("compare_dataset reports no differences when no periods overlap", {
  old <- tiny_frame("A", "202512", 1)
  rebuilt <- tiny_frame("A", "202601", 2)

  result <- compare_dataset("factors", rebuilt, tiny_key, old = old)

  empty <- data.table::data.table(region = character(), period = character())
  expect_equal(result$only_old, empty)
  expect_equal(result$only_new, empty)
  expect_equal(result$max_abs_difference, 0)
})
test_that("LinesSource is abstract", {
  expect_error(LinesSource$new(), "abstract")
  expect_error(R6::R6Class("Bare", inherit = LinesSource)$new()$read_lines("f"), "must be implemented")
})

test_that("HttpZipSource retries a failing download, then reports the URL", {
  FailingSource <- R6::R6Class(
    "FailingSource",
    inherit = HttpZipSource,
    public = list(attempts = 0L),
    private = list(download = function(url) {
      self$attempts <- self$attempts + 1L
      stop("boom")
    })
  )
  source <- FailingSource$new("http://example.test/", retries = 2L)

  expect_error(source$read_lines("f"), "http://example.test/f_CSV.zip")
  expect_equal(source$attempts, 2L)
})

test_that("HttpZipSource succeeds when a later attempt works", {
  FlakySource <- R6::R6Class(
    "FlakySource",
    inherit = HttpZipSource,
    public = list(attempts = 0L),
    private = list(download = function(url) {
      self$attempts <- self$attempts + 1L
      if (self$attempts < 2L) stop("transient")
      "lines"
    })
  )
  source <- FlakySource$new(retries = 3L)

  expect_equal(source$read_lines("f"), "lines")
  expect_equal(source$attempts, 2L)
})

test_that("CachedSource reads each file from its inner source once", {
  CountingSource <- R6::R6Class(
    "CountingSource",
    inherit = LinesSource,
    public = list(
      reads = 0L,
      initialize = function() {},
      read_lines = function(file) {
        self$reads <- self$reads + 1L
        c("a", "b")
      }
    )
  )
  inner <- CountingSource$new()
  cached <- CachedSource$new(inner, withr::local_tempdir())

  expect_equal(cached$read_lines("f"), c("a", "b"))
  expect_equal(cached$read_lines("f"), c("a", "b"))
  expect_equal(inner$reads, 1L)
})

test_that("DatasetBuilder is abstract and its steps must be implemented", {
  expect_error(DatasetBuilder$new("x"), "abstract")

  Incomplete <- R6::R6Class("Incomplete", inherit = DatasetBuilder)
  expect_error(Incomplete$new("x")$build(), "read_tables")
})

test_that("DatasetWriter saves what the builder builds under the builder's name", {
  ThingBuilder <- R6::R6Class(
    "ThingBuilder",
    inherit = DatasetBuilder,
    private = list(
      read_tables = function() 1,
      assemble = function(tables) data.frame(a = tables)
    )
  )
  dir <- withr::local_tempdir()

  path <- DatasetWriter$new(dir)$write(ThingBuilder$new("thing"))
  loaded <- new.env()
  load(path, loaded)

  expect_equal(loaded$thing, data.frame(a = 1))
})

test_that("DatasetWriter rejects anything that is not a builder", {
  expect_error(DatasetWriter$new(tempdir())$write(1), "DatasetBuilder")
})

# In-memory source serving the fixtures under tests/testthat/fixtures.
FixtureSource <- R6::R6Class(
  "FixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      name <- if (grepl("Mom", file)) "mom.csv" else "ff5.csv"
      readLines(testthat::test_path("fixtures", name), warn = FALSE)
    }
  )
)

fixture_lines <- function(name) readLines(testthat::test_path("fixtures", name), warn = FALSE)

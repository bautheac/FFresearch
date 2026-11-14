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

# In-memory source serving the breakpoints fixtures under tests/testthat/fixtures.
BreakpointsFixtureSource <- R6::R6Class(
  "BreakpointsFixtureSource",
  inherit = LinesSource,
  public = list(
    initialize = function() {},
    read_lines = function(file) {
      name <- c(
        ME_Breakpoints = "breakpoints-me.csv",
        `BE-ME_Breakpoints` = "breakpoints-beme.csv",
        OP_Breakpoints = "breakpoints-op.csv",
        INV_Breakpoints = "breakpoints-inv.csv",
        `E-P_Breakpoints` = "breakpoints-ep.csv",
        `CF-P_Breakpoints` = "breakpoints-cfp.csv",
        `D-P_Breakpoints` = "breakpoints-dp.csv",
        `Prior_2-12_Breakpoints` = "breakpoints-prior.csv")[[file]]
      if (is.null(name)) stop("No fixture for library file '", file, "'.", call. = FALSE)
      readLines(testthat::test_path("fixtures", name), warn = FALSE)
    }
  )
)

fixture_lines <- function(name) readLines(testthat::test_path("fixtures", name), warn = FALSE)

# The label a sources mapping assigns to one library file.
source_label <- function(sources, file, column) sources[[column]][sources$file == file]

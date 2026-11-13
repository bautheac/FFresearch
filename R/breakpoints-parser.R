#' Parser for French library breakpoints CSV files
#'
#' Turns the lines of a breakpoints file into a long table (`variable`,
#' `frequency`, `percentile`, `period`, `value`). The `variable` label is
#' supplied by the caller (the builder maps each library file to its variable).
#' Breakpoints files have no section headings: a free-text preamble, an optional
#' header naming the firm-count columns, data rows, and a copyright footer. Each
#' data row is a period, one or two firm counts, then 20 percentiles (every 5th,
#' 5% to 100%). Counts are labelled `# positive` / `# negative`; frequency is
#' inferred from the period width (4 = year, 6 = month). Missing-value markers
#' (-99.99, -999) are dropped.
#'
#' @keywords internal
#' @noRd
BreakpointsParser <- R6::R6Class(
  "BreakpointsParser",
  public = list(
    parse = function(lines, variable) {
      if (missing(variable)) {
        stop("`variable` is required: name the breakpoints variable (e.g. \"size\").", call. = FALSE)
      }
      counts <- private$count_columns(lines)
      rows <- lines[grepl("^[[:space:]]*[0-9]{4,8}[[:space:]]*,", lines)]
      if (!length(rows)) stop("No data rows found in the breakpoints file.", call. = FALSE)
      labels <- c(counts, paste0(seq(5, 100, by = 5), "%"))
      fields <- strsplit(rows, ",")
      period <- trimws(vapply(fields, `[[`, "", 1L))
      values <- do.call(rbind, lapply(fields, function(x) as.numeric(trimws(x[-1L]))))
      colnames(values) <- labels
      wide <- data.table::as.data.table(values)
      wide[, period := period]
      long <- data.table::melt(wide, id.vars = "period", variable.name = "percentile",
                               variable.factor = FALSE)
      long[, variable := variable]
      long[, frequency := c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]]
      long[, .(variable, frequency, percentile, period, value)]
    }
  ),
  private = list(
    count_columns = function(lines) {
      "# positive"
    }
  )
)
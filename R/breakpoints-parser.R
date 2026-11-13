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
      widths <- lengths(fields)
      ncols <- length(labels) + 1L
      if (any(widths != ncols)) {
        stop("Breakpoints data rows must have ", ncols, " columns (period, ",
             length(counts), " firm count(s), 20 percentiles); found row(s) with ",
             paste(sort(unique(widths[widths != ncols])), collapse = ", "), " fields.",
             call. = FALSE)
      }
      period <- trimws(vapply(fields, `[[`, "", 1L))
      values <- do.call(rbind, lapply(fields, function(x) as.numeric(trimws(x[-1L]))))
      colnames(values) <- labels
      wide <- data.table::as.data.table(values)
      wide[, period := period]
      long <- data.table::melt(wide, id.vars = "period", variable.name = "percentile",
                               variable.factor = FALSE)
      long[, variable := variable]
      long[, frequency := c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]]
      long <- long[!value %in% c(-99.99, -999)]
      long[, .(variable, frequency, percentile, period, value)]
    }
  ),
  private = list(
    count_columns = function(lines) {
      header <- lines[grepl("^[[:space:]]*,", lines)]
      if (!length(header)) return("# positive")
      labels <- trimws(strsplit(header[[1L]], ",")[[1L]])[-1L]
      mapping <- c("Count" = "# positive", "<= 0" = "# negative", ">0" = "# positive")
      if (!length(labels) || !all(labels %in% names(mapping))) {
        stop("Unrecognised breakpoints header: count columns must be 'Count' or '<= 0' and '>0', got '",
             paste(labels, collapse = "', '"), "'.", call. = FALSE)
      }
      unname(mapping[labels])
    }
  )
)
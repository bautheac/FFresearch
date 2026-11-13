#' Parser for French library CSV files
#'
#' Turns the lines of a monthly/annual or daily factor file into a long table
#' (`period`, `factor`, `value`, `frequency`). Frequency is inferred from the
#' period width: 4 = year, 6 = month, 8 = day. Missing-value markers (-99.99,
#' -999) are dropped.
#'
#' @keywords internal
#' @noRd
FrenchParser <- R6::R6Class(
  "FrenchParser",
  public = list(
    parse = function(lines) {
      header_line <- lines[grepl("^,", lines)][1L]
      if (is.na(header_line)) stop("No header line found", call. = FALSE)
      header <- trimws(strsplit(header_line, ",")[[1L]])[-1L]
      rows <- lines[grepl("^[[:space:]]*[0-9]{4,8}[[:space:]]*,", lines)]
      if (!length(rows)) stop("No data rows found", call. = FALSE)
      fields <- strsplit(rows, ",")
      period <- trimws(vapply(fields, `[[`, "", 1L))
      values <- do.call(rbind, lapply(fields, function(x) as.numeric(trimws(x[-1L]))))
      colnames(values) <- header
      out <- data.table::as.data.table(values)
      out[, period := period]
      out <- data.table::melt(out, id.vars = "period", variable.name = "factor",
                              variable.factor = FALSE)
      out[, frequency := c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]]
      out[!is.na(value) & value > -99]
    }
  )
)

#' Parser for French library portfolio CSV files
#'
#' Turns the lines of a multi-section portfolio file (industry, size, bivariate
#' or trivariate sorts) into a long table (`portfolio`, `field`, `weights`,
#' `period`, `value`, `frequency`). Each section heading is mapped to a field
#' and a weighting through an explicit lookup; an unknown heading raises an
#' error naming it. Frequency is inferred from the period width: 4 = year,
#' 6 = month, 8 = day. Missing-value markers (-99.99, -999, -9999) are dropped.
#' Builders tag region, sort and dividend labels on the returned table.
#'
#' @keywords internal
#' @noRd
PortfolioParser <- R6::R6Class(
  "PortfolioParser",
  public = list(
    parse = function(lines) {
      sections <- private$read_sections(private$split_lines(lines))
      private$assemble(sections)
    }
  ),
  private = list(
    # Section heading -> field and weights. Headings are matched after
    # whitespace normalisation (trimmed, internal runs collapsed). The
    # library uses several wordings for the same field: "Value Weighted",
    # "Value Weight" and "Value Weight Average" returns, with or without
    # "Average", and annual suffixes "-- Annual" or "-- Annual from January
    # to December". Firm counts and sizes carry no weighting (NA).
    headings = data.table::data.table(
      heading = c(
        "Average Value Weighted Returns -- Monthly",
        "Average Equal Weighted Returns -- Monthly",
        "Average Value Weighted Returns -- Annual",
        "Average Equal Weighted Returns -- Annual",
        "Number of Firms in Portfolios",
        "Average Firm Size",
        "Sum of BE / Sum of ME",
        "Value-Weighted Average of BE/ME"
      ),
      field = c(
        "return", "return", "return", "return",
        "number of firms", "average firm size",
        "Sum of BE / Sum of ME", "value weight average of BE/ME"
      ),
      weights = c("value", "equal", "value", "equal",
                  NA_character_, NA_character_, "value", "value")
    ),
    split_lines = function(lines) {
      # Library files use CRLF; some heading blocks use lone CR separators.
      unlist(strsplit(lines, "\r\n|\r|\n"), use.names = FALSE)
    },
    read_sections = function(lines) {
      sections <- list()
      current <- NULL
      started <- FALSE
      for (line in lines) {
        if (!nzchar(trimws(line))) next
        if (grepl("^[[:space:]]*[0-9]{4,8}[[:space:]]*,", line)) {
          if (is.null(current)) stop("Data row before any section heading", call. = FALSE)
          section <- sections[[current]]
          if (is.null(section$names)) {
            stop("No header line found for section '", section$heading, "'", call. = FALSE)
          }
          sections[[current]]$rows[[length(section$rows) + 1L]] <- trimws(strsplit(line, ",")[[1L]])
          next
        }
        trimmed <- trimws(line)
        if (startsWith(trimmed, ",")) {
          if (is.null(current)) stop("Header line before any section heading", call. = FALSE)
          sections[[current]]$names <- trimws(strsplit(trimmed, ",")[[1L]])[-1L]
          next
        }
        if (!grepl("^[[:space:]]", line)) next  # preamble or footer free text
        tags <- private$lookup(private$normalise(line))
        if (is.null(tags)) {
          if (started) stop("Unknown section heading: '", trimmed, "'", call. = FALSE)
          next  # indented preamble continuation
        }
        sections[[length(sections) + 1L]] <- list(
          heading = trimmed, field = tags$field, weights = tags$weights,
          names = NULL, rows = list())
        current <- length(sections)
        started <- TRUE
      }
      if (!length(sections)) stop("No section headings found", call. = FALSE)
      sections
    },
    normalise = function(line) {
      trimws(gsub("[[:space:]]+", " ", line))
    },
    lookup = function(heading) {
      i <- match(heading, private$headings$heading)
      if (is.na(i)) return(NULL)
      list(field = private$headings$field[[i]], weights = private$headings$weights[[i]])
    },
    assemble = function(sections) {
      tables <- lapply(sections, function(section) {
        if (!length(section$rows)) return(NULL)
        values <- do.call(rbind, lapply(section$rows, function(row) as.numeric(row[-1L])))
        colnames(values) <- section$names
        wide <- data.table::as.data.table(values)
        wide[, period := vapply(section$rows, `[[`, "", 1L)]
        long <- data.table::melt(wide, id.vars = "period", variable.name = "portfolio",
                                 variable.factor = FALSE)
        long[, `:=`(field = section$field, weights = section$weights)]
      })
      tables <- tables[!vapply(tables, is.null, logical(1L))]
      if (!length(tables)) stop("No data rows found", call. = FALSE)
      out <- data.table::rbindlist(tables)
      frequency <- c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(out$period))]
      out[, frequency := frequency]
      out <- out[!is.na(value) & !value %in% c(-99.99, -999, -9999)]
      out[, .(portfolio, field, weights, period, value, frequency)]
    }
  )
)

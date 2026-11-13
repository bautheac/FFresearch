#' Parser for French library portfolio CSV files
#'
#' Turns the lines of a multi-section portfolio file (industry, size, bivariate
#' or trivariate sorts) into a long table (`portfolio`, `field`, `weights`,
#' `period`, `value`, `frequency`). Each section heading is mapped to a field
#' and a weighting through an explicit lookup; an unknown heading raises an
#' error naming it. Multi-line heading blocks are identified by their
#' "Value Weight Average of <field> Calculated ..." line. Frequency is
#' inferred from the period width: 4 = year, 6 = month, 8 = day.
#' Missing-value markers (-99.99, -999, -9999) are dropped.
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
    # to December". Firm counts and sizes carry no weighting (NA). The CF/P
    # and D/P formation headings follow the verified E/P wording (the
    # 6_Portfolios_ME_CFP_2x3 and _DP_2x3 files were not sampled).
    headings = data.table::rbindlist(list(
      data.table::data.table(
        heading = c(
          "Average Value Weighted Returns -- Monthly",
          "Average Value Weighted Returns -- Annual",
          "Average Value Weight Returns -- Monthly",
          "Value Weight Returns -- Monthly",
          "Value Weight Returns -- Annual from January to December",
          "Value Weighted Returns -- Monthly",
          "Value Weighted Returns -- Annual from January to December",
          "Value Weight Average Returns -- Monthly",
          "Value Weight Average Returns -- Annual"
        ),
        field = "return", weights = "value"),
      data.table::data.table(
        heading = c(
          "Average Equal Weighted Returns -- Monthly",
          "Average Equal Weighted Returns -- Annual",
          "Equal Weight Returns -- Monthly",
          "Equal Weight Returns -- Annual from January to December",
          "Equal Weighted Returns -- Monthly",
          "Equal Weighted Returns -- Annual from January to December",
          "Equal Weight Average Returns -- Monthly",
          "Equal Weight Average Returns -- Annual"
        ),
        field = "return", weights = "equal"),
      data.table::data.table(
        heading = c("Number of Firms in Portfolios", "Average Firm Size", "Average Market Cap"),
        field = c("number of firms", "average firm size", "average firm size"),
        weights = NA_character_),
      data.table::data.table(
        heading = c("Sum of BE / Sum of ME",
                    "Value-Weighted Average of BE/ME",
                    "Value Weight Average of BE / ME",
                    "Value-Weighted Average of NI",
                    "Value-Weighted Average of Prior Returns",
                    "Value Weight Average of OP",
                    "Value Weight Average of Natural Log of INV",
                    "Value Weight Average of E / ME",
                    "Value Weight Average of CF / ME",
                    "Value-Weighted Average of ACCR",
                    "Value-Weighted Average of Prior Beta",
                    "Value-Weighted Average of Past Return Variance",
                    "Value Weight Average of E/P when portfolio is formed",
                    "Value Weight Average of CF/P when portfolio is formed",
                    "Value Weight Average of D/P when portfolio is formed"),
        field = c("Sum of BE / Sum of ME",
                  "value weight average of BE/ME",
                  "value weight average of BE/ME",
                  "value weight average of NI",
                  "value weight average of Prior Returns",
                  "value weight average of OP",
                  "value weight average of Natural Log of INV",
                  "value weight average of E/ME",
                  "value weight average of CF/ME",
                  "value weight average of ACCR",
                  "value weight average of Prior Beta",
                  "value weight average of Past Return Variance",
                  "value weight average of E/P",
                  "value weight average of CF/P",
                  "value weight average of D/P"),
        weights = "value")
    )),
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
        norm <- private$normalise(line)
        tags <- private$lookup(norm)
        if (!is.null(tags)) {
          sections[[length(sections) + 1L]] <- list(
            heading = trimmed, field = tags$field, weights = tags$weights,
            names = NULL, rows = list())
          current <- length(sections)
          started <- TRUE
          next
        }
        if (norm == "For portfolios formed in June of year t") {
          # Multi-line heading block: the next recognised line names the field.
          sections[[length(sections) + 1L]] <- list(
            heading = trimmed, field = NULL, weights = NULL, names = NULL, rows = list())
          current <- length(sections)
          started <- TRUE
          next
        }
        block <- regmatches(norm, regexec("^Value Weight Average of (.+) Calculated", norm))[[1L]]
        if (length(block) == 2L) {
          field <- paste0("value weight average of ", block[[2L]])
          if (!is.null(current) && is.null(sections[[current]]$field)) {
            sections[[current]]$heading <- trimmed
            sections[[current]]$field <- field
            sections[[current]]$weights <- "value"
          } else {
            sections[[length(sections) + 1L]] <- list(
              heading = trimmed, field = field, weights = "value",
              names = NULL, rows = list())
            current <- length(sections)
          }
          started <- TRUE
          next
        }
        if (private$is_block_description(norm)) next
        if (started) stop("Unknown section heading: '", trimmed, "'", call. = FALSE)
        next  # indented preamble continuation
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
    is_block_description = function(norm) {
      # Formula and explanation lines inside multi-line heading blocks.
      grepl("^Sum\\[", norm) || grepl("^Where Mth", norm) || grepl("^and ", norm)
    },
    assemble = function(sections) {
      tables <- lapply(sections, function(section) {
        if (!length(section$rows)) return(NULL)
        if (is.null(section$field)) {
          stop("No field recognised for section '", section$heading, "'", call. = FALSE)
        }
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

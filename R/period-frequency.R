# Frequency inferred from the period width: 4 = year, 6 = month, 8 = day.
# Shared by the factor and breakpoints parsers. The portfolio parser inlines
# the map: it is serialised into worker processes (see portfolio-parser.R).
period_frequency <- function(period) {
  c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]
}

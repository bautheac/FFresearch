# Frequency inferred from the period width: 4 = year, 6 = month, 8 = day.
# Shared by the factor, portfolio and breakpoints parsers.
period_frequency <- function(period) {
  c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]
}

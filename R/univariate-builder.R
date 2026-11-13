# Univariate dataset ------------------------------------------------------------------

# One row per library file: region, sort variable, dividend and the weightings
# the file provides. Every univariate file carries both value- and
# equal-weighted returns, so `weights` is a list column. Base and daily files
# include dividends (Y); `_Wout_Div` files exclude them (N).
univariate_sources <- function() {
  sorts <- c(
    "Portfolios_Formed_on_ME" = "market capitalization",
    "Portfolios_Formed_on_BE-ME" = "book/market",
    "Portfolios_Formed_on_OP" = "operating profitability",
    "Portfolios_Formed_on_INV" = "investment",
    "Portfolios_Formed_on_E-P" = "earnings/price",
    "Portfolios_Formed_on_CF-P" = "cash flow/price",
    "Portfolios_Formed_on_D-P" = "dividend/price",
    "10_Portfolios_Prior_12_2" = "momentum",
    "10_Portfolios_Prior_1_0" = "short term reversal",
    "10_Portfolios_Prior_60_13" = "long term reversal",
    "Portfolios_Formed_on_AC" = "accruals",
    "Portfolios_Formed_on_BETA" = "market beta",
    "Portfolios_Formed_on_NI" = "net share issues",
    "Portfolios_Formed_on_VAR" = "variance",
    "Portfolios_Formed_on_RESVAR" = "residual variance")
  ex_dividend <- c("Portfolios_Formed_on_ME", "Portfolios_Formed_on_BE-ME",
                   "Portfolios_Formed_on_OP", "Portfolios_Formed_on_INV",
                   "Portfolios_Formed_on_E-P", "Portfolios_Formed_on_CF-P",
                   "Portfolios_Formed_on_D-P")
  daily <- c("Portfolios_Formed_on_ME", "Portfolios_Formed_on_BE-ME",
             "Portfolios_Formed_on_OP", "Portfolios_Formed_on_INV",
             "10_Portfolios_Prior_12_2", "10_Portfolios_Prior_1_0",
             "10_Portfolios_Prior_60_13")
  rows <- function(files, dividend) {
    base <- sub("_(Wout_Div|Daily)$", "", files)
    data.table::data.table(
      file = files, region = "US", `sort variable` = unname(sorts[base]),
      dividend = dividend, weights = rep(list(c("value", "equal")), length(files)))
  }
  data.table::rbindlist(list(
    rows(names(sorts), "Y"),
    rows(paste0(ex_dividend, "_Wout_Div"), "N"),
    rows(paste0(daily, "_Daily"), "Y")))
}

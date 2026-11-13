# Rebuild the `factors` dataset from Kenneth French's data library.
# Run from the package root: Rscript data-raw/factors.R

library(data.table)

base_url <- "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/"

# One row per region: file stems (without "_CSV.zip") for monthly+annual and daily.
sources <- rbindlist(list(
  data.table(
    region = "US", kind = c("5 factors", "5 factors", "momentum", "momentum",
                            "short term reversal", "short term reversal", "long term reversal", "long term reversal"),
    file = c("F-F_Research_Data_5_Factors_2x3", "F-F_Research_Data_5_Factors_2x3_daily",
             "F-F_Momentum_Factor", "F-F_Momentum_Factor_daily",
             "F-F_ST_Reversal_Factor", "F-F_ST_Reversal_Factor_daily",
             "F-F_LT_Reversal_Factor", "F-F_LT_Reversal_Factor_daily")),
  rbindlist(lapply(list(
    list("global", "Developed_5_Factors", "Developed_Mom_Factor"),
    list("global (ex US)", "Developed_ex_US_5_Factors", "Developed_ex_US_Mom_Factor"),
    list("Europe", "Europe_5_Factors", "Europe_Mom_Factor"),
    list("JP", "Japan_5_Factors", "Japan_Mom_Factor"),
    list("Asia-Pacific (ex JP)", "Asia_Pacific_ex_Japan_5_Factors", "Asia_Pacific_ex_Japan_MOM_Factor"),
    list("North America", "North_America_5_Factors", "North_America_Mom_Factor")
  ), function(x) data.table(
    region = x[[1]], kind = rep(c("5 factors", "momentum"), each = 2L),
    file = c(x[[2]], paste0(x[[2]], "_Daily"), x[[3]], paste0(x[[3]], "_Daily"))))
  )
))

read_french <- function(file) {
  zip <- tempfile(fileext = ".zip")
  on.exit(unlink(zip))
  download.file(paste0(base_url, file, "_CSV.zip"), zip, mode = "wb", quiet = TRUE)
  lines <- readLines(unz(zip, utils::unzip(zip, list = TRUE)$Name[[1L]]), warn = FALSE)
  header <- trimws(strsplit(lines[grepl("^,", lines)][[1L]], ",")[[1L]])[-1L]
  data_lines <- lines[grepl("^[[:space:]]*[0-9]{4,8}[[:space:]]*,", lines)]
  fields <- strsplit(data_lines, ",")
  period <- trimws(vapply(fields, `[[`, "", 1L))
  values <- do.call(rbind, lapply(fields, function(x) as.numeric(trimws(x[-1L]))))
  colnames(values) <- header
  out <- as.data.table(values)
  out[, period := period]
  out <- melt(out, id.vars = "period", variable.name = "factor", variable.factor = FALSE)
  out[, frequency := c(`4` = "year", `6` = "month", `8` = "day")[as.character(nchar(period))]]
  out[!is.na(value) & value > -99]  # -99.99 / -999 mark missing observations
}

factors <- rbindlist(lapply(seq_len(nrow(sources)), function(i) {
  message(sources$region[[i]], ": ", sources$file[[i]])
  x <- read_french(sources$file[[i]])
  x[, region := sources$region[[i]]]
}))

# Market return = excess return + risk free rate, as in earlier releases.
rf <- factors[factor == "RF", .(region, frequency, period, rf = value)]
market <- merge(factors[factor == "Mkt-RF"], rf, by = c("region", "frequency", "period"))
market[, `:=`(factor = "market", value = value + rf)][, rf := NULL]

factors <- rbindlist(list(factors[!factor %in% c("Mkt-RF")], market), use.names = TRUE)
factors[factor == "RF", factor := "risk free rate"]
factors[factor == "ST_REV", factor := "ST_Rev"]
factors[factor %in% c("LT_REV"), factor := "LT_Rev"]

levels_region <- c("US", "global", "global (ex US)", "Europe", "JP", "Asia-Pacific (ex JP)", "North America")
factors <- factors[, .(region = factor(region, levels_region),
                       frequency = factor(frequency, c("month", "day", "year")),
                       factor, period, value)]
# Earlier releases start the US history in 1971 (50-year window), as the portfolio datasets do.
factors <- factors[!(region == "US" & substr(period, 1L, 4L) < "1971")]
setorder(factors, region, frequency, factor, period)

save(factors, file = "data/factors.rda", compress = "xz", version = 2L)

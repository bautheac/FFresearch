#!/usr/bin/env Rscript
# Ticket #16: finRes asset-pricing article, "factor'em!" core analysis.
# Executes the article's eval=TRUE chunks: pullit equity/futures pulls from
# the bundled sqlite, factorem workhorse + wrappers, accessors, summary,
# plotit performance/positions plots.
# Deviation: the article resolves the sqlite via
# system.file("extdata", "storethat.sqlite", package = "finRes"); finRes is
# not installed in fct-r (deps fewISOs/GICS/storethat unavailable offline),
# so the identical bundled file is used directly. Bloomberg chunks are
# eval=FALSE in the article and are not exercised.
path <- "/tmp/storethat.sqlite"
stopifnot(file.exists(path))

library(pullit); library(lubridate)
tickers_equity <- c("LZB US Equity", "SGA US Equity", "AGCO US Equity", "CLR US Equity",
                    "GHC US Equity", "MAN US Equity", "SITE US Equity", "AJRD US Equity",
                    "COMM US Equity", "GME US Equity", "MEI US Equity", "SMP US Equity")
start <- "2016-01-01"; end <- "2017-12-31"
equity_data_market <- pull_equity_market(
  source = "storethat", tickers = tickers_equity, start = start, end = end,
  verbose = FALSE, file = path)
print(pullit::get_data(equity_data_market))

library(factorem)
ranking_period <- 1L
factor <- factorem(
  name = "momentum", data = pullit::get_data(equity_data_market),
  sort_levels = FALSE, weighted = FALSE, ranking_period = ranking_period)
print(factor)

equity_market <- market_factor(data = equity_data_market)
print(equity_market)
equity_momentum <- momentum_factor(data = equity_data_market, ranking_period = ranking_period)
print(equity_momentum)

tickers_futures <- c(
  "C A Comdty", "CLA Comdty", "COA Comdty", "GCA Comdty", "HOA Comdty",
  "KWA Comdty", "LHA Comdty", "QSA Comdty", "S A Comdty", "SBA Comdty",
  "W A Comdty")
futures_data_TS <- pull_futures_market(
  source = "storethat", type = "term structure", tickers_futures, start, end,
  verbose = FALSE, file = path)
print(pullit::get_data(futures_data_TS))

futures_market <- market_factor(data = futures_data_TS)
print(futures_market)
futures_momentum <- momentum_factor(data = futures_data_TS, ranking_period = ranking_period)
print(futures_momentum)

futures_data_CFTC <- pull_futures_CFTC(
  source = "storethat", tickers_futures, start, end, verbose = FALSE, file = path)
futures_CHP <- CHP_factor(
  price_data = futures_data_TS, CHP_data = futures_data_CFTC,
  ranking_period = ranking_period)
print(futures_CHP)

futures_OI_nearby <- OI_nearby_factor(data = futures_data_TS, ranking_period = ranking_period)
print(futures_OI_nearby)

futures_data_agg <- pull_futures_market(
  source = "storethat", type = "aggregate", tickers_futures, start, end,
  verbose = FALSE, file = path)
futures_OI_aggregate <- OI_aggregate_factor(
  price_data = futures_data_TS, aggregate_data = futures_data_agg,
  ranking_period = ranking_period)
print(futures_OI_aggregate)

futures_TS <- TS_factor(data = futures_data_TS, ranking_period = ranking_period)
print(futures_TS)

# accessors + summary chunks
print(get_name(factor))
print(head(get_positions(factor)))
print(head(get_returns(factor)))
print(head(factorem::get_data(factor)))
print(get_parameters(factor))
print(get_call(factor))
print(summary(factor))

# plotit chunks (headless pdf device)
library(plotit)
pdf(NULL)
plot(object = factor, type = "performance")
plot(object = factor, type = "positions")
dev.off()
cat("ARTICLE_FACTOREM_OK\n")

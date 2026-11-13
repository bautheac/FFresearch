# Industries dataset ------------------------------------------------------------------

#' Build the `portfolios_industries` dataset
#'
#' Concrete `DatasetBuilder`: reads every industry file listed in `sources`
#' through a `LinesSource`, parses it with a `PortfolioParser`, keeps the
#' committed fields (returns and the value-weighted average of BE/ME) and
#' resolves labels shared by several classifications in favour of the finest
#' one (49 > 48 > 38 > 30 > 17 > 12 > 10 > 5). Returns one long table ordered
#' by region, frequency, dividend, weights, portfolio, field and period.
#'
#' @noRd
IndustriesBuilder <- R6::R6Class(
  "IndustriesBuilder",
  inherit = DatasetBuilder,
  public = list(
    initialize = function(source, parser = PortfolioParser$new(), sources = industries_sources()) {
      super$initialize("portfolios_industries")
      private$source <- source
      private$parser <- parser
      private$sources <- sources
    }
  ),
  private = list(
    source = NULL,
    parser = NULL,
    sources = NULL,
    read_tables = function() {
      lapply(seq_len(nrow(private$sources)), function(i) {
        lines <- private$source$read_lines(private$sources$file[[i]])
        table <- private$parser$parse(lines)
        table <- table[field %in% industries_fields()]
        private$check_portfolios(table, private$sources$file[[i]])
        table[, `:=`(region = private$sources$region[[i]],
                     dividend = private$sources$dividend[[i]],
                     classification = private$sources$classification[[i]])]
      })
    },
    check_portfolios = function(table, file) {
      unknown <- setdiff(unique(table$portfolio), industries_portfolios())
      if (length(unknown)) {
        stop("Unknown industry portfolio label in ", file, ": ",
             paste(unknown, collapse = ", "), call. = FALSE)
      }
      invisible(table)
    },
    assemble = function(tables) {
      industries <- private$keep_finest(tables)
      private$order_columns(industries)
    },
    keep_finest = function(tables) {
      # Finest classification first: a label already kept by a finer file
      # wins, so coarser files only contribute labels they alone provide.
      # Tables are consumed as they are merged to bound memory on the daily
      # files.
      key <- c("region", "frequency", "dividend", "weights", "portfolio", "field", "period")
      sizes <- vapply(tables, function(table) table$classification[[1L]], integer(1L))
      tables <- tables[order(-sizes)]
      kept <- NULL
      while (length(tables)) {
        table <- tables[[1L]]
        tables[[1L]] <- NULL
        if (!is.null(kept)) table <- table[!kept, on = key]
        kept <- data.table::rbindlist(list(kept, table))
      }
      kept
    },
    order_columns = function(industries) {
      ordered <- industries[, .(region = factor(region, "US"),
                                frequency = factor(frequency, c("month", "year", "day")),
                                dividend = factor(dividend, c("Y", "N")),
                                weights = factor(weights, c("value", "equal")),
                                portfolio,
                                field = factor(field, industries_fields()),
                                period, value)]
      data.table::setorder(ordered, region, frequency, dividend, weights, portfolio, field, period)
      ordered[]
    }
  )
)

#' Create the industries builder
#'
#' `IndustriesBuilderFactory$create()` wires an `IndustriesBuilder` to the live
#' library, optionally cached on disk under `cache_dir`, or to any other
#' `LinesSource` given as `source`.
#'
#' @noRd
IndustriesBuilderFactory <- R6::R6Class(
  "IndustriesBuilderFactory",
  public = list(
    create = function(cache_dir = NULL, source = HttpZipSource$new()) {
      if (!is.null(cache_dir)) source <- CachedSource$new(source, cache_dir)
      IndustriesBuilder$new(source)
    }
  )
)

# The fields shipped in `portfolios_industries`; firm counts, firm sizes and
# the Sum of BE / Sum of ME sections are skipped.
industries_fields <- function() {
  c("return", "value weight average of BE/ME")
}

# The 86 portfolio labels shipped in `portfolios_industries`: the union of the
# 5/10/12/17/30/38/48/49-industry headers, taken from the committed data.
industries_portfolios <- function() {
  c("Aero", "Agric", "Apprl", "Autos", "Banks", "Beer", "BldMt", "Books", "Boxes",
    "BusEq", "BusSv", "Carry", "Cars", "Chair", "Chems", "Chips", "Clths", "Cnsmr",
    "Cnstr", "Cnsum", "Coal", "Comps", "Drugs", "Durbl", "ElcEq", "Elctr", "Enrgy",
    "FabPr", "Fin", "Finan", "Food", "Fun", "Games", "Garbg", "Glass", "Gold",
    "Govt", "Guns", "Hardw", "HiTec", "Hlth", "Hshld", "Instr", "Insur", "LabEq",
    "Lethr", "Mach", "Machn", "Manuf", "Meals", "MedEq", "Metal", "Mines", "Money",
    "MtlPr", "NoDur", "Oil", "Other", "Paper", "PerSv", "Phone", "Print", "Ptrlm",
    "RlEst", "Rtail", "Rubbr", "Servs", "Ships", "Shops", "Smoke", "Soda", "Softw",
    "Srvc", "Steam", "Steel", "Stone", "Telcm", "Toys", "Trans", "TV", "Txtls",
    "Util", "Utils", "Water", "Whlsl", "Wood")
}

# One row per library file: region, dividend, classification size (number of
# industry portfolios) and the weightings the file provides. Base and daily
# files include dividends (Y); `_Wout_Div` files exclude them (N).
industries_sources <- function() {
  sizes <- c(5L, 10L, 12L, 17L, 30L, 38L, 48L, 49L)
  rows <- function(suffix, dividend) {
    data.table::data.table(
      file = paste0(sizes, "_Industry_Portfolios", suffix),
      region = "US", dividend = dividend, classification = sizes,
      weights = rep(list(c("value", "equal")), length(sizes)))
  }
  data.table::rbindlist(list(rows("", "Y"), rows("_Wout_Div", "N"), rows("_daily", "Y")))
}

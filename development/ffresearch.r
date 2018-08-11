library(magrittr)

urls <- tibble::tibble(region = c("US", "Global", "Global (ex US)", "Europe", "Japan", "Asia-Pacific (ex JP)", "North America"),
                       url = c("http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_5_Factors_Daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_5_Factors_Daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_5_Factors_Daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_5_Factors_Daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_5_Factors_Daily_CSV.zip",
                               "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_5_Factors_Daily_CSV.zip")
                       )

fffactors <- lapply(urls$region, function(x){

  temp <- tempfile(tmpdir = "data-raw")
  download.file(urls %>% dplyr::filter(region == x) %>% dplyr::select(url) %>% purrr::flatten_chr(), temp, mode = "wb")
  utils::unzip(temp, exdir = "data-raw")
  utils::read.table(paste("data-raw", utils::unzip(temp, list = TRUE)$Name, sep = "/"), sep = ",", skip = 3L, header = T) %>%
    dplyr::mutate(Date = as.Date(as.character(X), "%Y%m%d"), `Mkt-RF` = Mkt.RF, Mkt = Mkt.RF + RF, Region = x) %>%
    dplyr::select(Region, Date, `Mkt-RF`, SMB, HML, RMW, CMA, RF, Mkt)

}) %>%
  data.table::rbindlist(use.names = TRUE)
invisible(do.call(file.remove, list(list.files("data-raw", full.names = TRUE))))

usethis::use_data(fffactors, overwrite = TRUE)













urls <- tibble::tibble(region = c(rep("US", 2L),
                              rep("Global", 2L),
                              rep("Global (ex US)", 2L),
                              rep("Europe", 2L),
                              rep("Japan", 2L),
                              rep("Asia-Pacific (ex JP)", 2L),
                              rep("North America", 2L)),
                   frequency = rep(c("monthly", "daily"), 7L),
                   url = c("http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_5_Factors_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_5_Factors_Daily_CSV.zip"))

fffactors <- lapply(dplyr::distinct(urls, region)%>% purrr::flatten_chr(), function(x){
  lapply(c("monthly", "daily"), function(y){

    temp <- tempfile(tmpdir = "data-raw")
    download.file(urls %>% dplyr::filter(region == x, frequency == y) %>% dplyr::select(url) %>% purrr::flatten_chr(), temp, mode = "wb")
    utils::unzip(temp, exdir = "data-raw")
    read.csv(paste("data-raw", utils::unzip(temp, list = TRUE)$Name, sep = "/"), sep = ",", skip = 3L, header = T, stringsAsFactors = FALSE) %>%
      dplyr::mutate_at(dplyr::vars(`Mkt.RF`:`RF`), dplyr::funs(as.numeric(.))) %>%
      dplyr::mutate(Period = as.character(as.integer(`X`)),
             `Mkt-Rf` = Mkt.RF,
             Mkt = Mkt.RF + RF,
             Rf = RF,
             Region = x) %>%
      dplyr::mutate(Frequency = dplyr::case_when(
        nchar(Period) == 8L ~ "day",
        nchar(Period) == 6L ~ "month",
        nchar(Period) == 4L ~ "year")) %>%
      dplyr::select(Region, Frequency, Period, `Mkt-Rf`, Mkt, Rf, SMB, HML, RMW, CMA) %>%
      dplyr::filter(complete.cases(.))

  }) %>%
    data.table::rbindlist(use.names = TRUE)
}) %>%
  data.table::rbindlist(use.names = TRUE) %>%
  dplyr::arrange(Region, Frequency, Period) %>%
  data.table::data.table()


urls <- tibble::tibble(region = c(rep("US", 2L),
                              rep("Global", 2L),
                              rep("Global (ex US)", 2L),
                              rep("Europe", 2L),
                              rep("Japan", 2L),
                              rep("Asia-Pacific (ex JP)", 2L),
                              rep("North America", 2L)),
                   frequency = rep(c("monthly", "daily"), 7L),
                   skip = c(rep(13L, 2L), rep(6L, 12L)),
                   var_name = c(rep("Mom", 2L), rep("WML", 12L)),
                   url = c("http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Momentum_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Momentum_Factor_daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_Mom_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_Mom_Factor_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_Mom_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_Mom_Factor_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_Mom_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_Mom_Factor_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_Mom_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_Mom_Factor_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_MOM_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_MOM_Factor_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_Mom_Factor_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_Mom_Factor_Daily_CSV.zip"))

momentum <- lapply(dplyr::distinct(urls, region)%>% purrr::flatten_chr(), function(x){
  lapply(c("monthly", "daily"), function(y){

    temp <- tempfile(tmpdir = "data-raw")
    download.file(urls %>% dplyr::filter(region == x, frequency == y) %>% dplyr::select(url) %>% purrr::flatten_chr(), temp, mode = "wb")
    utils::unzip(temp, exdir = "data-raw")
    read.csv(paste("data-raw", utils::unzip(temp, list = TRUE)$Name, sep = "/"),
             sep = ",",
             skip = dplyr::filter(urls, region == x, frequency == y) %>% dplyr::select(skip) %>% purrr::flatten_int(),
             # skip = (urls %>% filter(region == x, frequency == y))$skip,
             header = TRUE,
             stringsAsFactors = FALSE) %>%
      dplyr::mutate(Period = as.character(as.integer(`X`)), Region = x) %>%
      dplyr::mutate(Frequency = dplyr::case_when(
        nchar(Period) == 8L ~ "day",
        nchar(Period) == 6L ~ "month",
        nchar(Period) == 4L ~ "year")) %>%
      dplyr::select(Region, Frequency, Period, Mom = dplyr::filter(urls, region == x, frequency == y) %>% dplyr::select(var_name) %>% purrr::flatten_chr()) %>%
      dplyr::filter(complete.cases(.))

  }) %>%
    data.table::rbindlist(use.names = TRUE)
}) %>%
  data.table::rbindlist(use.names = TRUE) %>%
  dplyr::arrange(Region, Frequency, Period)

invisible(do.call(file.remove, list(list.files("data-raw", full.names = TRUE))))

fffactors %<>%
  dplyr::full_join(momentum, by = c("Region", "Frequency", "Period")) %>%
  dplyr::arrange(desc(Region), Frequency, Period) %>%
  data.table::data.table()

usethis::use_data(fffactors, overwrite = TRUE)
usethis::use_readme_md()


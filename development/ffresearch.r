library(dplyr); library(stringr)

urls.tbl <- tibble(region = c("US", "Global", "Global (ex US)", "Europe", "Japan", "Asia-Pacific (ex JP)", "North America"),
                   url = c("http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Global_ex_US_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Europe_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Japan_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/Asia_Pacific_ex_Japan_5_Factors_Daily_CSV.zip",
                           "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/North_America_5_Factors_Daily_CSV.zip"))

fffactors <- lapply(urls.tbl$region, function(x){

  temp.file <- tempfile(tmpdir = "data-raw")
  download.file((urls.tbl %>% filter(region == x))$url, temp.file, mode = "wb")
  unzip(temp.file, exdir = "data-raw")
  ff.tbl <- read.table(paste("data-raw", unzip(temp.file, list = TRUE)$Name, sep = "/"), sep = ",", skip = 3L, header = T) %>% as_tibble %>%
    mutate(Date = as.Date(as.character(X), "%Y%m%d"), `Mkt-RF` = Mkt.RF, Mkt = Mkt.RF + RF, Region = x) %>%
    select(Region, Date, `Mkt-RF`, SMB, HML, RMW, CMA, RF, Mkt)

}) %>% do.call(what = rbind, args = .) %>% as.data.frame()
invisible(do.call(file.remove, list(list.files("data-raw", full.names = TRUE))))

usethis::use_data(fffactors, overwrite = TRUE)















urls.tbl <- tibble(region = c(rep("US", 2L),
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

fffactors <- lapply(urls.tbl$region %>% unique, function(x){
  lapply(c("monthly", "daily"), function(y){

    temp.file <- tempfile(tmpdir = "data-raw")
    download.file((urls.tbl %>% filter(region == x, frequency == y))$url, temp.file, mode = "wb")
    unzip(temp.file, exdir = "data-raw")
    ff.tbl <- read.csv(paste("data-raw", unzip(temp.file, list = TRUE)$Name, sep = "/"), sep = ",", skip = 3L, header = T, stringsAsFactors = FALSE) %>%
      as_tibble %>%
      mutate_at(vars(`Mkt.RF`:`RF`),
                funs(as.numeric(.))) %>%
      mutate(Period = as.character(as.integer(`X`)),
             `Mkt-Rf` = Mkt.RF,
             Mkt = Mkt.RF + RF,
             Rf = RF,
             Region = x) %>%
      mutate(Frequency = case_when(
        nchar(Period) == 8L ~ "day",
        nchar(Period) == 6L ~ "month",
        nchar(Period) == 4L ~ "year")) %>%
      select(Region, Frequency, Period, `Mkt-Rf`, Mkt, Rf, SMB, HML, RMW, CMA) %>%
      filter(complete.cases(.))

  }) %>% do.call(what = rbind, args = .)
}) %>% do.call(what = rbind, args = .) %>% arrange(Region, Frequency, Period) %>% as.data.frame()


urls.tbl <- tibble(region = c(rep("US", 2L),
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

momentum <- lapply(urls.tbl$region %>% unique, function(x){
  lapply(c("monthly", "daily"), function(y){

    temp.file <- tempfile(tmpdir = "data-raw")
    download.file((urls.tbl %>% filter(region == x, frequency == y))$url, temp.file, mode = "wb")
    unzip(temp.file, exdir = "data-raw")
    ff.tbl <- read.csv(paste("data-raw", unzip(temp.file, list = TRUE)$Name, sep = "/"),
                       sep = ",",
                       skip = (urls.tbl %>% filter(region == x, frequency == y))$skip,
                       header = T,
                       stringsAsFactors = FALSE) %>%
      as_tibble %>%
      mutate(Period = as.character(as.integer(`X`)),
             Region = x) %>%
      mutate(Frequency = case_when(
        nchar(Period) == 8L ~ "day",
        nchar(Period) == 6L ~ "month",
        nchar(Period) == 4L ~ "year")) %>%
      select(Region, Frequency, Period, Mom = (urls.tbl %>% filter(region == x, frequency == y))$var_name) %>%
      filter(complete.cases(.))

  }) %>% do.call(what = rbind, args = .)
}) %>% do.call(what = rbind, args = .) %>% arrange(Region, Frequency, Period) %>% as.data.frame()

invisible(do.call(file.remove, list(list.files("data-raw", full.names = TRUE))))

fffactors %<>% full_join(momentum, by = c("Region", "Frequency", "Period")) %>% arrange(desc(Region), Frequency, Period)

usethis::use_data(fffactors, overwrite = TRUE)



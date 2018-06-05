library(dplyr)

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



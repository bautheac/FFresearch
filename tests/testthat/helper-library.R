# Every library file a sources mapping lists must exist in the live library.
# Network-gated: skipped unless FFRESEARCH_NETWORK is true, so the offline
# suite and CRAN never touch the network.
expect_files_in_library <- function(files) {
  skip_if(Sys.getenv("FFRESEARCH_NETWORK") != "true", "FFRESEARCH_NETWORK is not true")

  page <- tempfile(fileext = ".html")
  on.exit(unlink(page))
  utils::download.file("https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html",
                       page, quiet = TRUE)
  links <- readLines(page, warn = FALSE)
  archives <- unlist(regmatches(links, gregexpr("ftp/[^\"]+_CSV\\.zip", links)))
  stems <- sub("_CSV\\.zip$", "", sub("^ftp/", "", archives))

  expect_equal(setdiff(files, stems), character(0))
}

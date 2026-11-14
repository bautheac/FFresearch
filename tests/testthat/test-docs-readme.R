# README links must use https (spec #3, story 22). The READMEs ship with the
# source tree only, so the check skips when they are absent (installed package).
test_that("READMEs link over https only", {
  for (file in c("README.rmd", "README.md")) {
    path <- test_path("..", "..", file)
    skip_if_not(file.exists(path), paste(file, "not found"))
    lines <- readLines(path, warn = FALSE)
    hits <- grep("http://", lines, fixed = TRUE)
    expect_identical(hits, integer(0),
                     info = paste(file, "http:// on lines:", paste(hits, collapse = ", ")))
  }
})

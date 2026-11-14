# Rebuild `factors` from the live library and compare it with the committed
# dataset on the overlapping period. Only runs when FFRESEARCH_NETWORK=true;
# otherwise it skips, so the offline suite never touches the network.
test_that("rebuilt factors are identical to committed factors on the overlap", {
  skip_if_not(identical(Sys.getenv("FFRESEARCH_NETWORK"), "true"),
              "FFRESEARCH_NETWORK is not true")

  cache_dir <- test_path("..", "..", "data-raw", "cache")
  rebuilt <- FactorsBuilderFactory$new()$create(cache_dir = cache_dir)$build()

  comparison <- compare_dataset("factors", rebuilt, dataset_contract$factors$key)

  expect_equal(nrow(comparison$only_old), 0L,
               info = "keys present only in committed factors")
  expect_equal(nrow(comparison$only_new), 0L,
               info = "keys present only in rebuilt factors")
  expect_equal(comparison$max_abs_difference, 0,
               info = "largest absolute value difference on the overlap")
})
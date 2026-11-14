# Compare a rebuilt dataset with the committed one on the overlapping period.
# `compare_dataset(name, rebuilt, key)` loads the committed dataset `name`
# (unless `old` is given) and returns list(only_old, only_new,
# max_abs_difference): the keys found on only one side, as data tables of key
# columns, and the largest absolute value difference over the shared keys.
compare_dataset <- function(name, rebuilt, key, old = load_dataset(name)) {
  old <- data.table::as.data.table(old)
  rebuilt <- data.table::as.data.table(rebuilt)
  if ("period" %in% names(old) && "period" %in% names(rebuilt)) {
    overlap <- intersect(old$period, rebuilt$period)
    old <- old[period %in% overlap]
    rebuilt <- rebuilt[period %in% overlap]
  }
  old_keys <- old[, key, with = FALSE]
  new_keys <- rebuilt[, key, with = FALSE]
  shared <- merge(old, rebuilt, by = key, suffixes = c("_old", "_new"))
  list(
    only_old = old_keys[!new_keys, on = key],
    only_new = new_keys[!old_keys, on = key],
    max_abs_difference = if (nrow(shared)) max(abs(shared$value_new - shared$value_old)) else 0
  )
}
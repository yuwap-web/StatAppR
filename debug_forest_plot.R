#!/usr/bin/env Rscript
# Debug forest plot generation

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()

cat("=== Debug Forest Plot Generation ===\n")

# Load plot_utils
source(file.path(runner_dir, "utils", "plot_utils.R"))

# Test data: HR dataframe
tbl <- data.frame(
  term = c("age", "bmi", "smoker"),
  HR = c(1.0480, 0.8535, 5.3698),
  CI_low = c(0.8680, 0.5853, 0.5588),
  CI_high = c(1.2654, 1.2446, 51.597),
  p_value = c(0.6278, 0.4295, 0.1331),
  stringsAsFactors = FALSE
)

cat("Test data:\n")
print(tbl)

cat("\nCalling make_forest_plot()...\n")

tryCatch({
  forest_file <- make_forest_plot(
    tbl,
    "HR",
    "CI_low",
    "CI_high",
    "term"
  )

  if (!is.null(forest_file)) {
    cat("✅ SUCCESS: Forest plot created at", forest_file, "\n")
    cat("   File exists?", file.exists(forest_file), "\n")
  } else {
    cat("❌ FAILED: make_forest_plot returned NULL\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
  traceback()
})

cat("\n\nChecking make_forest_plot function...\n")

if (exists("make_forest_plot", mode = "function")) {
  cat("✅ make_forest_plot function exists\n")

  # Print function signature
  cat("\nFunction parameters:\n")
  f_args <- formals(make_forest_plot)
  for (i in seq_along(f_args)) {
    cat("  -", names(f_args)[i], "\n")
  }
} else {
  cat("❌ make_forest_plot function NOT found\n")
}

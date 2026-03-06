#!/usr/bin/env Rscript
# Final comprehensive test for image-generating recipes

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("=== Final Recipe Test Suite ===\n")
cat("Workdir:", workdir, "\n\n")

# Pre-load utilities
env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- workdir

tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
  cat("✅ Loaded plot_utils.R\n")
}, error = function(e) {
  cat("❌ Failed to load plot_utils.R:", conditionMessage(e), "\n")
})

tryCatch({
  sys.source(file.path(runner_dir, "utils", "km_plot.R"), envir = env)
  cat("✅ Loaded km_plot.R\n")
}, error = function(e) {
  cat("❌ Failed to load km_plot.R:", conditionMessage(e), "\n")
})

tryCatch({
  sys.source(file.path(runner_dir, "utils", "balance_plot.R"), envir = env)
  cat("✅ Loaded balance_plot.R\n")
}, error = function(e) {
  cat("❌ Failed to load balance_plot.R:", conditionMessage(e), "\n")
})

cat("\n--- Testing Image-Generating Recipes ---\n\n")

test_count <- 0
success_count <- 0

# Test 1: survival_km
cat("1️⃣  survival_km\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_iptw_survival.csv"))
  source(file.path(runner_dir, "recipes", "survival_km.R"), local = env)
  result <- env$run(list(variables = list(time="time", status="status", group="treatment")), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

# Test 2: cox_regression
cat("2️⃣  cox_regression\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_survival_cox.csv"))
  source(file.path(runner_dir, "recipes", "cox_regression.R"), local = env)
  result <- env$run(list(variables = list(time="time", status="status", x=list("age","bmi","smoker"))), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

# Test 3: meta_analysis
cat("3️⃣  meta_analysis\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_meta.csv"))
  source(file.path(runner_dir, "recipes", "meta_analysis.R"), local = env)
  result <- env$run(list(variables = list(effect="effect", se="se", label="study_name")), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

# Test 4: iptw_km_survival
cat("4️⃣  iptw_km_survival\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_iptw_survival.csv"))
  source(file.path(runner_dir, "recipes", "iptw_km_survival.R"), local = env)
  result <- env$run(list(variables = list(treat="treatment", time="time", status="status", x=list("age","bmi"))), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

# Test 5: aipw_ate
cat("5️⃣  aipw_ate\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))
  source(file.path(runner_dir, "recipes", "aipw_ate.R"), local = env)
  result <- env$run(list(variables = list(treat="treatment", y="outcome", x=list("age","bmi","sex","education"))), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

# Test 6: ps_matching (with larger dataset)
cat("6️⃣  ps_matching (with expanded data)\n")
test_count <- test_count + 1
tryCatch({
  data <- read.csv(file.path(data_dir, "sample_causal_ate_large.csv"))
  source(file.path(runner_dir, "recipes", "ps_matching.R"), local = env)
  result <- env$run(list(variables = list(treat="treatment", y="outcome", x=list("age","bmi","sex","education"))), data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("   ✅ SUCCESS:", length(result$figures), "figure(s)\n")
    success_count <- success_count + 1
  } else {
    cat("   ⚠️  No figures generated\n")
  }
}, error = function(e) {
  cat("   ❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Summary ===\n")
cat("Total recipes tested:", test_count, "\n")
cat("Successful:", success_count, "\n")
cat("Success rate:", round(100 * success_count / test_count), "%\n\n")

if (success_count == test_count) {
  cat("🎉 All image-generating recipes working correctly!\n")
} else {
  cat("⚠️  Some recipes need attention\n")
}

#!/usr/bin/env Rscript
# Test script for image-generating recipes

library(jsonlite)

# Setup
runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("=== Recipe Test Suite ===\n")
cat("Workdir:", workdir, "\n\n")

# Pre-load utilities into environment
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

cat("\n--- Testing Recipes ---\n\n")

# Test 1: survival_km
cat("1️⃣  Testing survival_km...\n")
tryCatch({
  survival_data <- read.csv(file.path(data_dir, "sample_iptw_survival.csv"))

  source(file.path(runner_dir, "recipes", "survival_km.R"), local = env)

  request <- list(
    variables = list(
      time = "time",
      status = "status",
      group = "treatment"
    )
  )

  result <- env$run(request, survival_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ survival_km: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  survival_km: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ survival_km ERROR:", conditionMessage(e), "\n")
})

# Test 2: cox_regression
cat("\n2️⃣  Testing cox_regression...\n")
tryCatch({
  cox_data <- read.csv(file.path(data_dir, "sample_survival_cox.csv"))

  source(file.path(runner_dir, "recipes", "cox_regression.R"), local = env)

  request <- list(
    variables = list(
      time = "time",
      status = "status",
      x = list("age", "bmi", "smoker")
    )
  )

  result <- env$run(request, cox_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ cox_regression: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  cox_regression: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ cox_regression ERROR:", conditionMessage(e), "\n")
})

# Test 3: meta_analysis
cat("\n3️⃣  Testing meta_analysis...\n")
tryCatch({
  meta_data <- read.csv(file.path(data_dir, "sample_meta.csv"))

  source(file.path(runner_dir, "recipes", "meta_analysis.R"), local = env)

  request <- list(
    variables = list(
      effect = "effect",
      se = "se",
      label = "study_name"
    )
  )

  result <- env$run(request, meta_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ meta_analysis: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  meta_analysis: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ meta_analysis ERROR:", conditionMessage(e), "\n")
})

# Test 4: iptw_km_survival
cat("\n4️⃣  Testing iptw_km_survival...\n")
tryCatch({
  iptw_surv_data <- read.csv(file.path(data_dir, "sample_iptw_survival.csv"))

  source(file.path(runner_dir, "recipes", "iptw_km_survival.R"), local = env)

  request <- list(
    variables = list(
      treat = "treatment",
      time = "time",
      status = "status",
      x = list("age", "bmi")
    )
  )

  result <- env$run(request, iptw_surv_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ iptw_km_survival: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  iptw_km_survival: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ iptw_km_survival ERROR:", conditionMessage(e), "\n")
})

# Test 5: aipw_ate
cat("\n5️⃣  Testing aipw_ate...\n")
tryCatch({
  ate_data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))

  source(file.path(runner_dir, "recipes", "aipw_ate.R"), local = env)

  request <- list(
    variables = list(
      treat = "treatment",
      y = "outcome",
      x = list("age", "bmi", "sex", "education")
    )
  )

  result <- env$run(request, ate_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ aipw_ate: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  aipw_ate: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ aipw_ate ERROR:", conditionMessage(e), "\n")
})

# Test 6: ps_matching
cat("\n6️⃣  Testing ps_matching...\n")
tryCatch({
  ps_match_data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))

  source(file.path(runner_dir, "recipes", "ps_matching.R"), local = env)

  request <- list(
    variables = list(
      treat = "treatment",
      y = "outcome",
      x = list("age", "bmi", "sex", "education")
    )
  )

  result <- env$run(request, ps_match_data)

  if (!is.null(result$figures) && length(result$figures) > 0) {
    cat("✅ ps_matching: Generated", length(result$figures), "figure(s)\n")
    for (fig in result$figures) {
      cat("   - ", fig$id, ": ", fig$path, "\n")
    }
  } else {
    cat("⚠️  ps_matching: No figures generated\n")
  }
}, error = function(e) {
  cat("❌ ps_matching ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Test Complete ===\n")

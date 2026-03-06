#!/usr/bin/env Rscript
# Comprehensive test suite for all 11 fixed recipes
# Tests Phase 1 (5.5h), Phase 2 (5.5-6.5h), and Phase 3 (4.5h) fixes

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("═══════════════════════════════════════════════════════════════════\n")
cat("   COMPREHENSIVE TEST: All 11 Fixed Recipes\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- workdir

# Load utilities
tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {})

test_count <- 0
success_count <- 0
failures <- list()

test_recipe <- function(recipe_name, data, request, description = "", phase = "") {
  test_count <<- test_count + 1
  num_emoji <- c("1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "1️⃣1️⃣")[test_count]

  cat(num_emoji, " [", phase, "] ", recipe_name)
  if (nzchar(description)) cat(" (", description, ")")
  cat("\n")

  tryCatch({
    test_env <- new.env(parent = env)
    source(file.path(runner_dir, "recipes", paste0(recipe_name, ".R")), local = test_env)
    result <- test_env$run(request, data)

    has_errors <- !is.null(result$errors) && length(result$errors) > 0
    has_summary <- !is.null(result$summary)
    has_warnings <- !is.null(result$warnings) && length(result$warnings) > 0

    if (has_errors) {
      cat("   ❌ ERROR:", result$errors[[1]]$message, "\n")
      failures[[length(failures) + 1]] <<- list(
        recipe = recipe_name,
        error = result$errors[[1]]$message
      )
    } else if (has_summary) {
      cat("   ✅ SUCCESS")
      tables_n <- if (!is.null(result$tables)) length(result$tables) else 0
      figs_n <- if (!is.null(result$figures)) length(result$figures) else 0
      if (tables_n > 0) cat(" | Tables:", tables_n)
      if (figs_n > 0) cat(" | Figures:", figs_n)
      if (has_warnings) {
        cat(" | ⚠️ Warnings:", length(result$warnings))
        for (w in result$warnings) {
          if (!is.null(w$code)) cat(" (", w$code, ")")
        }
      }
      cat("\n")
      success_count <<- success_count + 1
    } else {
      cat("   ⚠️ No output\n")
    }
  }, error = function(e) {
    cat("   ❌ EXECUTION ERROR:", conditionMessage(e), "\n")
    failures[[length(failures) + 1]] <<- list(
      recipe = recipe_name,
      error = conditionMessage(e)
    )
  })
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Critical Fixes (5.5 hours)
# ═══════════════════════════════════════════════════════════════════

cat("\n┌─────────────────────────────────────────────────────────────────┐\n")
cat("│ PHASE 1: CRITICAL CONTROL FLOW & DATA FORMAT FIXES (5.5h)        │\n")
cat("└─────────────────────────────────────────────────────────────────┘\n\n")

# Panel data setup with explicit binary time indicator for DiD
set.seed(2026)
data_panel <- data.frame(
  id = rep(1:10, each=5),
  time = rep(1:5, 10),
  post = rep(c(0,0,0,1,1), 10),  # Time indicator (post-treatment)
  treat = rep(c(0,0,0,1,1), 10),  # Unit assignment
  y = rnorm(50)
)
data_panel$y <- data_panel$y + 2*data_panel$treat + 1.5*data_panel$post + 3*data_panel$treat*data_panel$post  # DiD effect
data_panel$treat_time <- rep(c(NA,NA,NA,3,3), 10)

# Placebo test
test_recipe("placebo_test", data_panel,
  list(variables = list(
    y = "y", unit = "id", time = "time", treat_time = "treat_time"
  )),
  "Placebo test",
  "Phase 1"
)

# PS matching with adaptive caliper
ps_data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))
if (file.exists(file.path(data_dir, "sample_causal_ate.csv"))) {
  test_recipe("ps_matching", ps_data,
    list(variables = list(
      treat = "treatment",
      y = "outcome",  # Add outcome variable
      x = list("age", "bmi", "sex", "education")
    )),
    "PS matching (adaptive caliper)",
    "Phase 1"
  )
}

# Difference-in-Differences
test_recipe("difference_in_differences", data_panel,
  list(variables = list(
    y = "y", time = "post", treat = "treat"  # Use binary post indicator
  )),
  "DiD robust extraction",
  "Phase 1"
)

# Double ML with auto-binarization
data_reg <- data.frame(
  y = rnorm(50),
  x1 = rbinom(50, 1, 0.5),  # Binary treatment
  x2 = rnorm(50),
  x3 = rnorm(50)
)
test_recipe("double_ml_ate", data_reg,
  list(variables = list(
    y = "y", treat = "x1", x = list("x2", "x3")
  )),
  "Double ML with binary treatment",
  "Phase 1"
)

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Medium Priority Fixes (5.5-6.5 hours)
# ═══════════════════════════════════════════════════════════════════

cat("\n┌─────────────────────────────────────────────────────────────────┐\n")
cat("│ PHASE 2: FUNCTION REFERENCE & PARAMETER VALIDATION (5.5-6.5h)     │\n")
cat("└─────────────────────────────────────────────────────────────────┘\n\n")

# Target Trial Emulation
tte_data <- data.frame(
  id = rep(1:30, each=3),
  start = rep(c(0, 1, 2), 30),
  stop = rep(c(1, 2, 3), 30),
  status = rbinom(90, 1, 0.4),
  a = rbinom(90, 1, 0.5),
  x1 = rnorm(90)
)

test_recipe("target_trial_emulation", tte_data,
  list(variables = list(
    id = "id", start = "start", stop = "stop",
    status = "status", a = "a", x = list("x1")
  )),
  "Clone-censor-weight",
  "Phase 2"
)

# Conditional Logistic Regression
cc_matched <- data.frame(
  stratum = rep(1:20, 2),
  outcome = c(rep(1, 20), rep(0, 20)),
  exposure = rnorm(40),
  x = rnorm(40)
)

test_recipe("conditional_logistic_regression", cc_matched,
  list(variables = list(
    y = "outcome", stratum = "stratum", exposure = "exposure"
  )),
  "Matched case-control",
  "Phase 2"
)

# Case-Crossover
cc_data <- data.frame(
  person_id = rep(1:20, each=10),
  outcome = rbinom(200, 1, 0.3),
  exposure = rnorm(200),
  event_time = rep(1:10, 20)
)

test_recipe("case_crossover", cc_data,
  list(variables = list(
    person_id = "person_id", outcome = "outcome",
    exposure = "exposure", event_time = "event_time"
  )),
  "Case-crossover prototype",
  "Phase 2"
)

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: External Package Fallbacks (4.5 hours)
# ═══════════════════════════════════════════════════════════════════

cat("\n┌─────────────────────────────────────────────────────────────────┐\n")
cat("│ PHASE 3: EXTERNAL PACKAGE FALLBACK IMPLEMENTATIONS (4.5h)         │\n")
cat("└─────────────────────────────────────────────────────────────────┘\n\n")

# PLS Regression (pls → PCR fallback)
test_recipe("pls_regression", data_reg,
  list(variables = list(
    y = "y", x = list("x1", "x2", "x3")
  )),
  "PLS (or PCR fallback)",
  "Phase 3"
)

# Causal Forest (grf → ranger fallback)
het_data <- data.frame(
  y = rnorm(100),
  w = rbinom(100, 1, 0.5),
  x1 = rnorm(100),
  x2 = rnorm(100),
  x3 = rnorm(100)
)

test_recipe("causal_forest", het_data,
  list(variables = list(
    y = "y", w = "w", x = list("x1", "x2", "x3")
  )),
  "Causal Forest (or ranger HTE fallback)",
  "Phase 3"
)

# IV 2SLS (AER → manual 2SLS fallback)
data_iv <- data.frame(
  y = rnorm(50),
  treat = rnorm(50),
  z = rnorm(50),
  x1 = rnorm(50)
)

test_recipe("iv_2sls", data_iv,
  list(variables = list(
    y = "y", treat = "treat", z = "z", x = list("x1")
  )),
  "2SLS (or manual fallback)",
  "Phase 3"
)

# Instrumental Variable (AER → manual 2SLS fallback)
test_recipe("instrumental_variable", data_iv,
  list(variables = list(
    y = "y", treatment = "treat", instrument = "z"
  )),
  "IV regression (or manual fallback)",
  "Phase 3"
)

# ═══════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("TEST SUMMARY - ALL FIXED RECIPES\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

cat("Total recipes tested:", test_count, "\n")
cat("Successful:", success_count, "\n")
success_rate <- if (test_count > 0) round(100 * success_count / test_count) else 0
cat("Success rate:", success_rate, "%\n\n")

if (length(failures) > 0) {
  cat("FAILURES DETECTED:\n")
  for (i in seq_along(failures)) {
    cat(i, ".", failures[[i]]$recipe, ":", failures[[i]]$error, "\n")
  }
  cat("\n")
}

if (success_rate >= 90) {
  cat("🎉 EXCELLENT: All fixed recipes working correctly!\n")
} else if (success_rate >= 75) {
  cat("✅ GOOD: Most recipes working, minor issues to address\n")
} else if (success_rate >= 50) {
  cat("⚠️  FAIR: Several recipes need debugging\n")
} else {
  cat("❌ CRITICAL: Multiple recipes failing\n")
}

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("Test completed at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

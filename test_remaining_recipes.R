#!/usr/bin/env Rscript
# Comprehensive test of remaining 15 recipes

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("═══════════════════════════════════════════════════════════\n")
cat("   Remaining Recipes Comprehensive Test (15 recipes)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- workdir

# Load utilities
tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {})

test_count <- 0
success_count <- 0

test_recipe <- function(recipe_name, data, request, description = "") {
  test_count <<- test_count + 1
  num_emoji <- c("1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟",
                 "1️⃣1️⃣", "1️⃣2️⃣", "1️⃣3️⃣", "1️⃣4️⃣", "1️⃣5️⃣")[test_count]

  cat(num_emoji, recipe_name)
  if (nzchar(description)) cat(" (", description, ")")
  cat("\n")

  tryCatch({
    test_env <- new.env(parent = env)
    source(file.path(runner_dir, "recipes", paste0(recipe_name, ".R")), local = test_env)
    result <- test_env$run(request, data)

    has_errors <- !is.null(result$errors) && length(result$errors) > 0
    has_summary <- !is.null(result$summary)

    if (has_errors) {
      cat("   ❌", result$errors[[1]]$message, "\n")
    } else if (has_summary) {
      tables_n <- if (!is.null(result$tables)) length(result$tables) else 0
      figs_n <- if (!is.null(result$figures)) length(result$figures) else 0
      cat("   ✅ Success")
      if (tables_n > 0) cat(" | Tables:", tables_n)
      if (figs_n > 0) cat(" | Figures:", figs_n)
      cat("\n")
      success_count <<- success_count + 1
    } else {
      cat("   ⚠️  No output\n")
    }
  }, error = function(e) {
    cat("   ❌", conditionMessage(e), "\n")
  })
}

# Prepare test data
cat("Preparing test data...\n\n")

# Basic regression data
data_reg <- data.frame(
  y = rnorm(50), x1 = rnorm(50), x2 = rnorm(50), x3 = rnorm(50)
)

# Panel data (for DiD, event study, etc)
data_panel <- data.frame(
  id = rep(1:10, each=5),
  time = rep(1:5, 10),
  y = rnorm(50),
  treat = rep(c(0,0,0,1,1), 10)
)
data_panel$treat_time <- rep(c(NA,NA,NA,3,3), 10)

# IV data
data_iv <- data.frame(
  y = rnorm(50),
  treat = rnorm(50),
  z = rnorm(50),  # instrument
  x1 = rnorm(50)
)

# Survival-like data
surv_data <- read.csv(file.path(data_dir, "sample_survival_cox.csv"))

# Causal data with heterogeneity
het_data <- data.frame(
  y = rnorm(100),
  w = rbinom(100, 1, 0.5),  # treatment
  x1 = rnorm(100),
  x2 = rnorm(100),
  x3 = rnorm(100)
)

# Case-crossover (person-level repeated obs)
cc_data <- data.frame(
  person_id = rep(1:20, each=10),
  outcome = rbinom(200, 1, 0.3),
  exposure = rnorm(200),
  event_time = rep(1:10, 20)
)

cat("─────────────────────────────────────────────────────────────\n\n")

cat("DIMENSION REDUCTION & SUPERVISED LEARNING\n\n")

# 1. PCA
test_recipe("pca_analysis", data_reg,
  list(variables = list(x = list("x1", "x2", "x3"))),
  "PCA"
)

# 2. PLS regression
test_recipe("pls_regression", data_reg,
  list(variables = list(y = "y", x = list("x1", "x2", "x3"))),
  "Partial Least Squares"
)

# 3. Bayesian regression
test_recipe("bayesian_regression", data_reg,
  list(variables = list(y = "y", x = list("x1", "x2"))),
  "Bayesian linear"
)

cat("\n─────────────────────────────────────────────────────────────\n")
cat("ADVANCED CAUSAL INFERENCE\n\n")

# 4. Double ML
test_recipe("double_ml_ate", data_reg,
  list(variables = list(y = "y", treat = "x1", x = list("x2", "x3"))),
  "Double/Debiased ML"
)

# 5. Causal Forest
test_recipe("causal_forest", het_data,
  list(variables = list(y = "y", w = "w", x = list("x1", "x2", "x3"))),
  "Heterogeneous treatment"
)

# 6. Instrumental Variables (2SLS)
test_recipe("iv_2sls", data_iv,
  list(variables = list(y = "y", treat = "treat", z = "z", x = list("x1"))),
  "2SLS"
)

# 7. Instrumental Variable (general)
test_recipe("instrumental_variable", data_iv,
  list(variables = list(y = "y", treatment = "treat", instrument = "z")),
  "IV regression"
)

cat("\n─────────────────────────────────────────────────────────────\n")
cat("PANEL DATA & POLICY EVALUATION\n\n")

# 8. Difference-in-Differences
test_recipe("difference_in_differences", data_panel,
  list(variables = list(y = "y", time = "time", treat = "treat")),
  "DiD"
)

# 9. Event Study (TWFE)
test_recipe("event_study", data_panel,
  list(variables = list(
    y = "y", unit = "id", time = "time", treat_time = "treat_time"
  )),
  "Event study"
)

# 10. Synthetic Control
test_recipe("synthetic_control", data_panel,
  list(variables = list(
    y = "y", unit = "id", time = "time",
    treat_unit = 1, treat_time = 3
  )),
  "Synth Control"
)

# 11. Placebo Test
test_recipe("placebo_test", data_panel,
  list(variables = list(
    y = "y", unit = "id", time = "time", treat_time = "treat_time"
  )),
  "Placebo test"
)

cat("\n─────────────────────────────────────────────────────────────\n")
cat("SPECIALIZED DESIGNS\n\n")

# 12. Conditional Logistic (matched case-control)
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
  "Matched case-control"
)

# 13. Case-crossover
test_recipe("case_crossover", cc_data,
  list(variables = list(
    person_id = "person_id", outcome = "outcome",
    exposure = "exposure", event_time = "event_time"
  )),
  "Case-crossover"
)

# 14. Target Trial Emulation
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
  "Clone-censor-weight"
)

cat("\n─────────────────────────────────────────────────────────────\n\n")

cat("═══════════════════════════════════════════════════════════\n")
cat("TEST SUMMARY\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("Total tested:", test_count, "\n")
cat("Successful:", success_count, "\n")
success_rate <- if (test_count > 0) round(100 * success_count / test_count) else 0
cat("Success rate:", success_rate, "%\n\n")

if (success_rate >= 80) {
  cat("✅ EXCELLENT: Most recipes working!\n")
} else if (success_rate >= 60) {
  cat("✅ GOOD: Majority working, some issues to address\n")
} else {
  cat("⚠️  FAIR: Multiple recipes need debugging\n")
}

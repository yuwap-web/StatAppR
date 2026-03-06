#!/usr/bin/env Rscript
# Test non-graphics recipes (basic statistics, regression, etc.)

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("=== Non-Graphics Recipe Test Suite ===\n")
cat("Workdir:", workdir, "\n\n")

# Load utilities into environment
env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- workdir

# Try to load utility functions if available
tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {})

test_count <- 0
success_count <- 0

# Helper function to run recipe test
test_recipe <- function(recipe_name, data, request, description = "") {
  test_count <<- test_count + 1
  cat(test_count, "️⃣ ", recipe_name)
  if (nzchar(description)) cat(" (", description, ")")
  cat("\n")

  tryCatch({
    # Create fresh environment for each recipe
    test_env <- new.env(parent = env)

    # Source the recipe
    source(file.path(runner_dir, "recipes", paste0(recipe_name, ".R")), local = test_env)

    # Run the recipe
    result <- test_env$run(request, data)

    # Check result structure
    has_summary <- !is.null(result$summary)
    has_tables <- !is.null(result$tables) && length(result$tables) > 0
    has_errors <- !is.null(result$errors) && length(result$errors) > 0
    has_figures <- !is.null(result$figures) && length(result$figures) > 0

    if (has_errors) {
      cat("   ❌ ERRORS:\n")
      for (err in result$errors) {
        cat("      -", err$code, ":", err$message, "\n")
      }
    } else if (has_summary) {
      cat("   ✅ SUCCESS\n")
      cat("      - Summary:", substr(result$summary$headline, 1, 60), "...\n")
      cat("      - Tables:", length(result$tables), "\n")
      if (has_figures) cat("      - Figures:", length(result$figures), "\n")
      success_count <<- success_count + 1
    } else {
      cat("   ⚠️  No summary generated\n")
    }
  }, error = function(e) {
    cat("   ❌ ERROR:", conditionMessage(e), "\n")
  })
}

cat("--- Basic Statistical Tests ---\n\n")

# 1. Two group continuous (t-test / Wilcoxon)
data_basic <- data.frame(
  group = c(1,1,1,1,1,2,2,2,2,2),
  value = c(10.2, 11.3, 9.8, 12.1, 10.5, 15.3, 16.2, 14.8, 17.1, 15.9)
)

test_recipe("two_group_continuous", data_basic,
  list(variables = list(
    group = "group",
    y = "value"
  )),
  "t-test/Wilcoxon"
)

# 2. Two group categorical (Chi-square / Fisher)
data_cat <- data.frame(
  group = c(rep("A", 10), rep("B", 10)),
  outcome = c(rep(1, 6), rep(0, 4), rep(1, 8), rep(0, 2))
)

test_recipe("two_group_categorical", data_cat,
  list(variables = list(
    group = "group",
    y = "outcome"
  )),
  "Chi-square/Fisher"
)

# 3. ANOVA continuous
data_anova <- data.frame(
  group = rep(c("A", "B", "C"), 10),
  value = c(
    rnorm(10, mean=10, sd=2),
    rnorm(10, mean=12, sd=2),
    rnorm(10, mean=11, sd=2)
  )
)

test_recipe("anova_continuous", data_anova,
  list(variables = list(
    group = "group",
    y = "value"
  )),
  "ANOVA"
)

cat("\n--- Regression Analysis ---\n\n")

# 4. Linear regression
data_regression <- data.frame(
  x = rnorm(30, mean=10, sd=3),
  y = rnorm(30, mean=20, sd=5)
)
# Add some correlation
data_regression$y <- data_regression$y + data_regression$x * 0.5

test_recipe("linear_regression", data_regression,
  list(variables = list(
    y = "y",
    x = "x"
  )),
  "Simple linear"
)

# 5. Multiple regression
data_multi_reg <- data.frame(
  y = rnorm(30),
  x1 = rnorm(30),
  x2 = rnorm(30),
  x3 = rnorm(30)
)

test_recipe("multiple_regression", data_multi_reg,
  list(variables = list(
    y = "y",
    x = list("x1", "x2", "x3")
  )),
  "Multiple linear"
)

# 6. Logistic regression
data_logistic <- data.frame(
  outcome = rbinom(30, 1, 0.5),
  x1 = rnorm(30),
  x2 = rnorm(30)
)

test_recipe("logistic_regression", data_logistic,
  list(variables = list(
    y = "outcome",
    x = list("x1", "x2")
  )),
  "Logit"
)

cat("\n--- Propensity Score & Causal ---\n\n")

# 7. Propensity score estimation
ps_data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))

test_recipe("propensity_score", ps_data,
  list(variables = list(
    treat = "treatment",
    x = list("age", "bmi", "sex", "education")
  )),
  "PS logit"
)

# 8. Balance table
balance_data <- ps_data

test_recipe("balance_table", balance_data,
  list(variables = list(
    treat = "treatment",
    x = list("age", "bmi", "sex", "education")
  )),
  "SMD balance"
)

cat("\n--- Mixed Models ---\n\n")

# 9. Mixed model
mixed_data <- data.frame(
  id = rep(1:10, each=3),
  time = rep(1:3, 10),
  y = rnorm(30),
  x = rnorm(30)
)

test_recipe("mixed_model", mixed_data,
  list(variables = list(
    y = "y",
    x = list("x"),
    group = "id"
  )),
  "Random intercept"
)

cat("\n=== Summary ===\n")
cat("Total recipes tested:", test_count, "\n")
cat("Successful:", success_count, "\n")
cat("Success rate:", round(100 * success_count / test_count), "%\n\n")

if (success_count >= test_count * 0.7) {
  cat("✅ Most recipes working correctly!\n")
} else {
  cat("⚠️  Some recipes need attention\n")
}

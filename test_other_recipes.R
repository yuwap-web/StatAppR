library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"

env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- tempdir()

# Load utilities
tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {})

# Test other recipes not in the main 11
test_recipes <- c(
  "basic_statistics",
  "logistic_regression",
  "linear_regression",
  "multiple_regression",
  "meta_analysis",
  "two_group_continuous",
  "two_group_categorical",
  "cox_regression",
  "survival_km",
  "iptw_ate",
  "iptw_km_survival"
)

test_count <- 0
success_count <- 0

for (recipe_name in test_recipes) {
  test_count <- test_count + 1
  cat(sprintf("%2d. %s ... ", test_count, recipe_name))
  
  recipe_file <- file.path(runner_dir, "recipes", paste0(recipe_name, ".R"))
  if (!file.exists(recipe_file)) {
    cat("FILE NOT FOUND\n")
    next
  }
  
  tryCatch({
    test_env <- new.env(parent = env)
    source(recipe_file, local = test_env)
    cat("✅ LOADED\n")
    success_count <- success_count + 1
  }, error = function(e) {
    cat("❌ ERROR:", conditionMessage(e), "\n")
  })
}

cat(sprintf("\nTotal recipes: %d, Successfully loaded: %d\n", test_count, success_count))

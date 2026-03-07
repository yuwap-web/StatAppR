library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
data_dir <- "/Users/uts/Desktop"

env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- tempdir()

# Load utilities
tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {})

# Load ps_matching recipe
test_env <- new.env(parent = env)
source(file.path(runner_dir, "recipes", "ps_matching.R"), local = test_env)

# Load data
ps_data <- read.csv(file.path(data_dir, "sample_causal_ate.csv"))

# Test parameters
request <- list(variables = list(
  treat = "treatment",
  y = "outcome",
  x = list("age", "bmi", "sex", "education")
))

cat("Testing ps_matching with list x parameter\n")
cat("request$variables$x class:", class(request$variables$x), "\n")
cat("request$variables$x:", paste(request$variables$x, collapse=", "), "\n\n")

result <- tryCatch({
  test_env$run(request, ps_data)
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
  traceback()
  NULL
})

if (!is.null(result)) {
  cat("SUCCESS - ps_matching works\n")
}

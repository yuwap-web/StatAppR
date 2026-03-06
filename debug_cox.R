#!/usr/bin/env Rscript
# Debug Cox regression

library(jsonlite)

runner_dir <- "/Users/uts/StatAppR/Engine"
workdir <- tempdir()
data_dir <- "/Users/uts/Desktop"

cat("=== Debug Cox Regression ===\n")

# Load utilities
env <- new.env()
env$runner_dir <- runner_dir
env$workdir <- workdir

tryCatch({
  sys.source(file.path(runner_dir, "utils", "plot_utils.R"), envir = env)
}, error = function(e) {
  cat("ERROR loading plot_utils:", conditionMessage(e), "\n")
})

# Load cox_regression recipe
cox_data <- read.csv(file.path(data_dir, "sample_survival_cox.csv"))
cat("Data shape:", nrow(cox_data), "x", ncol(cox_data), "\n")
cat("Columns:", names(cox_data), "\n\n")

source(file.path(runner_dir, "recipes", "cox_regression.R"), local = env)

request <- list(
  variables = list(
    time = "time",
    status = "status",
    x = list("age", "bmi", "smoker")
  )
)

cat("Executing cox_regression...\n\n")
result <- env$run(request, cox_data)

cat("Result summary:\n")
cat("- Status:", result$summary$headline, "\n")
cat("- Key metrics:\n")
for (k in names(result$summary$key_metrics)) {
  cat("  -", k, ":", result$summary$key_metrics[[k]], "\n")
}

cat("\n- Tables:")
if (!is.null(result$tables)) {
  cat("\n")
  for (tbl in result$tables) {
    cat("  - ", tbl$id, " (", nrow(tbl$data), "rows)\n")
    if (nrow(tbl$data) <= 5) {
      print(tbl$data)
    }
  }
} else {
  cat(" none\n")
}

cat("\n- Figures:")
if (!is.null(result$figures)) {
  cat("\n")
  for (fig in result$figures) {
    cat("  - ", fig$id, ": ", fig$path, "\n")
  }
} else {
  cat(" none\n")
}

cat("\n- Errors:")
if (!is.null(result$errors) && length(result$errors) > 0) {
  for (err in result$errors) {
    cat("  -", err$code, ":", err$message, "\n")
  }
} else {
  cat(" none\n")
}

cat("\n- Warnings:")
if (!is.null(result$warnings) && length(result$warnings) > 0) {
  for (wrn in result$warnings) {
    cat("  -", wrn$code, ":", wrn$message, "\n")
  }
} else {
  cat(" none\n")
}

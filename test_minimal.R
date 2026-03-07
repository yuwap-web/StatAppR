library(jsonlite)

# Load sample data
sample_data <- read.csv("Sample_Data/survival_data.csv")
cat("Sample data loaded:\n")
print(head(sample_data))
cat("Columns:", names(sample_data), "\n\n")

# Test cox_regression
source("Engine/runner.R")

request <- list(
  recipe_name = "cox_regression",
  variables = list(
    time_column = "time",
    event_column = "event",
    covariates = c("age", "sex")
  )
)

cat("Testing cox_regression...\n")
result <- tryCatch({
  execute_recipe_from_request(request, sample_data)
}, error = function(e) {
  list(error = e$message)
})

if (!is.null(result$error)) {
  cat("ERROR:", result$error, "\n")
} else {
  cat("SUCCESS!\n")
  if (!is.null(result$summary)) {
    cat("Summary:", result$summary$headline, "\n")
  }
}

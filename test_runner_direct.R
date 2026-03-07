# Direct test of runner with fixed recipes

library(jsonlite)

# Load the runner and sample data
source("Engine/runner.R")

# Test data
data1 <- read.csv("Sample_Data/5_Survival_patient_followup.csv")

cat("=== Testing CRITICAL FIXES ===\n")

# Test 1: cox_regression (fixed runner_dir)
cat("\n1. cox_regression - Testing runner_dir fix\n")
request1 <- list(
  recipe_name = "cox_regression",
  variables = list(
    time_column = "time",
    event_column = "status",
    covariates = c("age", "treatment")
  )
)

result1 <- tryCatch({
  execute_recipe_from_request(request1, data1)
}, error = function(e) {
  list(error = e$message)
})

if (!is.null(result1$error)) {
  cat("❌ ERROR:", result1$error, "\n")
} else {
  cat("✅ SUCCESS - cox_regression works\n")
}

# Test 2: survival_km
cat("\n2. survival_km - Testing runner_dir fix\n")
request2 <- list(
  recipe_name = "survival_km",
  variables = list(
    time_column = "time",
    event_column = "status",
    group_column = "treatment"
  )
)

result2 <- tryCatch({
  execute_recipe_from_request(request2, data1)
}, error = function(e) {
  list(error = e$message)
})

if (!is.null(result2$error)) {
  cat("❌ ERROR:", result2$error, "\n")
} else {
  cat("✅ SUCCESS - survival_km works\n")
}

# Test 3: iptw_km_survival
cat("\n3. iptw_km_survival - Testing runner_dir fix\n")
request3 <- list(
  recipe_name = "iptw_km_survival",
  variables = list(
    time_column = "time",
    event_column = "status",
    treatment_column = "treatment"
  )
)

result3 <- tryCatch({
  execute_recipe_from_request(request3, data1)
}, error = function(e) {
  list(error = e$message)
})

if (!is.null(result3$error)) {
  cat("❌ ERROR:", result3$error, "\n")
} else {
  cat("✅ SUCCESS - iptw_km_survival works\n")
}

cat("\n=== CRITICAL FIXES SUMMARY ===\n")
cat("cox_regression:", if(is.null(result1$error)) "✅" else "❌", "\n")
cat("survival_km:", if(is.null(result2$error)) "✅" else "❌", "\n") 
cat("iptw_km_survival:", if(is.null(result3$error)) "✅" else "❌", "\n")

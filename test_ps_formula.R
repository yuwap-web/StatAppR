# Test formula construction with list x parameter
xraw <- list("age", "bmi", "sex", "education")

# Current code tries:
xvars <- trimws(xraw)
xvars <- xvars[xvars!=""]
cat("After direct trim on list:\n")
print(xvars)

# What it should do:
xvars2 <- unlist(xraw)
xvars2 <- trimws(xvars2)
xvars2 <- xvars2[xvars2!=""]
cat("\nAfter unlist then trim:\n")
print(xvars2)

# Build formula
treat_col <- "treatment"
fml1 <- paste0(treat_col,"~",paste(xvars,collapse="+"))
cat("\nFormula with wrong xvars:\n", fml1, "\n")

fml2 <- paste0(treat_col,"~",paste(xvars2,collapse="+"))
cat("Formula with correct xvars:\n", fml2, "\n")

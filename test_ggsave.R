#!/usr/bin/env Rscript
# Test ggsave with different approaches

library(ggplot2)

cat("=== Test ggsave ===\n")
cat("ggplot2 version:", as.character(packageVersion("ggplot2")), "\n\n")

# Simple test data
df <- data.frame(
  x = c(1, 2, 3),
  y = c("A", "B", "C")
)

# Test 1: Basic plot
cat("Test 1: Basic ggplot + ggsave\n")
tryCatch({
  p <- ggplot(df, aes(x=x, y=y)) + geom_point()
  file1 <- tempfile(fileext=".png")
  ggsave(file1, p, width=6, height=4, dpi=300)
  cat("✅ SUCCESS:", file1, "\n\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n\n")
})

# Test 2: ggsave without plot object
cat("Test 2: ggsave with last_plot()\n")
tryCatch({
  file2 <- tempfile(fileext=".png")
  ggplot(df, aes(x=x, y=y)) + geom_point()
  ggsave(file2, width=6, height=4, dpi=300)
  cat("✅ SUCCESS:", file2, "\n\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n\n")
})

# Test 3: Test with errorbarh
cat("Test 3: ggplot with geom_errorbarh\n")
tryCatch({
  df_test <- data.frame(
    label = c("A", "B", "C"),
    est = c(1, 2, 3),
    ci_low = c(0.5, 1.5, 2.5),
    ci_high = c(1.5, 2.5, 3.5)
  )

  p <- ggplot(df_test, aes(x=est, y=label)) +
    geom_point(size=3) +
    geom_errorbarh(aes(xmin=ci_low, xmax=ci_high), height=0.2) +
    theme_minimal()

  file3 <- tempfile(fileext=".png")
  ggsave(file3, p, width=6, height=4, dpi=300)
  cat("✅ SUCCESS:", file3, "\n\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n\n")
})

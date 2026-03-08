# utils/forest_plot.R

# Create persistent results directory (respects STATAPPR_RESULTS_FOLDER env var)
.ensure_results_dir <- function() {
  results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  }
  results_dir
}

make_forest_plot <- function(tbl, estimate, low, high, label) {

  df <- tbl

  if (!all(c(estimate, low, high, label) %in% names(df))) {
    stop("forest plot columns missing")
  }

  n <- nrow(df)
  if (n == 0) stop("forest plot table empty")

  # Save to persistent directory (not temp)
  results_dir <- .ensure_results_dir()
  pngfile <- file.path(results_dir, sprintf("forest_plot_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

  png(pngfile, width = 900, height = 600)

  est <- df[[estimate]]
  lo  <- df[[low]]
  hi  <- df[[high]]

  plot(
    est,
    seq_len(n),
    xlim = range(c(lo, hi), na.rm = TRUE),
    pch = 19,
    yaxt = "n",
    ylab = "",
    xlab = "Effect size"
  )

  segments(
    lo,
    seq_len(n),
    hi,
    seq_len(n)
  )

  axis(
    2,
    at = seq_len(n),
    labels = df[[label]],
    las = 2
  )

  abline(v = 1, lty = 2)

  dev.off()

  return(pngfile)
}
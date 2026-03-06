# utils/forest_plot.R

make_forest_plot <- function(tbl, estimate, low, high, label) {

  df <- tbl

  if (!all(c(estimate, low, high, label) %in% names(df))) {
    stop("forest plot columns missing")
  }

  n <- nrow(df)
  if (n == 0) stop("forest plot table empty")

  pngfile <- tempfile(fileext = ".png")

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
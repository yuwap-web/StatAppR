# utils/plot_utils.R

# ============================================================
# Helper functions
# ============================================================

# Create persistent results directory (respects STATAPPR_RESULTS_FOLDER env var)
.ensure_results_dir <- function() {
  results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  }
  results_dir
}

safe_require <- function(pkg) {
  # Try to load package, return TRUE if successful
  tryCatch({
    requireNamespace(pkg, quietly = TRUE)
  }, error = function(e) {
    FALSE
  })
}

save_plot <- function(p, filename, width = 7, height = 5) {
  # Save a ggplot object to PNG file
  # Returns file path or NULL if save fails

  # Use persistent results directory
  output_dir <- .ensure_results_dir()

  filepath <- file.path(output_dir, sprintf("%s_%s.png", filename, format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

  tryCatch({
    ggplot2::ggsave(
      filepath,
      p,
      width = width,
      height = height,
      dpi = 300,
      device = "png"
    )
    return(filepath)
  }, error = function(e) {
    warning(paste("Failed to save plot:", filename, "-", e$message))
    return(NULL)
  })
}

# ============================================================
# Legacy function (kept for compatibility)
# ============================================================

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  cat("📦 Installing ggplot2 package...\n")
  install.packages("ggplot2", repos = "https://cran.r-project.org", quiet = TRUE)
}

library(ggplot2)

# Optional: ragg for better Japanese text rendering in PNG output
if (!requireNamespace("ragg", quietly = TRUE)) {
  cat("📦 Installing ragg package for improved Japanese text support...\n")
  tryCatch({
    install.packages("ragg", repos = "https://cran.r-project.org", quiet = TRUE)
  }, error = function(e) {
    cat("⚠️  ragg installation skipped (will use standard PNG device)\n")
  })
}

# safe persistent file (not temp)
make_plot_file <- function(prefix="plot") {
  results_dir <- .ensure_results_dir()
  f <- file.path(results_dir, sprintf("%s_%s.png", prefix, format(Sys.time(), "%Y%m%d_%H%M%S_%N")))
  return(f)
}

# ------------------------------------------------------------
# FOREST PLOT (ggplot2版 - 日本語対応)
# used by logistic / cox / other regression recipes
# Japanese text rendering: supported via ggplot2::ggsave()
# ------------------------------------------------------------

make_forest_plot <- function(df,
                             est_col,
                             low_col,
                             high_col,
                             label_col,
                             ref_line = 1,
                             title = "Forest Plot") {

  # ---- Validation ----
  if (!is.data.frame(df) || nrow(df) == 0) {
    stop("df must be a non-empty data.frame")
  }

  if (!all(c(est_col, low_col, high_col, label_col) %in% names(df))) {
    missing_cols <- setdiff(c(est_col, low_col, high_col, label_col), names(df))
    stop(paste("Required columns missing:", paste(missing_cols, collapse=", ")))
  }

  # ---- Prepare output file ----
  file <- make_plot_file("forest")

  # ---- Sort by estimate value ----
  df <- df[order(df[[est_col]]), ]

  # ---- Rename columns for ggplot ----
  df_plot <- df
  names(df_plot)[names(df_plot) == est_col] <- "est"
  names(df_plot)[names(df_plot) == low_col] <- "ci_low"
  names(df_plot)[names(df_plot) == high_col] <- "ci_high"
  names(df_plot)[names(df_plot) == label_col] <- "label"

  # ---- Create ggplot object ----
  p <- ggplot2::ggplot(
    df_plot,
    ggplot2::aes(
      x = est,
      y = reorder(label, est)
    )
  ) +
    ggplot2::geom_point(size = 3, color = "steelblue") +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        xmin = ci_low,
        xmax = ci_high
      ),
      orientation = "y",
      width = 0.2,
      color = "steelblue"
    ) +
    ggplot2::geom_vline(
      xintercept = ref_line,
      linetype = "dashed",
      color = "gray50",
      alpha = 0.7
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 10),
      axis.text.x = ggplot2::element_text(size = 9),
      plot.title = ggplot2::element_text(hjust = 0.5, size = 12, face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::xlab("Effect Size") +
    ggplot2::ylab("") +
    ggplot2::ggtitle(title)

  # ---- Save plot (with ragg for better UTF-8/Japanese support) ----
  tryCatch({
    # Dynamic height based on number of rows
    n_rows <- nrow(df_plot)
    height <- max(4, 2 + n_rows * 0.2)

    # Try to use ragg device if available (better UTF-8 support for Japanese)
    # Fallback to standard png device if ragg not installed
    device_fn <- "png"

    if (requireNamespace("ragg", quietly = TRUE)) {
      device_fn <- ragg::agg_png
    }

    ggplot2::ggsave(
      file,
      p,
      width = 7,
      height = height,
      dpi = 300,
      device = device_fn
    )

    cat("✅ Forest plot saved:", file, "\n")
    return(file)

  }, error = function(e) {
    warning(paste("❌ Failed to save forest plot:", e$message))
    return(NULL)
  })

}

# ------------------------------------------------------------
# BALANCE PLOT (Love plot)
# ------------------------------------------------------------

make_balance_plot <- function(balance_tbl, threshold=0.1) {

  file <- make_plot_file("balance")

  df <- balance_tbl

  df_long <- rbind(

    data.frame(
      covariate=df$covariate,
      smd=df$smd_before,
      type="Before"
    ),

    data.frame(
      covariate=df$covariate,
      smd=df$smd_after,
      type="After"
    )

  )

  p <- ggplot(
    df_long,
    aes(
      x=smd,
      y=reorder(covariate, smd, FUN=median),
      color=type,
      shape=type
    )
  ) +
    geom_point(size=3) +
    geom_vline(
      xintercept=c(-threshold, threshold),
      linetype="dashed",
      alpha=0.6
    ) +
    geom_vline(
      xintercept=0,
      linetype="solid",
      color="black",
      alpha=0.3
    ) +
    theme_minimal() +
    xlab("Standardized Mean Difference") +
    ylab("Covariate") +
    labs(color="Stage", shape="Stage")

  tryCatch({
    ggsave(file, p, width=7, height=5, dpi=300)
  }, error = function(e) {
    warning(paste("Failed to save balance plot:", e$message))
  })

  file

}

# ------------------------------------------------------------
# PS overlap plot
# ------------------------------------------------------------

make_ps_overlap_plot <- function(ps, treat) {

  file <- make_plot_file("ps_overlap")

  df <- data.frame(
    ps=ps,
    treat=factor(treat)
  )

  # Use histogram instead of density to avoid scaling issues
  p <- ggplot(
    df,
    aes(x=ps, fill=treat)
  ) +
    geom_histogram(bins=12, alpha=0.6, position="identity") +
    theme_minimal() +
    xlab("Propensity Score") +
    ylab("Count") +
    labs(fill="Treatment Group", title="Propensity Score Distribution by Treatment Group") +
    theme(plot.title=element_text(hjust=0.5, size=12))

  tryCatch({
    ggsave(file, p, width=7, height=5, dpi=300)
  }, error = function(e) {
    warning(paste("Failed to save PS overlap plot:", e$message))
  })

  file

}

# ------------------------------------------------------------
# IPTW weight histogram
# ------------------------------------------------------------

make_weight_hist <- function(w) {

  file <- make_plot_file("weights")

  df <- data.frame(weight=w)

  p <- ggplot(
    df,
    aes(x=weight)
  ) +
    geom_histogram(
      bins=40,
      fill="steelblue"
    ) +
    theme_minimal() +
    xlab("IPTW Weight")

  ggsave(file,p,width=6,height=4,dpi=300)

  file

}

# Note: make_km_plot() has been moved to Engine/utils/km_plot.R for better
# error handling, survminer support, and proper return structure (list with curve/risk_table fields)

# ============================================================
# Generic summary plot function for recipes without specific plots
# ============================================================

make_summary_plot <- function(recipe_name, summary_text = "") {
  # Generate a simple text-based summary plot for recipes without graphics
  file <- make_plot_file(paste0("summary_", recipe_name))

  png(file, width = 800, height = 600, bg = "white")

  par(mar = c(1, 1, 1, 1))
  plot(0, 0, type = "n", xlab = "", ylab = "", axes = FALSE, xlim = c(0, 1), ylim = c(0, 1))

  # Add title
  text(0.5, 0.95, paste0(recipe_name, " - Analysis Summary"),
       cex = 1.5, fontweight = 2, adj = 0.5)

  # Add summary text
  if (nchar(summary_text) > 0) {
    text(0.5, 0.5, summary_text, cex = 1, adj = 0.5, wrap = TRUE)
  } else {
    text(0.5, 0.5, "Analysis completed successfully", cex = 1, adj = 0.5)
  }

  dev.off()
  return(file)
}

# ============================================================
# Simplified histogram for numeric columns
# ============================================================

make_histogram_plot <- function(data, column, main_title = "") {
  file <- make_plot_file("histogram")

  x <- as.numeric(data[[column]])
  x <- x[!is.na(x)]

  if (length(x) < 2) {
    return(make_summary_plot("histogram", "Insufficient data for histogram"))
  }

  png(file, width = 800, height = 600)
  hist(x, main = ifelse(nchar(main_title) > 0, main_title, paste("Distribution of", column)),
       xlab = column, col = "steelblue", breaks = 15)
  dev.off()

  return(file)
}
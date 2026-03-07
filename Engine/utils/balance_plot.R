# Engine/utils/balance_plot.R
# Plot utilities for IPTW diagnostics
# - balance plot (Love plot)
# - PS overlap
# - weight histogram
#
# Note: plot_utils.R functions (safe_require, save_plot, etc.) are pre-loaded by runner.R

# -------------------------------------------------------
# Balance plot (Standardized Mean Difference)
# -------------------------------------------------------

make_balance_plot <- function(balance_tbl, threshold = 0.1) {

  if (!safe_require("ggplot2")) {
    stop("ggplot2 is required for balance plot")
  }

  df <- balance_tbl

  if (!all(c("covariate","smd_before","smd_after") %in% names(df))) {
    stop("balance_tbl must contain covariate, smd_before, smd_after")
  }

  df_long <- rbind(
    data.frame(covariate=df$covariate,
               SMD=df$smd_before,
               stage="Before"),
    data.frame(covariate=df$covariate,
               SMD=df$smd_after,
               stage="After")
  )

  df_long$covariate <- factor(df_long$covariate,
                              levels=rev(unique(df_long$covariate)))

  p <- ggplot2::ggplot(df_long,
        ggplot2::aes(x=SMD,y=covariate,color=stage)) +
      ggplot2::geom_point(size=3) +
      ggplot2::geom_vline(xintercept=c(-threshold,threshold),
                          linetype="dashed",
                          color="grey50") +
      ggplot2::geom_vline(xintercept=0,
                          linetype="solid",
                          color="black") +
      ggplot2::labs(
        title="Covariate Balance (Standardized Mean Difference)",
        x="Standardized Mean Difference",
        y=NULL
      ) +
      ggplot2::theme_minimal()

  save_plot(p,"balance_plot",width=7,height=5)
}

# -------------------------------------------------------
# Propensity score overlap
# -------------------------------------------------------

make_ps_overlap_plot <- function(ps, treat) {

  if (!safe_require("ggplot2")) {
    stop("ggplot2 is required for PS overlap plot")
  }

  df <- data.frame(ps=ps,treat=treat)

  df$treat <- factor(df$treat)

  p <- ggplot2::ggplot(df,
        ggplot2::aes(x=ps,fill=treat)) +
        ggplot2::geom_density(alpha=0.4) +
        ggplot2::labs(
          title="Propensity Score Overlap",
          x="Propensity Score",
          y="Density",
          fill="Treatment"
        ) +
        ggplot2::theme_minimal()

  save_plot(p,"ps_overlap",width=7,height=5)
}

# -------------------------------------------------------
# Weight histogram
# -------------------------------------------------------

make_weight_hist <- function(weights) {

  if (!safe_require("ggplot2")) {
    stop("ggplot2 is required for weight histogram")
  }

  df <- data.frame(w=weights)

  p <- ggplot2::ggplot(df,
        ggplot2::aes(x=w)) +
        ggplot2::geom_histogram(
            bins=40,
            fill="steelblue",
            color="white"
        ) +
        ggplot2::labs(
          title="Distribution of IPTW Weights",
          x="Weight",
          y="Count"
        ) +
        ggplot2::theme_minimal()

  save_plot(p,"iptw_weight_hist",width=7,height=5)
}
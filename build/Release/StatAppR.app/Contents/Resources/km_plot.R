# Engine/utils/km_plot.R
# Plot utilities for survival_km
# - Kaplan–Meier curve (ggplot)
# - optional confidence band
# - optional risk table (survminer if available; otherwise fallback to curve only)

source(file.path(runner_dir, "utils", "plot_utils.R"))

make_km_plot <- function(fit,
                         df,
                         group_col = "group",
                         conf_int = TRUE,
                         show_risk_table = TRUE,
                         title = "Kaplan–Meier Curve") {

  # Validate input
  if (!inherits(fit, "survfit")) {
    stop("fit must be a survfit object")
  }
  if (!is.data.frame(df)) {
    stop("df must be a data.frame")
  }
  if (!(group_col %in% names(df))) {
    stop(paste0("group_col '", group_col, "' not found in df"))
  }

  if (!safe_require("survival")) stop("survival is required for KM plot")

  # Prefer survminer if available (publication-quality + risk table)
  has_survminer <- safe_require("survminer")
  has_ggplot2 <- safe_require("ggplot2")

  if (has_survminer) {

    # ggsurvplot can draw both curve and risk table
    g <- survminer::ggsurvplot(
      fit,
      data = df,
      conf.int = isTRUE(conf_int),
      risk.table = isTRUE(show_risk_table),
      pval = FALSE,                # p-value is computed in recipe; keep plot clean
      legend.title = group_col,
      legend.labs = levels(as.factor(df[[group_col]])),
      title = title,
      ggtheme = ggplot2::theme_minimal()
    )

    # Save curve
    curve_path <- save_plot(g$plot, "km_curve", width = 7, height = 5)

    # Save risk table (if generated)
    risk_path <- NULL
    if (isTRUE(show_risk_table) && !is.null(g$table)) {
      risk_path <- save_plot(g$table, "km_risk_table", width = 7, height = 2.8)
    }

    return(list(
      curve = curve_path,
      risk_table = risk_path
    ))
  }

  # ---- fallback: no survminer ----
  if (!has_ggplot2) stop("ggplot2 is required for KM plot (survminer not installed)")

  # Convert survfit to data.frame for ggplot
  s <- summary(fit)

  # summary(fit) returns vectors; for strata it returns "strata" labels like "group=A"
  strata <- s$strata
  if (is.null(strata)) {
    grp <- rep("all", length(s$time))
  } else {
    grp <- as.character(strata)
    # make nicer label if "group=xxx"
    grp <- sub("^.*=", "", grp)
  }

  plot_df <- data.frame(
    time = s$time,
    surv = s$surv,
    lower = if (!is.null(s$lower)) s$lower else NA_real_,
    upper = if (!is.null(s$upper)) s$upper else NA_real_,
    group = factor(grp),
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(plot_df,
                       ggplot2::aes(x = time, y = surv, color = group)) +
    ggplot2::geom_step(linewidth = 1.0)

  if (isTRUE(conf_int) && any(!is.na(plot_df$lower)) && any(!is.na(plot_df$upper))) {
    p <- p + ggplot2::geom_step(ggplot2::aes(y = lower), linetype = "dashed", alpha = 0.6) +
      ggplot2::geom_step(ggplot2::aes(y = upper), linetype = "dashed", alpha = 0.6)
  }

  p <- p +
    ggplot2::labs(
      title = title,
      x = "Time",
      y = "Survival probability",
      color = group_col
    ) +
    ggplot2::theme_minimal()

  curve_path <- save_plot(p, "km_curve", width = 7, height = 5)

  # risk table fallback: skip (needs survminer)
  return(list(
    curve = curve_path,
    risk_table = NULL
  ))
}
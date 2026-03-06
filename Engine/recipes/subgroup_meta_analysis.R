# recipes/subgroup_meta_analysis.R
# Subgroup Meta-Analysis: Stratified analysis of multiple studies by categorical grouping variable

# Create persistent results directory (respects STATAPPR_RESULTS_FOLDER env var)
.ensure_results_dir <- function() {
  # Check environment variable first (set by Swift RecipeRunner)
  results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")

  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  }
  results_dir
}

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

make_unique_labels <- function(x) {
  out <- x
  seen <- list()
  for (i in seq_along(out)) {
    key <- out[i]
    if (is.null(seen[[key]])) {
      seen[[key]] <- 1L
    } else {
      seen[[key]] <- seen[[key]] + 1L
      out[i] <- paste0(key, "__", seen[[key]])
    }
  }
  out
}

# ---- Helper: Fixed-effect meta-analysis ----
# Extracted from meta_analysis.R to reuse across subgroups
fixed_effect_meta <- function(effect_vec, se_vec, label_vec, tolerance = 1e-10) {
  # Handles one subgroup's worth of studies
  # Returns: list with pooled statistics and study table

  # Input validation
  if (length(effect_vec) < 2) {
    return(list(error = TRUE, message = "少なくとも2研究が必要です"))
  }

  if (any(se_vec <= 0, na.rm = TRUE)) {
    return(list(error = TRUE, message = "se は正の値である必要があります"))
  }

  # Fixed effect: inverse-variance
  w <- 1 / (se_vec^2)
  w[!is.finite(w)] <- 0

  if (sum(w, na.rm = TRUE) < tolerance) {
    return(list(error = TRUE, message = "有効な重みがありません"))
  }

  fixed <- sum(w * effect_vec, na.rm = TRUE) / sum(w, na.rm = TRUE)
  se_fixed <- sqrt(1 / sum(w, na.rm = TRUE))
  ci <- c(fixed - 1.96 * se_fixed, fixed + 1.96 * se_fixed)
  z <- fixed / se_fixed
  p <- 2 * (1 - stats::pnorm(abs(z)))

  # Heterogeneity
  Q <- sum(w * (effect_vec - fixed)^2, na.rm = TRUE)
  df_Q <- length(effect_vec) - 1
  p_Q <- 1 - stats::pchisq(Q, df = df_Q)
  I2 <- max(0, (Q - df_Q) / Q) * 100
  if (is.nan(I2)) I2 <- 0

  list(
    error = FALSE,
    pooled_effect = fixed,
    se = se_fixed,
    ci_low = ci[1],
    ci_high = ci[2],
    p_value = p,
    z = z,
    Q = Q,
    Q_df = df_Q,
    Q_p_value = p_Q,
    I2_percent = I2,
    weight_vector = w / sum(w, na.rm = TRUE),
    n_studies = length(effect_vec)
  )
}

# ---- Helper: Validate subgroup column ----
validate_subgroup <- function(subgroup_col, complete_indices) {
  # subgroup_col: character or numeric vector
  # complete_indices: indices of rows with complete effect/se data

  if (length(complete_indices) == 0) {
    return(list(valid = FALSE, message = "完全なデータがありません"))
  }

  subgroup_subset <- subgroup_col[complete_indices]
  subgroup_subset <- as.character(trimws(subgroup_subset))
  subgroup_subset[subgroup_subset == ""] <- NA_character_

  unique_subgroups <- unique(subgroup_subset[!is.na(subgroup_subset)])

  if (length(unique_subgroups) == 0) {
    return(list(valid = FALSE, message = "有効なサブグループがありません"))
  }

  if (length(unique_subgroups) == 1) {
    return(list(valid = FALSE, message = "サブグループが1つです（比較が不可）。最低2つ必要です"))
  }

  list(
    valid = TRUE,
    subgroups = unique_subgroups,
    subgroup_data = subgroup_subset,
    n_missing = sum(is.na(subgroup_subset))
  )
}

# ---- Helper: Forest plot for subgroup ----
make_forest_plot_subgroup <- function(study_tbl, pooled_row, subgroup_name) {
  # study_tbl: data.frame(label, effect, se, weight)
  # pooled_row: list with pooled statistics
  # subgroup_name: character, name of this subgroup

  if (is.null(study_tbl) || nrow(study_tbl) < 1) {
    return(NULL)
  }

  df <- study_tbl
  df$ci_low  <- df$effect - 1.96 * df$se
  df$ci_high <- df$effect + 1.96 * df$se

  n <- nrow(df)

  x_min <- min(df$ci_low, pooled_row$ci_low, na.rm = TRUE)
  x_max <- max(df$ci_high, pooled_row$ci_high, na.rm = TRUE)

  pad <- 0.05 * (x_max - x_min)
  if (!is.finite(pad) || pad <= 0) pad <- 1
  x_min <- x_min - pad
  x_max <- x_max + pad

  # Save to persistent directory (not temp)
  results_dir <- .ensure_results_dir()
  file <- file.path(results_dir, sprintf("forest_plot_%s_%s.png",
                                          make.names(subgroup_name),
                                          format(Sys.time(), "%Y%m%d_%H%M%S_%N")))
  grDevices::png(file, width = 1000, height = max(500, 100 + 80 * n), res = 120)

  op <- par(no.readonly = TRUE)
  on.exit({
    try(par(op), silent = TRUE)
    try(grDevices::dev.off(), silent = TRUE)
  }, add = TRUE)

  par(mar = c(5, 14, 4, 2))

  y_study <- rev(seq_len(n))
  y_pool  <- 0

  plot(
    NA,
    xlim = c(x_min, x_max),
    ylim = c(-1, n + 1),
    xlab = "Effect (with 95% CI)",
    ylab = "",
    yaxt = "n",
    main = paste0("Forest plot (fixed effect): ", subgroup_name),
    bty = "n"
  )

  axis(2, at = y_study, labels = df$label, las = 2, cex.axis = 0.85)

  abline(v = 0, lty = 3)
  abline(v = pooled_row$pooled_effect, lty = 2)

  w <- df$weight
  w <- w / max(w, na.rm = TRUE)
  cex_pt <- 0.8 + 1.6 * w

  segments(df$ci_low, y_study, df$ci_high, y_study, lwd = 2)
  points(df$effect, y_study, pch = 15, cex = cex_pt)

  pe  <- pooled_row$pooled_effect
  lwr <- pooled_row$ci_low
  upr <- pooled_row$ci_high
  diamond_y <- y_pool
  diamond_h <- 0.35

  polygon(
    x = c(lwr, pe, upr, pe),
    y = c(diamond_y, diamond_y + diamond_h, diamond_y, diamond_y - diamond_h),
    border = "black",
    col = "gray"
  )
  text(x = x_min, y = diamond_y, labels = "Pooled", pos = 4, cex = 0.95, font = 2)

  file
}

# ---- PDF Report Generation (Improved with gridExtra) ----
generate_pdf_report <- function(summary_info, tables_list, subgroup_results, results_dir) {
  tryCatch({
    # Load required library
    if (!require("gridExtra", quietly = TRUE)) {
      # Fallback: use simple text-based PDF if gridExtra not available
      return(.generate_pdf_report_simple(summary_info, tables_list, subgroup_results, results_dir))
    }

    if (!require("grid", quietly = TRUE)) {
      return(.generate_pdf_report_simple(summary_info, tables_list, subgroup_results, results_dir))
    }

    # Create PDF file
    pdf_file <- file.path(results_dir, sprintf("report_%s.pdf", format(Sys.time(), "%Y%m%d_%H%M%S")))

    # Open PDF device with better encoding
    pdf(pdf_file, width = 8.5, height = 11, onefile = TRUE, encoding = "UTF-8")

    # Suppress warnings
    old_warn <- options(warn = -1)

    # ========== PAGE 1: Title & Summary ==========
    grid.newpage()

    # Create layout: title at top, content in middle, footer at bottom
    pushViewport(viewport(layout = grid.layout(3, 1, heights = unit(c(1.5, 7, 0.5), "cm"))))

    # Title section
    pushViewport(viewport(layout.pos.row = 1, gp = gpar(fontface = "bold")))
    grid.text("サブグループメタアナリシス報告書",
              x = 0.5, y = 0.5,
              gp = gpar(fontsize = 18, fontface = "bold"))
    popViewport()

    # Content section
    pushViewport(viewport(layout.pos.row = 2, x = 0.1, width = 0.8, just = "left"))

    content <- vector("list", 0)

    # Headline
    content[[length(content) + 1]] <- grid.text(summary_info$headline,
                                                 x = 0, y = 0.95, just = c("left", "top"),
                                                 gp = gpar(fontsize = 11, fontface = "bold"))

    # Method
    content[[length(content) + 1]] <- grid.text(paste0("方法: ", summary_info$method_used),
                                                 x = 0, y = 0.88, just = c("left", "top"),
                                                 gp = gpar(fontsize = 10))

    # Key metrics section
    metrics <- summary_info$key_metrics
    content[[length(content) + 1]] <- grid.text("主要指標:",
                                                 x = 0, y = 0.80, just = c("left", "top"),
                                                 gp = gpar(fontsize = 10, fontface = "bold"))

    # Create metrics table
    metrics_df <- data.frame(
      指標 = c("総研究数", "サブグループ数", "全体効果量", "P値", "I²"),
      値 = c(
        metrics$n_total_studies,
        metrics$n_subgroups,
        sprintf("%.4f", metrics$pooled_effect_overall),
        sprintf("%.4e", metrics$p_value_overall),
        sprintf("%.1f%%", metrics$I2_percent_overall)
      ),
      stringsAsFactors = FALSE
    )

    metrics_table <- gridExtra::tableGrob(metrics_df, rows = NULL,
                                           theme = ttheme_minimal(
                                             base_size = 9,
                                             padding = unit(c(2, 4), "mm")))

    grid.draw(metrics_table)
    popViewport()

    # Footer
    pushViewport(viewport(layout.pos.row = 3))
    grid.text(sprintf("生成日時: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
              x = 0.5, y = 0.5, just = c("center", "center"),
              gp = gpar(fontsize = 8, fontface = "italic"))
    popViewport()

    popViewport()  # Close main layout

    # ========== PAGE 2+: Subgroup Results ==========
    page_num <- 2
    for (subg_name in names(subgroup_results)) {
      res <- subgroup_results[[subg_name]]

      grid.newpage()
      pushViewport(viewport(layout = grid.layout(2, 1, heights = unit(c(1, 9.5), "cm"))))

      # Subgroup header
      pushViewport(viewport(layout.pos.row = 1, gp = gpar(fontface = "bold")))
      grid.text(paste0("サブグループ: ", subg_name),
                x = 0.5, y = 0.5,
                gp = gpar(fontsize = 14, fontface = "bold"))
      popViewport()

      # Subgroup content
      pushViewport(viewport(layout.pos.row = 2, x = 0.1, width = 0.8, just = "left"))

      # Statistics table
      stats_df <- data.frame(
        項目 = c("研究数", "効果量", "95% 信頼区間", "下限", "上限", "P値", "I²", "Q統計量", "Q P値"),
        値 = c(
          res$n_studies,
          sprintf("%.4f", res$pooled_effect),
          sprintf("[%.4f, %.4f]", res$ci_low, res$ci_high),
          sprintf("%.4f", res$ci_low),
          sprintf("%.4f", res$ci_high),
          sprintf("%.4e", res$p_value),
          sprintf("%.1f%%", res$I2_percent),
          sprintf("%.2f", res$Q),
          sprintf("%.4f", res$Q_p_value)
        ),
        stringsAsFactors = FALSE
      )

      stats_table <- gridExtra::tableGrob(stats_df, rows = NULL,
                                           theme = ttheme_minimal(
                                             base_size = 9,
                                             padding = unit(c(2, 4), "mm")))

      grid.draw(stats_table)
      popViewport()

      popViewport()  # Close main layout
      page_num <- page_num + 1
    }

    # Close PDF
    options(old_warn)
    dev.off()

    return(pdf_file)
  }, error = function(e) {
    # Return NULL if PDF generation fails (will use fallback)
    return(NULL)
  })
}

# ---- Fallback Simple PDF Report (if gridExtra not available) ----
.generate_pdf_report_simple <- function(summary_info, tables_list, subgroup_results, results_dir) {
  tryCatch({
    pdf_file <- file.path(results_dir, sprintf("report_%s.pdf", format(Sys.time(), "%Y%m%d_%H%M%S")))
    pdf(pdf_file, width = 8.5, height = 11, onefile = TRUE, encoding = "UTF-8")
    old_warn <- options(warn = -1)

    # Page 1: Title and Summary
    plot.new()
    par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))

    # Title
    text(0.5, 0.98, "サブグループメタアナリシス報告書", cex = 1.8, font = 2, adj = 0.5)

    # Summary section
    y_pos <- 0.90
    text(0.05, y_pos, summary_info$headline, cex = 1.0, font = 1, adj = 0)
    y_pos <- y_pos - 0.06

    text(0.05, y_pos, paste0("方法: ", summary_info$method_used), cex = 0.85, font = 1, adj = 0)
    y_pos <- y_pos - 0.05

    # Key metrics
    text(0.05, y_pos, "主要指標:", cex = 0.9, font = 2, adj = 0)
    y_pos <- y_pos - 0.04

    metrics <- summary_info$key_metrics
    metric_lines <- c(
      sprintf("総研究数: %d", metrics$n_total_studies),
      sprintf("サブグループ数: %d", metrics$n_subgroups),
      sprintf("全体効果量: %.4f (p = %.4e)", metrics$pooled_effect_overall, metrics$p_value_overall),
      sprintf("I²: %.1f%%", metrics$I2_percent_overall)
    )

    for (line in metric_lines) {
      text(0.08, y_pos, line, cex = 0.80, font = 1, adj = 0)
      y_pos <- y_pos - 0.03
    }

    y_pos <- y_pos - 0.02

    # Tables list
    text(0.05, y_pos, "生成されたテーブル:", cex = 0.9, font = 2, adj = 0)
    y_pos <- y_pos - 0.03

    if (length(tables_list) > 0) {
      for (i in seq_along(tables_list)) {
        tbl <- tables_list[[i]]
        text(0.08, y_pos, sprintf("  %d. %s (%d行)", i, tbl$title, nrow(tbl$data)), cex = 0.75, adj = 0)
        y_pos <- y_pos - 0.03
      }
    }

    # Footer
    text(0.5, 0.01, sprintf("生成日時: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
         cex = 0.65, font = 3, adj = 0.5)

    # Page 2+: Subgroup details
    for (subg_name in names(subgroup_results)) {
      res <- subgroup_results[[subg_name]]

      plot.new()
      par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))

      # Subgroup title
      text(0.5, 0.98, paste0("サブグループ: ", subg_name), cex = 1.3, font = 2, adj = 0.5)

      # Statistics
      y_pos <- 0.90
      text(0.05, y_pos, "統計量:", cex = 0.9, font = 2, adj = 0)
      y_pos <- y_pos - 0.04

      stat_lines <- c(
        sprintf("研究数: %d", res$n_studies),
        sprintf("効果量: %.4f", res$pooled_effect),
        sprintf("95%信頼区間: [%.4f, %.4f]", res$ci_low, res$ci_high),
        sprintf("P値: %.4e", res$p_value),
        sprintf("I²: %.1f%%", res$I2_percent),
        sprintf("Q統計量: %.2f (df=%d, p = %.4f)", res$Q, res$Q_df, res$Q_p_value)
      )

      for (line in stat_lines) {
        text(0.08, y_pos, line, cex = 0.80, font = 1, adj = 0)
        y_pos <- y_pos - 0.03
      }

      # Footer
      text(0.5, 0.01, sprintf("生成日時: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
           cex = 0.65, font = 3, adj = 0.5)
    }

    # Close PDF
    options(old_warn)
    dev.off()

    return(pdf_file)
  }, error = function(e) {
    return(NULL)
  })
}

# ---- Main function ----
run_recipe_impl <- function(request, data) {

  # Extract parameters
  eff <- request$variables$effect
  se  <- request$variables$se
  label <- request$variables$label
  subgroup_col <- request$variables$subgroup_column

  # Parameter validation
  if (is.null(eff) || eff == "") stop("variables.effect が必要です（効果量）")
  if (is.null(se)  || se  == "") stop("variables.se が必要です（標準誤差）")
  if (is.null(subgroup_col) || subgroup_col == "") stop("variables.subgroup_column が必要です")

  if (!(eff %in% names(data))) stop(paste0("effect column not found: ", eff))
  if (!(se  %in% names(data))) stop(paste0("se column not found: ", se))
  if (!(subgroup_col %in% names(data))) stop(paste0("subgroup_column not found: ", subgroup_col))

  # Extract vectors
  df <- data.frame(
    effect = data[[eff]],
    se = data[[se]],
    subgroup = as.character(data[[subgroup_col]]),
    stringsAsFactors = FALSE
  )

  # Coerce numeric columns
  if (!is.numeric(df$effect)) {
    e0 <- df$effect
    suppressWarnings(df$effect <- as.numeric(gsub(",", "", as.character(df$effect))))
    if (all(is.na(df$effect)) && any(!is.na(e0))) stop("effect は数値列である必要があります")
  }
  if (!is.numeric(df$se)) {
    s0 <- df$se
    suppressWarnings(df$se <- as.numeric(gsub(",", "", as.character(df$se))))
    if (all(is.na(df$se)) && any(!is.na(s0))) stop("se は数値列である必要があります")
  }

  # Label column handling
  label_col_ok <- (!is.null(label) && label != "" && (label %in% names(data)))
  if (label_col_ok) {
    df$label <- as.character(data[[label]])
  } else {
    df$label <- rep(NA_character_, nrow(df))
  }

  # Trim labels
  df$label <- trimws(df$label)
  df$label[df$label == ""] <- NA_character_
  df$row_id <- seq_len(nrow(df))
  df$subgroup <- trimws(df$subgroup)
  df$subgroup[df$subgroup == ""] <- NA_character_

  # Filter: complete cases on effect/se
  ok <- stats::complete.cases(df[, c("effect", "se"), drop = FALSE])
  df_complete <- df[ok, , drop = FALSE]
  complete_indices <- which(ok)

  if (nrow(df_complete) < 2) stop("メタ解析には少なくとも2研究が必要です")
  if (any(df_complete$se <= 0, na.rm = TRUE)) stop("se は正の値である必要があります")

  # Validate and extract subgroups
  subgroup_validation <- validate_subgroup(df$subgroup, complete_indices)
  if (!subgroup_validation$valid) {
    stop(subgroup_validation$message)
  }

  subgroup_list <- subgroup_validation$subgroups
  subgroup_data_clean <- subgroup_validation$subgroup_data

  # Update subgroup in complete dataset
  df_complete$subgroup <- subgroup_data_clean

  # Fill missing labels
  miss_lab <- is.na(df_complete$label) | !nzchar(df_complete$label)
  if (any(miss_lab)) {
    df_complete$label[miss_lab] <- paste0("study_", df_complete$row_id[miss_lab])
  }
  df_complete$label[is.na(df_complete$label)] <- paste0("study_", df_complete$row_id[is.na(df_complete$label)])

  # Make labels unique
  df_complete$label <- make_unique_labels(df_complete$label)

  warnings_out <- list()

  if (label_col_ok && subgroup_validation$n_missing > 0) {
    warnings_out <- c(warnings_out, list(list(
      code = "LABEL_MISSING_FILLED",
      severity = "info",
      message = paste0("label 欠損が ", sum(is.na(df$label[ok])) + subgroup_validation$n_missing, " 件あり、自動補完しました")
    )))
  }

  # Stratified meta-analysis: iterate over subgroups
  subgroup_results <- list()
  study_data_output <- list()
  small_subgroups <- character(0)

  for (subg in subgroup_list) {
    # Filter to this subgroup
    idx_subgroup <- which(df_complete$subgroup == subg)

    if (length(idx_subgroup) < 2) {
      small_subgroups <- c(small_subgroups, subg)
      next
    }

    df_subg <- df_complete[idx_subgroup, ]

    # Fixed effect meta-analysis for this subgroup
    fe_result <- fixed_effect_meta(
      effect_vec = df_subg$effect,
      se_vec = df_subg$se,
      label_vec = df_subg$label
    )

    if (fe_result$error) {
      warnings_out <- c(warnings_out, list(list(
        code = paste0("SUBGROUP_ERROR_", subg),
        severity = "warning",
        message = paste0("サブグループ '", subg, "' の分析に失敗: ", fe_result$message)
      )))
      next
    }

    # Prepare study table for forest plot
    study_tbl <- data.frame(
      label = df_subg$label,
      effect = df_subg$effect,
      se = df_subg$se,
      weight = fe_result$weight_vector,
      stringsAsFactors = FALSE
    )

    # Prepare pooled row
    pooled_row <- list(
      pooled_effect = fe_result$pooled_effect,
      ci_low = fe_result$ci_low,
      ci_high = fe_result$ci_high
    )

    # Generate forest plot for this subgroup
    forest_file <- tryCatch(
      make_forest_plot_subgroup(study_tbl, pooled_row, subg),
      error = function(e) {
        warnings_out <<- c(warnings_out, list(list(
          code = paste0("FOREST_PLOT_FAILED_", subg),
          severity = "info",
          message = paste0("forest plot の生成に失敗しました (", subg, "): ", conditionMessage(e))
        )))
        NULL
      }
    )

    # Store subgroup result
    subgroup_results[[subg]] <- list(
      subgroup = subg,
      n_studies = fe_result$n_studies,
      pooled_effect = fe_result$pooled_effect,
      se = fe_result$se,
      ci_low = fe_result$ci_low,
      ci_high = fe_result$ci_high,
      p_value = fe_result$p_value,
      z = fe_result$z,
      Q = fe_result$Q,
      Q_df = fe_result$Q_df,
      Q_p_value = fe_result$Q_p_value,
      I2_percent = fe_result$I2_percent,
      forest_file = forest_file
    )

    # Add study data for output
    for (i in seq_len(nrow(df_subg))) {
      study_data_output[[length(study_data_output) + 1]] <- list(
        label = df_subg$label[i],
        effect = df_subg$effect[i],
        se = df_subg$se[i],
        subgroup = subg,
        ci_low = df_subg$effect[i] - 1.96 * df_subg$se[i],
        ci_high = df_subg$effect[i] + 1.96 * df_subg$se[i],
        weight = fe_result$weight_vector[i]
      )
    }
  }

  # Check if any subgroups had sufficient data
  if (length(subgroup_results) < 2) {
    stop("2つ以上の有効なサブグループが必要です（各グループ最低2研究）")
  }

  # Add warning for small subgroups
  if (length(small_subgroups) > 0) {
    warnings_out <- c(warnings_out, list(list(
      code = "SMALL_SUBGROUP",
      severity = "warning",
      message = paste0(
        "次のサブグループは2研究未満のため分析から除外しました: ",
        paste(small_subgroups, collapse = ", ")
      )
    )))
  }

  # Calculate overall effect (across all studies)
  fe_overall <- fixed_effect_meta(
    effect_vec = df_complete$effect,
    se_vec = df_complete$se,
    label_vec = df_complete$label
  )

  # Generate overall forest plot
  overall_study_tbl <- data.frame(
    label = df_complete$label,
    effect = df_complete$effect,
    se = df_complete$se,
    weight = fe_overall$weight_vector,
    stringsAsFactors = FALSE
  )

  overall_pooled_row <- list(
    pooled_effect = fe_overall$pooled_effect,
    ci_low = fe_overall$ci_low,
    ci_high = fe_overall$ci_high
  )

  forest_overall_file <- tryCatch(
    make_forest_plot_subgroup(overall_study_tbl, overall_pooled_row, "全体（全研究）"),
    error = function(e) NULL
  )

  # Prepare subgroup summary table
  subgroup_summary_data <- list()
  for (subg in names(subgroup_results)) {
    res <- subgroup_results[[subg]]
    subgroup_summary_data[[length(subgroup_summary_data) + 1]] <- list(
      subgroup = res$subgroup,
      n_studies = res$n_studies,
      pooled_effect = signif(res$pooled_effect, 4),
      se = signif(res$se, 4),
      ci_low = signif(res$ci_low, 4),
      ci_high = signif(res$ci_high, 4),
      p_value = signif(res$p_value, 3),
      I2_percent = signif(res$I2_percent, 3),
      Q = signif(res$Q, 3),
      Q_p_value = signif(res$Q_p_value, 3)
    )
  }

  # Subgroup comparison (simple: effect differences)
  subgroup_comparison_data <- list()
  subg_names <- names(subgroup_results)
  if (length(subg_names) >= 2) {
    for (i in 1:(length(subg_names) - 1)) {
      for (j in (i + 1):length(subg_names)) {
        subg_i <- subg_names[i]
        subg_j <- subg_names[j]
        res_i <- subgroup_results[[subg_i]]
        res_j <- subgroup_results[[subg_j]]

        effect_diff <- res_i$pooled_effect - res_j$pooled_effect
        se_diff <- sqrt(res_i$se^2 + res_j$se^2)
        z_diff <- effect_diff / se_diff
        p_diff <- 2 * (1 - stats::pnorm(abs(z_diff)))

        subgroup_comparison_data[[length(subgroup_comparison_data) + 1]] <- list(
          comparison = paste0(subg_i, " vs ", subg_j),
          effect_diff = signif(effect_diff, 4),
          se_diff = signif(se_diff, 4),
          z = signif(z_diff, 3),
          p_value = signif(p_diff, 3)
        )
      }
    }
  }

  # Build output
  figures_list <- list()

  # Add forest plots for each subgroup
  for (subg in names(subgroup_results)) {
    res <- subgroup_results[[subg]]
    if (!is.null(res$forest_file)) {
      figures_list[[length(figures_list) + 1]] <- list(
        id = paste0("forest_subgroup_", gsub(" ", "_", subg)),
        title = paste0("Forest plot: ", subg),
        path = res$forest_file
      )
    }
  }

  # Add overall forest plot
  if (!is.null(forest_overall_file)) {
    figures_list[[length(figures_list) + 1]] <- list(
      id = "forest_overall",
      title = "Forest plot: 全体（全研究）",
      path = forest_overall_file
    )
  }

  # Summary
  headline <- paste0(
    "サブグループメタ分析: ",
    length(subgroup_results),
    "グループ, ",
    nrow(df_complete),
    "研究, p = ",
    signif(fe_overall$p_value, 3)
  )

  # Generate PDF report
  summary_for_pdf <- list(
    headline = headline,
    method_used = "固定効果（サブグループ層別）",
    key_metrics = list(
      n_total_studies = nrow(df_complete),
      n_subgroups = length(subgroup_results),
      pooled_effect_overall = signif(fe_overall$pooled_effect, 4),
      p_value_overall = signif(fe_overall$p_value, 3),
      I2_percent_overall = signif(fe_overall$I2_percent, 3),
      Q_overall = signif(fe_overall$Q, 3),
      Q_df_overall = fe_overall$Q_df,
      Q_p_value_overall = signif(fe_overall$Q_p_value, 3)
    ),
    interpretation_notes = list(
      "各サブグループの効果推定値はテーブルを参照してください。",
      "サブグループ間の効果の差は 'サブグループ間の比較' テーブルを確認してください。",
      "各グループのI²が高い場合は異質性が大きい可能性があります。"
    )
  )

  pdf_file <- generate_pdf_report(
    summary_for_pdf,
    list(
      list(id = "study_data", title = "研究別データ（サブグループ注釈付き）", data = study_data_output),
      list(id = "subgroup_summary", title = "サブグループ別統合結果", data = subgroup_summary_data),
      list(id = "subgroup_comparison", title = "サブグループ間の比較", data = subgroup_comparison_data)
    ),
    subgroup_results,
    .ensure_results_dir()
  )

  # Add PDF to figures if generated successfully
  if (!is.null(pdf_file)) {
    figures_list[[length(figures_list) + 1]] <- list(
      id = "report_pdf",
      title = "統計報告書（PDF）",
      type = "application/pdf",
      path = pdf_file
    )

    # Also add warning if PDF generation succeeded
    warnings_out <- c(warnings_out, list(list(
      code = "PDF_GENERATED",
      severity = "info",
      message = paste0("PDF レポート が生成されました: ", basename(pdf_file))
    )))
  }

  list(
    summary = summary_for_pdf,
    tables = list(
      list(id = "study_data", title = "研究別データ（サブグループ注釈付き）", data = study_data_output),
      list(id = "subgroup_summary", title = "サブグループ別統合結果", data = subgroup_summary_data),
      list(id = "subgroup_comparison", title = "サブグループ間の比較", data = subgroup_comparison_data)
    ),
    figures = figures_list,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl

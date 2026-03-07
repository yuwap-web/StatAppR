# recipes/multiple_regression.R

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  ycol <- request$variables$outcome_column
  xraw <- request$variables$predictor_columns   # vector or comma-separated string

  # optional (advanced)
  compute_vif <- request$variables$compute_vif %||% FALSE

  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("request$variables$predictor_columns（説明変数）が必要です")

  # x normalization
  xs <- NULL
  if (is.character(xraw) && length(xraw) == 1) {
    xs <- trimws(unlist(strsplit(xraw, ",")))
  } else if (is.character(xraw) && length(xraw) >= 1) {
    xs <- xraw
  } else if (is.list(xraw)) {
    xs <- unlist(xraw)
  } else {
    xs <- as.character(xraw)
  }

  xs <- trimws(xs)
  xs <- xs[xs != ""]

  # y が混ざる事故防止
  xs <- setdiff(xs, ycol)

  if (length(xs) < 2) stop("multiple_regression は x を2つ以上指定してください")

  for (cname in c(ycol, xs)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(ycol, xs), drop = FALSE]

  # y numeric coercion
  if (!is.numeric(df[[ycol]])) {
    y0 <- df[[ycol]]
    suppressWarnings(
      df[[ycol]] <- as.numeric(gsub(",", "", as.character(df[[ycol]])))
    )
    if (all(is.na(df[[ycol]])) && any(!is.na(y0))) {
      stop("y は数値列である必要があります")
    }
  }

  # x numeric coercion（factorはそのまま）
  for (nm in xs) {

    if (is.character(df[[nm]])) {

      x0 <- df[[nm]]

      suppressWarnings(
        df[[nm]] <- as.numeric(gsub(",", "", df[[nm]]))
      )

      if (all(is.na(df[[nm]])) && any(!is.na(x0))) {
        df[[nm]] <- as.factor(x0)
      }

    }

  }

  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (nrow(df) < 5) stop("有効データが少なすぎます")

  # formula
  fml <- stats::as.formula(
    paste0(ycol, " ~ ", paste(xs, collapse = " + "))
  )

  fit <- stats::lm(fml, data = df)
  sm <- summary(fit)

  coef_mat <- sm$coefficients

  if (is.null(coef_mat) || nrow(coef_mat) < 1) {
    stop("lm coefficients not available")
  }

  coefs <- as.data.frame(coef_mat)

  coefs$term <- rownames(coefs)
  rownames(coefs) <- NULL

  cn <- colnames(coefs)

  est_col <- cn[grepl("^Estimate", cn)][1]
  se_col  <- cn[grepl("Std", cn)][1]
  t_col   <- cn[grepl("t", cn)][1]
  p_col   <- cn[grepl("Pr", cn)][1]

  coefs <- data.frame(
    term = coefs$term,
    estimate = coefs[[est_col]],
    std_error = coefs[[se_col]],
    t_value = coefs[[t_col]],
    p_value = coefs[[p_col]],
    stringsAsFactors = FALSE
  )

  metrics <- data.frame(
    n_used = nrow(df),
    r_squared = unname(sm$r.squared),
    adj_r_squared = unname(sm$adj.r.squared),
    sigma = unname(sm$sigma),
    aic = unname(stats::AIC(fit)),
    stringsAsFactors = FALSE
  )

  warnings_out <- list()
  vif_tbl <- NULL

  # VIF
  if (isTRUE(compute_vif)) {

    if (requireNamespace("car", quietly = TRUE)) {

      v <- try(car::vif(fit), silent = TRUE)

      if (!inherits(v, "try-error")) {

        if (is.matrix(v)) {

          vif_tbl <- data.frame(
            term = rownames(v),
            v,
            row.names = NULL,
            check.names = FALSE
          )

        } else {

          vif_tbl <- data.frame(
            term = names(v),
            vif = as.numeric(v),
            row.names = NULL
          )

        }

      } else {

        warnings_out <- c(warnings_out, list(list(
          code = "VIF_FAILED",
          severity = "info",
          message = "VIF計算に失敗しました"
        )))

      }

    } else {

      warnings_out <- c(warnings_out, list(list(
        code = "CAR_NOT_INSTALLED",
        severity = "info",
        message = "VIF計算には car パッケージが必要です"
      )))

    }

  }

  tables_out <- list(
    list(id = "model_metrics", title = "モデル指標", data = metrics),
    list(id = "coefficients", title = "回帰係数", data = coefs)
  )

  if (!is.null(vif_tbl)) {

    tables_out <- c(tables_out, list(list(
      id = "vif",
      title = "VIF（多重共線性の指標）",
      data = vif_tbl
    )))

  }

  # ---- 図表生成 ----
  figures <- list()

  tryCatch({
    # Create diagnostic plot (residuals vs fitted)
    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
    if (!dir.exists(results_dir)) {
      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
    }
    plot_file <- file.path(results_dir, sprintf("multiple_regression_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

    png(plot_file, width = 800, height = 600)
    plot(fit, which = 1)  # Residuals vs Fitted
    dev.off()

    if (file.exists(plot_file)) {
      figures <- c(figures, list(list(
        id = "residuals_plot",
        title = "Residuals vs Fitted Values",
        type = "plot",
        path = plot_file
      )))
    }
  }, error = function(e) {
    warnings_out <<- c(warnings_out, list(list(
      code = "PLOT_GENERATION_FAILED",
      severity = "info",
      message = paste("図表生成に失敗しました:", e$message)
    )))
  })

  list(
    summary = list(
      headline = paste0("重回帰: adj R² = ", signif(sm$adj.r.squared, 3)),
      method_used = "最小二乗法（lm）",
      key_metrics = list(
        adj_r_squared = unname(sm$adj.r.squared),
        r_squared = unname(sm$r.squared),
        aic = unname(stats::AIC(fit)),
        n_used = nrow(df)
      ),
      interpretation_notes = list(
        "多重共線性（VIF）や外れ値の影響に注意してください。",
        "カテゴリ変数は自動的にダミー化されます。"
      )
    ),
    tables = tables_out,
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
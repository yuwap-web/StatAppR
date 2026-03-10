# recipes/logistic_regression.R

# Source plot utilities
tryCatch({
  source(file.path(runner_dir, "utils/plot_utils.R"), local = TRUE)
}, error = function(e) {
  # plot_utils failed to load - continue without plots
})

run_recipe_impl <- function(request, data) {

  # ---- dependencies (optional) ----
  # If you use forest plot, make_forest_plot must be available.
  # Either:
  #  - source("Engine/utils/forest_plot.R") somewhere (runner or recipe), or
  #  - define make_forest_plot in the global env before calling runner.
  #
  # This recipe will NOT fail if make_forest_plot is missing; it will just skip the plot.

  ycol <- request$variables$outcome_column
  xraw <- request$variables$predictor_columns  # vector or comma-separated string

  if (is.null(ycol) || ycol == "") stop("variables.outcome_column（2値目的変数）が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("variables.predictor_columns（説明変数）が必要です")

  # ---- x normalization (array or "a,b") ----
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

  # y が混ざる事故を防ぐ
  xs <- setdiff(xs, ycol)

  # ---- 投与期間の自動計算 ----
  # 投与開始日と投与終了日がある場合、投与期間（日数）を新しい列として追加
  if (("投与開始日" %in% names(data)) && ("投与終了日" %in% names(data))) {
    tryCatch({
      start_date <- as.Date(as.character(data[["投与開始日"]]), format = "%Y%m%d")
      end_date <- as.Date(as.character(data[["投与終了日"]]), format = "%Y%m%d")

      # 有効な日付ペアのみ計算
      duration_days <- as.numeric(difftime(end_date, start_date, units = "days"))
      duration_days[duration_days < 0 | is.na(duration_days)] <- NA

      data[["投与期間_日数"]] <- duration_days

      # predictor に追加（まだ含まれていない場合）
      if (!("投与期間_日数" %in% xs)) {
        xs <- c(xs, "投与期間_日数")
        cat("ℹ️  [logistic_regression] 投与期間（日数）を自動計算して predictor に追加しました\n")
      }

      # 元の日付列を削除（数値化されると意味不明な値になるため）
      xs <- setdiff(xs, c("投与開始日", "投与終了日"))
      cat("ℹ️  [logistic_regression] 元の日付列（投与開始日、投与終了日）を predictor から削除しました\n")
    }, error = function(e) {
      cat("⚠️  [logistic_regression] 投与期間の計算に失敗しました:", e$message, "\n")
      # エラー時も日付列を削除
      xs <- setdiff(xs, c("投与開始日", "投与終了日"))
    })
  } else {
    # 投与開始日か投与終了日がない場合も、あれば日付列を削除
    xs <- setdiff(xs, c("投与開始日", "投与終了日"))
  }

  if (length(xs) < 1) stop("logistic_regression は x を1つ以上指定してください")

  # ---- column existence ----
  for (cname in c(ycol, xs)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(ycol, xs), drop = FALSE]

  # ---- y normalization (0/1, TRUE/FALSE, 2-level factor/character) ----
  yv <- df[[ycol]]

  if (is.factor(yv)) yv <- as.character(yv)
  if (is.logical(yv)) yv <- ifelse(yv, 1, 0)

  if (is.character(yv)) {

    v <- tolower(trimws(yv))
    v[v %in% c("t","true","yes","y","1")] <- "1"
    v[v %in% c("f","false","no","n","0")] <- "0"

    u <- unique(v[!is.na(v) & nzchar(v)])

    # ---- 特殊ケース：医薬品の処置 ----
    # 複数の値がある場合、「投与中止」を1に二値化
    if (ycol == "医薬品の処置" && length(u) > 2) {
      cat("ℹ️  [logistic_regression] 医薬品の処置を二値化: '投与中止' = 1, その他 = 0\n")
      ybin <- ifelse(tolower(trimws(yv)) == "投与中止", 1, 0)
      ybin[is.na(yv) | !nzchar(trimws(yv))] <- NA  # 元々NAの行はNAのまま
      df[[ycol]] <- ybin
    } else if (length(u) != 2) {
      # その他のカテゴリ変数が2値でない場合
      stop(paste0("y は2水準（2値）の列である必要があります。現在の値: ", paste(u, collapse=", ")))
    } else {
      # 通常の2値カテゴリ変数：sort(u)[2] を 1 に
      ybin <- ifelse(v == sort(u)[2], 1, 0)
      df[[ycol]] <- ybin
    }

  } else {

    suppressWarnings(yv_num <- as.numeric(yv))

    if (!all(yv_num %in% c(0,1), na.rm = TRUE)) {
      stop("y は 0/1 または2水準factor/characterである必要があります")
    }

    df[[ycol]] <- yv_num
  }

  # ---- x numeric coercion (with categorical variable support) ----
  for (nm in xs) {

    if (!is.numeric(df[[nm]])) {

      x0 <- df[[nm]]

      # Try numeric conversion first (for date/time strings, numbers with commas)
      suppressWarnings(
        x_numeric <- as.numeric(gsub(",", "", as.character(df[[nm]])))
      )

      # If numeric conversion fails, try factor conversion (for categorical variables)
      if (all(is.na(x_numeric)) && any(!is.na(x0))) {
        cat(sprintf("ℹ️  [logistic_regression] Converting categorical variable '%s' to numeric via factorization\n", nm))
        df[[nm]] <- as.numeric(as.factor(df[[nm]]))
      } else {
        df[[nm]] <- x_numeric
      }
    }
  }

  # ---- complete cases ----
  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (nrow(df) < 5) stop("有効データが少なすぎます")

  # ---- formula ----
  fml <- stats::as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))

  fit <- stats::glm(
    fml,
    data = df,
    family = stats::binomial()
  )

  sm <- summary(fit)

  coef_mat <- sm$coefficients
  if (is.null(coef_mat) || nrow(coef_mat) < 1) {
    stop("glm coefficients not available")
  }

  coefs0 <- as.data.frame(coef_mat)
  coefs0$term <- rownames(coef_mat)
  rownames(coefs0) <- NULL

  cn <- colnames(coefs0)

  est_col <- cn[grepl("^Estimate", cn)][1]
  se_col  <- cn[grepl("Std", cn)][1]
  z_col   <- cn[grepl("z", cn, ignore.case = TRUE)][1]
  p_col   <- cn[grepl("Pr", cn)][1]

  if (is.na(est_col) || is.na(se_col) || is.na(z_col) || is.na(p_col)) {
    stop("glm coefficient columns not found (Estimate/Std/z/Pr)")
  }

  coefs <- data.frame(
    term = coefs0$term,
    estimate_logit = as.numeric(coefs0[[est_col]]),
    std_error      = as.numeric(coefs0[[se_col]]),
    z_value        = as.numeric(coefs0[[z_col]]),
    p_value        = as.numeric(coefs0[[p_col]]),
    stringsAsFactors = FALSE
  )

  est <- coefs$estimate_logit
  se  <- coefs$std_error

  coefs$odds_ratio <- exp(est)
  coefs$conf_low   <- exp(est - 1.96 * se)
  coefs$conf_high  <- exp(est + 1.96 * se)

  coefs <- coefs[, c(
    "term",
    "odds_ratio",
    "conf_low",
    "conf_high",
    "p_value",
    "estimate_logit",
    "std_error"
  )]

  metrics <- data.frame(
    n_used = nrow(df),
    aic = unname(stats::AIC(fit)),
    stringsAsFactors = FALSE
  )

  # ---- Forest plot (ggplot2版 - 日本語対応) ----
  warnings_out <- list()
  forest_file <- NULL

  # Try to generate forest plot using ggplot2 + ggsave
  # This version supports Japanese text rendering
  if (exists("make_forest_plot", mode = "function")) {

    forest_file <- tryCatch({

      make_forest_plot(
        coefs,
        est_col = "odds_ratio",
        low_col = "conf_low",
        high_col = "conf_high",
        label_col = "term",
        ref_line = 1,
        title = "Odds Ratio Forest Plot"
      )

    }, error = function(e) {
      cat("⚠️  [logistic_regression] Forest plot 生成に失敗:", e$message, "\n")
      return(NULL)
    })

  }

  # Add warning if forest plot could not be generated
  if (is.null(forest_file)) {
    warnings_out <- c(warnings_out, list(list(
      code = "FOREST_PLOT_UNAVAILABLE",
      severity = "info",
      message = "Forest plot は生成できませんでした。統計値テーブルでご確認ください。"
    )))
  }

  # ---- headline metric ----
  pmin <- suppressWarnings(
    min(coefs$p_value[coefs$term != "(Intercept)"], na.rm = TRUE)
  )
  if (is.infinite(pmin)) pmin <- NA_real_

  # ---- possible separation warning ----
  if (any(abs(coefs$estimate_logit) > 10, na.rm = TRUE)) {
    warnings_out <- c(warnings_out, list(list(
      code = "POSSIBLE_SEPARATION",
      severity = "info",
      message = "完全分離の可能性があります（係数が極端に大きい）"
    )))
  }

  # ---- return ----
  list(
    summary = list(
      headline = paste0("ロジスティック回帰: 最小p = ", signif(pmin, 3)),
      method_used = "glm(binomial)",
      key_metrics = list(
        aic = unname(stats::AIC(fit)),
        min_p_predictors = unname(pmin),
        n_used = nrow(df)
      ),
      interpretation_notes = list(
        "ORは『1単位増加あたりのオッズ比』です（カテゴリは基準に対する比）。",
        "イベント数が少ない場合は過学習に注意してください。"
      )
    ),
    tables = list(
      list(id = "model_metrics", title = "モデル指標", data = metrics),
      list(id = "odds_ratios", title = "オッズ比（OR）", data = coefs)
    ),
    figures = if (!is.null(forest_file)) list(
      list(
        id = "forest",
        title = "Odds Ratio Forest Plot",
        type = "forest_plot",
        path = forest_file
      )
    ) else list(),
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl

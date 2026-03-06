# recipes/logistic_regression.R

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

    if (length(u) != 2) stop("y は2水準（2値）の列である必要があります")

    # 安定化：sort(u)[2] を 1 に
    ybin <- ifelse(v == sort(u)[2], 1, 0)

    df[[ycol]] <- ybin

  } else {

    suppressWarnings(yv_num <- as.numeric(yv))

    if (!all(yv_num %in% c(0,1), na.rm = TRUE)) {
      stop("y は 0/1 または2水準factor/characterである必要があります")
    }

    df[[ycol]] <- yv_num
  }

  # ---- x numeric coercion (NOTE: this will ERROR for categorical predictors) ----
  # If you want to allow categorical x, remove this coercion and let glm handle factors.
  for (nm in xs) {

    if (!is.numeric(df[[nm]])) {

      x0 <- df[[nm]]

      suppressWarnings(
        df[[nm]] <- as.numeric(gsub(",", "", as.character(df[[nm]])))
      )

      if (all(is.na(df[[nm]])) && any(!is.na(x0))) {
        stop(paste0("x column not numeric: ", nm))
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

  # ---- Forest plot (optional) ----
  warnings_out <- list()
  forest_file <- NULL

  if (exists("make_forest_plot", mode = "function")) {
    forest_file <- tryCatch(
      make_forest_plot(
        coefs[coefs$term != "(Intercept)", , drop = FALSE],
        "odds_ratio",
        "conf_low",
        "conf_high",
        "term"
      ),
      error = function(e) {
        warnings_out <<- c(warnings_out, list(list(
          code = "FOREST_PLOT_FAILED",
          severity = "info",
          message = "Forest plot の生成に失敗したためスキップしました。"
        )))
        NULL
      }
    )
  } else {
    warnings_out <- c(warnings_out, list(list(
      code = "FOREST_PLOT_NOT_AVAILABLE",
      severity = "info",
      message = "make_forest_plot が見つからないため Forest plot をスキップしました。"
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
        path = forest_file
      )
    ) else list(),
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
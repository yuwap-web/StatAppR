# recipes/linear_regression.R
# - x は「単一列」を想定（column）
# - ただし request$variables$predictor_column が配列 or "a,b" で来ても検出して丁寧にエラーにする
# - y は数値必須、x は数値 or factor（数値化できなければ factor に逃がす）

# Source plot utilities
tryCatch({
  source(file.path(runner_dir, "utils/plot_utils.R"), local = TRUE)
}, error = function(e) {
  # plot_utils failed to load - continue without plots
})

run_recipe_impl <- function(request, data) {

  ycol <- request$variables$outcome_column
  xraw <- request$variables$predictor_column   # string or array (misconfigured)

  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column が必要です")
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  # ---- x normalization (single column expected) ----
  if (is.null(xraw) || length(xraw) == 0) stop("request$variables$predictor_column が必要です（単一の列）")

  xs <- NULL
  if (is.character(xraw) && length(xraw) == 1) {
    # allow accidental "a,b" too
    xs <- trimws(unlist(strsplit(xraw, ",")))
  } else if (is.character(xraw)) {
    xs <- xraw
  } else if (is.list(xraw)) {
    xs <- unlist(xraw)
  } else {
    xs <- as.character(xraw)
  }
  xs <- trimws(xs)
  xs <- xs[xs != ""]

  if (length(xs) < 1) stop("request$variables$predictor_column の指定が不正です（空）")
  if (length(xs) > 1) {
    stop(paste0(
      "linear_regression は x を1つだけ指定してください（単回帰）。指定: ",
      paste(xs, collapse = ", "),
      "（recipes.json 側で x の type を column にしてください）"
    ))
  }

  xcol <- xs[1]
  if (!(xcol %in% names(data))) stop(paste0("x column not found: ", xcol))

  # ---- build df ----
  df <- data.frame(
    y = data[[ycol]],
    x = data[[xcol]],
    stringsAsFactors = FALSE
  )

  # complete cases
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 3) stop("有効データが少なすぎます（NA除外後）")

  warnings_out <- list()

  # ---- coerce y to numeric (required) ----
  if (!is.numeric(df$y)) {
    y0 <- df$y
    suppressWarnings(df$y <- as.numeric(gsub(",", "", as.character(df$y))))
    if (all(is.na(df$y)) && any(!is.na(y0))) {
      stop("y は数値列である必要があります（数値に変換できません）")
    }
  }

  # ---- coerce x: numeric preferred, else factor ----
  if (!is.numeric(df$x) && !is.factor(df$x)) {
    x0 <- df$x
    suppressWarnings(xn <- as.numeric(gsub(",", "", as.character(df$x))))
    if (all(is.na(xn)) && any(!is.na(x0))) {
      df$x <- as.factor(as.character(x0))
      warnings_out <- c(warnings_out, list(list(
        code = "X_CASTED_TO_FACTOR",
        severity = "info",
        message = "x が数値に変換できなかったため、カテゴリ（factor）として扱いました。"
      )))
    } else {
      df$x <- xn
    }
  }

  # safety: factor levels check
  if (is.factor(df$x)) {
    if (nlevels(df$x) < 2) stop("x（カテゴリ）の水準が1つしかありません（回帰できません）")
    if (nlevels(df$x) > 30) {
      warnings_out <- c(warnings_out, list(list(
        code = "MANY_LEVELS",
        severity = "info",
        message = "x（カテゴリ）の水準が多いため（>30）、解釈や推定が不安定になる可能性があります。"
      )))
    }
  }

  # ---- fit ----
  fit <- stats::lm(y ~ x, data = df)
  sm <- summary(fit)

  coefs <- as.data.frame(sm$coefficients)
  coefs$term <- rownames(coefs)
  rownames(coefs) <- NULL
  names(coefs) <- c("estimate", "std_error", "t_value", "p_value", "term")
  coefs <- coefs[, c("term", "estimate", "std_error", "t_value", "p_value")]

  metrics <- data.frame(
    n_used = nrow(df),
    r_squared = unname(sm$r.squared),
    adj_r_squared = unname(sm$adj.r.squared),
    sigma = unname(sm$sigma),
    stringsAsFactors = FALSE
  )

  # p-value summary:
  # - numeric x: term "x"
  # - factor x: multiple dummy terms -> min p (reference)
  p_slope <- NA_real_
  if ("x" %in% coefs$term) {
    p_slope <- coefs$p_value[coefs$term == "x"][1]
  } else {
    pv <- coefs$p_value[coefs$term != "(Intercept)"]
    if (length(pv) > 0) p_slope <- min(pv, na.rm = TRUE)
  }

  # ---- 図表生成 ----
  figures <- list()

  tryCatch({
    # Create scatter plot with regression line
    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
    if (!dir.exists(results_dir)) {
      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
    }
    plot_file <- file.path(results_dir, sprintf("linear_regression_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

    png(plot_file, width = 800, height = 600)
    plot(df$x, df$y, main = "Linear Regression", xlab = xcol, ylab = ycol, pch = 19)
    abline(fit, col = "red", lwd = 2)
    dev.off()

    if (file.exists(plot_file)) {
      figures <- c(figures, list(list(
        id = "scatter_plot",
        title = "Scatter Plot with Regression Line",
        type = "ggplot2",
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
      headline = paste0("線形回帰（単回帰）: p = ", signif(p_slope, 3)),
      method_used = "最小二乗法（lm）",
      key_metrics = list(
        p_value = unname(p_slope),
        r_squared = unname(sm$r.squared),
        n_used = nrow(df)
      ),
      interpretation_notes = list(
        "線形性・外れ値・残差分布の確認が重要です。",
        "説明変数がカテゴリの場合はダミー化して解釈します（表示pはカテゴリ水準の最小pの参考値）。"
      )
    ),
    tables = list(
      list(id = "model_metrics", title = "モデル指標", data = metrics),
      list(id = "coefficients", title = "回帰係数", data = coefs)
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl

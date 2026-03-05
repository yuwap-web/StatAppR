# recipes/linear_regression.R
run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  xcol <- request$variables$x

  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (is.null(xcol) || xcol == "") stop("variables.x が必要です")
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))
  if (!(xcol %in% names(data))) stop(paste0("x column not found: ", xcol))

  df <- data.frame(y = data[[ycol]], x = data[[xcol]])
  df <- df[!is.na(df$y) & !is.na(df$x), ]

  fit <- stats::lm(y ~ x, data = df)
  sm <- summary(fit)

  coefs <- as.data.frame(sm$coefficients)
  coefs$term <- rownames(coefs)
  rownames(coefs) <- NULL
  names(coefs) <- c("estimate", "std_error", "t_value", "p_value", "term")
  coefs <- coefs[, c("term","estimate","std_error","t_value","p_value")]

  metrics <- data.frame(
    n = nrow(df),
    r_squared = sm$r.squared,
    adj_r_squared = sm$adj.r.squared,
    sigma = sm$sigma,
    stringsAsFactors = FALSE
  )

  p <- coefs$p_value[coefs$term == "x"]

  list(
    summary = list(
      headline = paste0("線形回帰（単回帰）: p = ", signif(p, 3)),
      method_used = "最小二乗法（lm）",
      key_metrics = list(
        list(name="p_value_slope", value = unname(p)),
        list(name="r_squared", value = unname(sm$r.squared))
      ),
      interpretation_notes = list(
        "線形性・外れ値・残差分布の確認が重要です。",
        "説明変数がカテゴリの場合はダミー化して解釈します。"
      )
    ),
    tables = list(
      list(id="model_metrics", title="モデル指標", data=metrics),
      list(id="coefficients", title="回帰係数", data=coefs)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
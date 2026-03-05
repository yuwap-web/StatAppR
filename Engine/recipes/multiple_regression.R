# recipes/multiple_regression.R
run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  xcols <- request$variables$x  # comma-separated e.g. "age,bmi,sex"

  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (is.null(xcols) || xcols == "") stop("variables.x（カンマ区切り）が必要です")

  xs <- trimws(unlist(strsplit(xcols, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 2) stop("multiple_regression は x を2つ以上指定してください（例: age,bmi,sex）")

  for (cname in c(ycol, xs)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(ycol, xs), drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]

  fml <- stats::as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))
  fit <- stats::lm(fml, data = df)
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

  list(
    summary = list(
      headline = paste0("重回帰: adj R² = ", signif(sm$adj.r.squared, 3)),
      method_used = "最小二乗法（lm）",
      key_metrics = list(
        list(name="adj_r_squared", value = unname(sm$adj.r.squared)),
        list(name="r_squared", value = unname(sm$r.squared))
      ),
      interpretation_notes = list(
        "多重共線性（VIF）や外れ値の影響に注意してください。",
        "カテゴリ変数は自動的にダミー化されます。"
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
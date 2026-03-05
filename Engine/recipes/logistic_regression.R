# recipes/logistic_regression.R
run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  xcols <- request$variables$x  # comma-separated

  if (is.null(ycol) || ycol == "") stop("variables.y（2値目的変数）が必要です")
  if (is.null(xcols) || xcols == "") stop("variables.x（カンマ区切り）が必要です")

  xs <- trimws(unlist(strsplit(xcols, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 1) stop("logistic_regression は x を1つ以上指定してください")

  for (cname in c(ycol, xs)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(ycol, xs), drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]

  # y must be 0/1 or 2-level factor
  yv <- df[[ycol]]
  if (is.factor(yv)) {
    if (nlevels(yv) != 2) stop("y は2水準のfactor か 0/1 の数値である必要があります")
  } else {
    uy <- sort(unique(yv))
    if (!all(uy %in% c(0,1))) stop("y は 0/1 を推奨します（factorでも可）")
  }

  fml <- stats::as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))
  fit <- stats::glm(fml, data = df, family = stats::binomial())
  sm <- summary(fit)

  coefs <- as.data.frame(sm$coefficients)
  coefs$term <- rownames(coefs)
  rownames(coefs) <- NULL
  names(coefs) <- c("estimate_logit", "std_error", "z_value", "p_value", "term")

  # OR + CI
  est <- coefs$estimate_logit
  se <- coefs$std_error
  coefs$odds_ratio <- exp(est)
  coefs$conf_low <- exp(est - 1.96*se)
  coefs$conf_high <- exp(est + 1.96*se)
  coefs <- coefs[, c("term","odds_ratio","conf_low","conf_high","p_value","estimate_logit","std_error")]

  metrics <- data.frame(
    n = nrow(df),
    aic = stats::AIC(fit),
    stringsAsFactors = FALSE
  )

  # headline: best p among predictors
  pmin <- min(coefs$p_value[coefs$term != "(Intercept)"], na.rm = TRUE)

  list(
    summary = list(
      headline = paste0("ロジスティック回帰: 最小p = ", signif(pmin, 3)),
      method_used = "glm(binomial)",
      key_metrics = list(
        list(name="aic", value = unname(stats::AIC(fit))),
        list(name="min_p_predictors", value = unname(pmin))
      ),
      interpretation_notes = list(
        "ORは『1単位増加あたりのオッズ比』です（カテゴリは基準に対する比）。",
        "イベント数が少ない場合は過学習に注意してください。"
      )
    ),
    tables = list(
      list(id="model_metrics", title="モデル指標", data=metrics),
      list(id="odds_ratios", title="オッズ比（OR）", data=coefs)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
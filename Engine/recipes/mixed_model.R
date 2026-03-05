# recipes/mixed_model.R
run_recipe_impl <- function(request, data) {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("nlme パッケージが見つかりません（mixed_model を使うには nlme が必要です）")
  }

  ycol <- request$variables$y
  xcols <- request$variables$x  # comma-separated fixed effects (optional)
  gcol <- request$variables$group # random intercept group

  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (is.null(gcol) || gcol == "") stop("variables.group（ランダム切片の群）が必要です")
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))
  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))

  xs <- character(0)
  if (!is.null(xcols) && xcols != "") {
    xs <- trimws(unlist(strsplit(xcols, ",")))
    xs <- xs[xs != ""]
    for (cname in xs) if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  cols <- unique(c(ycol, gcol, xs))
  df <- data[, cols, drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]
  df[[gcol]] <- as.factor(df[[gcol]])

  fixed <- if (length(xs) == 0) {
    stats::as.formula(paste0(ycol, " ~ 1"))
  } else {
    stats::as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))
  }
  random <- stats::as.formula(paste0("~ 1 | ", gcol))

  fit <- nlme::lme(fixed = fixed, random = random, data = df, method = "REML")
  sm <- summary(fit)

  # fixed effects table
  fe <- as.data.frame(sm$tTable)
  fe$term <- rownames(fe)
  rownames(fe) <- NULL
  names(fe) <- c("estimate","std_error","df","t_value","p_value","term")
  fe <- fe[, c("term","estimate","std_error","df","t_value","p_value")]

  # random effects SD
  vc <- nlme::VarCorr(fit)
  vc_df <- data.frame(component = rownames(vc), value = vc[, "StdDev"], row.names = NULL)

  metrics <- data.frame(
    n = nrow(df),
    aic = stats::AIC(fit),
    bic = stats::BIC(fit),
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = "混合効果モデル（ランダム切片）を推定しました",
      method_used = "nlme::lme（REML）",
      key_metrics = list(list(name="aic", value=unname(stats::AIC(fit)))),
      interpretation_notes = list(
        "ランダム切片の分散が大きい場合、群（施設等）によるばらつきが大きい可能性があります。",
        "固定効果の解釈は共変量調整後の平均差として行います。"
      )
    ),
    tables = list(
      list(id="model_metrics", title="モデル指標", data=metrics),
      list(id="fixed_effects", title="固定効果", data=fe),
      list(id="random_effects", title="ランダム効果（SD）", data=vc_df)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
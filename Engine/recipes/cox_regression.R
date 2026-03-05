# recipes/cox_regression.R
run_recipe_impl <- function(request, data) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが見つかりません（cox_regression には survival が必要です）")
  }

  time_col <- request$variables$time
  status_col <- request$variables$status
  xcols <- request$variables$x  # comma-separated covariates

  if (is.null(time_col) || time_col=="") stop("variables.time が必要です")
  if (is.null(status_col) || status_col=="") stop("variables.status が必要です")
  if (is.null(xcols) || xcols=="") stop("variables.x（共変量; カンマ区切り）が必要です")

  xs <- trimws(unlist(strsplit(xcols, ",")))
  xs <- xs[xs != ""]
  for (cname in c(time_col, status_col, xs)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(time_col, status_col, xs), drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]

  fml <- stats::as.formula(paste0("survival::Surv(", time_col, ",", status_col, ") ~ ", paste(xs, collapse=" + ")))
  fit <- survival::coxph(fml, data = df)
  sm <- summary(fit)

  co <- as.data.frame(sm$coefficients)
  co$term <- rownames(co)
  rownames(co) <- NULL

  # coefficients includes exp(coef) etc
  out <- data.frame(
    term = co$term,
    hazard_ratio = co$`exp(coef)`,
    conf_low = sm$conf.int[, "lower .95"],
    conf_high = sm$conf.int[, "upper .95"],
    p_value = co$`Pr(>|z|)`,
    stringsAsFactors = FALSE
  )

  metrics <- data.frame(
    n = nrow(df),
    concordance = sm$concordance[1],
    stringsAsFactors = FALSE
  )

  pmin <- min(out$p_value, na.rm = TRUE)

  list(
    summary = list(
      headline = paste0("Cox回帰: 最小p = ", signif(pmin, 3)),
      method_used = "survival::coxph",
      key_metrics = list(
        list(name="concordance", value=unname(sm$concordance[1])),
        list(name="min_p", value=unname(pmin))
      ),
      interpretation_notes = list(
        "HR>1 はハザード増加、HR<1 はハザード減少を意味します。",
        "比例ハザード性の検討（cox.zph）も必要です。"
      )
    ),
    tables = list(
      list(id="model_metrics", title="モデル指標", data=metrics),
      list(id="hazard_ratios", title="ハザード比（HR）", data=out)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
# recipes/iptw_ate.R
# runner expects: run_recipe_impl(request, data) OR run(request, data)

run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  trt  <- request$variables$treatment
  xraw <- request$variables$x

  if (is.null(ycol) || ycol == "") stop("y variable not specified")
  if (is.null(trt)  || trt  == "") stop("treatment variable not specified")
  if (is.null(xraw) || xraw == "") stop("x (covariates) not specified (comma-separated)")

  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))
  if (!(trt  %in% names(data))) stop(paste0("treatment column not found: ", trt))

  xs <- trimws(unlist(strsplit(xraw, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 1) stop("x (covariates) parse failed")
  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("covariate columns not found: ", paste(miss, collapse = ", ")))

  # treatment must be 0/1 or 2-level
  tvec <- data[[trt]]
  if (is.factor(tvec)) tvec <- as.character(tvec)
  if (is.character(tvec)) {
    u <- unique(tvec)
    if (length(u) != 2) stop("treatment must have exactly 2 levels")
    tvec <- ifelse(tvec == u[2], 1, 0)
  }
  tvec <- as.numeric(tvec)
  if (!all(tvec %in% c(0,1))) stop("treatment must be 0/1 (or 2-level factor/character)")

  f_ps <- as.formula(paste0(trt, " ~ ", paste(xs, collapse = " + ")))
  ps_fit <- glm(f_ps, data = data, family = binomial())

  ps <- as.numeric(predict(ps_fit, type = "response"))
  eps <- 1e-6
  ps <- pmin(pmax(ps, eps), 1 - eps)

  w <- ifelse(tvec == 1, 1/ps, 1/(1-ps))

  # Weighted outcome model (ATE)
  f_out <- as.formula(paste0(ycol, " ~ ", trt))
  out_fit <- lm(f_out, data = data, weights = w)
  sm <- summary(out_fit)

  est <- coef(sm)[2,1]
  se  <- coef(sm)[2,2]
  p   <- coef(sm)[2,4]
  ciL <- est - 1.96*se
  ciH <- est + 1.96*se

  tbl <- data.frame(
    estimand = "ATE",
    estimate = est,
    std_error = se,
    conf_low = ciL,
    conf_high = ciH,
    p_value = p,
    n = nrow(data),
    stringsAsFactors = FALSE
  )

  wsum <- data.frame(
    weight_min = min(w),
    weight_p01 = unname(quantile(w, 0.01)),
    weight_median = unname(median(w)),
    weight_mean = unname(mean(w)),
    weight_p99 = unname(quantile(w, 0.99)),
    weight_max = max(w),
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = paste0("IPTW（ATE）: p = ", signif(p, 3)),
      method_used = "IPTW + weighted linear regression",
      key_metrics = list(
        list(name="estimate", value=est),
        list(name="p_value", value=p)
      ),
      interpretation_notes = list(
        "重みが極端（最大が大きい）場合はトリミング等を検討してください。",
        "共変量バランス評価（SMD）も本来は必要です。"
      )
    ),
    tables = list(
      iptw_ate = tbl,
      weight_summary = wsum
    ),
    figures = list()
  )
}

run <- run_recipe_impl
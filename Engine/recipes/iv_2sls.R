# recipes/iv_2sls.R
run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  trt  <- request$variables$treatment
  zcol <- request$variables$z
  xraw <- request$variables$x %||% ""

  if (is.null(ycol) || ycol == "") stop("y variable not specified")
  if (is.null(trt)  || trt  == "") stop("treatment variable not specified")
  if (is.null(zcol) || zcol == "") stop("z (instrument) not specified")

  need <- c(ycol, trt, zcol)
  miss0 <- need[!(need %in% names(data))]
  if (length(miss0) > 0) stop(paste0("columns not found: ", paste(miss0, collapse = ", ")))

  xs <- trimws(unlist(strsplit(xraw, ",")))
  xs <- xs[xs != ""]
  if (length(xs) > 0) {
    miss <- xs[!(xs %in% names(data))]
    if (length(miss) > 0) stop(paste0("covariate columns not found: ", paste(miss, collapse = ", ")))
  }

  if (!requireNamespace("AER", quietly = TRUE)) {
    stop("Package 'AER' is required for ivreg. Install it in your R environment.")
  }

  rhs1 <- paste(c(trt, xs), collapse = " + ")
  rhs2 <- paste(c(zcol, xs), collapse = " + ")
  f <- as.formula(paste0(ycol, " ~ ", rhs1, " | ", rhs2))

  fit <- AER::ivreg(f, data = data)
  sm  <- summary(fit, diagnostics = TRUE)

  # Main effect row
  co <- sm$coefficients
  if (!(trt %in% rownames(co))) stop("treatment term not found in ivreg coefficients")

  est <- co[trt, 1]
  se  <- co[trt, 2]
  p   <- co[trt, 4]
  ciL <- est - 1.96*se
  ciH <- est + 1.96*se

  main_tbl <- data.frame(
    estimate = est,
    std_error = se,
    conf_low = ciL,
    conf_high = ciH,
    p_value = p,
    stringsAsFactors = FALSE
  )

  diag_tbl <- data.frame()
  if (!is.null(sm$diagnostics)) {
    d <- sm$diagnostics
    diag_tbl <- data.frame(
      test = rownames(d),
      statistic = d[,1],
      p_value = d[,4],
      stringsAsFactors = FALSE
    )
    rownames(diag_tbl) <- NULL
  }

  list(
    summary = list(
      headline = paste0("IV（2SLS）: p = ", signif(p, 3)),
      method_used = "AER::ivreg (2SLS)",
      key_metrics = list(
        list(name="estimate", value=est),
        list(name="p_value", value=p)
      ),
      interpretation_notes = list(
        "weak instrument（弱い操作変数）の場合、推定が不安定になります。diagnosticsを確認してください。",
        "IVの前提（排除制約等）はデータだけでは検証できません。"
      )
    ),
    tables = list(
      iv_effect = main_tbl,
      iv_diagnostics = diag_tbl
    ),
    figures = list()
  )
}
run <- run_recipe_impl
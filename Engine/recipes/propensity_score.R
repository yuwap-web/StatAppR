# recipes/propensity_score.R
run_recipe_impl <- function(request, data) {
  trt  <- request$variables$treatment
  xraw <- request$variables$x

  if (is.null(trt)  || trt  == "") stop("treatment variable not specified")
  if (is.null(xraw) || xraw == "") stop("x (covariates) not specified (comma-separated)")
  if (!(trt %in% names(data))) stop(paste0("treatment column not found: ", trt))

  xs <- trimws(unlist(strsplit(xraw, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 1) stop("x (covariates) parse failed")
  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("covariate columns not found: ", paste(miss, collapse = ", ")))

  f_ps <- as.formula(paste0(trt, " ~ ", paste(xs, collapse = " + ")))
  ps_fit <- glm(f_ps, data = data, family = binomial())

  ps <- as.numeric(predict(ps_fit, type = "response"))

  tbl <- data.frame(
    ps = ps,
    treatment = data[[trt]],
    stringsAsFactors = FALSE
  )

  s <- summary(ps_fit)
  coef_tbl <- as.data.frame(s$coefficients)
  coef_tbl$term <- rownames(coef_tbl)
  rownames(coef_tbl) <- NULL
  coef_tbl <- coef_tbl[, c("term", "Estimate", "Std. Error", "z value", "Pr(>|z|)")]

  list(
    summary = list(
      headline = "傾向スコア（PS）推定が完了しました。",
      method_used = "Logistic regression (glm binomial)",
      key_metrics = list(
        list(name="n", value=nrow(data))
      ),
      interpretation_notes = list(
        "PSの重なり（overlap）が弱い場合、因果推論の前提が厳しくなります。"
      )
    ),
    tables = list(
      ps_values = tbl,
      ps_model_coef = coef_tbl
    ),
    figures = list()
  )
}
run <- run_recipe_impl
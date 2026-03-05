# recipes/pls_regression.R
run_recipe_impl <- function(request, data) {
  ycol <- request$variables$y
  xraw <- request$variables$x

  if (is.null(ycol) || ycol == "") stop("y not specified")
  if (is.null(xraw) || xraw == "") stop("x (comma-separated) not specified")
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  xs <- trimws(unlist(strsplit(xraw, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 2) stop("PLS requires at least 2 x columns")

  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("x columns not found: ", paste(miss, collapse = ", ")))

  if (!requireNamespace("pls", quietly = TRUE)) {
    stop("Package 'pls' is required. Install it in your R environment.")
  }

  df <- data[, c(ycol, xs), drop = FALSE]
  df <- stats::na.omit(df)
  if (nrow(df) < 10) stop("Not enough complete rows for PLS")

  f <- as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))
  fit <- pls::plsr(f, data = df, validation = "CV", scale = TRUE)

  # Choose ncomp by min RMSEP
  rm <- pls::RMSEP(fit)
  vals <- as.numeric(rm$val[1,1,])
  ncomp <- which.min(vals) - 1
  if (ncomp < 1) ncomp <- 1

  coefs <- as.vector(pls::coef(fit, ncomp = ncomp))
  coef_tbl <- data.frame(
    term = xs,
    coefficient = coefs,
    stringsAsFactors = FALSE
  )

  perf <- data.frame(
    ncomp = seq_along(vals) - 1,
    rmsep = vals,
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = paste0("PLS完了：選択成分数=", ncomp),
      method_used = "pls::plsr (CV)",
      key_metrics = list(
        list(name="ncomp", value=ncomp),
        list(name="rmsep_min", value=min(vals))
      ),
      interpretation_notes = list(
        "PLSは多重共線性に強い一方、解釈は回帰より難しくなります。",
        "外部検証があるならCVだけでなくホールドアウトも推奨です。"
      )
    ),
    tables = list(
      pls_coefficients = coef_tbl,
      pls_rmsep = perf
    ),
    figures = list()
  )
}
run <- run_recipe_impl
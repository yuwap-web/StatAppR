# recipes/instrumental_variable.R
# Instrumental Variable regression (2SLS)

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  # Check if AER package is available; otherwise use manual 2SLS fallback
  use_fallback <- !requireNamespace("AER", quietly = TRUE)
  fallback_warning <- NULL

  y_col <- request$variables$y
  d_col <- request$variables$treatment
  z_col <- request$variables$instrument
  xraw  <- request$variables$x %||% NULL

  if (is.null(y_col) || y_col == "") stop("variables.y が必要です")
  if (is.null(d_col) || d_col == "") stop("variables.treatment が必要です")
  if (is.null(z_col) || z_col == "") stop("variables.instrument が必要です")

  for (cname in c(y_col, d_col, z_col)) {
    if (!(cname %in% names(data))) {
      stop(paste0("column not found: ", cname))
    }
  }

  # ---- normalize X ----

  xvars <- c()

  if (!is.null(xraw)) {

    if (is.character(xraw) && length(xraw) == 1) {
      xvars <- trimws(unlist(strsplit(xraw, ",")))
    } else if (is.character(xraw)) {
      xvars <- xraw
    } else if (is.list(xraw)) {
      xvars <- unlist(xraw)
    } else {
      xvars <- as.character(xraw)
    }

    xvars <- trimws(xvars)
    xvars <- xvars[xvars != ""]
  }

  xvars <- setdiff(xvars, c(y_col, d_col, z_col))

  for (cname in xvars) {
    if (!(cname %in% names(data))) {
      stop(paste0("column not found: ", cname))
    }
  }

  cols <- unique(c(y_col, d_col, z_col, xvars))

  df <- data[, cols, drop = FALSE]

  # ---- numeric coercion ----

  num_cast <- function(v) {
    if (is.numeric(v)) return(v)
    suppressWarnings(as.numeric(gsub(",", "", as.character(v))))
  }

  for (c in cols) {
    df[[c]] <- num_cast(df[[c]])
  }

  df <- df[stats::complete.cases(df), , drop = FALSE]

  n <- nrow(df)

  if (n < 20) {
    stop("データが少なすぎます（IV推定には最低20以上推奨）")
  }

  # ---- build formula ----

  x_part <- if (length(xvars) > 0) paste(xvars, collapse=" + ") else "1"

  fml <- stats::as.formula(
    paste0(
      y_col,
      " ~ ",
      d_col,
      if (length(xvars)>0) paste0(" + ", x_part) else "",
      " | ",
      z_col,
      if (length(xvars)>0) paste0(" + ", x_part) else ""
    )
  )

  # ---- IV regression ----

  if (!use_fallback) {
    # ✅ AER: IV regression (primary method)
    fit <- AER::ivreg(fml, data=df)
    sm <- summary(fit, diagnostics=TRUE)
    coef_mat <- sm$coefficients

    if (!(d_col %in% rownames(coef_mat))) {
      stop("treatment係数が見つかりません")
    }

    est <- coef_mat[d_col,"Estimate"]
    se  <- coef_mat[d_col,"Std. Error"]
    p   <- coef_mat[d_col,"Pr(>|t|)"]

    # First stage (from AER summary)
    fs_fit <- NULL
    fs_sm <- NULL

  } else {
    # ⚠️ FALLBACK: Manual 2SLS implementation
    fallback_warning <- list(
      code = "IV_FALLBACK_MANUAL2SLS",
      severity = "warning",
      message = paste0(
        "AER package not available. Using manual 2SLS implementation as fallback.\\n",
        "For best results, install AER package: install.packages('AER')"
      )
    )

    # First stage: instrument → treatment
    x_part <- if (length(xvars) > 0) paste(xvars, collapse=" + ") else "1"
    fs_fml <- stats::as.formula(
      paste0(d_col, " ~ ", z_col, if (length(xvars)>0) paste0(" + ", x_part) else "")
    )
    fs_fit <- stats::lm(fs_fml, data=df)
    fs_sm <- summary(fs_fit)

    # Get predicted treatment
    df$d_pred <- predict(fs_fit)

    # Second stage: predicted treatment → outcome
    ss_fml <- stats::as.formula(
      paste0(y_col, " ~ d_pred", if (length(xvars)>0) paste0(" + ", x_part) else "")
    )
    ss_fit <- stats::lm(ss_fml, data=df)
    ss_sm <- summary(ss_fit)

    # Extract treatment effect from second stage
    ss_coef <- ss_sm$coefficients
    if (!("d_pred" %in% rownames(ss_coef))) {
      stop("treatment coefficient not found in second stage")
    }

    est <- ss_coef["d_pred", "Estimate"]
    se  <- ss_coef["d_pred", "Std. Error"]
    p   <- ss_coef["d_pred", "Pr(>|t|)"]

    # Create mock sm object for diagnostics extraction below
    sm <- list()
    sm$coefficients <- data.frame(
      Estimate = est,
      "Std. Error" = se,
      "t value" = est/se,
      "Pr(>|t|)" = p,
      row.names = d_col
    )
    sm$diagnostics <- NULL
  }

  ci_low  <- est - 1.96*se
  ci_high <- est + 1.96*se

  effect_tbl <- data.frame(
    estimate = est,
    conf_low = ci_low,
    conf_high = ci_high,
    p_value = p,
    n = n,
    stringsAsFactors = FALSE
  )

  # ---- diagnostics ----

  diag_tbl <- data.frame()

  if (!is.null(sm$diagnostics)) {

    d <- sm$diagnostics

    diag_tbl <- data.frame(
      test = rownames(d),
      statistic = d[,"statistic"],
      p_value = d[,"p-value"],
      stringsAsFactors = FALSE
    )

  } else if (use_fallback && !is.null(fs_fit)) {
    # For manual 2SLS fallback, use first-stage F statistic as main diagnostic
    fs_r2 <- summary(fs_fit)$r.squared
    fs_f <- (fs_r2 / (1 - fs_r2)) * (nrow(df) - length(coefficients(fs_fit)))

    diag_tbl <- data.frame(
      test = c("First Stage F-stat"),
      statistic = fs_f,
      p_value = 1 - stats::pf(fs_f, 1, nrow(df) - 2),
      stringsAsFactors = FALSE
    )
  }

  # ---- first stage (already computed in fallback, skip if already done) ----

  if (is.null(fs_fit)) {
    x_part <- if (length(xvars) > 0) paste(xvars, collapse=" + ") else "1"
    fs_fml <- stats::as.formula(
      paste0(
        d_col,
        " ~ ",
        z_col,
        if (length(xvars)>0) paste0(" + ", x_part) else ""
      )
    )

    fs_fit <- stats::lm(fs_fml, data=df)
    fs_sm <- summary(fs_fit)
  } else {
    fs_sm <- summary(fs_fit)
  }

  fs_coef <- as.data.frame(fs_sm$coefficients)

  fs_coef$term <- rownames(fs_coef)

  rownames(fs_coef) <- NULL

  names(fs_coef) <- c(
    "estimate",
    "std_error",
    "t_value",
    "p_value",
    "term"
  )

  headline <- paste0(
    "Instrumental Variable (2SLS): ",
    signif(est,3),
    " (p=",
    signif(p,3),
    ")"
  )

  method_label <- if (use_fallback) "Manual 2SLS (fallback)" else "Two Stage Least Squares (IV)"

  warnings_out <- list()

  if (!is.null(fallback_warning)) {
    warnings_out <- c(warnings_out, list(fallback_warning))
  }

  if (n < 50) {

    warnings_out <- c(
      warnings_out,
      list(list(
        code="SMALL_SAMPLE",
        severity="info",
        message="サンプルサイズが小さい可能性があります"
      ))
    )

  }

  list(
    summary=list(
      headline=headline,
      method_used=method_label,
      key_metrics=list(
        estimate=est,
        p_value=p,
        n=n
      ),
      interpretation_notes=list(
        "IVは外生的なinstrumentが必要です",
        "weak instrumentの可能性はfirst stage F統計で確認してください"
      )
    ),
    tables=list(
      list(
        id="iv_effect",
        title="IV 推定",
        data=effect_tbl
      ),
      list(
        id="first_stage",
        title="First Stage",
        data=fs_coef
      ),
      list(
        id="diagnostics",
        title="Diagnostics",
        data=diag_tbl
      )
    ),
    figures=list(),
    warnings=warnings_out
  )

}

run <- run_recipe_impl
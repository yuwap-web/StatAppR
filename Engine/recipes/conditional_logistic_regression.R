# recipes/conditional_logistic_regression.R
# Conditional logistic regression (survival::clogit)
# For matched case-control studies

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  # Ensure survival package is available
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが必要です（conditional logistic regression 用）")
  }
  library(survival)

  ycol     <- request$variables$outcome_column
  stratumcol <- request$variables$matchset_column
  exposurecol <- request$variables$exposure
  xraw     <- request$variables$covariates

  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column（アウトカム 0/1）が必要です")
  if (is.null(stratumcol) || stratumcol == "") stop("request$variables$matchset_column（マッチング層）が必要です")
  if (is.null(exposurecol) || exposurecol == "") stop("variables.exposure（曝露変数）が必要です")

  # ---- x normalization (array or "a,b") ----
  xs <- character(0)
  if (!is.null(xraw) && length(xraw) > 0) {
    if (is.character(xraw) && length(xraw) == 1) {
      xs <- trimws(unlist(strsplit(xraw, ",")))
    } else if (is.character(xraw)) {
      xs <- xraw
    } else if (is.list(xraw)) {
      xs <- unlist(xraw)
    } else {
      xs <- as.character(xraw)
    }
  }
  xs <- trimws(xs)
  xs <- xs[xs != ""]

  # ---- column existence ----
  reqcols <- c(ycol, stratumcol, exposurecol, xs)
  for (cname in reqcols) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  # ---- prepare data frame ----
  df <- data[, reqcols, drop = FALSE]

  # ---- y normalization (0/1) ----
  yv <- df[[ycol]]
  if (is.factor(yv)) yv <- as.character(yv)
  if (is.logical(yv)) yv <- ifelse(yv, 1, 0)

  if (is.character(yv)) {
    v <- tolower(trimws(yv))
    v[v %in% c("t","true","yes","y","1")] <- "1"
    v[v %in% c("f","false","no","n","0")] <- "0"
    u <- unique(v[!is.na(v) & nzchar(v)])
    if (length(u) != 2) stop("y は 0/1 の2水準である必要があります")
    ybin <- ifelse(v == sort(u)[2], 1, 0)
    df[[ycol]] <- ybin
  } else {
    suppressWarnings(yv_num <- as.numeric(yv))
    if (!all(yv_num %in% c(0,1), na.rm = TRUE)) {
      stop("y は 0/1 である必要があります")
    }
    df[[ycol]] <- yv_num
  }

  # ---- build formula ----
  # clogit uses outcome ~ predictors + strata(stratum)
  # The outcome should be binary (0/1)

  if (length(xs) > 0) {
    formula_str <- paste0(ycol, " ~ ", exposurecol, " + ", paste(xs, collapse = " + "), " + strata(", stratumcol, ")")
  } else {
    formula_str <- paste0(ycol, " ~ ", exposurecol, " + strata(", stratumcol, ")")
  }

  # ---- fit conditional logistic model ----
  model <- tryCatch({
    survival::clogit(as.formula(formula_str), data = df)
  }, error = function(e) {
    stop(paste0("clogit model fitting failed: ", e$message))
  })

  # ---- extract results ----
  coef_table <- coef(summary(model))
  n_cases <- sum(df[[ycol]] == 1, na.rm = TRUE)
  n_controls <- sum(df[[ycol]] == 0, na.rm = TRUE)

  # Prepare coefficient table for output
  coef_df <- as.data.frame(coef_table)
  coef_df$term <- rownames(coef_df)
  rownames(coef_df) <- NULL

  list(
    summary = list(
      headline = "Conditional Logistic Regression（マッチングケース対照研究用）",
      method_used = "Conditional Logistic Regression (clogit)",
      key_metrics = list(
        n_cases = n_cases,
        n_controls = n_controls,
        n_strata = length(unique(df[[stratumcol]]))
      ),
      interpretation_notes = list(
        "マッチング層（strata）を考慮した条件付きロジスティック回帰分析です。",
        "オッズ比（OR）の解釈：各変数の単位上昇あたりのオッズ比です。",
        "95%信頼区間（95% CI）をご確認ください。"
      )
    ),
    tables = list(
      list(id = "coef_table", title = "係数（条件付きロジスティック回帰）", data = coef_df),
      list(id = "summary_stats", title = "ケース・コントロール数", data = data.frame(
        category = c("ケース数", "コントロール数"),
        count = c(n_cases, n_controls)
      ))
    ),
    figures = list(),
    warnings = list(),
    errors = list()
  )
}

run <- run_recipe_impl

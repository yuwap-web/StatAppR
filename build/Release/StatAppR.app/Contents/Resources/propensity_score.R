# recipes/propensity_score.R

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  # Swift/recipes.json 側は treat を送る想定
  # 互換のため treatment も許容
  trt  <- request$variables$treat %||% request$variables$treatment
  xraw <- request$variables$x

  # advanced (optional)
  ps_model <- request$variables$ps_model %||% "logit"  # logit/probit

  if (is.null(trt) || trt == "") stop("variables.treat が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("variables.x（共変量）が必要です")
  if (!(trt %in% names(data))) stop(paste0("treat column not found: ", trt))

  # x を character vector に正規化（配列 or "a,b" どちらもOK）
  if (is.character(xraw) && length(xraw) == 1) {
    xs <- trimws(unlist(strsplit(xraw, ",")))
  } else if (is.character(xraw) && length(xraw) >= 1) {
    xs <- xraw
  } else if (is.list(xraw)) {
    xs <- unlist(xraw)
  } else {
    xs <- as.character(xraw)
  }
  xs <- trimws(xs)
  xs <- xs[xs != ""]
  if (length(xs) < 1) stop("variables.x（共変量）の指定が不正です（空）")

  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("covariate columns not found: ", paste(miss, collapse = ", ")))

  # use only needed columns
  df <- data[, unique(c(trt, xs)), drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 10) stop("有効データが少なすぎます（NA除外後）")

  # treatment must be 0/1 or 2-level -> create .treat01
  tvec <- df[[trt]]
  if (is.factor(tvec)) tvec <- as.character(tvec)

  if (is.character(tvec)) {
    u <- unique(tvec[!is.na(tvec)])
    if (length(u) != 2) stop("treat must have exactly 2 levels (character/factor)")
    t01 <- ifelse(tvec == u[2], 1, 0)
  } else {
    suppressWarnings(t01 <- as.numeric(tvec))
  }

  if (!all(t01 %in% c(0, 1), na.rm = TRUE)) {
    stop("treat must be 0/1 (or 2-level factor/character)")
  }
  df$.treat01 <- t01

  # PS model
  link <- "logit"
  if (tolower(ps_model) == "probit") link <- "probit"

  f_ps <- stats::as.formula(paste0(".treat01 ~ ", paste(xs, collapse = " + ")))
  ps_fit <- stats::glm(f_ps, data = df, family = stats::binomial(link = link))

  ps <- as.numeric(stats::predict(ps_fit, type = "response"))
  # safety clip
  eps <- 1e-6
  ps <- pmin(pmax(ps, eps), 1 - eps)

  tbl <- data.frame(
    ps = ps,
    treat01 = df$.treat01,
    stringsAsFactors = FALSE
  )

  s <- summary(ps_fit)
  coef_tbl <- as.data.frame(s$coefficients)
  coef_tbl$term <- rownames(coef_tbl)
  rownames(coef_tbl) <- NULL

  # 列名は環境で変わることがあるので保険
  keep <- intersect(c("term", "Estimate", "Std. Error", "z value", "Pr(>|z|)"), names(coef_tbl))
  coef_tbl <- coef_tbl[, keep, drop = FALSE]

  list(
    summary = list(
      headline = "傾向スコア（PS）推定が完了しました。",
      method_used = paste0("glm(binomial, link=", link, ")"),
      key_metrics = list(
        n_used = nrow(df),
        ps_min = min(ps, na.rm = TRUE),
        ps_max = max(ps, na.rm = TRUE)
      ),
      interpretation_notes = list(
        "PSの重なり（overlap）が弱い場合、因果推論の前提が厳しくなります。",
        "このレシピはPS推定のみです。IPTWやマッチングは別レシピで実行してください。"
      )
    ),
    tables = list(
      list(id = "ps_values", title = "傾向スコア（PS）推定値", data = tbl),
      list(id = "ps_model_coef", title = "PSモデル係数（glm）", data = coef_tbl)
    ),
    figures = list(),
    warnings = list()
  )
}

run <- run_recipe_impl
# recipes/event_study.R
# Event study (TWFE) with unit/time fixed effects and event-time indicators
# Assumes panel data with (unit, time, y), and treatment start time per unit (treat_time).
# k = time - treat_time, create dummies for k in [min_lag, max_lead], omit ref_k.

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  ycol   <- request$variables$outcome_column
  unitcol <- request$variables$unit_id %||% request$variables$id
  timecol <- request$variables$time_column
  ttimecol <- request$variables$event_date_column %||% request$variables$policy_time

  # options
  min_lag  <- request$variables$min_lag %||% -5   # e.g. -5
  max_lead <- request$variables$max_lead %||% 5   # e.g. +5
  ref_k    <- request$variables$ref_k %||% -1     # omitted baseline dummy

  # optional: restrict to treated + not-yet-treated controls
  drop_never_treated <- request$variables$drop_never_treated %||% FALSE
  # optional: cluster SE (not implemented robustly here)
  robust_se <- request$variables$robust_se %||% FALSE

  suppressWarnings(min_lag <- as.integer(min_lag))
  suppressWarnings(max_lead <- as.integer(max_lead))
  suppressWarnings(ref_k <- as.integer(ref_k))

  if (is.na(min_lag)) min_lag <- -5L
  if (is.na(max_lead)) max_lead <- 5L
  if (is.na(ref_k)) ref_k <- -1L

  if (min_lag >= 0) stop("min_lag は負の値（例: -5）を推奨します")
  if (max_lead <= 0) stop("max_lead は正の値（例: 5）を推奨します")
  if (ref_k < min_lag || ref_k > max_lead) stop("ref_k は [min_lag, max_lead] の範囲内にしてください")
  if (ref_k == 0) {
    # 0基準もあり得るが、一般的には -1
    # allow, no stop
  }

  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column が必要です")
  if (is.null(unitcol) || unitcol == "") stop("request$variables$unit_id（または id）が必要です")
  if (is.null(timecol) || timecol == "") stop("request$variables$time_column が必要です")
  if (is.null(ttimecol) || ttimecol == "") stop("request$variables$event_date_column が必要です")

  for (cname in c(ycol, unitcol, timecol, ttimecol)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, c(ycol, unitcol, timecol, ttimecol), drop = FALSE]

  # ---- y numeric coercion ----
  if (!is.numeric(df[[ycol]])) {
    y0 <- df[[ycol]]
    suppressWarnings(df[[ycol]] <- as.numeric(gsub(",", "", as.character(df[[ycol]]))))
    if (all(is.na(df[[ycol]])) && any(!is.na(y0))) stop("y は数値列である必要があります")
  }

  # ---- time / treat_time numeric coercion ----
  for (nm in c(timecol, ttimecol)) {
    if (!is.numeric(df[[nm]])) {
      x0 <- df[[nm]]
      suppressWarnings(df[[nm]] <- as.numeric(gsub(",", "", as.character(df[[nm]]))))
      if (all(is.na(df[[nm]])) && any(!is.na(x0))) stop(paste0(nm, " は数値列である必要があります"))
    }
  }

  # ---- unit as factor ----
  df[[unitcol]] <- as.factor(df[[unitcol]])

  # drop NA
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 20) stop("有効データが少なすぎます（NA除外後）")
  if (nlevels(df[[unitcol]]) < 2) stop("unit は2水準以上必要です")

  # treat_time validity:
  # - never-treated can be NA or Inf or very large sentinel; here allow NA as never-treated
  ttime <- df[[ttimecol]]
  # Mark never-treated
  never <- is.na(ttime)
  # Optionally drop never-treated units entirely
  if (isTRUE(drop_never_treated)) {
    df <- df[!never, , drop = FALSE]
    if (nrow(df) < 20) stop("never-treated を除外した結果、有効データが不足しました")
    ttime <- df[[ttimecol]]
    never <- is.na(ttime)
  }

  # compute event time k for treated units; for never-treated keep NA
  df$k <- NA_integer_
  df$k[!never] <- as.integer(round(df[[timecol]][!never] - df[[ttimecol]][!never]))

  # build window and truncate outside
  # We'll create dummies for k in [min_lag, max_lead], excluding ref_k, and include:
  # - unit FE: factor(unit)
  # - time FE: factor(time)
  # Use only treated observations within window OR controls always included (never-treated or not-yet-treated) in TWFE
  # Keep all, but dummies are 0 when k is NA or outside window.
  ks <- seq(min_lag, max_lead)
  ks_use <- ks[ks != ref_k]

  # create dummy columns
  for (kk in ks_use) {
    nm <- paste0("K_", ifelse(kk < 0, paste0("m", abs(kk)), paste0("p", kk)))
    df[[nm]] <- 0
    idx <- which(!is.na(df$k) & df$k == kk)
    if (length(idx) > 0) df[[nm]][idx] <- 1
  }

  # Optional: remove observations AFTER treatment for controls that eventually treated?
  # For classic event study, it's okay. If you want "not-yet-treated" controls only (staggered adoption),
  # you would need a more careful estimator. We'll leave as TWFE baseline.
  warnings_out <- list()
  warnings_out <- c(warnings_out, list(list(
    code = "TWFE_NOTE",
    severity = "info",
    message = "本実装は TWFE（unit/time固定効果）によるevent studyです。介入時期がずれる（staggered adoption）場合、TWFEはバイアスの可能性があるため、Sun & Abraham / Callaway & Sant’Anna 等の検討も推奨します。"
  )))

  # formula: y ~ dummies + factor(unit) + factor(time)
  dcols <- unlist(lapply(ks_use, function(kk) paste0("K_", ifelse(kk < 0, paste0("m", abs(kk)), paste0("p", kk)))))
  rhs <- paste(c(dcols, paste0("factor(", unitcol, ")"), paste0("factor(", timecol, ")")), collapse = " + ")
  fml <- stats::as.formula(paste0(ycol, " ~ ", rhs))

  fit <- stats::lm(fml, data = df)
  sm <- summary(fit)

  # extract coefficients for event-time dummies
  coef_mat <- sm$coefficients
  if (is.null(coef_mat) || nrow(coef_mat) < 1) stop("lm coefficients not available")

  # build results table for ks
  est_tbl <- data.frame(
    k = integer(0),
    term = character(0),
    estimate = numeric(0),
    std_error = numeric(0),
    conf_low = numeric(0),
    conf_high = numeric(0),
    p_value = numeric(0),
    stringsAsFactors = FALSE
  )

  for (kk in ks_use) {
    nm <- paste0("K_", ifelse(kk < 0, paste0("m", abs(kk)), paste0("p", kk)))
    if (nm %in% rownames(coef_mat)) {
      est <- unname(coef_mat[nm, 1])
      se  <- unname(coef_mat[nm, 2])
      p   <- unname(coef_mat[nm, 4])
      est_tbl <- rbind(est_tbl, data.frame(
        k = kk,
        term = nm,
        estimate = est,
        std_error = se,
        conf_low = est - 1.96 * se,
        conf_high = est + 1.96 * se,
        p_value = p,
        stringsAsFactors = FALSE
      ))
    } else {
      # dummy col might be dropped due to collinearity (no variation)
      est_tbl <- rbind(est_tbl, data.frame(
        k = kk,
        term = nm,
        estimate = NA_real_,
        std_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        p_value = NA_real_,
        stringsAsFactors = FALSE
      ))
      warnings_out <- c(warnings_out, list(list(
        code = "DUMMY_DROPPED",
        severity = "info",
        message = paste0("k=", kk, " のダミーが推定から落ちました（共線性/該当データ不足の可能性）。")
      )))
    }
  }

  # add reference row for plotting convenience
  est_tbl <- rbind(est_tbl, data.frame(
    k = ref_k,
    term = "REFERENCE",
    estimate = 0,
    std_error = NA_real_,
    conf_low = NA_real_,
    conf_high = NA_real_,
    p_value = NA_real_,
    stringsAsFactors = FALSE
  ))

  est_tbl <- est_tbl[order(est_tbl$k), , drop = FALSE]
  rownames(est_tbl) <- NULL

  # metrics
  metrics <- data.frame(
    n_used = nrow(df),
    n_units = nlevels(df[[unitcol]]),
    n_times = length(unique(df[[timecol]])),
    min_lag = min_lag,
    max_lead = max_lead,
    ref_k = ref_k,
    r_squared = unname(sm$r.squared),
    adj_r_squared = unname(sm$adj.r.squared),
    stringsAsFactors = FALSE
  )

  # simple pre-trend check: joint significance of negative ks (excluding ref)
  pre_ks <- ks_use[ks_use < 0]
  pre_terms <- paste0("K_", ifelse(pre_ks < 0, paste0("m", abs(pre_ks)), paste0("p", pre_ks)))
  pre_terms <- pre_terms[pre_terms %in% rownames(coef_mat)]

  pretest_tbl <- data.frame()
  if (length(pre_terms) >= 1) {
    # Wald test via linearHypothesis if car exists, else skip
    if (requireNamespace("car", quietly = TRUE)) {
      lh <- tryCatch(
        car::linearHypothesis(fit, pre_terms, test = "F"),
        error = function(e) NULL
      )
      if (!is.null(lh) && nrow(lh) >= 2) {
        pretest_tbl <- data.frame(
          test = "Pre-trend joint test (all k<0 dummies)",
          F = as.numeric(lh[2, "F"]),
          df1 = as.numeric(lh[2, "Df"]),
          df2 = as.numeric(lh[2, "Res.Df"]),
          p_value = as.numeric(lh[2, "Pr(>F)"]),
          stringsAsFactors = FALSE
        )
      } else {
        warnings_out <- c(warnings_out, list(list(
          code = "PRETEST_FAILED",
          severity = "info",
          message = "Pre-trendの同時検定（car::linearHypothesis）に失敗しました。"
        )))
      }
    } else {
      warnings_out <- c(warnings_out, list(list(
        code = "CAR_NOT_INSTALLED",
        severity = "info",
        message = "Pre-trend同時検定には car パッケージが必要です（未インストールのためスキップ）。"
      )))
    }
  }

  # ---- optional plot ----
  plot_file <- NULL
  plot_file <- tryCatch({
    if (exists("make_event_study_plot", mode = "function")) {
      make_event_study_plot(
        est_tbl,
        k_col = "k",
        est_col = "estimate",
        lo_col = "conf_low",
        hi_col = "conf_high",
        ref_k = ref_k
      )
    } else {
      NULL
    }
  }, error = function(e) NULL)

  figures_out <- list()
  if (!is.null(plot_file)) {
    figures_out <- list(list(
      id = "event_study",
      title = "Event study plot",
      type = "plot",
      path = plot_file
    ))
  }

  headline <- "Event study を推定しました。"
  # show strongest post effect p (k>0)
  post <- est_tbl[est_tbl$k > 0 & !is.na(est_tbl$p_value), , drop = FALSE]
  if (nrow(post) >= 1) {
    pmin_post <- min(post$p_value, na.rm = TRUE)
    headline <- paste0("Event study: post期 最小p = ", signif(pmin_post, 3))
  }

  list(
    summary = list(
      headline = headline,
      method_used = "TWFE event study (lm with unit FE + time FE)",
      key_metrics = list(
        n_used = nrow(df),
        n_units = nlevels(df[[unitcol]]),
        n_times = length(unique(df[[timecol]])),
        r_squared = unname(sm$r.squared),
        adj_r_squared = unname(sm$adj.r.squared)
      ),
      interpretation_notes = list(
        "推定値は ref_k（基準時点）に対する相対効果です。",
        "k<0（介入前）の推定が0付近で有意でないことが、平行トレンドの目安になります。",
        "staggered adoption ではTWFEの限界があるため、より頑健な推定法も検討してください。"
      )
    ),
    tables = c(
      list(
        list(id = "model_metrics", title = "モデル指標", data = metrics),
        list(id = "event_time_effects", title = "Event-time 推定結果", data = est_tbl)
      ),
      if (nrow(pretest_tbl) > 0) list(list(id = "pretrend_test", title = "Pre-trend同時検定（参考）", data = pretest_tbl)) else list()
    ),
    figures = figures_out,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
# recipes/target_trial_emulation.R
# Target Trial Emulation (clone-censor-weight) for time-to-event
# Requires LONG format data: one row per interval per person
#
# Required columns:
# - id: subject identifier
# - start: interval start time
# - stop: interval stop time
# - status: event indicator at stop (1=event, 0=censor/no event in interval)
# - a: treatment indicator during interval (0/1)
# - x: baseline covariates (columns; can be repeated per row)
#
# Regimes implemented:
# - never treat (A=0 throughout)
# - always treat (A=1 throughout)
#
# Steps:
# 1) clone each subject into 2 regimes
# 2) censor clone at first deviation from assigned regime
# 3) estimate IPC weights for censoring via pooled logistic regression
# 4) weighted Cox model (start-stop) comparing regimes

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが見つかりません（target_trial_emulation には survival が必要です）")
  }

  id_col     <- request$variables$id
  start_col  <- request$variables$time_column %||% request$variables$start %||% request$variables$time
  stop_col   <- request$variables$stop
  status_col <- request$variables$outcome_column %||% request$variables$status %||% request$variables$y
  a_col      <- request$variables$a
  xraw       <- request$variables$covariates %||% request$variables$x

  # optional (advanced)
  stabilize   <- request$variables$stabilized %||% TRUE
  trim_cap    <- request$variables$trim %||% 0
  use_ggplot  <- request$variables$plot %||% TRUE

  if (is.null(id_col) || id_col == "") stop("variables.id が必要です")
  if (is.null(start_col) || start_col == "") stop("request$variables$time_column が必要です")
  if (is.null(stop_col) || stop_col == "") stop("variables.stop が必要です")
  if (is.null(status_col) || status_col == "") stop("request$variables$outcome_column が必要です")
  if (is.null(a_col) || a_col == "") stop("variables.a（区間治療 0/1）が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("request$variables$covariates（共変量）が必要です")

  # x normalization
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
  xvars <- setdiff(xvars, c(id_col, start_col, stop_col, status_col, a_col))

  if (length(xvars) < 1) stop("request$variables$covariates が空です")

  # column checks
  for (cname in c(id_col, start_col, stop_col, status_col, a_col, xvars)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  cols <- unique(c(id_col, start_col, stop_col, status_col, a_col, xvars))
  df0 <- data[, cols, drop = FALSE]

  # numeric coercions for start/stop/status/a
  num_cast <- function(v, nm) {
    if (is.numeric(v)) return(v)
    v0 <- v
    suppressWarnings(v <- as.numeric(gsub(",", "", as.character(v))))
    if (all(is.na(v)) && any(!is.na(v0))) stop(paste0(nm, " は数値に変換できません"))
    v
  }

  df0[[start_col]]  <- num_cast(df0[[start_col]],  "start")
  df0[[stop_col]]   <- num_cast(df0[[stop_col]],   "stop")
  df0[[status_col]] <- num_cast(df0[[status_col]], "status")
  df0[[a_col]]      <- num_cast(df0[[a_col]],      "a")

  # require 0/1 for status and a
  if (!all(df0[[status_col]] %in% c(0, 1), na.rm = TRUE)) stop("status は 0/1 が必要です")
  if (!all(df0[[a_col]] %in% c(0, 1), na.rm = TRUE)) stop("a は 0/1 が必要です")

  # drop NA rows
  df0 <- df0[stats::complete.cases(df0), , drop = FALSE]
  if (nrow(df0) < 20) stop("有効データが少なすぎます（NA除外後）")

  # basic checks: start < stop
  if (any(df0[[stop_col]] <= df0[[start_col]], na.rm = TRUE)) {
    stop("stop は start より大きい必要があります")
  }

  # ---- clone (two regimes) ----
  df_never <- df0
  df_never$regime <- "never"
  df_never$assigned <- 0

  df_always <- df0
  df_always$regime <- "always"
  df_always$assigned <- 1

  cl <- rbind(df_never, df_always)

  # ---- censor on deviation ----
  # deviation when a != assigned
  cl$deviate <- as.integer(cl[[a_col]] != cl$assigned)

  # For each (id, regime), find first deviation time -> censor from that interval onward
  # We implement by keeping rows until (and excluding) first deviate==1 interval.
  cl <- cl[order(cl[[id_col]], cl$regime, cl[[start_col]], cl[[stop_col]]), , drop = FALSE]

  keep <- rep(TRUE, nrow(cl))
  key <- paste(cl[[id_col]], cl$regime, sep = "||")

  first_dev <- tapply(seq_len(nrow(cl)), key, function(ix) {
    j <- ix[cl$deviate[ix] == 1]
    if (length(j) == 0) return(NA_integer_)
    min(j)
  })

  for (k in names(first_dev)) {
    j0 <- first_dev[[k]]
    if (!is.na(j0)) {
      # drop from deviation interval onward
      ix <- which(key == k)
      keep[ix[ix >= j0]] <- FALSE
    }
  }

  cl2 <- cl[keep, , drop = FALSE]
  if (nrow(cl2) < 20) stop("逸脱による打ち切り後、有効行が少なすぎます（caliper等ではなくデータ仕様を確認）")

  # ---- build censoring indicator per interval (for IPCW) ----
  # censor occurs at end of last kept interval if next interval existed and deviated
  # Pooled logistic model requires rows where still at risk of censoring
  # We'll define C=1 if this interval is the LAST observed for (id, regime) AND original had deviation later.
  cl2$C <- 0L

  # Determine for each (id, regime) whether a deviation existed in original clone
  had_dev <- tapply(cl$deviate, key, function(v) any(v == 1))
  # Last row index in cl2 for each key
  key2 <- paste(cl2[[id_col]], cl2$regime, sep = "||")
  last_ix <- tapply(seq_len(nrow(cl2)), key2, max)

  for (k in names(last_ix)) {
    if (isTRUE(had_dev[[k]])) {
      cl2$C[last_ix[[k]]] <- 1L
      # Ensure no event on censoring interval due to protocol censoring priority
      # (If event happens before deviation, it would have occurred earlier intervals.)
      # We keep status as-is; if status=1 on the last interval, it's an event, not a censor.
      # So set C=0 when status=1.
      if (cl2[[status_col]][last_ix[[k]]] == 1) cl2$C[last_ix[[k]]] <- 0L
    }
  }

  # ---- IPC weights for censoring ----
  # Model P(C=1 | history) using pooled logistic regression
  # Use baseline covariates + time (stop) + regime as predictors
  # NOTE: This is a practical approximation (discrete-time)
  f_c <- stats::as.formula(
    paste0("C ~ regime + ", stop_col, " + ", paste(xvars, collapse = " + "))
  )

  # Ensure regime as factor
  cl2$regime <- as.factor(cl2$regime)

  cfit <- stats::glm(f_c, data = cl2, family = stats::binomial())

  phat <- as.numeric(stats::predict(cfit, type = "response"))
  phat <- pmin(pmax(phat, 1e-6), 1 - 1e-6)

  # weight per interval = 1 / (1 - phat) for those not censored before end of interval
  # For censored interval itself, still contributes until censoring time; common practice keeps it.
  w <- 1 / (1 - phat)

  # stabilized: numerator model without covariates (regime + time only)
  if (isTRUE(stabilize)) {
    f_num <- stats::as.formula(paste0("C ~ regime + ", stop_col))
    cnum <- stats::glm(f_num, data = cl2, family = stats::binomial())
    pnum <- as.numeric(stats::predict(cnum, type = "response"))
    pnum <- pmin(pmax(pnum, 1e-6), 1 - 1e-6)
    w <- (1 / (1 - phat)) * (1 - pnum)
  }

  # trim/cap
  if (!is.null(trim_cap) && is.numeric(trim_cap) && trim_cap > 0) {
    w <- pmin(w, trim_cap)
  }

  cl2$w_ipcw <- w

  # Validate weights
  if (!("w_ipcw" %in% names(cl2))) {
    stop("Internal error: w_ipcw column not created in dataset")
  }
  if (any(is.na(cl2$w_ipcw)) || any(is.infinite(cl2$w_ipcw))) {
    stop("Invalid weights: contains NA or Inf values")
  }

  # ---- weighted Cox model comparing regimes ----
  # start-stop Surv
  f_cox <- stats::as.formula(
    paste0("survival::Surv(", start_col, ",", stop_col, ",", status_col, ") ~ regime")
  )

  # Extract weights as vector for coxph
  w_vec <- as.numeric(cl2$w_ipcw)
  cox_fit <- survival::coxph(f_cox, data = cl2, weights = w_vec, robust = TRUE)
  s <- summary(cox_fit)

  coef_mat <- s$coefficients
  if (is.null(coef_mat) || nrow(coef_mat) < 1) stop("coxph summary not available")

  # Extract regimealways effect (reference=never)
  rn <- rownames(coef_mat)
  term <- rn[1]
  est <- as.numeric(coef_mat[1, "coef"])
  se  <- as.numeric(coef_mat[1, "robust se"] %||% coef_mat[1, "se(coef)"])
  z   <- est / se
  p   <- 2 * (1 - stats::pnorm(abs(z)))

  hr  <- exp(est)
  ciL <- exp(est - 1.96 * se)
  ciH <- exp(est + 1.96 * se)

  effect_tbl <- data.frame(
    contrast = term,
    HR = hr,
    conf_low = ciL,
    conf_high = ciH,
    p_value = p,
    stringsAsFactors = FALSE
  )

  # weights summary
  wsum <- data.frame(
    stabilized = isTRUE(stabilize),
    trim_cap = ifelse(is.null(trim_cap), NA, trim_cap),
    weight_min = min(w),
    weight_p01 = unname(stats::quantile(w, 0.01)),
    weight_median = unname(stats::median(w)),
    weight_mean = unname(mean(w)),
    weight_p99 = unname(stats::quantile(w, 0.99)),
    weight_max = max(w),
    stringsAsFactors = FALSE
  )

  # censor model coef table
  cs <- summary(cfit)$coefficients
  ctbl <- as.data.frame(cs)
  ctbl$term <- rownames(ctbl)
  rownames(ctbl) <- NULL

  # optional plot (KM-like) is non-trivial with weights+startstop; skip here safely
  figs <- list()
  warnings_out <- list()

  if (isTRUE(use_ggplot)) {
    # Only if ggplot2 exists; otherwise warn
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      warnings_out <- c(warnings_out, list(list(
        code = "GGPLOT2_NOT_INSTALLED",
        severity = "info",
        message = "ggplot2 が無いため図はスキップしました。"
      )))
    } else {
      warnings_out <- c(warnings_out, list(list(
        code = "PLOT_SKIPPED",
        severity = "info",
        message = "TTEの重み付きstart-stopデータの論文品質プロットは次段で実装します（まず推定の安定性優先）。"
      )))
    }
  }

  headline <- paste0("Target Trial Emulation（CCW）: HR=", signif(hr, 3), " p=", signif(p, 3))

  list(
    summary = list(
      headline = headline,
      method_used = "Target Trial Emulation (clone-censor-weight) + weighted Cox (robust SE)",
      key_metrics = list(
        HR = hr,
        p_value = p,
        n_rows_used = nrow(cl2),
        n_ids = length(unique(cl2[[id_col]]))
      ),
      interpretation_notes = list(
        "縦持ち（start-stop）データが前提です（区間ごとの治療 a を使って逸脱で打ち切り）。",
        "C のモデルは pooled logistic による近似です。より厳密にする場合は time-varying covariates/スプライン等を検討します。",
        "重みの最大値が大きい場合は stabilized=TRUE や trim を検討してください。"
      )
    ),
    tables = list(
      list(id="tte_effect", title="TTE 推定（regime効果）", data=effect_tbl),
      list(id="ipcw_weights", title="IPCW重み要約", data=wsum),
      list(id="censor_model_coef", title="打ち切りモデル（logistic）係数", data=ctbl)
    ),
    figures = figs,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
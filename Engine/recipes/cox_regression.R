# recipes/cox_regression.R

source(file.path(runner_dir, "utils", "plot_utils.R"))

run_recipe_impl <- function(request, data) {

  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが見つかりません（cox_regression には survival が必要です）")
  }

  # --- params ---
  time_col   <- request$variables$time_column
  status_col <- request$variables$event_column
  xraw       <- request$variables$covariates

  # optional (advanced)
  check_ph  <- request$variables$check_ph %||% FALSE     # TRUEでcox.zph
  robust_se <- request$variables$robust_se %||% TRUE     # robust variance
  ties_meth <- request$variables$ties %||% "efron"       # "efron" / "breslow" / "exact"

  if (is.null(time_col) || time_col == "") stop("request$variables$time_column が必要です")
  if (is.null(status_col) || status_col == "") stop("request$variables$event_column が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("request$variables$covariates（共変量）が必要です")

  # ---- normalize x columns (array or "a,b") ----
  xvars <- NULL
  if (is.character(xraw) && length(xraw) == 1) {
    xvars <- trimws(unlist(strsplit(xraw, ",")))
  } else if (is.character(xraw) && length(xraw) >= 1) {
    xvars <- xraw
  } else if (is.list(xraw)) {
    xvars <- unlist(xraw)
  } else {
    xvars <- as.character(xraw)
  }
  xvars <- trimws(xvars)
  xvars <- xvars[xvars != ""]

  # accident guard: remove time/status if mixed
  xvars <- setdiff(xvars, c(time_col, status_col))

  if (length(xvars) < 1) stop("request$variables$covariates（共変量）の指定が不正です（空）")

  # column existence checks
  for (cname in c(time_col, status_col, xvars)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  # ---- build df ----
  cols <- unique(c(time_col, status_col, xvars))
  df <- data[, cols, drop = FALSE]

  # ---- time numeric coercion ----
  if (!is.numeric(df[[time_col]])) {
    t0 <- df[[time_col]]
    suppressWarnings(df[[time_col]] <- as.numeric(gsub(",", "", as.character(df[[time_col]]))))
    if (all(is.na(df[[time_col]])) && any(!is.na(t0))) {
      stop("time は数値列である必要があります（数値に変換できません）")
    }
  }

  # ---- status normalize to 0/1 ----
  st <- df[[status_col]]
  if (is.factor(st)) st <- as.character(st)
  if (is.logical(st)) st <- ifelse(st, 1, 0)

  if (is.character(st)) {
    v <- tolower(trimws(st))
    v[v %in% c("t", "true", "yes", "y", "event", "1")] <- "1"
    v[v %in% c("f", "false", "no", "n", "censor", "censored", "0")] <- "0"
    suppressWarnings(stn <- as.numeric(v))
  } else {
    suppressWarnings(stn <- as.numeric(st))
  }

  if (!all(stn %in% c(0, 1), na.rm = TRUE)) {
    stop("status は 0/1（または TRUE/FALSE, yes/no, event/censor）である必要があります")
  }
  df[[status_col]] <- stn

  # ---- drop NA after coercion ----
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 5) stop("有効データが少なすぎます（NA除外後の行数が不足）")

  n_events <- sum(df[[status_col]] == 1, na.rm = TRUE)
  if (n_events < 3) stop("イベント数が少なすぎます（Cox回帰の推定が不安定）")

  # ---- formula ----
  fml <- stats::as.formula(
    paste0(
      "survival::Surv(", time_col, ",", status_col, ") ~ ",
      paste(xvars, collapse = " + ")
    )
  )

  # ---- fit ----
  ties_meth <- tolower(as.character(ties_meth))
  if (!(ties_meth %in% c("efron", "breslow", "exact"))) ties_meth <- "efron"

  fit <- survival::coxph(
    fml,
    data = df,
    ties = ties_meth,
    robust = isTRUE(robust_se)
  )

  s <- summary(fit)

  # ---- coefficients table (robust to column-name variations) ----
  coef_mat <- s$coefficients
  if (is.null(coef_mat) || nrow(coef_mat) < 1) stop("coxph coefficients not available")

  cn <- colnames(coef_mat)

  # exp(coef)
  hr_col <- cn[grepl("^exp\\(coef\\)$", cn)][1]
  if (is.na(hr_col) || is.null(hr_col)) hr_col <- cn[grepl("exp\\(coef\\)", cn)][1]

  # se(coef)
  se_col <- cn[grepl("^se\\(coef\\)$", cn)][1]
  if (is.na(se_col) || is.null(se_col)) se_col <- cn[grepl("se\\(coef\\)", cn)][1]

  # p-value
  p_col <- cn[grepl("Pr\\(>\\|z\\|\\)", cn)][1]
  if (is.na(p_col) || is.null(p_col)) p_col <- cn[grepl("^p", cn, ignore.case = TRUE)][1]

  if (is.na(hr_col) || is.na(se_col) || is.na(p_col)) {
    stop("coxph summary columns not found (unexpected summary format)")
  }

  hr      <- as.numeric(coef_mat[, hr_col])
  se_coef <- as.numeric(coef_mat[, se_col])
  p_val   <- as.numeric(coef_mat[, p_col])

  # CI on log(HR)
  ci_low  <- exp(log(hr) - 1.96 * se_coef)
  ci_high <- exp(log(hr) + 1.96 * se_coef)

  tbl <- data.frame(
    term = rownames(coef_mat),
    HR = hr,
    CI_low = ci_low,
    CI_high = ci_high,
    p_value = p_val,
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # ---- forest plot (HR) ----
  # NOTE: make_forest_plot(df, est_col, low_col, high_col, label_col)
  forest_file <- tryCatch(
    make_forest_plot(
      tbl,
      "HR",
      "CI_low",
      "CI_high",
      "term"
    ),
    error = function(e) NULL
  )

  figures_out <- list()
  if (!is.null(forest_file)) {
    figures_out <- c(figures_out, list(
      list(
        id = "hr_forest",
        title = "Hazard Ratio Forest Plot",
        path = forest_file
      )
    ))
  }

  # ---- PH assumption check (optional) ----
  warnings_out <- list()
  ph_tbl <- NULL

  if (isTRUE(check_ph)) {
    zph <- tryCatch(survival::cox.zph(fit), error = function(e) NULL)
    if (!is.null(zph)) {
      z <- as.data.frame(zph$table)
      z$term <- rownames(z)
      rownames(z) <- NULL

      keep <- c("term", intersect(c("chisq", "df", "p"), names(z)))
      ph_tbl <- z[, keep, drop = FALSE]
    } else {
      warnings_out <- c(warnings_out, list(list(
        code = "PH_CHECK_FAILED",
        severity = "info",
        message = "PH仮定チェック（cox.zph）に失敗しました。"
      )))
    }
  }

  # ---- model metrics ----
  conc <- NA_real_
  if (!is.null(s$concordance) && length(s$concordance) >= 1) conc <- unname(s$concordance[1])

  metrics <- data.frame(
    n_used = nrow(df),
    n_events = n_events,
    concordance = conc,
    ties = ties_meth,
    robust_se = isTRUE(robust_se),
    stringsAsFactors = FALSE
  )

  # headline
  pmin <- suppressWarnings(min(tbl$p_value, na.rm = TRUE))
  headline <- paste0("Cox回帰: 最小p = ", signif(pmin, 3))

  tables_out <- list(
    list(id = "model_metrics", title = "モデル指標", data = metrics),
    list(id = "cox_results", title = "Cox回帰結果（HR）", data = tbl)
  )

  if (!is.null(ph_tbl)) {
    tables_out <- c(tables_out, list(
      list(id = "ph_assumption", title = "PH仮定チェック（cox.zph）", data = ph_tbl)
    ))
  }

  # sanity warnings (optional)
  if (any(is.infinite(tbl$HR)) || any(is.na(tbl$HR))) {
    warnings_out <- c(warnings_out, list(list(
      code = "HR_NA_OR_INF",
      severity = "info",
      message = "HRがNA/Infの項が含まれています（完全分離や極端なデータの可能性）。"
    )))
  }
  if (any(abs(log(tbl$HR)) > 5, na.rm = TRUE)) {
    warnings_out <- c(warnings_out, list(list(
      code = "EXTREME_HR",
      severity = "info",
      message = "HRが極端に大きい/小さい項があります（推定が不安定な可能性）。"
    )))
  }

  list(
    summary = list(
      headline = headline,
      method_used = "Cox proportional hazards regression (survival::coxph)",
      key_metrics = list(
        concordance = conc,
        n_used = nrow(df),
        n_events = n_events,
        min_p = unname(pmin)
      ),
      interpretation_notes = list(
        "HR > 1 はイベント発生リスク増加、HR < 1 は低下を示唆します。",
        "PH仮定が崩れる場合は time-varying effect や層別化も検討してください。",
        if (isTRUE(robust_se)) "robust=TRUE によりロバスト分散を使用しています。" else "標準の分散推定です（robust=FALSE）。"
      )
    ),
    tables = tables_out,
    figures = figures_out,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
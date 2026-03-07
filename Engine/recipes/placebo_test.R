# recipes/placebo_test.R
# Placebo test for event-study / DiD style designs.
# Two modes:
# 1) shift: move treat_time earlier/later by placebo_shift and re-estimate event-time effects
# 2) permute: randomly permute treat_time across units (keeps marginal distribution), estimate placebo distribution
#
# Output: placebo event-time estimates, and (optional) permutation p-value distribution.

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  # Required columns - support multiple parameter name formats
  ycol     <- request$variables$outcome_column %||% request$variables$y
  unitcol  <- request$variables$unit_id %||% request$variables$unit %||% request$variables$id
  timecol  <- request$variables$time_column %||% request$variables$time
  ttimecol <- request$variables$event_date_column %||% request$variables$treat_time %||% request$variables$policy_time

  # Options
  mode <- request$variables$mode %||% "shift"          # "shift" or "permute"
  placebo_shift <- request$variables$placebo_shift %||% -5  # for shift mode
  min_lag  <- request$variables$min_lag %||% -5
  max_lead <- request$variables$max_lead %||%  5
  ref_k    <- request$variables$ref_k %||% -1

  # Which summary statistic for permutation p-value
  # "post_avg": average of k>=1 estimates (within window)
  # "post_min_p": minimum p-value among k>=1 (not ideal but common)
  # "k_specific": focus on a specific k (set focus_k)
  stat <- request$variables$stat %||% "post_avg"
  focus_k <- request$variables$focus_k %||% 1

  reps <- request$variables$reps %||% 200
  seed <- request$variables$seed %||% 123

  # Optional: draw plot if helper exists
  draw_plot <- request$variables$draw_plot
  if (is.null(draw_plot)) draw_plot <- TRUE

  # ---- validate ----
  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column が必要です")
  if (is.null(unitcol) || unitcol == "") stop("request$variables$unit_id（または id）が必要です")
  if (is.null(timecol) || timecol == "") stop("request$variables$time_column が必要です")
  if (is.null(ttimecol) || ttimecol == "") stop("request$variables$event_date_column が必要です")

  for (cname in c(ycol, unitcol, timecol, ttimecol)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  mode <- tolower(as.character(mode))
  if (!(mode %in% c("shift", "permute"))) stop("mode は 'shift' または 'permute' を指定してください")

  suppressWarnings(placebo_shift <- as.integer(placebo_shift))
  suppressWarnings(min_lag <- as.integer(min_lag))
  suppressWarnings(max_lead <- as.integer(max_lead))
  suppressWarnings(ref_k <- as.integer(ref_k))
  suppressWarnings(reps <- as.integer(reps))
  suppressWarnings(seed <- as.integer(seed))
  suppressWarnings(focus_k <- as.integer(focus_k))

  if (is.na(placebo_shift)) placebo_shift <- -5L
  if (is.na(min_lag)) min_lag <- -5L
  if (is.na(max_lead)) max_lead <- 5L
  if (is.na(ref_k)) ref_k <- -1L
  if (is.na(reps) || reps < 50) reps <- 200L
  if (is.na(seed)) seed <- 123L
  if (is.na(focus_k)) focus_k <- 1L

  if (min_lag >= 0) stop("min_lag は負の値（例: -5）を推奨します")
  if (max_lead <= 0) stop("max_lead は正の値（例: 5）を推奨します")
  if (ref_k < min_lag || ref_k > max_lead) stop("ref_k は [min_lag, max_lead] の範囲内にしてください")

  # ---- prepare df ----
  df <- data[, c(ycol, unitcol, timecol, ttimecol), drop = FALSE]

  # y numeric coercion
  if (!is.numeric(df[[ycol]])) {
    y0 <- df[[ycol]]
    suppressWarnings(df[[ycol]] <- as.numeric(gsub(",", "", as.character(df[[ycol]]))))
    if (all(is.na(df[[ycol]])) && any(!is.na(y0))) stop("y は数値列である必要があります")
  }

  # time / treat_time numeric coercion
  for (nm in c(timecol, ttimecol)) {
    if (!is.numeric(df[[nm]])) {
      x0 <- df[[nm]]
      suppressWarnings(df[[nm]] <- as.numeric(gsub(",", "", as.character(df[[nm]]))))
      if (all(is.na(df[[nm]])) && any(!is.na(x0))) stop(paste0(nm, " は数値列である必要があります"))
    }
  }

  df[[unitcol]] <- as.factor(df[[unitcol]])

  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 20) stop("有効データが少なすぎます（NA除外後）")
  if (nlevels(df[[unitcol]]) < 2) stop("unit は2水準以上必要です")

  # never-treated: allow NA treat_time
  treat_time_orig <- df[[ttimecol]]
  never <- is.na(treat_time_orig)

  warnings_out <- list()
  if (any(never)) {
    warnings_out <- c(warnings_out, list(list(
      code = "NEVER_TREATED_PRESENT",
      severity = "info",
      message = "treat_time が NA の unit（never-treated）が含まれています。placeboではそのまま扱います（kダミーは0のまま）。"
    )))
  }

  # ---- helper: run TWFE event-study and extract table ----
  run_event_study_twfe <- function(df_in, treat_time_vec) {

    df2 <- df_in
    df2$.treat_time <- treat_time_vec

    # k
    df2$k <- NA_integer_
    df2$k[!is.na(df2$.treat_time)] <- as.integer(round(df2[[timecol]][!is.na(df2$.treat_time)] - df2$.treat_time[!is.na(df2$.treat_time)]))

    ks <- seq(min_lag, max_lead)
    ks_use <- ks[ks != ref_k]

    # create dummies
    for (kk in ks_use) {
      nm <- paste0("K_", ifelse(kk < 0, paste0("m", abs(kk)), paste0("p", kk)))
      df2[[nm]] <- 0
      idx <- which(!is.na(df2$k) & df2$k == kk)
      if (length(idx) > 0) df2[[nm]][idx] <- 1
    }

    dcols <- paste0("K_", ifelse(ks_use < 0, paste0("m", abs(ks_use)), paste0("p", ks_use)))
    rhs <- paste(c(dcols, paste0("factor(", unitcol, ")"), paste0("factor(", timecol, ")")), collapse = " + ")
    fml <- stats::as.formula(paste0(ycol, " ~ ", rhs))

    fit <- stats::lm(fml, data = df2)
    sm <- summary(fit)
    coef_mat <- sm$coefficients

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
      if (!is.null(coef_mat) && (nm %in% rownames(coef_mat))) {
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
      }
    }

    # add reference
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

    list(
      est_tbl = est_tbl,
      fit = fit,
      r2 = unname(sm$r.squared),
      adj_r2 = unname(sm$adj.r.squared)
    )
  }

  # ---- mode: shift ----
  figures_out <- list()
  perm_tbl <- data.frame()
  p_perm <- NA_real_
  obs_stat <- NA_real_

  if (mode == "shift") {

    # shift treat_time for treated units only
    t_placebo <- treat_time_orig
    t_placebo[!is.na(t_placebo)] <- t_placebo[!is.na(t_placebo)] + placebo_shift

    res <- run_event_study_twfe(df, t_placebo)
    est_tbl <- res$est_tbl

    # optional plot
    plot_file <- NULL
    if (isTRUE(draw_plot)) {
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
    }
    if (!is.null(plot_file)) {
      figures_out <- list(list(id = "placebo_event_study", title = "Placebo event study plot", path = plot_file))
    }

    metrics <- data.frame(
      mode = "shift",
      placebo_shift = placebo_shift,
      n_used = nrow(df),
      n_units = nlevels(df[[unitcol]]),
      n_times = length(unique(df[[timecol]])),
      min_lag = min_lag,
      max_lead = max_lead,
      ref_k = ref_k,
      r_squared = res$r2,
      adj_r_squared = res$adj_r2,
      stringsAsFactors = FALSE
    )

    headline <- paste0("Placebo test（shift）: treat_time を ", placebo_shift, " シフトして推定しました。")

    list(
      summary = list(
        headline = headline,
        method_used = "Placebo shift + TWFE event study (lm with unit/time FE)",
        key_metrics = list(
          mode = "shift",
          placebo_shift = placebo_shift,
          n_used = nrow(df),
          n_units = nlevels(df[[unitcol]]),
          r_squared = res$r2
        ),
        interpretation_notes = list(
          "placebo（偽の介入時点）でも post期効果が強く出る場合、モデル仕様や前提（平行トレンド等）を再点検してください。",
          "staggered adoption ではTWFE event studyに限界があるため、より頑健な推定法も検討してください。"
        )
      ),
      tables = list(
        list(id = "model_metrics", title = "モデル指標", data = metrics),
        list(id = "placebo_effects", title = "Placebo event-time 推定結果", data = est_tbl)
      ),
      figures = figures_out,
      warnings = warnings_out,
    errors = list()
    )

  }

  # ---- mode: permute ----
  # (Permutation distribution for a chosen statistic)
  if (mode == "permute") {

    set.seed(seed)

    # observed (using original treat_time)
    obs <- run_event_study_twfe(df, treat_time_orig)
    obs_tbl <- obs$est_tbl

    # compute statistic from est table
    compute_stat <- function(est_tbl) {
      if (stat == "post_avg") {
        post <- est_tbl[est_tbl$k >= 1 & !is.na(est_tbl$estimate), , drop = FALSE]
        if (nrow(post) < 1) return(NA_real_)
        return(mean(post$estimate))
      }
      if (stat == "post_min_p") {
        post <- est_tbl[est_tbl$k >= 1 & !is.na(est_tbl$p_value), , drop = FALSE]
        if (nrow(post) < 1) return(NA_real_)
        return(min(post$p_value))
      }
      if (stat == "k_specific") {
        row <- est_tbl[est_tbl$k == focus_k, , drop = FALSE]
        if (nrow(row) < 1) return(NA_real_)
        return(as.numeric(row$estimate[1]))
      }
      # default
      post <- est_tbl[est_tbl$k >= 1 & !is.na(est_tbl$estimate), , drop = FALSE]
      if (nrow(post) < 1) return(NA_real_)
      mean(post$estimate)
    }

    obs_stat <- compute_stat(obs_tbl)

    # permute treat_time across units:
    # build unit-level treat_time vector then shuffle among units, then map back to rows
    unit_levels <- levels(df[[unitcol]])
    unit_tt <- tapply(treat_time_orig, df[[unitcol]], function(v) v[1])
    unit_tt <- unit_tt[unit_levels]

    # if some units have multiple treat_time values (shouldn't), warn
    # (we won't hard-stop)
    # Determine if within-unit treat_time varies
    var_within <- tapply(treat_time_orig, df[[unitcol]], function(v) length(unique(v[!is.na(v)])) > 1)
    if (any(var_within, na.rm = TRUE)) {
      warnings_out <- c(warnings_out, list(list(
        code = "TREAT_TIME_VARIES_WITHIN_UNIT",
        severity = "info",
        message = "同一unit内で treat_time が複数値あります。先頭の値を代表として使用します。"
      )))
    }

    stats_vec <- rep(NA_real_, reps)

    for (b in seq_len(reps)) {
      perm_tt <- sample(unit_tt, size = length(unit_tt), replace = FALSE)
      # map to rows
      tt_row <- perm_tt[as.integer(df[[unitcol]])]
      res_b <- run_event_study_twfe(df, tt_row)
      stats_vec[b] <- compute_stat(res_b$est_tbl)
    }

    # permutation p-value (two-sided for estimates, one-sided for min p)
    if (stat == "post_min_p") {
      # smaller is "more extreme"
      p_perm <- mean(stats_vec <= obs_stat, na.rm = TRUE)
    } else {
      p_perm <- mean(abs(stats_vec) >= abs(obs_stat), na.rm = TRUE)
    }

    perm_tbl <- data.frame(
      rep = seq_len(reps),
      stat_value = stats_vec,
      stringsAsFactors = FALSE
    )

    obs_tbl2 <- obs_tbl
    obs_tbl2$note <- ifelse(obs_tbl2$k == ref_k, "reference", "")

    metrics <- data.frame(
      mode = "permute",
      stat = stat,
      focus_k = ifelse(stat == "k_specific", focus_k, NA_integer_),
      reps = reps,
      seed = seed,
      observed_stat = obs_stat,
      perm_p_value = p_perm,
      n_used = nrow(df),
      n_units = nlevels(df[[unitcol]]),
      n_times = length(unique(df[[timecol]])),
      min_lag = min_lag,
      max_lead = max_lead,
      ref_k = ref_k,
      r_squared = obs$r2,
      adj_r_squared = obs$adj_r2,
      stringsAsFactors = FALSE
    )

    # optional plot if helper exists
    plot_file <- NULL
    if (isTRUE(draw_plot)) {
      plot_file <- tryCatch({
        if (exists("make_placebo_perm_plot", mode = "function")) {
          make_placebo_perm_plot(perm_tbl, obs_stat = obs_stat)
        } else {
          NULL
        }
      }, error = function(e) NULL)
    }
    if (!is.null(plot_file)) {
      figures_out <- list(list(id = "placebo_perm", title = "Permutation placebo distribution", path = plot_file))
    }

    headline <- paste0("Placebo test（permute）: p = ", signif(p_perm, 3), "（", stat, "）")

    list(
      summary = list(
        headline = headline,
        method_used = "Permutation placebo (shuffle treat_time across units) + TWFE event study",
        key_metrics = list(
          mode = "permute",
          stat = stat,
          observed_stat = obs_stat,
          perm_p_value = p_perm,
          reps = reps,
          n_used = nrow(df)
        ),
        interpretation_notes = list(
          "Permutation placeboは『ランダムな介入割当でも同程度の効果が出るか』の感度分析です。",
          "staggered adoption ではTWFE event studyに限界があるため、より頑健な推定法も検討してください。"
        )
      ),
      tables = list(
        list(id = "model_metrics", title = "モデル指標", data = metrics),
        list(id = "observed_event_time", title = "観測データの event-time 推定", data = obs_tbl2),
        list(id = "perm_distribution", title = "Permutation 分布（stat）", data = perm_tbl)
      ),
      figures = figures_out,
      warnings = warnings_out,
    errors = list()
    )
  }
}

run <- run_recipe_impl
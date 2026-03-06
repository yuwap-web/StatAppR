# recipes/meta_analysis.R

# Create persistent results directory (respects STATAPPR_RESULTS_FOLDER env var)
.ensure_results_dir <- function() {
  results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  }
  results_dir
}

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

make_unique_labels <- function(x) {
  out <- x
  seen <- list()
  for (i in seq_along(out)) {
    key <- out[i]
    if (is.null(seen[[key]])) {
      seen[[key]] <- 1L
    } else {
      seen[[key]] <- seen[[key]] + 1L
      out[i] <- paste0(key, "__", seen[[key]])
    }
  }
  out
}

# ---- forest plot (self-contained) ----
make_forest_plot_meta <- function(study_tbl, pooled_row) {
  # study_tbl: data.frame(label, effect, se, weight)
  # pooled_row: data.frame(conf_low/conf_high/pooled_effect)
  if (is.null(study_tbl) || nrow(study_tbl) < 2) stop("forest plot needs >=2 studies")
  if (is.null(pooled_row) || nrow(pooled_row) < 1) stop("pooled row missing")

  df <- study_tbl
  df$ci_low  <- df$effect - 1.96 * df$se
  df$ci_high <- df$effect + 1.96 * df$se

  # sort by effect (optional). keep current order is also ok; here keep original.
  n <- nrow(df)

  # x range: include pooled CI and all study CI
  x_min <- min(df$ci_low, pooled_row$conf_low, na.rm = TRUE)
  x_max <- max(df$ci_high, pooled_row$conf_high, na.rm = TRUE)

  # pad
  pad <- 0.05 * (x_max - x_min)
  if (!is.finite(pad) || pad <= 0) pad <- 1
  x_min <- x_min - pad
  x_max <- x_max + pad

  # Save to persistent directory (not temp)
  results_dir <- .ensure_results_dir()
  file <- file.path(results_dir, sprintf("forest_plot_meta_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))
  grDevices::png(file, width = 1000, height = 700, res = 120)

  op <- par(no.readonly = TRUE)
  on.exit({
    try(par(op), silent = TRUE)
    try(grDevices::dev.off(), silent = TRUE)
  }, add = TRUE)

  par(mar = c(5, 14, 4, 2))

  # y positions (top to bottom)
  y_study <- rev(seq_len(n))
  y_pool  <- 0

  # blank plot
  plot(
    NA,
    xlim = c(x_min, x_max),
    ylim = c(-1, n + 1),
    xlab = "Effect (with 95% CI)",
    ylab = "",
    yaxt = "n",
    main = "Forest plot (fixed effect)",
    bty = "n"
  )

  axis(2, at = y_study, labels = df$label, las = 2, cex.axis = 0.9)

  # reference lines
  abline(v = 0, lty = 3)  # common reference (MD=0, logOR=0 etc)
  abline(v = pooled_row$pooled_effect[1], lty = 2)  # pooled estimate

  # study CIs and points (size by weight)
  w <- df$weight
  w <- w / max(w, na.rm = TRUE)
  cex_pt <- 0.8 + 1.6 * w

  segments(df$ci_low, y_study, df$ci_high, y_study, lwd = 2)
  points(df$effect, y_study, pch = 15, cex = cex_pt)

  # pooled diamond
  pe  <- pooled_row$pooled_effect[1]
  lwr <- pooled_row$conf_low[1]
  upr <- pooled_row$conf_high[1]

  diamond_y <- y_pool
  diamond_h <- 0.35

  polygon(
    x = c(lwr, pe, upr, pe),
    y = c(diamond_y, diamond_y + diamond_h, diamond_y, diamond_y - diamond_h),
    border = "black"
  )
  text(x = x_min, y = diamond_y, labels = "Pooled", pos = 4, cex = 0.95)

  file
}

run_recipe_impl <- function(request, data) {

  eff <- request$variables$effect
  se  <- request$variables$se
  label <- request$variables$label  # optional

  if (is.null(eff) || eff == "") stop("variables.effect が必要です（効果量）")
  if (is.null(se)  || se  == "") stop("variables.se が必要です（標準誤差）")
  if (!(eff %in% names(data))) stop(paste0("effect column not found: ", eff))
  if (!(se  %in% names(data))) stop(paste0("se column not found: ", se))

  df <- data.frame(
    effect = data[[eff]],
    se = data[[se]],
    stringsAsFactors = FALSE
  )

  # numeric coercion (CSV safety)
  if (!is.numeric(df$effect)) {
    e0 <- df$effect
    suppressWarnings(df$effect <- as.numeric(gsub(",", "", as.character(df$effect))))
    if (all(is.na(df$effect)) && any(!is.na(e0))) stop("effect は数値列である必要があります")
  }
  if (!is.numeric(df$se)) {
    s0 <- df$se
    suppressWarnings(df$se <- as.numeric(gsub(",", "", as.character(df$se))))
    if (all(is.na(df$se)) && any(!is.na(s0))) stop("se は数値列である必要があります")
  }

  # label column handling (solid)
  label_col_ok <- (!is.null(label) && label != "" && (label %in% names(data)))
  if (label_col_ok) {
    lab_raw <- as.character(data[[label]])
  } else {
    lab_raw <- rep(NA_character_, nrow(data))
  }

  # normalize whitespace / empty -> NA
  lab_raw <- trimws(lab_raw)
  lab_raw[lab_raw == ""] <- NA_character_

  # keep row_id before dropping NA rows
  df$row_id <- seq_len(nrow(df))
  df$label <- lab_raw

  # complete cases on effect/se (do NOT require label)
  ok <- stats::complete.cases(df[, c("effect", "se"), drop = FALSE])
  df <- df[ok, , drop = FALSE]

  if (nrow(df) < 2) stop("メタ解析には少なくとも2研究が必要です")
  if (any(df$se <= 0, na.rm = TRUE)) stop("se は正の値である必要があります")

  # fill missing labels after filtering
  miss_lab <- is.na(df$label) | !nzchar(df$label)
  if (any(miss_lab)) {
    df$label[miss_lab] <- paste0("study_", df$row_id[miss_lab])
  }

  # paranoia
  df$label[is.na(df$label)] <- paste0("study_", df$row_id[is.na(df$label)])

  # make labels unique (important for forest plot)
  df$label <- make_unique_labels(df$label)

  # Fixed effect (inverse-variance)
  w <- 1 / (df$se^2)
  fixed <- sum(w * df$effect) / sum(w)
  se_fixed <- sqrt(1 / sum(w))
  ci <- c(fixed - 1.96 * se_fixed, fixed + 1.96 * se_fixed)
  z <- fixed / se_fixed
  p <- 2 * (1 - stats::pnorm(abs(z)))

  # Heterogeneity (Cochran's Q, I^2)
  Q <- sum(w * (df$effect - fixed)^2)
  df_Q <- nrow(df) - 1
  p_Q <- 1 - stats::pchisq(Q, df = df_Q)
  I2 <- max(0, (Q - df_Q) / Q) * 100
  if (is.nan(I2)) I2 <- 0

  study_tbl <- data.frame(
    label = df$label,
    effect = df$effect,
    se = df$se,
    weight = w / sum(w),
    stringsAsFactors = FALSE
  )

  pooled <- data.frame(
    model = "fixed_effect",
    pooled_effect = fixed,
    se = se_fixed,
    conf_low = ci[1],
    conf_high = ci[2],
    z = z,
    p_value = p,
    Q = Q,
    Q_df = df_Q,
    Q_p_value = p_Q,
    I2_percent = I2,
    n_studies = nrow(df),
    stringsAsFactors = FALSE
  )

  warnings_out <- list()

  if (label_col_ok) {
    n_missing_original <- sum(is.na(lab_raw) | !nzchar(lab_raw), na.rm = TRUE)
    if (n_missing_original > 0) {
      warnings_out <- c(warnings_out, list(list(
        code = "LABEL_MISSING_FILLED",
        severity = "info",
        message = paste0("label 欠損が ", n_missing_original, " 件あり、自動補完しました（study_行番号）。")
      )))
    }
  }

  # ---- forest plot ----
  forest_file <- tryCatch(
    make_forest_plot_meta(study_tbl, pooled),
    error = function(e) {
      warnings_out <<- c(warnings_out, list(list(
        code = "FOREST_PLOT_FAILED",
        severity = "info",
        message = paste0("forest plot の生成に失敗しました: ", conditionMessage(e))
      )))
      NULL
    }
  )

  list(
    summary = list(
      headline = paste0("メタ解析（固定効果）: p = ", signif(p, 3)),
      method_used = "固定効果（逆分散重み）",
      key_metrics = list(
        pooled_effect = fixed,
        p_value = p,
        I2_percent = I2,
        n_studies = nrow(df)
      ),
      interpretation_notes = list(
        "I²が高い場合は異質性が大きい可能性があります（ランダム効果モデルも検討）。",
        "effect/se の定義（log OR, 平均差など）を明確にしてください。",
        "forest plot は effect のスケール（例：log OR）にそのまま従います。必要なら軸変換（expなど）版も追加できます。"
      )
    ),
    tables = list(
      list(id = "study_weights", title = "研究別（重み）", data = study_tbl),
      list(id = "pooled", title = "統合推定（固定効果）", data = pooled)
    ),
    figures = if (!is.null(forest_file)) list(
      list(
        id = "forest",
        title = "Forest plot (fixed effect)",
        path = forest_file
      )
    ) else list(),
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
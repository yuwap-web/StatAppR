# recipes/balance_table.R

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  treat_col <- request$variables$treat %||% request$variables$treatment
  xraw      <- request$variables$x

  # optional
  w_col <- request$variables$weights %||% request$variables$weight
  smd_thr <- request$variables$smd_threshold %||% 0.1
  suppressWarnings(smd_thr <- as.numeric(smd_thr))
  if (is.na(smd_thr) || smd_thr <= 0) smd_thr <- 0.1

  if (is.null(treat_col) || treat_col == "") stop("variables.treat（または treatment）が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("variables.x（共変量）が必要です")
  if (!(treat_col %in% names(data))) stop(paste0("treat column not found: ", treat_col))

  # ---- normalize x (array or "a,b") ----
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
    xs <- trimws(xs)
    xs <- xs[xs != ""]
  }

  # drop accidental treat in x
  xs <- setdiff(xs, treat_col)

  if (length(xs) < 1) stop("x は1つ以上必要です")

  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("x columns not found: ", paste(miss, collapse = ", ")))

  if (!is.null(w_col) && w_col != "") {
    if (!(w_col %in% names(data))) stop(paste0("weights column not found: ", w_col))
  } else {
    w_col <- NULL
  }

  cols <- unique(c(treat_col, xs, w_col))
  df <- data[, cols, drop = FALSE]

  # ---- treat normalize to 0/1 ----
  tr <- df[[treat_col]]
  if (is.factor(tr)) tr <- as.character(tr)
  if (is.logical(tr)) tr <- ifelse(tr, 1, 0)
  if (is.character(tr)) {
    v <- tolower(trimws(tr))
    v[v %in% c("t", "true", "yes", "y", "1", "treated")] <- "1"
    v[v %in% c("f", "false", "no", "n", "0", "control")] <- "0"
    suppressWarnings(trn <- as.numeric(v))
  } else {
    suppressWarnings(trn <- as.numeric(tr))
  }
  if (!all(trn %in% c(0,1), na.rm = TRUE)) {
    stop("treat は 0/1（または TRUE/FALSE, yes/no）である必要があります")
  }
  df[[treat_col]] <- trn

  # ---- weights ----
  if (!is.null(w_col)) {
    w <- df[[w_col]]
    if (is.factor(w)) w <- as.character(w)
    if (!is.numeric(w)) {
      w0 <- w
      suppressWarnings(w <- as.numeric(gsub(",", "", as.character(w))))
      if (all(is.na(w)) && any(!is.na(w0))) stop("weights は数値列である必要があります")
    }
    if (any(!is.finite(w), na.rm = TRUE)) stop("weights に Inf/NaN が含まれています")
    if (any(w <= 0, na.rm = TRUE)) stop("weights は正の値である必要があります")
    df[[w_col]] <- w
  }

  # complete cases (treat + x (+ weights))
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 10) stop("有効データが少なすぎます（NA除外後）")

  # ---- helpers ----
  wmean <- function(x, w) sum(w * x) / sum(w)
  wvar  <- function(x, w) {
    m <- wmean(x, w)
    sum(w * (x - m)^2) / sum(w)
  }
  wsd <- function(x, w) sqrt(wvar(x, w))

  # SMD for numeric
  smd_num <- function(x, g, w = NULL) {
    if (is.null(w)) {
      m1 <- mean(x[g==1], na.rm = TRUE)
      m0 <- mean(x[g==0], na.rm = TRUE)
      s1 <- stats::sd(x[g==1], na.rm = TRUE)
      s0 <- stats::sd(x[g==0], na.rm = TRUE)
      sp <- sqrt((s1^2 + s0^2) / 2)
    } else {
      m1 <- wmean(x[g==1], w[g==1])
      m0 <- wmean(x[g==0], w[g==0])
      s1 <- wsd(x[g==1], w[g==1])
      s0 <- wsd(x[g==0], w[g==0])
      sp <- sqrt((s1^2 + s0^2) / 2)
    }
    if (!is.finite(sp) || sp == 0) return(NA_real_)
    (m1 - m0) / sp
  }

  # SMD for binary indicator (0/1)
  smd_bin <- function(x01, g, w = NULL) {
    if (is.null(w)) {
      p1 <- mean(x01[g==1], na.rm = TRUE)
      p0 <- mean(x01[g==0], na.rm = TRUE)
    } else {
      p1 <- wmean(x01[g==1], w[g==1])
      p0 <- wmean(x01[g==0], w[g==0])
    }
    p <- (p1 + p0) / 2
    denom <- sqrt(p * (1 - p))
    if (!is.finite(denom) || denom == 0) return(NA_real_)
    (p1 - p0) / denom
  }

  g <- df[[treat_col]]
  w <- if (!is.null(w_col)) df[[w_col]] else NULL

  # ---- build balance table ----
  out_rows <- list()

  for (nm in xs) {

    x <- df[[nm]]

    # treat character/factor as categorical
    if (is.factor(x) || is.character(x) || is.logical(x)) {

      if (is.logical(x)) x <- ifelse(x, "TRUE", "FALSE")
      if (is.factor(x)) x <- as.character(x)
      x <- trimws(as.character(x))
      x[x == ""] <- NA_character_
      # already complete.cases, but keep safe:
      x <- x

      lv <- sort(unique(x))
      lv <- lv[!is.na(lv)]
      if (length(lv) < 2) {
        # single-level, still report counts
        lv <- lv[1]
      }

      # create indicators for each level (except baseline) to compute SMD
      baseline <- lv[1]
      for (k in lv) {
        ind <- as.numeric(x == k)
        if (is.null(w)) {
          p1 <- mean(ind[g==1], na.rm = TRUE)
          p0 <- mean(ind[g==0], na.rm = TRUE)
        } else {
          p1 <- wmean(ind[g==1], w[g==1])
          p0 <- wmean(ind[g==0], w[g==0])
        }
        smd <- smd_bin(ind, g, w)

        out_rows[[length(out_rows)+1]] <- data.frame(
          variable = nm,
          level = k,
          type = "categorical",
          treated = p1,
          control = p0,
          diff = p1 - p0,
          smd = smd,
          stringsAsFactors = FALSE
        )
      }

    } else {

      # numeric coercion if possible
      if (!is.numeric(x)) {
        x0 <- x
        suppressWarnings(x <- as.numeric(gsub(",", "", as.character(x))))
        if (all(is.na(x)) && any(!is.na(x0))) {
          stop(paste0("x column not numeric/categorical: ", nm))
        }
      }

      if (is.null(w)) {
        m1 <- mean(x[g==1], na.rm = TRUE)
        m0 <- mean(x[g==0], na.rm = TRUE)
        s1 <- stats::sd(x[g==1], na.rm = TRUE)
        s0 <- stats::sd(x[g==0], na.rm = TRUE)
      } else {
        m1 <- wmean(x[g==1], w[g==1])
        m0 <- wmean(x[g==0], w[g==0])
        s1 <- wsd(x[g==1], w[g==1])
        s0 <- wsd(x[g==0], w[g==0])
      }

      smd <- smd_num(x, g, w)

      out_rows[[length(out_rows)+1]] <- data.frame(
        variable = nm,
        level = "",
        type = "numeric",
        treated = m1,
        control = m0,
        diff = m1 - m0,
        smd = smd,
        treated_sd = s1,
        control_sd = s0,
        stringsAsFactors = FALSE
      )
    }
  }

  bal <- do.call(rbind, out_rows)
  rownames(bal) <- NULL

  # flag imbalance
  bal$abs_smd <- abs(bal$smd)
  bal$imbalanced <- ifelse(is.na(bal$abs_smd), NA, bal$abs_smd >= smd_thr)

  # summary metrics
  max_smd <- suppressWarnings(max(bal$abs_smd, na.rm = TRUE))
  mean_smd <- suppressWarnings(mean(bal$abs_smd, na.rm = TRUE))
  n_imbal <- suppressWarnings(sum(bal$imbalanced %in% TRUE, na.rm = TRUE))

  metrics <- data.frame(
    n_used = nrow(df),
    weighted = !is.null(w_col),
    max_abs_smd = max_smd,
    mean_abs_smd = mean_smd,
    n_imbalanced = n_imbal,
    smd_threshold = smd_thr,
    stringsAsFactors = FALSE
  )

  warnings_out <- list()
  if (is.finite(max_smd) && max_smd >= 0.2) {
    warnings_out <- c(warnings_out, list(list(
      code = "LARGE_IMBALANCE",
      severity = "info",
      message = "バランス不良（|SMD|が大きい共変量）が残っています。PSモデル見直し、トリミング、マッチング等を検討してください。"
    )))
  }

  headline <- paste0("Balance table: max |SMD| = ", signif(max_smd, 3))
  if (is.finite(max_smd) && max_smd < smd_thr) headline <- "Balance table: 指定閾値以内に概ね収まりました。"

  # ---- optional plot (if you already have utils/balance_plot.R) ----
  balance_plot_file <- NULL
  balance_plot_file <- tryCatch({
    if (exists("make_balance_plot", mode = "function")) {
      make_balance_plot(
        bal,
        smd_col = "smd",
        label_col = "variable",
        threshold = smd_thr
      )
    } else {
      NULL
    }
  }, error = function(e) NULL)

  figures_out <- list()
  if (!is.null(balance_plot_file)) {
    figures_out <- list(list(
      id = "balance_plot",
      title = "Covariate Balance (SMD Love plot)",
      path = balance_plot_file
    ))
  }

  list(
    summary = list(
      headline = headline,
      method_used = if (!is.null(w_col)) "Weighted balance table (SMD)" else "Unweighted balance table (SMD)",
      key_metrics = list(
        n_used = nrow(df),
        weighted = !is.null(w_col),
        max_abs_smd = max_smd,
        mean_abs_smd = mean_smd,
        n_imbalanced = n_imbal,
        smd_threshold = smd_thr
      ),
      interpretation_notes = list(
        "SMD（Standardized Mean Difference）は群間の共変量バランスを評価します。",
        "一般に |SMD| < 0.1 が目安として使われることが多いです（分野により異なります）。",
        "重み（IPTW等）がある場合は weights 列を指定すると、重み付きSMDを計算します。"
      )
    ),
    tables = list(
      list(id = "model_metrics", title = "指標", data = metrics),
      list(id = "balance_table", title = "Balance table（SMD）", data = bal)
    ),
    figures = figures_out,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
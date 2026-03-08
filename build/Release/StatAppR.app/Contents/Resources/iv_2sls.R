# recipes/iv_2sls.R

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

# Source plot utilities
tryCatch({
  source(file.path(runner_dir, "utils/plot_utils.R"), local = TRUE)
}, error = function(e) {
  # plot_utils failed to load - continue without plots
})


  ycol <- request$variables$y

  # treat / treatment どちらでも受ける
  trt  <- request$variables$treat %||% request$variables$treatment

  zcol <- request$variables$z
  xraw <- request$variables$x %||% character(0)

  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (is.null(trt)  || trt  == "") stop("variables.treat（または treatment）が必要です")
  if (is.null(zcol) || zcol == "") stop("variables.z（instrument）が必要です")

  # columns exist
  need <- c(ycol, trt, zcol)
  miss0 <- need[!(need %in% names(data))]
  if (length(miss0) > 0) stop(paste0("columns not found: ", paste(miss0, collapse = ", ")))

  # x を vector に正規化（配列 or "a,b"）
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

  if (length(xs) > 0) {
    miss <- xs[!(xs %in% names(data))]
    if (length(miss) > 0) stop(paste0("covariate columns not found: ", paste(miss, collapse = ", ")))
  }

  # Check if AER package is available; otherwise use manual 2SLS fallback
  use_fallback <- !requireNamespace("AER", quietly = TRUE)
  fallback_warning <- NULL

  # use only required columns and complete cases there
  cols <- unique(c(ycol, trt, zcol, xs))
  df <- data[, cols, drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]
  if (nrow(df) < 10) stop("有効データが少なすぎます（NA除外後）")

  rhs1 <- paste(c(trt, xs), collapse = " + ")
  rhs2 <- paste(c(zcol, xs), collapse = " + ")
  f <- stats::as.formula(paste0(ycol, " ~ ", rhs1, " | ", rhs2))

  if (!use_fallback) {
    # ✅ AER: IV regression (primary method)
    fit <- AER::ivreg(f, data = df)
    sm <- summary(fit, diagnostics = TRUE)
    has_diagnostics <- TRUE
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
    fs_formula <- stats::as.formula(paste0(trt, " ~ ", paste(c(zcol, xs), collapse = " + ")))
    fs_fit <- stats::lm(fs_formula, data = df)
    df$trt_pred <- predict(fs_fit)

    # Second stage: predicted treatment → outcome
    ss_formula <- stats::as.formula(paste0(ycol, " ~ trt_pred + ", ifelse(length(xs) > 0, paste(xs, collapse = " + "), "1")))
    ss_fit <- stats::lm(ss_formula, data = df)

    # Extract coefficients
    ss_sm <- summary(ss_fit)

    # Create a mock AER-style summary object for compatibility
    sm <- list()
    sm$coefficients <- ss_sm$coefficients
    sm$diagnostics <- NULL
    has_diagnostics <- FALSE

    # Store fits for later use
    attr(sm, "fs_fit") <- fs_fit
    attr(sm, "ss_fit") <- ss_fit
  }

  co <- sm$coefficients
  if (is.null(co) || nrow(co) < 1) stop("ivreg coefficients not available")

  # ---- robust: locate treatment row in coefficients ----
  rn <- rownames(co)

  # In fallback 2SLS, the predicted treatment is named trt_pred
  trt_candidates <- if (use_fallback) {
    c("trt_pred", trt, paste0("`", trt, "`"))
  } else {
    c(trt, paste0("`", trt, "`"))
  }

  idx <- which(rn %in% trt_candidates)

  if (length(idx) == 0) {
    # try regex exact match (just in case of escaping)
    idx <- which(grepl(paste0("^`?", gsub("([\\W])", "\\\\\\1", trt), "`?$"), rn))
  }

  if (length(idx) == 0 && use_fallback) {
    # For fallback, also try trt_pred if not found
    idx <- which(grepl("trt_pred", rn))
  }

  if (length(idx) == 0) {
    # last resort: start-with match (e.g. trt1, trtTRUE) -> warn by stopping with hints
    near <- rn[grepl(paste0("^`?", gsub("([\\W])", "\\\\\\1", trt)), rn)]
    hint <- if (length(near) > 0) {
      paste0("近い係数名: ", paste(head(near, 10), collapse = ", "))
    } else {
      paste0("係数名の例: ", paste(head(rn, 10), collapse = ", "))
    }
    stop(paste0("treatment term not found in ivreg coefficients. ", hint))
  }
  idx <- idx[1]
  # -----------------------------------------------

  est <- unname(co[idx, 1])
  se  <- unname(co[idx, 2])
  p   <- unname(co[idx, 4])
  ciL <- est - 1.96 * se
  ciH <- est + 1.96 * se

  main_tbl <- data.frame(
    term = rn[idx],
    estimate = est,
    std_error = se,
    conf_low = ciL,
    conf_high = ciH,
    p_value = p,
    stringsAsFactors = FALSE
  )

  # diagnostics table (robust extraction)
  diag_tbl <- data.frame()
  if (!is.null(sm$diagnostics)) {
    d <- sm$diagnostics
    cn <- colnames(d)
    stat_col <- cn[grepl("stat", cn, ignore.case = TRUE)][1] %||% cn[1]
    p_col <- cn[grepl("^p", cn, ignore.case = TRUE)][1] %||% cn[ncol(d)]

    diag_tbl <- data.frame(
      test = rownames(d),
      statistic = unname(d[, stat_col]),
      p_value = unname(d[, p_col]),
      stringsAsFactors = FALSE
    )
    rownames(diag_tbl) <- NULL
  } else if (use_fallback) {
    # For manual 2SLS fallback, compute first-stage F statistic as diagnostic
    fs_fit <- attr(sm, "fs_fit")
    fs_sm <- summary(fs_fit)
    fs_r2 <- fs_sm$r.squared
    fs_f <- (fs_r2 / (1 - fs_r2)) * (nrow(df) - length(fs_sm$coefficients[, 1]))

    diag_tbl <- data.frame(
      test = c("First Stage F-stat"),
      statistic = fs_f,
      p_value = 1 - stats::pf(fs_f, length(xs) + 1, nrow(df) - length(xs) - 2),
      stringsAsFactors = FALSE
    )
  }

  headline <- paste0("IV（2SLS）: p = ", signif(p, 3))
  if (!is.na(p) && p < 0.05) headline <- "IV（2SLS）: 有意な治療効果が示唆されました。"

  method_label <- if (use_fallback) "Manual 2SLS (fallback)" else "AER::ivreg (2SLS)"

  warnings_out <- list()
  if (!is.null(fallback_warning)) {
    warnings_out <- list(fallback_warning)
  }

  # ---- 図表生成 ----

  figures <- list()


  tryCatch({

    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")

    if (!dir.exists(results_dir)) {

      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

    }

    plot_file <- file.path(results_dir, sprintf("iv_2sls_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))


    png(plot_file, width = 800, height = 600)

    plot(1:10, main = "IV/2SLS Plot")

    dev.off()


    if (file.exists(plot_file)) {

      figures <- c(figures, list(list(

        id = "iv_2sls",

        title = "IV/2SLS Plot",

        type = "plot",

        path = plot_file

      )))

    }

  }, error = function(e) {

    warnings_out <<- c(warnings_out, list(list(

      code = "PLOT_GENERATION_FAILED",

      severity = "info",

      message = paste("図表生成に失敗しました:", e$message)

    )))

  })

  list(
    summary = list(
      headline = headline,
      method_used = method_label,
      key_metrics = list(
        estimate = est,
        p_value = p,
        n_used = nrow(df)
      ),
      interpretation_notes = list(
        "weak instrument（弱い操作変数）の場合、推定が不安定になります。diagnostics を確認してください。",
        "IVの前提（排除制約など）はデータだけでは検証できません。"
      )
    ),
    tables = list(
      list(id = "iv_effect", title = "IV推定（treatの効果）", data = main_tbl),
      list(id = "iv_diagnostics", title = "IV diagnostics", data = diag_tbl)
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl

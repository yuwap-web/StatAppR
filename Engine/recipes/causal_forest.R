# recipes/causal_forest.R
# Heterogeneous Treatment Effect estimation using Generalized Random Forest

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

run_recipe_impl <- function(request, data) {

  # Check if grf package is available; otherwise use ranger fallback
  use_fallback <- !requireNamespace("grf", quietly = TRUE)
  fallback_warning <- NULL

  y_col <- request$variables$outcome_column %||% request$variables$y
  w_col <- request$variables$treatment_column %||% request$variables$w %||% request$variables$treat
  xraw  <- request$variables$predictor_columns %||% request$variables$x

  n_trees <- request$variables$n_trees %||% 2000
  seed    <- request$variables$seed %||% 1
  plot    <- request$variables$plot %||% TRUE

  if (is.null(y_col) || y_col == "") stop("request$variables$outcome_column が必要です")
  if (is.null(w_col) || w_col == "") stop("request$variables$treatment_column が必要です")
  if (is.null(xraw)  || length(xraw) == 0) stop("request$variables$predictor_columns が必要です")

  # ---- normalize X ----

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
  xvars <- setdiff(xvars, c(y_col, w_col))

  if (length(xvars) < 1) stop("x が空です")

  for (cname in c(y_col, w_col, xvars)) {
    if (!(cname %in% names(data))) {
      stop(paste0("column not found: ", cname))
    }
  }

  df <- data[, c(y_col, w_col, xvars), drop = FALSE]

  # numeric coercion with categorical handling

  num_cast <- function(v) {
    if (is.numeric(v)) return(v)
    suppressWarnings(as.numeric(gsub(",", "", as.character(v))))
  }

  # ---- 型変換前のログ ----
  cat(paste0("🔍 [CausalForest] 型変換前の値:\n"))
  cat(paste0("   outcome ('", y_col, "'): ", paste(head(df[[y_col]], 5), collapse=", "), " ...\n"))
  cat(paste0("   treatment ('", w_col, "'): ", paste(head(df[[w_col]], 5), collapse=", "), " ...\n"))

  # Convert outcome to numeric
  df[[y_col]] <- num_cast(df[[y_col]])

  # Convert treatment: if text, convert to 0/1 (binary treatment)
  if (is.character(df[[w_col]]) || is.factor(df[[w_col]])) {
    # Get unique non-empty values
    unique_vals <- unique(df[[w_col]][df[[w_col]] != "" & !is.na(df[[w_col]])])
    cat(paste0("   treatment のユニーク値 (変換前): ", paste(unique_vals, collapse=", "), "\n"))
    if (length(unique_vals) >= 2) {
      # Binary categorical: first unique value → 1, others → 0
      treatment_val <- unique_vals[1]
      df[[w_col]] <- ifelse(df[[w_col]] == treatment_val, 1, 0)
      cat(paste0("✓ Treatment '", w_col, "' → binary:\n"))
      cat(paste0("  '", treatment_val, "' → 1 (n=", sum(df[[w_col]] == 1, na.rm=TRUE), ")\n"))
      cat(paste0("  Others → 0 (n=", sum(df[[w_col]] == 0, na.rm=TRUE), ")\n"))
    } else {
      # Single value, try numeric conversion
      df[[w_col]] <- num_cast(df[[w_col]])
      cat(paste0("⚠️ treatment のユニーク値が1以下のため numeric に変換\n"))
    }
  } else {
    df[[w_col]] <- num_cast(df[[w_col]])
  }

  # ---- 型変換後のチェック ----
  cat(paste0("✓ 型変換後: outcome NA=", sum(is.na(df[[y_col]])), ", treatment NA=", sum(is.na(df[[w_col]])), "\n"))

  # Convert predictors to numeric
  for (x in xvars) {
    df[[x]] <- num_cast(df[[x]])
  }

  # ---- データ品質チェック（詳細ログ） ----
  cat(paste0("📊 [CausalForest] 初期データ: ", nrow(data), " 行\n"))
  cat(paste0("   outcome列 ('", y_col, "'): NA数 = ", sum(is.na(data[[y_col]])), "\n"))
  cat(paste0("   treatment列 ('", w_col, "'): NA数 = ", sum(is.na(data[[w_col]])), "\n"))

  # Handle missing values more flexibly
  # Remove rows with missing outcome or treatment, but allow missing in predictors
  valid_idx <- !is.na(df[[y_col]]) & !is.na(df[[w_col]])
  n_before <- nrow(df)
  df <- df[valid_idx, , drop = FALSE]
  n <- nrow(df)

  cat(paste0("📊 [CausalForest] フィルタ後: ", n, " 行 (削除: ", n_before - n, " 行)\n"))

  if (n < 15) {
    cat(paste0("❌ エラー: outcome と treatment の両方が有効なデータが不足\n"))
    cat(paste0("   outcome列のユニーク値: ", length(unique(data[[y_col]][!is.na(data[[y_col]])])), "\n"))
    cat(paste0("   treatment列のユニーク値: ", length(unique(data[[w_col]][!is.na(data[[w_col]])])), "\n"))
    cat(paste0("   最低15行のデータが必要です (現在: ", n, " 行)\n"))
    stop("データが少なすぎます。outcome と treatment の両方に有効なデータが必要です")
  }

  # For predictors with missing values, use median/mode imputation
  for (x in xvars) {
    if (any(is.na(df[[x]]))) {
      if (is.numeric(df[[x]])) {
        df[[x]][is.na(df[[x]])] <- median(df[[x]], na.rm = TRUE)
      } else {
        # For categorical, use mode
        df[[x]][is.na(df[[x]])] <- names(sort(table(df[[x]])))[1]
      }
    }
  }

  Y <- df[[y_col]]
  W <- df[[w_col]]
  X <- as.matrix(df[, xvars, drop = FALSE])

  if (!all(W %in% c(0,1))) {
    stop("treatment は 0/1 必須")
  }

  set.seed(seed)

  # ---- causal forest or ranger fallback ----

  if (!use_fallback) {
    # ✅ GRF: Causal Forest (primary method)
    forest <- grf::causal_forest(
      X,
      Y,
      W,
      num.trees = n_trees
    )

    # ---- ATE ----
    ate <- grf::average_treatment_effect(forest)
    ate_est <- ate[1]
    ate_se  <- ate[2]

    # ITE prediction
    tau_hat <- predict(forest)$predictions

    # Variable importance
    vi <- grf::variable_importance(forest)

  } else {
    # ⚠️ FALLBACK: Ranger-based HTE estimation
    fallback_warning <- list(
      code = "CF_FALLBACK_RANGER",
      severity = "warning",
      message = paste0(
        "grf package not available. Using ranger (random forest) for heterogeneous treatment effect estimation as fallback.\\n",
        "For best results, install grf package: install.packages('grf')"
      )
    )

    # Fit separate forests for treated and control groups to estimate HTEs
    # This is a simplified approach compared to causal_forest
    idx_t <- which(W == 1)
    idx_c <- which(W == 0)

    if (length(idx_t) < 10 || length(idx_c) < 10) {
      stop("Insufficient treated or control samples for HTE estimation (need 10+ in each group)")
    }

    # Predict E[Y|X, W=1] and E[Y|X, W=0]
    if (!requireNamespace("ranger", quietly = TRUE)) {
      stop("Neither grf nor ranger packages available. Please install one: install.packages(c('grf', 'ranger'))")
    }

    # Fit on treated group
    forest_t <- ranger::ranger(Y ~ ., data = data.frame(Y = Y[idx_t], X[idx_t, ]), num.trees = n_trees, seed = seed)
    pred_t <- predict(forest_t, data = data.frame(X))$predictions

    # Fit on control group
    forest_c <- ranger::ranger(Y ~ ., data = data.frame(Y = Y[idx_c], X[idx_c, ]), num.trees = n_trees, seed = seed)
    pred_c <- predict(forest_c, data = data.frame(X))$predictions

    # Estimated ITEs
    tau_hat <- pred_t - pred_c

    # Simple ATE: mean of ITEs
    ate_est <- mean(tau_hat, na.rm = TRUE)
    ate_se <- stats::sd(tau_hat, na.rm = TRUE) / sqrt(length(tau_hat))

    # Variable importance: use treatment × covariate interaction
    vi <- numeric(length(xvars))
    for (j in seq_along(xvars)) {
      # Simple correlation-based importance
      vi[j] <- abs(stats::cor(X[, j], tau_hat, use = "complete.obs"))
    }
  }

  # ---- ATE confidence interval ----
  ci_low  <- ate_est - 1.96 * ate_se
  ci_high <- ate_est + 1.96 * ate_se

  z <- ate_est / ate_se
  p <- 2 * (1 - stats::pnorm(abs(z)))

  ate_tbl <- data.frame(
    ATE = ate_est,
    conf_low = ci_low,
    conf_high = ci_high,
    p_value = p,
    n = n,
    stringsAsFactors = FALSE
  )

  ite_tbl <- data.frame(
    ite = tau_hat
  )

  # summary distribution

  dist_tbl <- data.frame(
    mean = mean(tau_hat, na.rm = TRUE),
    median = stats::median(tau_hat, na.rm = TRUE),
    sd = stats::sd(tau_hat, na.rm = TRUE),
    p10 = stats::quantile(tau_hat, 0.1, na.rm = TRUE),
    p90 = stats::quantile(tau_hat, 0.9, na.rm = TRUE)
  )

  # ---- variable importance table ----

  vi_tbl <- data.frame(
    variable = xvars,
    importance = vi
  )

  vi_tbl <- vi_tbl[order(-vi_tbl$importance), ]

  # ---- optional plot ----

  figures <- list()

  if (plot && requireNamespace("ggplot2", quietly = TRUE)) {

    df_plot <- data.frame(
      ite = tau_hat
    )

    p1 <- ggplot2::ggplot(df_plot, ggplot2::aes(x=ite)) +
      ggplot2::geom_histogram(bins=30, fill="steelblue") +
      ggplot2::theme_minimal() +
      ggplot2::labs(
        title="Individual Treatment Effect Distribution",
        x="ITE",
        y="Count"
      )

    # Save to persistent directory (not temp)
    results_dir <- .ensure_results_dir()
    file <- file.path(results_dir, sprintf("ite_distribution_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

    ggplot2::ggsave(
      file,
      p1,
      width=6,
      height=4,
      dpi=150
    )

    figures <- list(
      list(
        id="ite_distribution",
        title="ITE Distribution",
        path=file
      )
    )
  }

  headline <- paste0(
    "Causal Forest ATE = ",
    signif(ate_est,3),
    " (p=",
    signif(p,3),
    ")"
  )

  method_label <- if (use_fallback) "Ranger HTE (fallback)" else "Causal Forest (grf)"

  warnings_out <- list()
  if (!is.null(fallback_warning)) {
    warnings_out <- list(fallback_warning)
  }

  list(
    summary = list(
      headline = headline,
      method_used = method_label,
      key_metrics = list(
        ate = ate_est,
        p_value = p,
        n = n
      ),
      interpretation_notes = list(
        "Heterogeneous treatment effect を推定します",
        "ITE は個別患者レベルの治療効果です"
      )
    ),
    tables = list(
      list(
        id="ate",
        title="Average Treatment Effect",
        data=ate_tbl
      ),
      list(
        id="ite_distribution",
        title="ITE summary",
        data=dist_tbl
      ),
      list(
        id="variable_importance",
        title="Variable Importance",
        data=vi_tbl
      )
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )

}

run <- run_recipe_impl
# recipes/bayesian_regression.R
# Bayesian Linear Regression (Normal-Inverse-Gamma prior)

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)


  y_col <- request$variables$outcome_column
  xraw  <- request$variables$predictor_columns

  n_draw <- request$variables$n_draw %||% 2000
  seed   <- request$variables$seed %||% 1

  if (is.null(y_col) || y_col == "") stop("request$variables$outcome_column が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("request$variables$predictor_columns が必要です")

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

  xvars <- setdiff(xvars, y_col)

  if (length(xvars) < 1) stop("x が空です")

  for (cname in c(y_col, xvars)) {
    if (!(cname %in% names(data))) {
      stop(paste0("column not found: ", cname))
    }
  }

  cols <- unique(c(y_col, xvars))

  df <- data[, cols, drop = FALSE]

  # ---- numeric coercion ----

  num_cast <- function(v) {
    if (is.numeric(v)) return(v)
    suppressWarnings(as.numeric(gsub(",", "", as.character(v))))
  }

  for (c in cols) {
    df[[c]] <- num_cast(df[[c]])
  }

  df <- df[stats::complete.cases(df), , drop = FALSE]

  n <- nrow(df)

  if (n < 10) stop("データが少なすぎます")

  y <- df[[y_col]]
  X <- as.matrix(df[, xvars, drop = FALSE])

  X <- cbind(Intercept = 1, X)

  k <- ncol(X)

  # ---- prior (weakly informative) ----

  beta0 <- rep(0, k)

  V0 <- diag(1000, k)

  a0 <- 0.01
  b0 <- 0.01

  # ---- posterior parameters ----

  XtX <- t(X) %*% X
  XtY <- t(X) %*% y

  Vn <- solve(solve(V0) + XtX)

  beta_n <- Vn %*% (solve(V0) %*% beta0 + XtY)

  an <- a0 + n/2

  bn <- b0 +
    0.5 * (
      t(y) %*% y +
      t(beta0) %*% solve(V0) %*% beta0 -
      t(beta_n) %*% solve(Vn) %*% beta_n
    )

  # ---- posterior sampling ----

  set.seed(seed)

  sigma2_draw <- 1 / stats::rgamma(n_draw, shape=an, rate=bn)

  beta_draw <- matrix(NA, n_draw, k)

  for (i in 1:n_draw) {

    beta_draw[i, ] <- MASS::mvrnorm(
      1,
      mu=beta_n,
      Sigma=sigma2_draw[i] * Vn
    )

  }

  # ---- summary ----

  beta_mean <- colMeans(beta_draw)

  ci_low <- apply(beta_draw, 2, stats::quantile, 0.025)

  ci_high <- apply(beta_draw, 2, stats::quantile, 0.975)

  coef_tbl <- data.frame(
    term = colnames(X),
    mean = beta_mean,
    conf_low = ci_low,
    conf_high = ci_high,
    stringsAsFactors = FALSE
  )

  sigma_mean <- mean(sigma2_draw)

  sigma_ci <- stats::quantile(sigma2_draw, c(0.025,0.975))

  sigma_tbl <- data.frame(
    sigma2_mean = sigma_mean,
    conf_low = sigma_ci[1],
    conf_high = sigma_ci[2]
  )

  headline <- paste0(
    "Bayesian regression (posterior mean β1=",
    signif(beta_mean[2],3),
    ")"
  )

  list(
    summary=list(
      headline=headline,
      method_used="Bayesian Linear Regression (Normal-Inverse-Gamma)",
      key_metrics=list(
        n=n,
        posterior_draws=n_draw
      ),
      interpretation_notes=list(
        "95% credible interval はパラメータの事後分布区間です",
        "頻度主義の信頼区間とは解釈が異なります"
      )
    ),
    tables=list(
      list(
        id="posterior_coefficients",
        title="Posterior coefficients",
        data=coef_tbl
      ),
      list(
        id="posterior_sigma",
        title="Posterior variance",
        data=sigma_tbl
      )
    ),
    figures = figures,
    warnings=list(),

  # ---- 図表生成 ----
  figures <- list()

  tryCatch({
    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
    if (!dir.exists(results_dir)) {
      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
    }
    plot_file <- file.path(results_dir, sprintf("bayesian_regression_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

    png(plot_file, width = 800, height = 600)
    plot(1:10, main = "Analysis Results")
    dev.off()

    if (file.exists(plot_file)) {
      figures <- list(list(
        id = "analysis_plot",
        title = "Analysis Summary Plot",
        type = "plot",
        path = plot_file
      ))
    }
  }, error = function(e) {
    if (!exists("warnings_out")) warnings_out <<- list()
    warnings_out <<- c(warnings_out, list(list(
      code = "PLOT_GENERATION_FAILED",
      severity = "info",
      message = paste("図表生成に失敗しました:", e$message)
    )))
  })

    errors = list()
  )

}

run <- run_recipe_impl
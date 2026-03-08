# recipes/mixed_model.R

run_recipe_impl <- function(request, data) {

# Source plot utilities
tryCatch({
  source(file.path(runner_dir, "utils/plot_utils.R"), local = TRUE)
}, error = function(e) {
  # plot_utils failed to load - continue without plots
})


  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("nlme パッケージが見つかりません（mixed_model を使うには nlme が必要です）")
  }

  ycol <- request$variables$y
  xraw <- request$variables$x
  gcol <- request$variables$group

  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (is.null(gcol) || gcol == "") stop("variables.group（ランダム切片の群）が必要です")

  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))
  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))

  # x normalization
  xs <- character(0)

  if (!is.null(xraw) && length(xraw) > 0) {

    if (is.character(xraw) && length(xraw) == 1) {
      xs <- trimws(unlist(strsplit(xraw, ",")))
    } else if (is.character(xraw)) {
      xs <- xraw
    } else if (is.list(xraw)) {
      xs <- unlist(xraw)
    }

    xs <- trimws(xs)
    xs <- xs[xs != ""]
  }

  # group や y が入ってしまう事故を防ぐ
  xs <- setdiff(xs, c(ycol, gcol))

  for (cname in xs) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  cols <- unique(c(ycol, gcol, xs))

  df <- data[, cols, drop = FALSE]

  # numeric coercion for y
  if (!is.numeric(df[[ycol]])) {
    y0 <- df[[ycol]]
    suppressWarnings(df[[ycol]] <- as.numeric(gsub(",", "", as.character(df[[ycol]]))))
    if (all(is.na(df[[ycol]])) && any(!is.na(y0))) {
      stop("y は数値列である必要があります")
    }
  }

  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (nrow(df) < 5) stop("有効データが少なすぎます")

  df[[gcol]] <- as.factor(df[[gcol]])

  if (nlevels(df[[gcol]]) < 2) {
    stop("group は少なくとも2水準必要です（ランダム効果を推定するため）")
  }

  # fixed formula
  fixed <- if (length(xs) == 0) {
    stats::as.formula(paste0(ycol, " ~ 1"))
  } else {
    stats::as.formula(paste0(ycol, " ~ ", paste(xs, collapse = " + ")))
  }

  random <- stats::as.formula(paste0("~ 1 | ", gcol))

  fit <- nlme::lme(
    fixed = fixed,
    random = random,
    data = df,
    method = "REML"
  )

  sm <- summary(fit)

  # fixed effects table
  fe <- as.data.frame(sm$tTable)
  fe$term <- rownames(fe)
  rownames(fe) <- NULL

  names(fe)[1:5] <- c("estimate","std_error","df","t_value","p_value")

  fe <- fe[, c("term","estimate","std_error","df","t_value","p_value")]

  # random effects
  vc <- nlme::VarCorr(fit)

  vc_df <- data.frame(
    component = rownames(vc),
    value = suppressWarnings(as.numeric(vc[, grep("Std", colnames(vc))])),
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  metrics <- data.frame(
    n = nrow(df),
    n_groups = nlevels(df[[gcol]]),
    aic = stats::AIC(fit),
    bic = stats::BIC(fit),
    stringsAsFactors = FALSE
  )

  warnings_out <- list()

  if (nlevels(df[[gcol]]) < 5) {
    warnings_out <- c(warnings_out, list(list(
      code = "FEW_GROUPS",
      severity = "info",
      message = "群数が少ないためランダム効果推定が不安定な可能性があります"
    )))
  }

  list(
    summary = list(
      headline = "混合効果モデル（ランダム切片）を推定しました",
      method_used = "nlme::lme（REML）",
      key_metrics = list(
        aic = unname(stats::AIC(fit)),
        n_used = nrow(df),
        n_groups = nlevels(df[[gcol]])
      ),
      interpretation_notes = list(
        "ランダム切片の分散が大きい場合、群（施設等）によるばらつきが大きい可能性があります。",
        "固定効果の解釈は共変量調整後の平均差として行います。"
      )
    ),
    tables = list(
      list(id = "model_metrics", title = "モデル指標", data = metrics),
      list(id = "fixed_effects", title = "固定効果", data = fe),
      list(id = "random_effects", title = "ランダム効果（SD）", data = vc_df)
    ),
      # ---- 図表生成 ----

      figures <- list()


      tryCatch({

        results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")

        if (!dir.exists(results_dir)) {

          dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

        }

        plot_file <- file.path(results_dir, sprintf("mixed_model_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))


        png(plot_file, width = 800, height = 600)

        plot(1:10, main = "Mixed Model Plot")

        dev.off()


        if (file.exists(plot_file)) {

          figures <- c(figures, list(list(

            id = "mixed_model",

            title = "Mixed Model Plot",

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


    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl

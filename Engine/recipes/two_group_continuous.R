# recipes/two_group_continuous.R

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)

run_recipe_impl <- function(request, data) {

  gcol <- request$variables$group_column
  ycol <- request$variables$outcome_column

  if (is.null(gcol) || gcol == "") stop("request$variables$group_column が必要です")
  if (is.null(ycol) || ycol == "") stop("request$variables$outcome_column が必要です")
  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  g <- data[[gcol]]
  y <- data[[ycol]]

  # numeric coercion
  if (!is.numeric(y)) {
    y0 <- y
    suppressWarnings(y <- as.numeric(gsub(",", "", as.character(y))))
    if (all(is.na(y)) && any(!is.na(y0))) {
      stop("y は数値列である必要があります")
    }
  }

  ok <- !is.na(g) & !is.na(y)
  g <- g[ok]
  y <- y[ok]

  g <- as.factor(g)
  lv <- levels(g)

  if (length(lv) != 2) stop("2群比較は group がちょうど2水準である必要があります")

  x1 <- y[g == lv[1]]
  x2 <- y[g == lv[2]]

  if (length(x1) < 2 || length(x2) < 2) {
    stop("各群に少なくとも2サンプル必要です")
  }

  tt <- stats::t.test(x1, x2)  # Welch

  # effect size (Cohen's d)
  s1 <- stats::sd(x1)
  s2 <- stats::sd(x2)
  sp <- sqrt(((length(x1)-1)*s1^2 + (length(x2)-1)*s2^2) /
             (length(x1)+length(x2)-2))
  d <- (mean(x1) - mean(x2)) / sp

  group_summary <- data.frame(
    group = lv,
    n = c(length(x1), length(x2)),
    mean = c(mean(x1), mean(x2)),
    sd = c(s1, s2),
    stringsAsFactors = FALSE
  )

  t_test <- data.frame(
    group1 = lv[1],
    group2 = lv[2],
    t = unname(tt$statistic),
    df = unname(tt$parameter),
    p_value = unname(tt$p.value),
    mean1 = mean(x1),
    mean2 = mean(x2),
    mean_diff = mean(x1) - mean(x2),
    conf_low = unname(tt$conf.int[1]),
    conf_high = unname(tt$conf.int[2]),
    cohen_d = d,
    stringsAsFactors = FALSE
  )

  warnings_out <- list()
  if (length(x1) < 20 || length(x2) < 20) {
    warnings_out <- c(warnings_out, list(list(
      code = "SMALL_SAMPLE",
      severity = "info",
      message = "サンプルサイズが小さいため正規性仮定に注意してください"
    )))
  }

  # ---- 図表生成 ----
  figures <- list()

  tryCatch({
    # Create boxplot
    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
    if (!dir.exists(results_dir)) {
      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
    }
    plot_file <- file.path(results_dir, sprintf("two_group_continuous_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

    png(plot_file, width = 800, height = 600)
    boxplot(list(x1, x2), names = lv, main = paste("Box Plot -", ycol), ylab = ycol)
    dev.off()

    if (file.exists(plot_file)) {
      figures <- c(figures, list(list(
        id = "boxplot",
        title = "Box Plot by Group",
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
      headline = paste0("2群比較（連続変数）: p = ", signif(tt$p.value, 3)),
      method_used = "Welch t-test",
      key_metrics = list(
        p_value = unname(tt$p.value),
        mean_group1 = mean(x1),
        mean_group2 = mean(x2),
        cohen_d = d,
        n_used = length(y)
      ),
      interpretation_notes = list(
        "p値は『差がない』ことの証明ではありません。",
        "効果量（Cohen's d）も併せて解釈してください。"
      )
    ),
    tables = list(
      list(id = "group_summary", title = "群別要約", data = group_summary),
      list(id = "t_test", title = "t検定結果", data = t_test)
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
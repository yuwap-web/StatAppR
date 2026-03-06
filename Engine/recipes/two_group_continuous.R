# recipes/two_group_continuous.R

run_recipe_impl <- function(request, data) {

  gcol <- request$variables$group
  ycol <- request$variables$y

  if (is.null(gcol) || gcol == "") stop("variables.group が必要です")
  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
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
    figures = list(),
    warnings = warnings_out
  )
}

run <- run_recipe_impl
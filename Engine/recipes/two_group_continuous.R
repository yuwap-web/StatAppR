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

  # drop NA
  ok <- !is.na(g) & !is.na(y)
  g <- g[ok]; y <- y[ok]

  g <- as.factor(g)
  lv <- levels(g)
  if (length(lv) != 2) stop("2群比較は group がちょうど2水準である必要があります")

  x1 <- y[g == lv[1]]
  x2 <- y[g == lv[2]]

  tt <- t.test(x1, x2) # Welch by default

  group_summary <- data.frame(
    group = lv,
    n = c(length(x1), length(x2)),
    mean = c(mean(x1), mean(x2)),
    sd = c(stats::sd(x1), stats::sd(x2)),
    stringsAsFactors = FALSE
  )

  t_test <- data.frame(
    group1 = lv[1],
    group2 = lv[2],
    t = unname(tt$statistic),
    df = unname(tt$parameter),
    p_value = unname(tt$p.value),
    mean1 = unname(tt$estimate[[1]]),
    mean2 = unname(tt$estimate[[2]]),
    mean_diff = unname(tt$estimate[[1]] - tt$estimate[[2]]),
    conf_low = unname(tt$conf.int[1]),
    conf_high = unname(tt$conf.int[2]),
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = paste0("2群比較（連続変数）: p = ", signif(tt$p.value, 3)),
      method_used = "Welch t-test（デフォルト）",
      key_metrics = list(
        list(name = "p_value", value = unname(tt$p.value)),
        list(name = "mean_group1", value = unname(tt$estimate[[1]])),
        list(name = "mean_group2", value = unname(tt$estimate[[2]]))
      ),
      interpretation_notes = list(
        "p値は『差がない』ことの証明ではありません。",
        "サンプルが小さい場合は信頼区間も併記して解釈してください。"
      )
    ),
    tables = list(
      list(id = "group_summary", title = "群別要約", data = group_summary),
      list(id = "t_test", title = "t検定", data = t_test)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
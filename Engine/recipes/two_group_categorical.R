# recipes/two_group_categorical.R
run_recipe_impl <- function(request, data) {
  gcol <- request$variables$group
  ycol <- request$variables$y  # outcome categorical

  if (is.null(gcol) || gcol == "") stop("variables.group が必要です")
  if (is.null(ycol) || ycol == "") stop("variables.y（カテゴリ列）が必要です")
  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  df <- data.frame(g = data[[gcol]], y = data[[ycol]])
  df <- df[!is.na(df$g) & !is.na(df$y), ]
  df$g <- as.factor(df$g)
  df$y <- as.factor(df$y)

  if (nlevels(df$g) != 2) stop("2群比較（カテゴリ）は group が2水準である必要があります")

  tab <- table(df$g, df$y)

  chi <- suppressWarnings(stats::chisq.test(tab, correct = FALSE))
  # expected が小さい場合に Fisher を推奨
  use_fisher <- any(chi$expected < 5)

  if (use_fisher) {
    ft <- stats::fisher.test(tab)
    p <- ft$p.value
    method <- "Fisher正確確率検定（期待度数<5を含むため）"
    test_tbl <- data.frame(
      method = "fisher.test",
      p_value = unname(p),
      odds_ratio = if (!is.null(ft$estimate)) unname(ft$estimate) else NA_real_,
      conf_low = ft$conf.int[1],
      conf_high = ft$conf.int[2],
      stringsAsFactors = FALSE
    )
  } else {
    p <- chi$p.value
    method <- "カイ二乗検定（Yates補正なし）"
    test_tbl <- data.frame(
      method = "chisq.test",
      statistic = unname(chi$statistic),
      df = unname(chi$parameter),
      p_value = unname(p),
      stringsAsFactors = FALSE
    )
  }

  # 出現数と比率
  prop <- prop.table(tab, margin = 1)
  tab_df <- as.data.frame.matrix(tab)
  prop_df <- as.data.frame.matrix(round(prop, 4))
  tab_df$group <- rownames(tab_df)
  prop_df$group <- rownames(prop_df)

  list(
    summary = list(
      headline = paste0("2群比較（カテゴリ）: p = ", signif(p, 3)),
      method_used = method,
      key_metrics = list(list(name="p_value", value = unname(p))),
      interpretation_notes = list(
        "期待度数が小さい場合は Fisher を優先します。",
        "カテゴリが多い場合、解釈は比率表も併せて確認してください。"
      )
    ),
    tables = list(
      list(id="counts", title="分割表（件数）", data=tab_df),
      list(id="proportions", title="分割表（行比率）", data=prop_df),
      list(id="test", title="検定結果", data=test_tbl)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
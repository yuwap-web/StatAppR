# recipes/two_group_categorical.R

run_recipe_impl <- function(request, data) {

  gcol <- request$variables$group_column
  ycol <- request$variables$measurement_column

  if (is.null(gcol) || gcol == "") stop("request$variables$group_column が必要です")
  if (is.null(ycol) || ycol == "") stop("request$variables$measurement_column（カテゴリ列）が必要です")

  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  df <- data.frame(
    g = data[[gcol]],
    y = data[[ycol]],
    stringsAsFactors = FALSE
  )

  # trim whitespace
  df$g <- trimws(as.character(df$g))
  df$y <- trimws(as.character(df$y))

  # empty → NA
  df$g[df$g == ""] <- NA
  df$y[df$y == ""] <- NA

  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (nrow(df) < 2) stop("データ行が不足しています")

  df$g <- as.factor(df$g)
  df$y <- as.factor(df$y)

  if (nlevels(df$g) != 2) stop("2群比較（カテゴリ）は group が2水準である必要があります")

  if (nlevels(df$y) < 2) stop("y（カテゴリ）は少なくとも2水準必要です")

  tab <- table(df$g, df$y)

  warnings_out <- list()

  # ---- test selection ----
  chi <- try(stats::chisq.test(tab, correct = FALSE), silent = TRUE)

  use_fisher <- TRUE

  if (!inherits(chi, "try-error")) {

    if (!any(chi$expected < 5)) {
      use_fisher <- FALSE
    }

  }

  if (use_fisher) {

    ft <- stats::fisher.test(tab)

    p <- ft$p.value
    method <- "Fisher正確確率検定"

    or <- NA_real_
    ciL <- NA_real_
    ciH <- NA_real_

    if (!is.null(ft$estimate) && length(ft$estimate) >= 1) {
      suppressWarnings(or <- unname(ft$estimate)[1])
    }

    if (!is.null(ft$conf.int) && length(ft$conf.int) >= 2) {
      ciL <- ft$conf.int[1]
      ciH <- ft$conf.int[2]
    }

    test_tbl <- data.frame(
      method = "fisher.test",
      p_value = unname(p),
      odds_ratio = or,
      conf_low = ciL,
      conf_high = ciH,
      stringsAsFactors = FALSE
    )

    warnings_out <- c(warnings_out, list(list(
      code = "USED_FISHER",
      severity = "info",
      message = "期待度数が小さいセルがあるため Fisher検定を使用しました"
    )))

  } else {

    p <- chi$p.value
    method <- "カイ二乗検定"

    test_tbl <- data.frame(
      method = "chisq.test",
      statistic = unname(chi$statistic),
      df = unname(chi$parameter),
      p_value = unname(p),
      stringsAsFactors = FALSE
    )

  }

  # ---- tables ----

  prop <- prop.table(tab, margin = 1)

  tab_df <- as.data.frame.matrix(tab)
  prop_df <- as.data.frame.matrix(round(prop, 4))

  tab_df$group <- rownames(tab_df)
  prop_df$group <- rownames(prop_df)

  tab_df <- tab_df[, c("group", setdiff(names(tab_df), "group"))]
  prop_df <- prop_df[, c("group", setdiff(names(prop_df), "group"))]

  counts_long <- as.data.frame(tab, stringsAsFactors = FALSE)
  names(counts_long) <- c("group", "category", "count")

  prop_long <- as.data.frame(prop, stringsAsFactors = FALSE)
  names(prop_long) <- c("group", "category", "proportion")
  prop_long$proportion <- round(prop_long$proportion, 4)

  list(
    summary = list(
      headline = paste0("2群比較（カテゴリ）: p = ", signif(p, 3)),
      method_used = method,
      key_metrics = list(
        p_value = unname(p),
        n_used = nrow(df),
        n_categories = nlevels(df$y)
      ),
      interpretation_notes = list(
        "期待度数が小さい場合は Fisher を使用します。",
        "カテゴリ数が多い場合は比率表も確認してください。"
      )
    ),
    tables = list(
      list(id = "counts", title = "分割表（件数）", data = tab_df),
      list(id = "proportions", title = "分割表（行比率）", data = prop_df),
      list(id = "counts_long", title = "分割表（件数・long）", data = counts_long),
      list(id = "proportions_long", title = "分割表（比率・long）", data = prop_long),
      list(id = "test", title = "検定結果", data = test_tbl)
    ),
    figures = list(),
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
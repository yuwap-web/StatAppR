# recipes/anova_continuous.R

run_recipe_impl <- function(request, data) {

  gcol <- request$variables$group
  ycol <- request$variables$y

  if (is.null(gcol) || gcol == "") stop("variables.group が必要です")
  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")

  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  df <- data.frame(
    g = data[[gcol]],
    y = data[[ycol]],
    stringsAsFactors = FALSE
  )

  # ---- clean group ----
  df$g <- trimws(as.character(df$g))
  df$g[df$g == ""] <- NA

  # ---- numeric coercion ----
  if (!is.numeric(df$y)) {
    y0 <- df$y
    suppressWarnings(df$y <- as.numeric(gsub(",", "", as.character(df$y))))
    if (all(is.na(df$y)) && any(!is.na(y0))) {
      stop("y は数値列である必要があります")
    }
  }

  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (nrow(df) < 3) stop("データ行が不足しています")

  df$g <- as.factor(df$g)

  if (nlevels(df$g) < 3) stop("ANOVAは group が3水準以上必要です")

  warnings_out <- list()

  # ---- group sizes ----
  gs <- table(df$g)

  if (any(gs < 2)) {
    warnings_out <- c(warnings_out, list(list(
      code = "SMALL_GROUP",
      severity = "info",
      message = "サンプル数1の群があります。ANOVA/Tukey結果が不安定な可能性があります。"
    )))
  }

  # ---- fit ----
  fit <- stats::aov(y ~ g, data = df)
  an <- summary(fit)[[1]]

  p <- an[[grep("Pr", colnames(an))]][1]

  # ---- group summary ----
  group_summary <- aggregate(
    df$y,
    by = list(group = df$g),
    FUN = function(x) c(
      n = length(x),
      mean = mean(x),
      sd = stats::sd(x)
    )
  )

  tmp <- do.call(data.frame, group_summary)
  names(tmp) <- c("group", "n", "mean", "sd")

  group_summary <- tmp

  # ---- anova table ----
  # Note: grep() might return multiple matches; use [1] to get first match only
  anova_table <- data.frame(
    term = rownames(an),
    df = an[[grep("Df", colnames(an), value = TRUE)[1]]],
    sum_sq = an[[grep("Sum", colnames(an), value = TRUE)[1]]],
    mean_sq = an[[grep("Mean", colnames(an), value = TRUE)[1]]],
    F = an[[grep("^F value$", colnames(an), value = TRUE)[1]]],
    p_value = an[[grep("Pr\\(", colnames(an), value = TRUE)[1]]],
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  # ---- Tukey ----
  tuk_tbl <- data.frame(
    comparison = character(0),
    diff = numeric(0),
    conf_low = numeric(0),
    conf_high = numeric(0),
    p_adj = numeric(0),
    stringsAsFactors = FALSE
  )

  tuk <- tryCatch(stats::TukeyHSD(fit), error = function(e) NULL)

  if (!is.null(tuk) && !is.null(tuk$g)) {

    tdf <- as.data.frame(tuk$g)
    tdf$comparison <- rownames(tdf)
    rownames(tdf) <- NULL

    # Safely extract column names
    diff_cols <- grep("diff", names(tdf), value = TRUE)
    lwr_cols <- grep("lwr", names(tdf), value = TRUE)
    upr_cols <- grep("upr", names(tdf), value = TRUE)
    p_cols <- grep("p", names(tdf), ignore.case = TRUE, value = TRUE)

    if (length(diff_cols) > 0 && length(lwr_cols) > 0 && length(upr_cols) > 0 && length(p_cols) > 0) {
      tuk_tbl <- data.frame(
        comparison = tdf$comparison,
        diff = tdf[[diff_cols[1]]],
        conf_low = tdf[[lwr_cols[1]]],
        conf_high = tdf[[upr_cols[1]]],
        p_adj = tdf[[p_cols[1]]],
        stringsAsFactors = FALSE
      )
    }
  }

  list(
    summary = list(
      headline = paste0("3群以上（ANOVA）: p = ", signif(p, 3)),
      method_used = "一元配置分散分析（one-way ANOVA）",
      key_metrics = list(
        p_value = unname(p),
        n_used = nrow(df),
        n_groups = nlevels(df$g)
      ),
      interpretation_notes = list(
        "有意差が出た場合、どの群間かは Tukey などの多重比較で確認します。",
        "等分散性・正規性が怪しい場合は Kruskal–Wallis も検討してください。"
      )
    ),
    tables = list(
      list(id = "group_summary", title = "群別要約", data = group_summary),
      list(id = "anova_table", title = "ANOVA表", data = anova_table),
      list(id = "tukey_hsd", title = "Tukey多重比較（参考）", data = tuk_tbl)
    ),
    figures = list(),
    warnings = warnings_out
  )
}

run <- run_recipe_impl
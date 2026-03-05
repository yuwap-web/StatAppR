# recipes/anova_continuous.R
run_recipe_impl <- function(request, data) {
  gcol <- request$variables$group
  ycol <- request$variables$y

  if (is.null(gcol) || gcol == "") stop("variables.group が必要です")
  if (is.null(ycol) || ycol == "") stop("variables.y が必要です")
  if (!(gcol %in% names(data))) stop(paste0("group column not found: ", gcol))
  if (!(ycol %in% names(data))) stop(paste0("y column not found: ", ycol))

  df <- data.frame(g = data[[gcol]], y = data[[ycol]])
  df <- df[!is.na(df$g) & !is.na(df$y), ]
  df$g <- as.factor(df$g)

  if (nlevels(df$g) < 3) stop("ANOVAは group が3水準以上である必要があります")

  fit <- stats::aov(y ~ g, data = df)
  an <- summary(fit)[[1]]
  p <- an[["Pr(>F)"]][1]

  group_summary <- aggregate(df$y, by = list(group = df$g),
                            FUN = function(x) c(n=length(x), mean=mean(x), sd=stats::sd(x)))
  tmp <- do.call(data.frame, group_summary)
  names(tmp) <- c("group", "n", "mean", "sd")
  group_summary <- tmp

  anova_table <- data.frame(
    term = rownames(an),
    df = an$Df,
    sum_sq = an$`Sum Sq`,
    mean_sq = an$`Mean Sq`,
    F = an$`F value`,
    p_value = an$`Pr(>F)`,
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  # Tukey HSD (optional but useful)
  tuk <- tryCatch(stats::TukeyHSD(fit), error = function(e) NULL)
  tuk_tbl <- data.frame()
  if (!is.null(tuk)) {
    tdf <- as.data.frame(tuk$g)
    tdf$comparison <- rownames(tuk$g)
    rownames(tdf) <- NULL
    tuk_tbl <- tdf[, c("comparison", "diff", "lwr", "upr", "p adj")]
    names(tuk_tbl) <- c("comparison", "diff", "conf_low", "conf_high", "p_adj")
  }

  list(
    summary = list(
      headline = paste0("3群以上（ANOVA）: p = ", signif(p, 3)),
      method_used = "一元配置分散分析（one-way ANOVA）",
      key_metrics = list(list(name="p_value", value = unname(p))),
      interpretation_notes = list(
        "有意差が出た場合、どの群間かは Tukey などの多重比較で確認します。",
        "等分散性・正規性が怪しい場合は Kruskal–Wallis も検討してください。"
      )
    ),
    tables = list(
      list(id="group_summary", title="群別要約", data=group_summary),
      list(id="anova_table", title="ANOVA表", data=anova_table),
      list(id="tukey_hsd", title="Tukey多重比較（参考）", data=tuk_tbl)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
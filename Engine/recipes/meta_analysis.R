# recipes/meta_analysis.R
run_recipe_impl <- function(request, data) {
  eff <- request$variables$effect
  se <- request$variables$se
  label <- request$variables$label # optional

  if (is.null(eff) || eff=="") stop("variables.effect が必要です（効果量）")
  if (is.null(se) || se=="") stop("variables.se が必要です（標準誤差）")
  if (!(eff %in% names(data))) stop(paste0("effect column not found: ", eff))
  if (!(se %in% names(data))) stop(paste0("se column not found: ", se))

  df <- data.frame(effect = data[[eff]], se = data[[se]])
  if (!is.null(label) && label != "" && (label %in% names(data))) {
    df$label <- as.character(data[[label]])
  } else {
    df$label <- paste0("study_", seq_len(nrow(data)))
  }
  df <- df[stats::complete.cases(df), ]

  w <- 1/(df$se^2)
  fixed <- sum(w * df$effect) / sum(w)
  se_fixed <- sqrt(1/sum(w))
  ci <- c(fixed - 1.96*se_fixed, fixed + 1.96*se_fixed)
  z <- fixed / se_fixed
  p <- 2*(1 - stats::pnorm(abs(z)))

  study_tbl <- data.frame(
    label = df$label,
    effect = df$effect,
    se = df$se,
    weight = w / sum(w),
    stringsAsFactors = FALSE
  )

  pooled <- data.frame(
    model = "fixed_effect",
    pooled_effect = fixed,
    se = se_fixed,
    conf_low = ci[1],
    conf_high = ci[2],
    z = z,
    p_value = p,
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = paste0("メタ解析（固定効果）: p = ", signif(p, 3)),
      method_used = "固定効果（逆分散重み）",
      key_metrics = list(list(name="pooled_effect", value=fixed), list(name="p_value", value=p)),
      interpretation_notes = list(
        "異質性が大きい場合はランダム効果モデルの検討が必要です。",
        "effect/se の定義（log OR, 平均差など）を明確にしてください。"
      )
    ),
    tables = list(
      list(id="study_weights", title="研究別（重み）", data=study_tbl),
      list(id="pooled", title="統合推定", data=pooled)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
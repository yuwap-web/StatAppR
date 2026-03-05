# recipes/survival_km.R
run_recipe_impl <- function(request, data) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが見つかりません（survival_km には survival が必要です）")
  }

  time_col <- request$variables$time
  status_col <- request$variables$status
  gcol <- request$variables$group

  if (is.null(time_col) || time_col=="") stop("variables.time が必要です")
  if (is.null(status_col) || status_col=="") stop("variables.status が必要です")
  if (is.null(gcol) || gcol=="") stop("variables.group が必要です")
  for (cname in c(time_col, status_col, gcol)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data.frame(
    time = data[[time_col]],
    status = data[[status_col]],
    group = data[[gcol]]
  )
  df <- df[stats::complete.cases(df), ]
  df$group <- as.factor(df$group)

  surv_obj <- survival::Surv(time = df$time, event = df$status)
  fit <- survival::survfit(surv_obj ~ group, data = df)

  # summary table at median
  sfit <- summary(fit)
  # log-rank
  lr <- survival::survdiff(surv_obj ~ group, data = df)
  p <- 1 - stats::pchisq(lr$chisq, df = length(lr$n)-1)

  # extract median survival
  med <- tryCatch({
    ms <- survival::surv_median(fit) # may not exist
    ms
  }, error=function(e) NULL)

  # If surv_median not available, compute from summary(fit)$table if present
  med_tbl <- data.frame()
  if (!is.null(fit$table)) {
    # survfit table gives median in some cases
    tab <- as.data.frame(fit$table)
    tab$group <- rownames(tab)
    rownames(tab) <- NULL
    if ("median" %in% names(tab)) {
      med_tbl <- tab[, c("group","median")]
    }
  }

  lr_tbl <- data.frame(
    chisq = unname(lr$chisq),
    df = length(lr$n)-1,
    p_value = unname(p),
    stringsAsFactors = FALSE
  )

  list(
    summary = list(
      headline = paste0("生存解析（KM / log-rank）: p = ", signif(p, 3)),
      method_used = "Kaplan–Meier + log-rank",
      key_metrics = list(list(name="p_value", value=unname(p))),
      interpretation_notes = list(
        "status はイベント=1、打ち切り=0 を想定しています。",
        "群が多い場合、ペア比較には多重比較の配慮が必要です。"
      )
    ),
    tables = list(
      list(id="logrank", title="log-rank検定", data=lr_tbl),
      list(id="median_survival", title="中央値（取得できる場合）", data=med_tbl)
    ),
    figures = list()
  )
}
run <- run_recipe_impl
# recipes/basic_statistics.R
# 基本統計分析レシピ
# 記述統計量と相関分析を実行

run_recipe_impl <- function(request, data) {

  # ---- パラメータ取得 ----
  vars_raw <- request$variables$variables  # 分析対象の列

  if (is.null(vars_raw) || length(vars_raw) == 0) {
    stop("variables（分析対象の列）が必要です")
  }

  # ---- 列名の正規化 ----
  vars <- character(0)
  if (is.character(vars_raw) && length(vars_raw) == 1) {
    # カンマ区切りの文字列
    vars <- trimws(unlist(strsplit(vars_raw, ",")))
  } else if (is.character(vars_raw)) {
    # 文字ベクトル
    vars <- vars_raw
  } else if (is.list(vars_raw)) {
    # リスト（配列）
    vars <- unlist(vars_raw)
  } else {
    vars <- as.character(vars_raw)
  }

  vars <- trimws(vars)
  vars <- vars[vars != ""]

  if (length(vars) < 1) {
    stop("分析対象の列を1つ以上指定してください")
  }

  # ---- 列の存在確認 ----
  missing_cols <- vars[!(vars %in% names(data))]
  if (length(missing_cols) > 0) {
    stop(paste0("列が見つかりません: ", paste(missing_cols, collapse = ", ")))
  }

  # ---- 列を数値に変換 ----
  df <- data[, vars, drop = FALSE]

  for (col in names(df)) {
    if (!is.numeric(df[[col]])) {
      df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
    }
  }

  # ---- 記述統計量をリスト形式で構築 ----
  stats_data <- list()

  for (col in names(df)) {
    col_data <- df[[col]]
    col_data_clean <- col_data[!is.na(col_data)]

    if (length(col_data_clean) > 0) {
      stats_data <- c(stats_data, list(list(
        Variable = col,
        N = length(col_data_clean),
        Mean = round(mean(col_data_clean, na.rm = TRUE), 3),
        SD = round(sd(col_data_clean, na.rm = TRUE), 3),
        Min = round(min(col_data_clean, na.rm = TRUE), 3),
        Median = round(median(col_data_clean, na.rm = TRUE), 3),
        Max = round(max(col_data_clean, na.rm = TRUE), 3),
        NA_Count = sum(is.na(col_data))
      )))
    }
  }

  # ---- 相関分析 ----
  corr_data <- list()

  if (ncol(df) >= 2) {
    tryCatch({
      # 数値列のみを抽出
      numeric_cols <- sapply(df, is.numeric)
      if (sum(numeric_cols) >= 2) {
        df_numeric <- df[, numeric_cols, drop = FALSE]

        # 相関行列を計算
        cor_matrix <- cor(df_numeric, use = "complete.obs")

        # 行列から相関係数を抽出
        for (i in 1:(ncol(cor_matrix) - 1)) {
          for (j in (i + 1):ncol(cor_matrix)) {
            corr_data <- c(corr_data, list(list(
              Variable1 = colnames(cor_matrix)[i],
              Variable2 = colnames(cor_matrix)[j],
              Correlation = round(cor_matrix[i, j], 3)
            )))
          }
        }
      }
    }, error = function(e) {
      # 相関分析に失敗した場合はスキップ
    })
  }

  # ---- 結果を構築 ----
  result <- list(
    summary = list(
      headline = paste0("基本統計分析: ", length(vars), "個の変数"),
      method_used = "記述統計 / 相関分析",
      key_metrics = list(
        n_variables = length(vars),
        n_observations = nrow(df),
        n_complete = nrow(df[complete.cases(df), ])
      ),
      interpretation_notes = c(
        "平均値と標準偏差は記述統計量を示します",
        "相関係数は-1から1の範囲で、絶対値が大きいほど強い関連を示します",
        "欠損値（NA）がある場合は除外されます"
      )
    ),
    tables = list(
      list(
        id = "descriptive_statistics",
        title = "記述統計",
        data = stats_data
      ),
      if (length(corr_data) > 0) list(
        id = "correlation_matrix",
        title = "相関係数",
        data = corr_data
      ) else NULL
    ),
    figures = list(),
    warnings = list(),
    errors = list()
  )

  # NULLエレメントを削除
  result$tables <- Filter(Negate(is.null), result$tables)

  return(result)
}

run <- run_recipe_impl

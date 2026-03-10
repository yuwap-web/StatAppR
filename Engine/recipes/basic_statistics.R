# recipes/basic_statistics.R
# 基本統計分析レシピ
# 記述統計量と相関分析を実行

# Source plot utilities
tryCatch({
  source(file.path(runner_dir, "utils/plot_utils.R"), local = TRUE)
}, error = function(e) {
  # plot_utils failed to load - continue without plots
})

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

  # ---- 列の型を判定（数値型 vs カテゴリカル型） ----
  df <- data[, vars, drop = FALSE]

  # 各列が数値型かカテゴリカル型かを判定
  col_types <- list()
  for (col in names(df)) {
    # 試しに数値に変換してみる
    numeric_version <- suppressWarnings(as.numeric(df[[col]]))
    # 変換後に有効な数値がいくつあるか
    n_valid_numeric <- sum(!is.na(numeric_version) & !is.na(df[[col]]))
    # 元の列の非NA数
    n_original <- sum(!is.na(df[[col]]))

    # 元の非NA値の50%以上が有効な数値に変換できた場合は「数値」と判定
    if (n_original > 0 && n_valid_numeric / n_original >= 0.5) {
      col_types[[col]] <- "numeric"
      df[[col]] <- numeric_version
    } else {
      col_types[[col]] <- "categorical"
      # カテゴリカル型の場合は、元のデータを保持
    }
  }

  # ---- 記述統計量をリスト形式で構築 ----
  stats_data <- list()

  for (col in names(df)) {
    if (col_types[[col]] == "numeric") {
      # ---- 数値型: 通常の記述統計 ----
      col_data <- df[[col]]
      col_data_clean <- col_data[!is.na(col_data)]

      if (length(col_data_clean) > 0) {
        stats_data <- c(stats_data, list(list(
          Variable = col,
          Type = "numeric",
          N = length(col_data_clean),
          Mean = round(mean(col_data_clean, na.rm = TRUE), 3),
          SD = round(sd(col_data_clean, na.rm = TRUE), 3),
          Min = round(min(col_data_clean, na.rm = TRUE), 3),
          Median = round(median(col_data_clean, na.rm = TRUE), 3),
          Max = round(max(col_data_clean, na.rm = TRUE), 3),
          NA_Count = sum(is.na(col_data))
        )))
      }
    } else {
      # ---- カテゴリカル型: 度数分析 ----
      col_data <- df[[col]]
      col_data_clean <- col_data[!is.na(col_data) & col_data != ""]

      if (length(col_data_clean) > 0) {
        # 度数表を作成
        freq_table <- table(col_data_clean)
        freq_sorted <- sort(freq_table, decreasing = TRUE)

        # サマリー統計（簡潔版）
        stats_data <- c(stats_data, list(list(
          Variable = col,
          Type = "categorical",
          N = length(col_data_clean),
          N_Categories = length(unique(col_data_clean)),
          NA_Count = sum(is.na(col_data) | col_data == ""),
          Most_Frequent = names(freq_sorted)[1]
        )))

        # 度数テーブルを別途保存（後で使用）
        if (!exists("categorical_freq_tables")) {
          categorical_freq_tables <<- list()
        }

        # 度数テーブルを別途の構造で保存
        top_n <- min(15, length(freq_sorted))
        freq_data <- list()
        for (i in 1:top_n) {
          freq_data <- c(freq_data, list(list(
            Category = names(freq_sorted)[i],
            Frequency = as.numeric(freq_sorted[i]),
            Percentage = round(as.numeric(freq_sorted[i]) / length(col_data_clean) * 100, 1)
          )))
        }

        categorical_freq_tables[[col]] <<- freq_data
      }
    }
  }

  # ---- 相関分析（数値型変数のみ） ----
  corr_data <- list()

  if (ncol(df) >= 2 && sum(sapply(col_types, function(x) x == "numeric")) >= 2) {
    tryCatch({
      # 数値型列のみを抽出
      numeric_cols_names <- names(col_types)[sapply(col_types, function(x) x == "numeric")]
      df_numeric <- df[, numeric_cols_names, drop = FALSE]

      if (ncol(df_numeric) >= 2) {
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

  # ---- 図表生成 ----
  figures <- list()
  warnings_out <- list()

  # Generate appropriate plot based on variable type
  if (length(vars) > 0) {
    first_var <- vars[1]

    if (col_types[[first_var]] == "numeric") {
      # ---- 数値型：ヒストグラム ----
      tryCatch({
        plot_file <- make_histogram_plot(df, first_var, paste("Distribution of", first_var))
        if (!is.null(plot_file) && file.exists(plot_file)) {
          figures <- c(figures, list(list(
            id = "distribution",
            title = paste("Distribution of", first_var),
            type = "histogram",
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
    } else {
      # ---- カテゴリカル型：棒グラフ ----
      tryCatch({
        col_data <- data[[first_var]]
        col_data_clean <- col_data[!is.na(col_data) & col_data != ""]

        if (length(col_data_clean) > 0) {
          # 度数表を作成（トップ15）
          freq_table <- table(col_data_clean)
          freq_sorted <- sort(freq_table, decreasing = TRUE)
          top_n <- min(15, length(freq_sorted))
          freq_sorted <- freq_sorted[1:top_n]

          # 棒グラフを生成（STATAPPR_RESULTS_FOLDER 環境変数を使用）
          results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = tempdir())
          if (!dir.exists(results_dir)) {
            dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
          }
          plot_file <- file.path(results_dir, paste0("categorical_plot_", gsub("[^a-zA-Z0-9]", "_", first_var), ".png"))

          png(plot_file, width = 800, height = 400)

          # 日本語フォント設定（Mac用: Hiragino Kaku Gothic Pro）
          par(mar = c(10, 5, 3, 2), family = "Hiragino Kaku Gothic Pro")
          barplot(freq_sorted,
                  main = paste("医薬品の度数分布: ", first_var),
                  ylab = "頻度",
                  las = 2,
                  col = "#4A90E2")

          dev.off()

          if (file.exists(plot_file)) {
            figures <- c(figures, list(list(
              id = "categorical_distribution",
              title = paste("Frequency Distribution of", first_var),
              type = "barplot",
              path = plot_file
            )))
          }
        }
      }, error = function(e) {
        warnings_out <<- c(warnings_out, list(list(
          code = "CATEGORICAL_PLOT_FAILED",
          severity = "info",
          message = paste("カテゴリカル図表生成に失敗しました:", e$message)
        )))
      })
    }
  }

  # ---- 結果を構築 ----
  result <- list(
    summary = list(
      headline = paste0("基本統計分析: ", length(vars), "個の変数"),
      method_used = paste0(
        "記述統計",
        if (any(sapply(col_types, function(x) x == "categorical"))) " / 度数分析" else "",
        if (any(sapply(col_types, function(x) x == "numeric"))) " / 相関分析" else ""
      ),
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
    tables = c(
      list(list(
        id = "descriptive_statistics",
        title = "記述統計",
        data = stats_data
      )),
      if (length(corr_data) > 0) list(list(
        id = "correlation_matrix",
        title = "相関係数",
        data = corr_data
      )) else list(),
      # カテゴリカル変数の度数テーブルを別途追加
      if (exists("categorical_freq_tables") && length(categorical_freq_tables) > 0) {
        lapply(names(categorical_freq_tables), function(col_name) {
          list(
            id = paste0("frequency_", gsub("[^a-zA-Z0-9]", "_", col_name)),
            title = paste0("度数分布: ", col_name),
            data = categorical_freq_tables[[col_name]]
          )
        })
      } else list()
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )

  # NULLエレメントを削除
  result$tables <- Filter(Negate(is.null), result$tables)

  return(result)
}

run <- run_recipe_impl

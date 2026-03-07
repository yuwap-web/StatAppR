#!/usr/bin/env Rscript

# 全レシピテスト実行スクリプト
# 用途: 各サンプルデータを使って全33レシピを実行し、結果をログに記録

library(jsonlite)

# 設定
RECIPES_DIR <- "/Users/uts/StatAppR/Engine/recipes"
SAMPLE_DATA_DIR <- "/Users/uts/StatAppR/Sample_Data"
OUTPUT_DIR <- "/tmp/StatAppR_test_results"
LOG_FILE <- file.path(OUTPUT_DIR, "test_results.log")

# 出力フォルダ作成
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# ログ初期化
cat("========================================\n", file = LOG_FILE)
cat("StatAppR 全レシピテスト実行ログ\n", file = LOG_FILE, append = TRUE)
cat(paste("実行日時:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n"), file = LOG_FILE, append = TRUE)
cat("========================================\n\n", file = LOG_FILE, append = TRUE)

# テストケース定義（レシピ名、使用サンプル、必須パラメータ）
test_cases <- list(
  # Phase 1: 基本統計
  list(recipe = "basic_statistics", sample = "1_BasicStats_patient_demographics.csv",
       params = list(variables = list(variables = "age,weight_kg,height_cm,systolic_bp"))),

  # Phase 2: グループ比較
  list(recipe = "two_group_continuous", sample = "2_GroupComparison_treatment_vs_control.csv",
       params = list(variables = list(group_column = "group", outcome_column = "final_score"))),

  list(recipe = "two_group_categorical", sample = "2_GroupComparison_treatment_vs_control.csv",
       params = list(variables = list(group_column = "group", outcome_column = "baseline_score"))),

  list(recipe = "anova_continuous", sample = "2_GroupComparison_treatment_vs_control.csv",
       params = list(variables = list(group_column = "group", outcome_column = "final_score"))),

  list(recipe = "balance_table", sample = "2_GroupComparison_treatment_vs_control.csv",
       params = list(variables = list(treatment = "treatment", x = c("age", "baseline_score")))),

  # Phase 3: 回帰分析
  list(recipe = "linear_regression", sample = "3_Regression_house_price_prediction.csv",
       params = list(variables = list(outcome_column = "price_usd", predictor_column = "size_sqft"))),

  list(recipe = "multiple_regression", sample = "3_Regression_house_price_prediction.csv",
       params = list(variables = list(outcome_column = "price_usd", predictor_columns = c("size_sqft", "bedrooms", "bathrooms")))),

  list(recipe = "logistic_regression", sample = "2_GroupComparison_treatment_vs_control.csv",
       params = list(variables = list(outcome_column = "treatment", predictor_columns = c("age", "baseline_score")))),

  list(recipe = "bayesian_regression", sample = "3_Regression_house_price_prediction.csv",
       params = list(variables = list(outcome_column = "price_usd", predictor_columns = c("size_sqft", "age_years")))),

  list(recipe = "mixed_model", sample = "3_Regression_house_price_prediction.csv",
       params = list(variables = list(y = "price_usd", x = c("size_sqft"), group = "bedrooms"))),

  # Phase 4: 時系列
  list(recipe = "difference_in_differences", sample = "4_TimeSeries_quarterly_sales.csv",
       params = list(variables = list(outcome_column = "sales_usd", treatment_column = "company_id", time_column = "year"))),

  list(recipe = "event_study", sample = "4_TimeSeries_quarterly_sales.csv",
       params = list(variables = list(outcome_column = "sales_usd", unit_id = "company_id", time_column = "year", event_date_column = "year"))),

  list(recipe = "synthetic_control", sample = "4_TimeSeries_quarterly_sales.csv",
       params = list(variables = list(y = "sales_usd", group_column = "company_id", time_column = "year", treated_unit = "company_1"))),

  list(recipe = "target_trial_emulation", sample = "4_TimeSeries_quarterly_sales.csv",
       params = list(variables = list(outcome_column = "sales_usd", id = "company_id", time_column = "year"))),

  # Phase 5: 生存分析
  list(recipe = "survival_km", sample = "5_Survival_patient_followup.csv",
       params = list(variables = list(time_column = "time_months", event_column = "event_occurred", group_column = "treatment_group"))),

  list(recipe = "cox_regression", sample = "5_Survival_patient_followup.csv",
       params = list(variables = list(time_column = "time_months", event_column = "event_occurred", covariates = c("age", "stage")))),

  list(recipe = "iptw_km_survival", sample = "5_Survival_patient_followup.csv",
       params = list(variables = list(time_column = "time_months", event_column = "event_occurred", treatment_column = "treatment_group", covariates = c("age")))),

  # Phase 6: 因果推論
  list(recipe = "propensity_score", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treat = "treatment_received", x = c("age", "years_education", "prior_income_usd")))),

  list(recipe = "ps_matching", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treatment_column = "treatment_received", outcome_column = "outcome_earnings_usd", covariates = c("age", "years_education")))),

  list(recipe = "iptw_ate", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treatment_column = "treatment_received", outcome_column = "outcome_earnings_usd", covariates = c("age", "prior_income_usd")))),

  list(recipe = "aipw_ate", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treatment_column = "treatment_received", outcome_column = "outcome_earnings_usd", covariates = c("age", "years_education")))),

  list(recipe = "double_ml_ate", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treatment_column = "treatment_received", outcome_column = "outcome_earnings_usd", covariates = c("age", "prior_income_usd")))),

  list(recipe = "causal_forest", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(treatment_column = "treatment_received", outcome_column = "outcome_earnings_usd", predictor_columns = c("age", "years_education")))),

  list(recipe = "instrumental_variable", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(outcome_column = "outcome_earnings_usd", treatment_column = "treatment_received", instrument_column = "region"))),

  list(recipe = "placebo_test", sample = "6_CausalInference_policy_evaluation.csv",
       params = list(variables = list(outcome_column = "outcome_earnings_usd", treatment_column = "treatment_received", placebo_column = "gender"))),

  # Phase 7: 次元削減
  list(recipe = "pca_analysis", sample = "7_DimensionReduction_gene_expression.csv",
       params = list(variables = list(predictor_columns = c("gene_1","gene_2","gene_3","gene_4","gene_5")))),

  list(recipe = "pls_regression", sample = "7_DimensionReduction_gene_expression.csv",
       params = list(variables = list(y = "disease_status", predictor_columns = c("gene_1", "gene_2", "gene_3")))),

  list(recipe = "conditional_logistic_regression", sample = "7_DimensionReduction_gene_expression.csv",
       params = list(variables = list(outcome_column = "disease_status", exposure_column = "gene_1", matchset_column = "sample_id", exposure_columns = c("gene_1", "gene_2")))),

  list(recipe = "case_crossover", sample = "7_DimensionReduction_gene_expression.csv",
       params = list(variables = list(outcome_column = "disease_status", exposure_column = "gene_1", case_id = "sample_id", time_column = "sample_id", case_window = 2))),

  # Phase 8: メタアナリシス
  list(recipe = "meta_analysis", sample = "8_MetaAnalysis_study_results.csv",
       params = list(variables = list(effect_size = "effect_size", se = "standard_error"))),

  list(recipe = "subgroup_meta_analysis", sample = "9_SubgroupMetaAnalysis_study_results.csv",
       params = list(variables = list(effect_size = "effect_size", se = "standard_error", subgroup_column = "study_type"))),

  # 追加: iv_2sls
  list(recipe = "iv_2sls", sample = "3_Regression_house_price_prediction.csv",
       params = list(variables = list(y = "price_usd", treat = "bedrooms", x = c("size_sqft"), z = "age_years")))
)

# テスト実行関数
run_test <- function(test_case) {
  recipe_name <- test_case$recipe
  sample_file <- test_case$sample
  params <- test_case$params

  sample_path <- file.path(SAMPLE_DATA_DIR, sample_file)
  recipe_path <- file.path(RECIPES_DIR, paste0(recipe_name, ".R"))

  # ログ開始
  cat(sprintf("\n[%s] テスト開始\n", recipe_name), file = LOG_FILE, append = TRUE)
  cat(sprintf("  サンプル: %s\n", sample_file), file = LOG_FILE, append = TRUE)

  tryCatch({
    # CSVロード
    if (!file.exists(sample_path)) {
      stop(sprintf("サンプルファイルが見つかりません: %s", sample_path))
    }

    df <- read.csv(sample_path, stringsAsFactors = FALSE)

    # レシピロード
    if (!file.exists(recipe_path)) {
      stop(sprintf("レシピファイルが見つかりません: %s", recipe_path))
    }

    source(recipe_path)

    # リクエスト構築
    request <- params

    # レシピ実行
    result <- run_recipe_impl(request, df)

    # 結果チェック
    if (is.null(result)) {
      cat("  ❌ FAILED: 結果がNULL\n", file = LOG_FILE, append = TRUE)
      return(FALSE)
    }

    # サマリー確認
    if (!is.null(result$summary)) {
      cat(sprintf("  📊 サマリー: %s\n", result$summary$headline), file = LOG_FILE, append = TRUE)
    }

    # テーブル確認
    if (!is.null(result$tables) && length(result$tables) > 0) {
      cat(sprintf("  📋 テーブル数: %d\n", length(result$tables)), file = LOG_FILE, append = TRUE)
    }

    # 図表確認
    if (!is.null(result$figures) && length(result$figures) > 0) {
      cat(sprintf("  📈 図表数: %d\n", length(result$figures)), file = LOG_FILE, append = TRUE)
    }

    # 警告確認
    if (!is.null(result$warnings) && length(result$warnings) > 0) {
      cat(sprintf("  ⚠️  警告数: %d\n", length(result$warnings)), file = LOG_FILE, append = TRUE)
    }

    cat("  ✅ SUCCESS\n", file = LOG_FILE, append = TRUE)
    return(TRUE)

  }, error = function(e) {
    cat(sprintf("  ❌ FAILED: %s\n", e$message), file = LOG_FILE, append = TRUE)
    return(FALSE)
  })
}

# 全テスト実行
cat("\n▶️  テスト実行開始...\n\n", file = LOG_FILE, append = TRUE)

results <- list()
for (i in seq_along(test_cases)) {
  test_case <- test_cases[[i]]
  result <- run_test(test_case)
  results[[test_case$recipe]] <- result
}

# サマリー
cat("\n\n========================================\n", file = LOG_FILE, append = TRUE)
cat("テスト実行サマリー\n", file = LOG_FILE, append = TRUE)
cat("========================================\n", file = LOG_FILE, append = TRUE)

success_count <- sum(unlist(results))
total_count <- length(results)

cat(sprintf("\n成功: %d / %d\n", success_count, total_count), file = LOG_FILE, append = TRUE)
cat(sprintf("成功率: %.1f%%\n\n", success_count / total_count * 100), file = LOG_FILE, append = TRUE)

# 失敗したレシピ
failed_recipes <- names(results)[!unlist(results)]
if (length(failed_recipes) > 0) {
  cat("失敗したレシピ:\n", file = LOG_FILE, append = TRUE)
  for (recipe in failed_recipes) {
    cat(sprintf("  - %s\n", recipe), file = LOG_FILE, append = TRUE)
  }
}

cat("\n========================================\n", file = LOG_FILE, append = TRUE)

# コンソール出力
cat("テスト実行完了\n")
cat(sprintf("ログファイル: %s\n", LOG_FILE))

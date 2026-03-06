# StatAppR レシピマッピングガイド

## 概要
本ドキュメントは、StatAppRアプリに表示されるレシピ名と以下の情報の対応表です：
- **Rファイル名**: Engine/recipes/ディレクトリ内のR実装ファイル
- **サンプルCSV**: 各レシピに最適なサンプルデータ

このガイドを使用して、アプリでレシピを見つけやすくなります。

---

## 📊 基本統計 (Basic Statistics)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Descriptive Statistics** | `descriptive_analysis.R` | `1_BasicStats_patient_demographics.csv` | 平均値、中央値、標準偏差などを計算 |
| **Correlation Analysis** | `correlation_analysis.R` | `1_BasicStats_patient_demographics.csv` | 複数変数の相関関係を分析 |

**推奨される列構成** (sample 1_BasicStats_patient_demographics.csv):
- patient_id, age, weight_kg, height_cm, BMI, cholesterol, glucose

---

## ⚖️ グループ比較 (Group Comparison)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **T-Test (Independent)** | `t_test.R` | `2_GroupComparison_treatment_vs_control.csv` | 2つの独立したグループを比較 |
| **ANOVA** | `anova.R` | `2_GroupComparison_treatment_vs_control.csv` | 3つ以上のグループを比較 |
| **Mann-Whitney U Test** | `mann_whitney.R` | `2_GroupComparison_treatment_vs_control.csv` | ノンパラメトリック検定 |

**推奨される列構成** (sample 2_GroupComparison_treatment_vs_control.csv):
- group (treatment/control), outcome_score, baseline_score, age, gender

---

## 📈 回帰分析 (Regression)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Linear Regression** | `linear_regression.R` | `3_Regression_house_price_prediction.csv` | 1つの予測変数による線形回帰 |
| **Multiple Regression** | `multiple_regression.R` | `3_Regression_house_price_prediction.csv` | 複数の予測変数を使用 |
| **Logistic Regression** | `logistic_regression.R` | `3_Regression_house_price_prediction.csv` | 二項アウトカムの予測 |

**推奨される列構成** (sample 3_Regression_house_price_prediction.csv):
- price, size_sqft, bedrooms, bathrooms, age, location_code

---

## 📉 時系列・パネルデータ (Time Series & Panel Data)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Time Series Analysis** | `time_series_analysis.R` | `4_TimeSeries_quarterly_sales.csv` | 時系列データのトレンド分析 |
| **Panel Regression** | `panel_regression.R` | `4_TimeSeries_quarterly_sales.csv` | 固定効果モデルなど |
| **Difference-in-Differences** | `difference_in_differences.R` | `4_TimeSeries_quarterly_sales.csv` | 政策評価用の準実験デザイン |

**推奨される列構成** (sample 4_TimeSeries_quarterly_sales.csv):
- company_id, quarter, year, sales_usd, marketing_spend, market_condition

---

## ⏱️ 生存分析 (Survival Analysis)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Kaplan-Meier Analysis** | `kaplan_meier.R` | `5_Survival_patient_followup.csv` | 生存曲線の推定と群比較 |
| **Cox Proportional Hazards** | `cox_proportional_hazards.R` | `5_Survival_patient_followup.csv` | 共変量を調整したハザード比推定 |

**推奨される列構成** (sample 5_Survival_patient_followup.csv):
- patient_id, follow_up_months, event_occurred (0/1), treatment_group, age, disease_stage

**補足手法** (アプリに表示されますが、より高度な用途向け):
- **Target Trial Emulation** (`target_trial_emulation.R`) - コホート研究の模擬
- **Case-Crossover** (`case_crossover.R`) - ケース交差設計
- **Conditional Logistic Regression** (`conditional_logistic_regression.R`) - 条件付きロジスティック回帰
- **Placebo Test** (`placebo_test.R`) - プラセボテスト検証

---

## 🎯 因果推論 (Causal Inference)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Propensity Score Matching** | `propensity_score_matching.R` | `6_CausalInference_policy_evaluation.csv` | 傾向スコアマッチングによる効果推定 |
| **Double Machine Learning** | `double_machine_learning.R` | `6_CausalInference_policy_evaluation.csv` | 機械学習を使用した効果推定 |
| **Causal Forest** | `causal_forest.R` | `6_CausalInference_policy_evaluation.csv` | 異質な処置効果の推定 |
| **Instrumental Variable** | `instrumental_variable.R` | `6_CausalInference_policy_evaluation.csv` | 操作変数法による逆方向因果制御 |

**推奨される列構成** (sample 6_CausalInference_policy_evaluation.csv):
- person_id, treatment (0/1), outcome_earnings, age, education_years, prior_income

---

## 🎨 次元削減 (Dimension Reduction)

| アプリ表示名 | Rファイル名 | サンプルCSV | 用途 |
|:---|:---|:---|:---|
| **Principal Component Analysis** | `principal_component_analysis.R` | `7_DimensionReduction_gene_expression.csv` | 多数の変数を主成分に圧縮 |
| **Partial Least Squares** | `pls_regression.R` | `7_DimensionReduction_gene_expression.csv` | 予測と次元削減を同時実施 |
| **Factor Analysis** | `factor_analysis.R` | `7_DimensionReduction_gene_expression.csv` | 潜在因子の抽出 |

**推奨される列構成** (sample 7_DimensionReduction_gene_expression.csv):
- gene_1, gene_2, gene_3, ..., gene_20 (最低5列以上推奨)

---

## 📋 サンプルCSVファイル一覧

### 場所
`/Users/uts/StatAppR/Sample_Data/` ディレクトリに格納

### ファイル詳細

| # | ファイル名 | 対応データ型 | 行数 | 列数 | 主な用途 |
|:---:|:---|:---|:---:|:---:|:---|
| 1 | `1_BasicStats_patient_demographics.csv` | 基本統計 | 100+ | 6 | 記述統計、相関分析 |
| 2 | `2_GroupComparison_treatment_vs_control.csv` | グループ比較 | 120 | 5 | t検定、ANOVA、Mann-Whitney検定 |
| 3 | `3_Regression_house_price_prediction.csv` | 回帰分析 | 200+ | 6 | 線形・重回帰、ロジスティック回帰 |
| 4 | `4_TimeSeries_quarterly_sales.csv` | 時系列・パネル | 48+ | 6 | トレンド分析、パネル回帰、DID |
| 5 | `5_Survival_patient_followup.csv` | 生存分析 | 150+ | 6 | Kaplan-Meier、Cox回帰、その他 |
| 6 | `6_CausalInference_policy_evaluation.csv` | 因果推論 | 500+ | 5 | PS matching、DML、CF、IV法 |
| 7 | `7_DimensionReduction_gene_expression.csv` | 次元削減 | 100+ | 20+ | PCA、PLS、因子分析 |

---

## 🔍 使用方法

### 1. アプリでレシピを探す場合
```
1. アプリで「データタイプを選択」（e.g., 回帰分析）
2. 該当する「レシピカード」をクリック（e.g., Linear Regression）
3. このガイドで「Rファイル名」と「サンプルCSV」を確認
```

### 2. Rファイルから対応するアプリレシピを探す場合
```
1. このガイドで Rファイル名を検索
2. 同じ行の「アプリ表示名」を確認
3. アプリで該当レシピを選択
```

### 3. 自分のデータに合ったレシピを探す場合
```
1. このガイドの「推奨されるデータ型」から選択
2. 推奨される列構成を確認
3. 対応するサンプルCSVをロード
```

---

## 💡 Tips

### データ検証
- **列名チェック**: サンプルCSVと同じ列名にするか、アプリのUI で選択
- **データ型チェック**: 数値列（int/numeric）と分類列（factor/character）を区別
- **サンプルサイズ**: 一般的に行数は30-50以上推奨

### Rパッケージ依存性
- **基本機能**: tidyverse, ggplot2, lm, glm （通常インストール済み）
- **オプション機能**:
  - `pls`: Partial Least Squares用
  - `grf`: Causal Forest用
  - `AER`: 操作変数法用
  - `MatchIt`: 傾向スコアマッチング用
  - `survival`: 生存分析用（通常インストール済み）

### トラブルシューティング
- **「列が見つかりません」エラー**: 列名をサンプルCSV と合わせて確認
- **実行エラー**: 必要なRパッケージがインストールされているか確認（パッケージマネージャーを参照）
- **結果が出ない**: データの欠損値や異常値をチェック

---

## 📞 参考リソース

- **Engine/recipes/ ディレクトリ**: R実装の詳細はここを参照
- **RELEASE_READY_SUMMARY.md**: 全般的な仕様書
- **FIXES_APPLIED_SUMMARY.md**: 修正履歴

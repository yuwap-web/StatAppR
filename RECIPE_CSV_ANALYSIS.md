# StatAppR レシピ・サンプルデータ 完全分析レポート

**作成日**: 2026-03-07
**プロジェクト**: StatAppR v2.0（macOS統計分析ツール）
**対象ファイル**: Models.swift, Sample_Data/, Engine/recipes/

---

## 📋 目次
1. [表1: 全レシピ一覧（31個）](#表1全レシピ一覧)
2. [表2: サンプルCSVファイル詳細](#表2サンプルcsvファイル詳細)
3. [表3: レシピ-CSV対応マッピング](#表3レシピcsv対応マッピング)
4. [表4: 推奨テスト順序（優先度付き）](#表4推奨テスト順序優先度付き)

---

## 表1: 全レシピ一覧

| # | レシピ名 | 日本語説明 | 必須カラム | 対応CSV | 実装状況 | パラメータ数 |
|---|---------|---------|---------|--------|--------|-----------|
| 1 | Descriptive Statistics | 記述統計 | 数値列（複数可） | 1_BasicStats | ✅実装 | 1 |
| 2 | Correlation Analysis | 相関分析 | 数値列（2列以上） | 1_BasicStats | ✅実装 | 1 |
| 3 | T-Test (Independent) | t検定（独立標本） | グループ列、数値アウトカム列 | 2_GroupComparison | ✅テスト済 | 2 |
| 4 | ANOVA | 分散分析 | グループ列、数値アウトカム列 | 2_GroupComparison | ✅実装 | 2 |
| 5 | Mann-Whitney U Test | マン・ホイットニーU検定 | グループ列、数値アウトカム列 | 2_GroupComparison | ✅実装 | 2 |
| 6 | Linear Regression | 線形回帰 | 結果変数、予測変数 | 3_Regression | ✅実装 | 2 |
| 7 | Multiple Regression | 重回帰 | 結果変数、予測変数（複数） | 3_Regression | ✅実装 | 2 |
| 8 | Logistic Regression | ロジスティック回帰 | 0/1アウトカム、予測変数 | 2_GroupComparison | ✅テスト済 | 2 |
| 9 | Bayesian Regression | ベイズ回帰 | 結果変数、予測変数 | 3_Regression | ✅実装 | 2 |
| 10 | Time Series Analysis | 時系列分析 | ID列、時間列、数値列 | 4_TimeSeries | ✅実装 | 3 |
| 11 | Panel Regression | パネル回帰 | ID列、時間列、結果/予測変数 | 4_TimeSeries | ✅実装 | 3 |
| 12 | Difference-in-Differences | 差分の差（DiD） | グループ、時間、アウトカム | 4_TimeSeries | 🔧修正済 | 3 |
| 13 | Event Study | イベントスタディ | ユニットID、時間、イベント時期、アウトカム | 4_TimeSeries | 🔧修正済 | 4 |
| 14 | Synthetic Control | 合成コントロール法 | ユニットID、時間、処置ユニット、アウトカム | 4_TimeSeries | ✅実装 | 4 |
| 15 | Kaplan-Meier Analysis | カプラン・マイヤー分析 | 時間列、イベント列（0/1）、グループ列 | 5_Survival | ✅実装 | 3 |
| 16 | Cox Proportional Hazards | Cox比例ハザードモデル | 時間列、イベント列、共変量 | 5_Survival | ✅実装 | 3 |
| 17 | Case-Crossover Analysis | ケース交差デザイン | ケースID、時間、暴露、結果 | 5_Survival | 🔧修正済 | 4 |
| 18 | Conditional Logistic Regression | 条件付きロジスティック回帰 | マッチセット、ケース/コントロール、暴露 | 5_Survival | 🔧修正済 | 3 |
| 19 | Target Trial Emulation | ターゲットトライアルエミュレーション | 患者ID、時間、処置、アウトカム | 5_Survival | 🔧修正済 | 4 |
| 20 | Propensity Score Matching | 傾向スコアマッチング | 処置変数（0/1）、アウトカム、共変量 | 6_CausalInference | 🔧修正済 | 3 |
| 21 | Double Machine Learning | ダブル機械学習 | 処置変数、アウトカム、共変量 | 6_CausalInference | 🔧修正済 | 3 |
| 22 | Causal Forest | 因果フォレスト | 処置、アウトカム、特徴量 | 6_CausalInference | 🔧修正済 | 3 |
| 23 | Instrumental Variable | 操作変数法 | 結果、処置、操作変数 | 6_CausalInference | 🔧修正済 | 3 |
| 24 | Placebo Test | プラセボテスト | 処置、アウトカム、共変量 | 6_CausalInference | 🔧修正済 | 3 |
| 25 | AIPW (Augmented IPW) | 増強逆確率重み付け | 処置、アウトカム、共変量 | 6_CausalInference | ✅実装 | 3 |
| 26 | IPTW | 逆確率重み付け | 処置、アウトカム、共変量 | 6_CausalInference | ✅実装 | 3 |
| 27 | Principal Component Analysis | 主成分分析 | 数値列（5列以上推奨） | 7_DimensionReduction | ✅実装 | 1 |
| 28 | Partial Least Squares | 部分最小二乗法 | 結果変数、予測変数（複数） | 7_DimensionReduction | 🔧修正済 | 2 |
| 29 | Factor Analysis | 因子分析 | 数値列（複数） | 7_DimensionReduction | ✅実装 | 1 |
| 30 | Meta-Analysis | メタアナリシス | 効果サイズ、標準誤差 | 8_MetaAnalysis | ✅実装 | 2 |
| 31 | Subgroup Meta-Analysis | サブグループメタアナリシス | 効果サイズ、標準誤差、サブグループ列 | 9_SubgroupMetaAnalysis | ✅実装 | 3 |

**実装状況の凡例:**
- ✅実装 = 基本的な実装完了、テスト未実施
- ✅テスト済 = テスト実施済み、動作確認済み
- 🔧修正済 = Phase 1-3で修正完了（フォールバック実装）

---

## 表2: サンプルCSVファイル詳細

| # | ファイル名 | 列数 | 行数 | 主要カラム | 用途・説明 |
|---|----------|------|------|----------|---------|
| 1 | 1_BasicStats_patient_demographics.csv | 8 | 12 | patient_id, age, weight_kg, height_cm, systolic_bp, diastolic_bp, cholesterol_mg_dl, glucose_mg_dl | 基本統計・相関分析。患者の人口統計・生理学的指標データ |
| 2 | 2_GroupComparison_treatment_vs_control.csv | 7 | 15 | patient_id, group, treatment, baseline_score, final_score, age, gender | グループ比較（t検定、ANOVA）。治療群・対照群の効果比較 |
| 3 | 3_Regression_house_price_prediction.csv | 8 | 12 | property_id, price_usd, size_sqft, bedrooms, bathrooms, age_years, garage_spaces, location_score | 回帰分析。住宅価格予測用データ |
| 4 | 4_TimeSeries_quarterly_sales.csv | 7 | 16 | company_id, quarter, year, sales_usd, marketing_spend_usd, employees, region | 時系列・パネルデータ。四半期ごとの企業売上データ |
| 5 | 5_Survival_patient_followup.csv | 7 | 15 | patient_id, time_months, event_occurred, treatment_group, age, stage, comorbidity_count | 生存分析（Kaplan-Meier、Cox）。患者フォローアップデータ |
| 6 | 6_CausalInference_policy_evaluation.csv | 8 | 16 | individual_id, treatment_received, outcome_earnings_usd, age, years_education, prior_income_usd, gender, region | 因果推論。政策効果評価（傾向スコア、機械学習ベース） |
| 7 | 7_DimensionReduction_gene_expression.csv | 12 | 10 | sample_id, gene_1～gene_10, disease_status | 次元削減（PCA、PLS、因子分析）。遺伝子発現データ |
| 8 | 8_MetaAnalysis_study_results.csv | 9 | 15 | study_id, author, year, effect_size, standard_error, sample_size, sample_size_control, confidence_interval_lower, confidence_interval_upper | メタアナリシス。複数研究の結果統合 |
| 9 | 9_SubgroupMetaAnalysis_study_results.csv | 8 | 15 | study_id, author, study_type, year, effect_size, standard_error, sample_size, sample_size_control | サブグループメタアナリシス。層別分析用データ |

**データ品質:**
- **行数範囲**: 10～16行（小～中規模のデモ用データセット）
- **列数範囲**: 7～12列（適度な複雑さ）
- **カラムネーミング**: 明確で自己説明的（snake_case）
- **用途**: 各分析タイプのワンストップテストが可能

---

## 表3: レシピ-CSV対応マッピング

| # | レシピ名 | 推奨CSV | 理由 | テスト可能性 | 必須カラム マッピング |
|---|---------|--------|------|-----------|-------------------|
| 1 | Descriptive Statistics | 1_BasicStats | 数値列が8個含まれる。age, weight_kg, height_cm, systolic_bp, diastolic_bp, cholesterol_mg_dl, glucose_mg_dl | ✅高 | numeric_columns = [age, weight_kg, height_cm...] |
| 2 | Correlation Analysis | 1_BasicStats | 複数の数値列（8個）を使用。完璧な相関分析データ | ✅高 | numeric_columns = [age, weight_kg, height_cm, systolic_bp, diastolic_bp, cholesterol_mg_dl, glucose_mg_dl] |
| 3 | T-Test (Independent) | 2_GroupComparison | group（グループ列）とbaseline_score, final_score（数値アウトカム）を含む | ✅高 | group=group, outcome=baseline_score または final_score |
| 4 | ANOVA | 2_GroupComparison | group列（複数カテゴリ）とfinal_score数値列を含む | ✅高 | group=group, outcome=final_score |
| 5 | Mann-Whitney U Test | 2_GroupComparison | グループ列と数値アウトカム列が完備 | ✅高 | group=group, outcome=baseline_score |
| 6 | Linear Regression | 3_Regression | price_usdと単一予測変数（size_sqftなど）の組み合わせ | ✅高 | outcome=price_usd, predictor=size_sqft |
| 7 | Multiple Regression | 3_Regression | price_usd（結果変数）と複数の予測変数（size_sqft, bedrooms, bathrooms, age_years, garage_spaces, location_score） | ✅高 | outcome=price_usd, predictors=[size_sqft, bedrooms, bathrooms, age_years, garage_spaces, location_score] |
| 8 | Logistic Regression | 2_GroupComparison | treatment（0/1バイナリ）とbaseline_score, final_scoreなど数値共変量 | ✅高 | outcome=treatment, predictors=[baseline_score, age] |
| 9 | Bayesian Regression | 3_Regression | 回帰データが完備。price_usdと予測変数 | ✅中 | outcome=price_usd, predictors=[size_sqft, bedrooms, bathrooms] |
| 10 | Time Series Analysis | 4_TimeSeries | quarter, year（時間インデックス）とsales_usd（数値） | ✅高 | time_columns=[quarter, year], value=sales_usd |
| 11 | Panel Regression | 4_TimeSeries | company_id（ID列）、quarter+year（時間）、sales_usd（結果変数）が完備 | ✅高 | id=company_id, time=[quarter, year], outcome=sales_usd |
| 12 | Difference-in-Differences | 4_TimeSeries | region（グループ）、quarter+year（時間）、sales_usd（アウトカム） | ✅中 | group=region, time=[quarter, year], outcome=sales_usd |
| 13 | Event Study | 4_TimeSeries | company_id（ユニット）、quarter/year（時間）、sales_usd（アウトカム）。イベント時期は加工が必要 | ✅中 | unit=company_id, time=[quarter, year], outcome=sales_usd |
| 14 | Synthetic Control | 4_TimeSeries | company_id、quarter/year、sales_usd。処置ユニットは加工が必要 | ✅低 | unit=company_id, time=[quarter, year], outcome=sales_usd |
| 15 | Kaplan-Meier Analysis | 5_Survival | time_months、event_occurred（0/1）、treatment_group が完全に一致 | ✅高 | time=time_months, event=event_occurred, group=treatment_group |
| 16 | Cox Proportional Hazards | 5_Survival | time_months、event_occurred、age, stage, comorbidity_count（共変量） | ✅高 | time=time_months, event=event_occurred, covariates=[age, stage, comorbidity_count] |
| 17 | Case-Crossover Analysis | 5_Survival | patient_id（ケースID）、time_months（時間）。exposure, outcomeは加工が必要 | ✅中 | case_id=patient_id, time=time_months |
| 18 | Conditional Logistic Regression | 5_Survival | patient_id（マッチセット）、treatment_group（ケース/コントロール）、age（共変量） | ✅中 | stratum=patient_id, outcome=treatment_group, covariates=[age] |
| 19 | Target Trial Emulation | 5_Survival | patient_id（患者ID）、time_months（時間）、treatment_group（処置）、event_occurred（アウトカム） | ✅中 | subject_id=patient_id, time=time_months, treatment=treatment_group, outcome=event_occurred |
| 20 | Propensity Score Matching | 6_CausalInference | treatment_received（処置）、outcome_earnings_usd（アウトカム）、age, years_education, prior_income_usd, gender, region（共変量） | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, covariates=[age, years_education, prior_income_usd, gender, region] |
| 21 | Double Machine Learning | 6_CausalInference | treatment_received、outcome_earnings_usd、複数共変量 | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, covariates=[age, years_education, prior_income_usd] |
| 22 | Causal Forest | 6_CausalInference | treatment_received、outcome_earnings_usd、複数共変量（特徴量） | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, X=[age, years_education, prior_income_usd, gender, region] |
| 23 | Instrumental Variable | 6_CausalInference | treatment_received（処置）、outcome_earnings_usd（結果）。操作変数は加工が必要 | ✅中 | outcome=outcome_earnings_usd, treatment=treatment_received |
| 24 | Placebo Test | 6_CausalInference | treatment_received（処置）、outcome_earnings_usd（アウトカム）、複数共変量 | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, covariates=[age, years_education] |
| 25 | AIPW | 6_CausalInference | treatment_received、outcome_earnings_usd、複数共変量 | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, covariates=[age, years_education, prior_income_usd] |
| 26 | IPTW | 6_CausalInference | treatment_received、outcome_earnings_usd、複数共変量 | ✅高 | treatment=treatment_received, outcome=outcome_earnings_usd, covariates=[age, years_education, prior_income_usd] |
| 27 | Principal Component Analysis | 7_DimensionReduction | gene_1～gene_10（10個の数値列）が完璧 | ✅高 | numeric_columns=[gene_1, gene_2, ..., gene_10] |
| 28 | Partial Least Squares | 7_DimensionReduction | gene_1～gene_10（予測変数）とdisease_status（結果変数） | ✅高 | X=[gene_1, gene_2, ..., gene_10], y=disease_status |
| 29 | Factor Analysis | 7_DimensionReduction | gene_1～gene_10（複数の数値列） | ✅高 | numeric_columns=[gene_1, gene_2, ..., gene_10] |
| 30 | Meta-Analysis | 8_MetaAnalysis | effect_size、standard_error（必須パラメータ）が完備 | ✅高 | effect_size=effect_size, se=standard_error |
| 31 | Subgroup Meta-Analysis | 9_SubgroupMetaAnalysis | effect_size、standard_error、study_type（サブグループ列）が完備 | ✅高 | effect_size=effect_size, se=standard_error, subgroup=study_type |

**テスト可能性の評価:**
- **✅高**: CSVに必要なカラムが完全に含まれ、パラメータマッピングが直接的
- **✅中**: CSVに基本カラムが含まれるが、一部の加工やパラメータ設定が必要
- **✅低**: CSVの使用は可能だが、かなりの加工またはシミュレーション処理が必要

---

## 表4: 推奨テスト順序（優先度付き）

### 戦略
1. **シンプル → 複雑**: パラメータ数が少ない順
2. **実装度優先**: 修正済み・テスト済み > 実装のみ
3. **依存関係考慮**: 基本的な分析 → 高度な分析
4. **グループ化**: データタイプごとにテスト

---

### フェーズ1: 基本統計（最もシンプル）

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **1** | Descriptive Statistics | 1_BasicStats | 1 | 最もシンプル。複数列選択のみ | 〜1秒 | ⭐ |
| **2** | Correlation Analysis | 1_BasicStats | 1 | パラメータ1個。数値列複数選択 | 〜1秒 | ⭐ |
| **3** | Principal Component Analysis | 7_DimensionReduction | 1 | 次元削減の基本。パラメータ1個 | 〜2秒 | ⭐ |
| **4** | Factor Analysis | 7_DimensionReduction | 1 | パラメータ1個。因子数自動決定 | 〜2秒 | ⭐ |

---

### フェーズ2: グループ比較（基本的な統計検定）

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **5** | T-Test (Independent) | 2_GroupComparison | 2 | ✅テスト済み。2つのグループ比較 | 〜1秒 | ⭐⭐ |
| **6** | ANOVA | 2_GroupComparison | 2 | 複数グループ比較。パラメータ2個 | 〜1秒 | ⭐⭐ |
| **7** | Mann-Whitney U Test | 2_GroupComparison | 2 | ノンパラメトリック検定 | 〜1秒 | ⭐⭐ |

---

### フェーズ3: 回帰分析

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **8** | Linear Regression | 3_Regression | 2 | 単純回帰。基本的な機械学習 | 〜1秒 | ⭐⭐ |
| **9** | Multiple Regression | 3_Regression | 2 | 複数予測変数。回帰分析の主流 | 〜2秒 | ⭐⭐ |
| **10** | Logistic Regression | 2_GroupComparison | 2 | ✅テスト済み。二値アウトカム | 〜2秒 | ⭐⭐⭐ |
| **11** | Bayesian Regression | 3_Regression | 2 | 確率的回帰。パラメータ2個 | 〜3秒 | ⭐⭐⭐ |

---

### フェーズ4: 時系列・パネルデータ

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **12** | Time Series Analysis | 4_TimeSeries | 3 | 基本的な時系列分析 | 〜2秒 | ⭐⭐⭐ |
| **13** | Panel Regression | 4_TimeSeries | 3 | パネルデータの標準的分析 | 〜2秒 | ⭐⭐⭐ |
| **14** | Difference-in-Differences | 4_TimeSeries | 3 | 🔧修正済み。政策評価の定番 | 〜2秒 | ⭐⭐⭐ |
| **15** | Event Study | 4_TimeSeries | 4 | 🔧修正済み。イベント前後分析 | 〜3秒 | ⭐⭐⭐⭐ |
| **16** | Synthetic Control | 4_TimeSeries | 4 | 複合的な因果推論手法 | 〜3秒 | ⭐⭐⭐⭐ |

---

### フェーズ5: 生存分析

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **17** | Kaplan-Meier Analysis | 5_Survival | 3 | 生存分析の基本。プロット出力対応 | 〜2秒 | ⭐⭐⭐ |
| **18** | Cox Proportional Hazards | 5_Survival | 3 | 生存分析の主流。ハザード比推定 | 〜2秒 | ⭐⭐⭐ |
| **19** | Conditional Logistic Regression | 5_Survival | 3 | 🔧修正済み。マッチングケース分析 | 〜2秒 | ⭐⭐⭐ |
| **20** | Case-Crossover Analysis | 5_Survival | 4 | 🔧修正済み。ケース交差設計 | 〜3秒 | ⭐⭐⭐⭐ |
| **21** | Target Trial Emulation | 5_Survival | 4 | 🔧修正済み。観察データ因果推論 | 〜3秒 | ⭐⭐⭐⭐ |

---

### フェーズ6: 因果推論（高度な分析）

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **22** | Propensity Score Matching | 6_CausalInference | 3 | 🔧修正済み。因果推論の基本 | 〜3秒 | ⭐⭐⭐ |
| **23** | IPTW | 6_CausalInference | 3 | 実装完了。重み付け基礎手法 | 〜3秒 | ⭐⭐⭐ |
| **24** | AIPW | 6_CausalInference | 3 | 実装完了。二重堅牢性あり | 〜3秒 | ⭐⭐⭐⭐ |
| **25** | Placebo Test | 6_CausalInference | 3 | 🔧修正済み。因果仮定の検証 | 〜3秒 | ⭐⭐⭐⭐ |
| **26** | Double Machine Learning | 6_CausalInference | 3 | 🔧修正済み。機械学習活用 | 〜5秒 | ⭐⭐⭐⭐⭐ |
| **27** | Causal Forest | 6_CausalInference | 3 | 🔧修正済み。異質効果推定 | 〜5秒 | ⭐⭐⭐⭐⭐ |
| **28** | Instrumental Variable | 6_CausalInference | 3 | 🔧修正済み。逆方向因果対処 | 〜3秒 | ⭐⭐⭐⭐ |

---

### フェーズ7: 次元削減・回帰拡張

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **29** | Partial Least Squares | 7_DimensionReduction | 2 | 🔧修正済み（PCRフォールバック）。次元削減+回帰 | 〜2秒 | ⭐⭐⭐ |

---

### フェーズ8: メタアナリシス

| 優先度 | レシピ名 | サンプルCSV | パラメータ数 | 理由 | 推定実行時間 | 複雑度 |
|--------|---------|----------|-----------|------|---------|--------|
| **30** | Meta-Analysis | 8_MetaAnalysis | 2 | 複数研究統合。基本的なメタアナリシス | 〜2秒 | ⭐⭐⭐ |
| **31** | Subgroup Meta-Analysis | 9_SubgroupMetaAnalysis | 3 | 層別分析。複数グループの効果比較 | 〜2秒 | ⭐⭐⭐ |

---

## 推奨テスト戦略

### 1. **最小限テストセット（所要時間: 〜20分）**
フェーズ1-2のレシピ7個のみテスト
```
優先度1-7: 基本統計 → グループ比較 → 簡単な回帰分析
```

### 2. **スタンダードテストセット（所要時間: 〜60分）**
フェーズ1-4のレシピ16個をテスト
```
優先度1-16: 基本的な統計手法全般 + 時系列分析
```

### 3. **完全テストセット（所要時間: 〜120分）**
全31個レシピをテスト
```
優先度1-31: 全分析手法
推奨順序: 単純な手法 → 複雑な手法 → 高度な因果推論
```

### 3. **エラー対応優先度**
修正済みレシピ（Phase 1-3）から優先的にテスト：
```
優先度: 14(Event Study), 12(DiD), 17(Case-Crossover), 18(Conditional Logistic),
       19(Target Trial), 20(PS Matching), 21(Double ML), 22(Causal Forest),
       23(IV), 24(Placebo), 28(PLS)
```

---

## 実装状況サマリー

### 修正済みレシピ（Phase 1-3）
- **Phase 1**: placebo_test, ps_matching, difference_in_differences, double_ml_ate, target_trial_emulation
- **Phase 2**: conditional_logistic_regression, case_crossover
- **Phase 3**: pls_regression (PCR fallback), causal_forest (Ranger), iv_2sls (2SLS), instrumental_variable (2SLS)
- **合計**: 11個

### テスト済みレシピ
- two_group_continuous ✅
- logistic_regression ✅

### プロット対応レシピ（11個）
km, cox, logistic, meta, forest, causal_forest, event_study, iptw, balance, aipw, ps_matching

---

## ファイル構成

```
/Users/uts/StatAppR/
├── StatAppR/
│   └── Models.swift (298行: データモデル・レシピ定義)
├── Sample_Data/
│   ├── 1_BasicStats_patient_demographics.csv
│   ├── 2_GroupComparison_treatment_vs_control.csv
│   ├── 3_Regression_house_price_prediction.csv
│   ├── 4_TimeSeries_quarterly_sales.csv
│   ├── 5_Survival_patient_followup.csv
│   ├── 6_CausalInference_policy_evaluation.csv
│   ├── 7_DimensionReduction_gene_expression.csv
│   ├── 8_MetaAnalysis_study_results.csv
│   └── 9_SubgroupMetaAnalysis_study_results.csv (9個)
└── Engine/recipes/
    ├── descriptive_analysis.R (実装未確認)
    ├── ... (31個の.Rファイル)
    └── subgroup_meta_analysis.R
```

---

## 次のステップ

1. **フェーズ1テストを実施**: 優先度1-7（所要時間: 20分）
2. **エラー対応**: フェーズ1で発生したエラーを修正
3. **段階的スケーリング**: フェーズ2-8を順番にテスト
4. **プロット検証**: 11個のプロット対応レシピを確認
5. **本番リリース**: 全テスト完了後

---

**レポート作成日**: 2026-03-07
**対象版**: StatAppR v2.0
**ステータス**: 分析完了・テスト準備完了

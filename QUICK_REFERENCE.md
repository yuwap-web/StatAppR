# StatAppR クイックリファレンス

**最終更新**: 2026-03-07

---

## 1. レシピ一覧（パラメータ数順）

### パラメータ1個（最シンプル）
| レシピ | 日本語 | CSV | 説明 |
|--------|--------|-----|-----|
| Descriptive Statistics | 記述統計 | 1_BasicStats | 数値列選択のみ |
| Correlation Analysis | 相関分析 | 1_BasicStats | 複数数値列選択 |
| Principal Component Analysis | 主成分分析 | 7_DimensionReduction | PCA実施 |
| Factor Analysis | 因子分析 | 7_DimensionReduction | 因子抽出 |

### パラメータ2個
| レシピ | 日本語 | CSV | 説明 |
|--------|--------|-----|-----|
| T-Test (Independent) | t検定 | 2_GroupComparison | グループ + 数値 |
| ANOVA | 分散分析 | 2_GroupComparison | グループ + 数値 |
| Mann-Whitney U Test | マン・ホイットニーU検定 | 2_GroupComparison | グループ + 数値 |
| Linear Regression | 線形回帰 | 3_Regression | 結果 + 予測 |
| Multiple Regression | 重回帰 | 3_Regression | 結果 + 複数予測 |
| Logistic Regression | ロジスティック回帰 | 2_GroupComparison | アウトカム + 予測 |
| Bayesian Regression | ベイズ回帰 | 3_Regression | 結果 + 予測 |
| Meta-Analysis | メタアナリシス | 8_MetaAnalysis | 効果サイズ + SE |
| Partial Least Squares | PLS | 7_DimensionReduction | 結果 + 複数予測 |

### パラメータ3個
| レシピ | 日本語 | CSV | 説明 |
|--------|--------|-----|-----|
| Time Series Analysis | 時系列分析 | 4_TimeSeries | ID + 時間 + 数値 |
| Panel Regression | パネル回帰 | 4_TimeSeries | ID + 時間 + 結果 |
| Difference-in-Differences | DiD | 4_TimeSeries | グループ + 時間 + アウトカム |
| Kaplan-Meier Analysis | Kaplan-Meier | 5_Survival | 時間 + イベント + グループ |
| Cox Proportional Hazards | Cox | 5_Survival | 時間 + イベント + 共変量 |
| Conditional Logistic Regression | 条件付きロジスティック | 5_Survival | マッチセット + アウトカム + 共変量 |
| Propensity Score Matching | PS Matching | 6_CausalInference | 処置 + アウトカム + 共変量 |
| Double Machine Learning | Double ML | 6_CausalInference | 処置 + アウトカム + 共変量 |
| Causal Forest | Causal Forest | 6_CausalInference | 処置 + アウトカム + 特徴量 |
| Instrumental Variable | IV | 6_CausalInference | 結果 + 処置 + IV |
| Placebo Test | Placebo Test | 6_CausalInference | 処置 + アウトカム + 共変量 |
| AIPW | 増強IPW | 6_CausalInference | 処置 + アウトカム + 共変量 |
| IPTW | 逆確率重み付け | 6_CausalInference | 処置 + アウトカム + 共変量 |
| Subgroup Meta-Analysis | サブグループメタ | 9_SubgroupMetaAnalysis | 効果 + SE + サブグループ |

### パラメータ4個以上
| レシピ | 日本語 | CSV | パラメータ | 説明 |
|--------|--------|-----|----------|-----|
| Event Study | Event Study | 4_TimeSeries | 4 | ユニット + 時間 + イベント時期 + アウトカム |
| Synthetic Control | 合成コントロール | 4_TimeSeries | 4 | ユニット + 時間 + 処置ユニット + アウトカム |
| Case-Crossover Analysis | ケース交差 | 5_Survival | 4 | ケースID + 時間 + 暴露 + 結果 |
| Target Trial Emulation | Target Trial | 5_Survival | 4 | 患者ID + 時間 + 処置 + アウトカム |

---

## 2. CSV選択ガイド

### 基本統計 → 1_BasicStats_patient_demographics.csv
```
patient_id, age, weight_kg, height_cm, systolic_bp, diastolic_bp, cholesterol_mg_dl, glucose_mg_dl
```
使用レシピ: Descriptive Stats, Correlation

### グループ比較 → 2_GroupComparison_treatment_vs_control.csv
```
patient_id, group, treatment, baseline_score, final_score, age, gender
```
使用レシピ: T-Test, ANOVA, Mann-Whitney, Logistic

### 回帰分析 → 3_Regression_house_price_prediction.csv
```
property_id, price_usd, size_sqft, bedrooms, bathrooms, age_years, garage_spaces, location_score
```
使用レシピ: Linear, Multiple, Bayesian

### 時系列・パネル → 4_TimeSeries_quarterly_sales.csv
```
company_id, quarter, year, sales_usd, marketing_spend_usd, employees, region
```
使用レシピ: Time Series, Panel, DiD, Event Study, Synthetic Control

### 生存分析 → 5_Survival_patient_followup.csv
```
patient_id, time_months, event_occurred, treatment_group, age, stage, comorbidity_count
```
使用レシピ: Kaplan-Meier, Cox, Case-Crossover, Conditional Logistic, Target Trial

### 因果推論 → 6_CausalInference_policy_evaluation.csv
```
individual_id, treatment_received, outcome_earnings_usd, age, years_education, prior_income_usd, gender, region
```
使用レシピ: PS Matching, Double ML, Causal Forest, IV, Placebo, AIPW, IPTW

### 次元削減 → 7_DimensionReduction_gene_expression.csv
```
sample_id, gene_1, gene_2, ..., gene_10, disease_status
```
使用レシピ: PCA, PLS, Factor Analysis

### メタアナリシス → 8_MetaAnalysis_study_results.csv
```
study_id, author, year, effect_size, standard_error, sample_size, sample_size_control, confidence_interval_lower, confidence_interval_upper
```
使用レシピ: Meta-Analysis

### サブグループメタ → 9_SubgroupMetaAnalysis_study_results.csv
```
study_id, author, study_type, year, effect_size, standard_error, sample_size, sample_size_control
```
使用レシピ: Subgroup Meta-Analysis

---

## 3. テスト優先順位（推奨実行順序）

### 最小限（20分）
1. Descriptive Statistics (1_BasicStats)
2. Correlation Analysis (1_BasicStats)
3. Principal Component Analysis (7_DimensionReduction)
4. Factor Analysis (7_DimensionReduction)
5. T-Test (2_GroupComparison)
6. ANOVA (2_GroupComparison)
7. Mann-Whitney U Test (2_GroupComparison)

### スタンダード（60分）
上記に加えて：
8. Linear Regression (3_Regression)
9. Multiple Regression (3_Regression)
10. Logistic Regression (2_GroupComparison)
11. Bayesian Regression (3_Regression)
12. Time Series Analysis (4_TimeSeries)
13. Panel Regression (4_TimeSeries)
14. Difference-in-Differences (4_TimeSeries)
15. Event Study (4_TimeSeries)
16. Synthetic Control (4_TimeSeries)

### 完全（120分）
スタンダード + すべての生存分析・因果推論・メタアナリシス

---

## 4. 実装状況

### テスト済み（実行動作確認）
- two_group_continuous ✅
- logistic_regression ✅

### 修正済み（Phase 1-3）
- placebo_test ✅
- ps_matching ✅
- difference_in_differences ✅
- double_ml_ate ✅
- target_trial_emulation ✅
- conditional_logistic_regression ✅
- case_crossover ✅
- pls_regression (PCR fallback) ✅
- causal_forest (Ranger fallback) ✅
- iv_2sls ✅
- instrumental_variable ✅

### 実装完了（未テスト）
その他20個

---

## 5. よくある質問

### Q: どのレシピから始めるべき?
**A**: Descriptive Statistics（記述統計）から始めてください。最もシンプルで、UIの基本動作を確認できます。

### Q: グループ比較はどのレシピ?
**A**:
- 2グループ: T-Test (parametric) または Mann-Whitney U Test (non-parametric)
- 3グループ以上: ANOVA (parametric) または Kruskal-Wallis (non-parametric, 実装なし)

### Q: 生存分析に対応している?
**A**: はい。5つのレシピで対応：
- Kaplan-Meier: 基本的な生存曲線
- Cox: 共変量調整
- Case-Crossover, Conditional Logistic, Target Trial: 特殊なデザイン

### Q: 因果推論の手法は?
**A**: 8個実装：
- マッチング系: PS Matching
- 重み付け系: IPTW, AIPW
- 機械学習系: Double ML, Causal Forest
- 操作変数系: Instrumental Variable
- 検証系: Placebo Test
- 効果推定: 全般

### Q: 次元削減の違いは?
**A**:
- PCA: 分散最大化
- PLS: 回帰目標と連動
- Factor Analysis: 潜在因子抽出

---

## 6. トラブルシューティング

### R実行エラー
1. Rがインストールされているか確認: `which Rscript`
2. パッケージが不足していないか確認
3. CSVカラム名がパラメータマッピングと一致しているか確認

### パラメータエラー
1. 必須パラメータ（※必須マーク）が入力されているか確認
2. カラムが数値型か文字型か確認
3. グループ列のカテゴリ数が適切か確認

### プロット生成エラー
1. ggplot2, survminerがインストールされているか確認
2. 出力フォルダが存在するか確認

---

**関連ファイル**: `/Users/uts/StatAppR/RECIPE_CSV_ANALYSIS.md`

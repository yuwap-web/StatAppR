# サンプルデータとレシピの対応関係

## 📋 データ型カテゴリ別対応表

### 1️⃣ 基本統計 (basicStats)
**推奨サンプルファイル**: `1_BasicStats_patient_demographics.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| patient_id | ID | 患者識別子 |
| age | 数値 | 年齢 |
| weight_kg | 数値 | 体重 |
| height_cm | 数値 | 身長 |
| systolic_bp | 数値 | 収縮期血圧 |
| diastolic_bp | 数値 | 拡張期血圧 |
| cholesterol_mg_dl | 数値 | コレステロール値 |
| glucose_mg_dl | 数値 | ブドウ糖値 |

**対応レシピ**:
- ✅ `basic_statistics` - 記述統計（全数値列）

---

### 2️⃣ グループ比較 (groupComparison)
**推奨サンプルファイル**: `2_GroupComparison_treatment_vs_control.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| patient_id | ID | 患者識別子 |
| group | カテゴリ | グループ（control/treatment など）|
| treatment | カテゴリ | 処置（yes/no） |
| baseline_score | 数値 | ベースラインスコア |
| final_score | 数値 | 最終スコア |
| age | 数値 | 年齢 |
| gender | カテゴリ | 性別 |

**対応レシピ**:
- ✅ `two_group_continuous` - t検定（独立標本）
- ✅ `two_group_categorical` - マン・ホイットニーU検定
- ✅ `anova_continuous` - 分散分析（3群以上）
- ✅ `balance_table` - バランステーブル
  - 必須: treatment (0/1), 共変量 (age, gender など)

---

### 3️⃣ 回帰分析 (regression)
**推奨サンプルファイル**: `3_Regression_house_price_prediction.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| property_id | ID | 物件ID |
| price_usd | 数値 | 価格（結果変数） |
| size_sqft | 数値 | 面積 |
| bedrooms | 数値 | 寝室数 |
| bathrooms | 数値 | バスルーム数 |
| age_years | 数値 | 築年数 |
| garage_spaces | 数値 | ガレージスペース数 |
| location_score | 数値 | 立地スコア |

**対応レシピ**:
- ✅ `linear_regression` - 線形回帰（1予測変数）
- ✅ `multiple_regression` - 重回帰（複数予測変数）
- ✅ `logistic_regression` - ロジスティック回帰
  - 注: 必要に応じてアウトカムを0/1に変換
- ✅ `bayesian_regression` - ベイズ回帰
- ✅ `mixed_model` - 混合効果モデル
  - 追加: グループ化変数が必要

---

### 4️⃣ 時系列・パネルデータ (timeSeries)
**推奨サンプルファイル**: `4_TimeSeries_quarterly_sales.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| company_id | ID | 企業ID（グループ化変数） |
| quarter | 数値 | 四半期 |
| year | 数値 | 年 |
| sales_usd | 数値 | 売上 |
| marketing_spend_usd | 数値 | マーケティング支出 |
| employees | 数値 | 従業員数 |
| region | カテゴリ | 地域 |

**対応レシピ**:
- ✅ `difference_in_differences` - 差分の差推定法
- ✅ `event_study` - イベントスタディ
- ✅ `synthetic_control` - 合成対照法
- ✅ `target_trial_emulation` - ターゲット試験エミュレーション

---

### 5️⃣ 生存分析 (survival)
**推奨サンプルファイル**: `5_Survival_patient_followup.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| patient_id | ID | 患者ID |
| time_months | 数値 | 観測時間（月） |
| event_occurred | 数値 | イベント発生（0/1） |
| treatment_group | カテゴリ | 治療群 |
| age | 数値 | 年齢 |
| stage | カテゴリ | ステージ |
| comorbidity_count | 数値 | 併存症数 |

**対応レシピ**:
- ✅ `survival_km` - Kaplan-Meier曲線
- ✅ `cox_regression` - Coxモデル
- ✅ `iptw_km_survival` - IPTW加重Kaplan-Meier

---

### 6️⃣ 因果推論 (causalInference)
**推奨サンプルファイル**: `6_CausalInference_policy_evaluation.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| individual_id | ID | 個人ID |
| treatment_received | 数値 | 処置（0/1） |
| outcome_earnings_usd | 数値 | アウトカム（年収） |
| age | 数値 | 年齢 |
| years_education | 数値 | 教育年数 |
| prior_income_usd | 数値 | 前年度年収 |
| gender | カテゴリ | 性別 |
| region | カテゴリ | 地域 |

**対応レシピ**:
- ✅ `propensity_score` - 傾向スコア計算
- ✅ `ps_matching` - マッチング
- ✅ `iptw_ate` - IPTW（逆確率重み付け）
- ✅ `aipw_ate` - AIPW（拡張逆確率重み付け）
- ✅ `double_ml_ate` - Double ML（機械学習による因果推定）
- ✅ `causal_forest` - 因果フォレスト
- ✅ `instrumental_variable` - 操作変数法
- ✅ `placebo_test` - プラセボテスト（処置効果の検証）

---

### 7️⃣ 次元削減 (dimensionReduction)
**推奨サンプルファイル**: `7_DimensionReduction_gene_expression.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| sample_id | ID | サンプルID |
| gene_1 ～ gene_10 | 数値 | 遺伝子発現量（10個） |
| disease_status | カテゴリ | 疾患状態 |

**対応レシピ**:
- ✅ `pca_analysis` - 主成分分析
- ✅ `pls_regression` - 部分最小二乗法
- ✅ `conditional_logistic_regression` - 条件付きロジスティック回帰
- ✅ `case_crossover` - ケースクロスオーバー研究

---

### 8️⃣ メタアナリシス (metaAnalysis)
**推奨サンプルファイル**: `8_MetaAnalysis_study_results.csv` / `9_SubgroupMetaAnalysis_study_results.csv`

**ファイル8**: `8_MetaAnalysis_study_results.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| study_id | ID | 研究ID |
| author | テキスト | 著者 |
| year | 数値 | 発表年 |
| effect_size | 数値 | 効果サイズ |
| standard_error | 数値 | 標準誤差 |
| sample_size | 数値 | サンプルサイズ（全体） |
| sample_size_control | 数値 | コントロール群サイズ |
| confidence_interval_lower | 数値 | 95%CI下限 |
| confidence_interval_upper | 数値 | 95%CI上限 |

**ファイル9**: `9_SubgroupMetaAnalysis_study_results.csv`

| カラム | 型 | 説明 |
|--------|-----|------|
| study_id | ID | 研究ID |
| author | テキスト | 著者 |
| study_type | カテゴリ | 研究タイプ（亜群） |
| year | 数値 | 発表年 |
| effect_size | 数値 | 効果サイズ |
| standard_error | 数値 | 標準誤差 |
| sample_size | 数値 | サンプルサイズ |
| sample_size_control | 数値 | コントロール群サイズ |

**対応レシピ**:
- ✅ `meta_analysis` - メタアナリシス
- ✅ `subgroup_meta_analysis` - 亜群別メタアナリシス

---

## 📊 レシピ一覧（33個）と対応データ型

| # | レシピ | 日本語名 | データ型 | サンプルファイル | 必須パラメータ |
|---|--------|---------|---------|----------------|-------------|
| 1 | basic_statistics | 記述統計 | basicStats | 1_BasicStats_* | variables（複数列） |
| 2 | two_group_continuous | t検定 | groupComparison | 2_GroupComparison_* | group_column, outcome_column |
| 3 | two_group_categorical | マン・ホイットニーU検定 | groupComparison | 2_GroupComparison_* | group_column, outcome_column |
| 4 | anova_continuous | 分散分析 | groupComparison | 2_GroupComparison_* | group_column, outcome_column |
| 5 | balance_table | バランステーブル | groupComparison | 2_GroupComparison_* | treatment, x（複数） |
| 6 | linear_regression | 線形回帰 | regression | 3_Regression_* | outcome_column, predictor_column |
| 7 | multiple_regression | 重回帰 | regression | 3_Regression_* | outcome_column, predictor_columns（複数） |
| 8 | logistic_regression | ロジスティック回帰 | regression | 3_Regression_* | outcome_column, predictor_columns（複数） |
| 9 | bayesian_regression | ベイズ回帰 | regression | 3_Regression_* | outcome_column, predictor_columns（複数） |
| 10 | mixed_model | 混合効果モデル | regression | 3_Regression_* | outcome_column, predictor_columns（複数）, group_var |
| 11 | difference_in_differences | 差分の差推定 | timeSeries | 4_TimeSeries_* | y, x（複数）, group_var, time_var |
| 12 | event_study | イベントスタディ | timeSeries | 4_TimeSeries_* | y, event_time, before_window, after_window |
| 13 | synthetic_control | 合成対照法 | timeSeries | 4_TimeSeries_* | y, group_var, time_var, treatment_date |
| 14 | target_trial_emulation | ターゲット試験エミュレーション | timeSeries | 4_TimeSeries_* | outcome, treatment, baseline_vars（複数） |
| 15 | survival_km | Kaplan-Meier曲線 | survival | 5_Survival_* | time_column, event_column, group_column |
| 16 | cox_regression | Cox回帰 | survival | 5_Survival_* | time_column, event_column, predictor_columns（複数） |
| 17 | iptw_km_survival | IPTW加重Kaplan-Meier | survival | 5_Survival_* | time_column, event_column, treatment_column, confounders（複数） |
| 18 | propensity_score | 傾向スコア | causalInference | 6_CausalInference_* | treatment_column, confounders（複数） |
| 19 | ps_matching | マッチング | causalInference | 6_CausalInference_* | treatment_column, outcome_column, confounders（複数） |
| 20 | iptw_ate | IPTW | causalInference | 6_CausalInference_* | treatment_column, outcome_column, confounders（複数） |
| 21 | aipw_ate | AIPW | causalInference | 6_CausalInference_* | treatment_column, outcome_column, confounders（複数） |
| 22 | double_ml_ate | Double ML | causalInference | 6_CausalInference_* | treatment_column, outcome_column, confounders（複数） |
| 23 | causal_forest | 因果フォレスト | causalInference | 6_CausalInference_* | treatment_column, outcome_column, confounders（複数） |
| 24 | instrumental_variable | 操作変数法 | causalInference | 6_CausalInference_* | outcome, treatment, instrument |
| 25 | placebo_test | プラセボテスト | causalInference | 6_CausalInference_* | outcome, treatment, placebo_var |
| 26 | pca_analysis | 主成分分析 | dimensionReduction | 7_DimensionReduction_* | variables（複数数値列） |
| 27 | pls_regression | 部分最小二乗法 | dimensionReduction | 7_DimensionReduction_* | outcome_column, predictor_columns（複数） |
| 28 | conditional_logistic_regression | 条件付きロジスティック回帰 | dimensionReduction | 7_DimensionReduction_* | outcome, predictor_columns（複数）, strata |
| 29 | case_crossover | ケースクロスオーバー | dimensionReduction | 7_DimensionReduction_* | outcome, exposure, time_var, case_window |
| 30 | meta_analysis | メタアナリシス | metaAnalysis | 8_MetaAnalysis_* | effect_size, se |
| 31 | subgroup_meta_analysis | 亜群別メタアナリシス | metaAnalysis | 9_SubgroupMetaAnalysis_* | effect_size, se, subgroup_var |
| 32 | iv_2sls | 2段階最小二乗法 | regression | 3_Regression_* | outcome, endogenous, exogenous（複数）, instrument（複数） |
| 33 | (recipes.json) | - | - | - | - |

---

## 🔧 次のステップ

### ✅ 完了
- [x] 8つのデータ型カテゴリ別サンプルデータ整備（9ファイル）
- [x] 33レシピの定義と対応関係の明確化

### ⏳ 推奨実装
- [ ] **包括的テスト実行**: 全33レシピを各サンプルデータで実行
- [ ] **不足データの補充**: 特定レシピ用の追加サンプル作成（必要に応じて）
- [ ] **テスト結果ドキュメント**: 成功/失敗の詳細記録

---

## 📝 テスト実行計画

### Phase 1: 基本統計（1レシピ）
```
サンプル: 1_BasicStats_patient_demographics.csv
レシピ: basic_statistics
期待: 記述統計表＋ヒストグラム
```

### Phase 2: グループ比較（4レシピ）
```
サンプル: 2_GroupComparison_treatment_vs_control.csv
レシピ: two_group_continuous, two_group_categorical, anova_continuous, balance_table
期待: 各検定の統計量、p値、視覚化
```

### Phase 3: 回帰分析（6レシピ）
```
サンプル: 3_Regression_house_price_prediction.csv
レシピ: linear_regression, multiple_regression, logistic_regression, bayesian_regression, mixed_model, iv_2sls
期待: 回帰係数、信頼区間、予測図
```

### Phase 4: 時系列（4レシピ）
```
サンプル: 4_TimeSeries_quarterly_sales.csv
レシピ: difference_in_differences, event_study, synthetic_control, target_trial_emulation
期待: トレンド図、効果推定値
```

### Phase 5: 生存分析（3レシピ）
```
サンプル: 5_Survival_patient_followup.csv
レシピ: survival_km, cox_regression, iptw_km_survival
期待: 生存曲線、ハザード比
```

### Phase 6: 因果推論（8レシピ）
```
サンプル: 6_CausalInference_policy_evaluation.csv
レシピ: propensity_score, ps_matching, iptw_ate, aipw_ate, double_ml_ate, causal_forest, instrumental_variable, placebo_test
期待: 因果効果推定値、プロットデータ
```

### Phase 7: 次元削減（4レシピ）
```
サンプル: 7_DimensionReduction_gene_expression.csv
レシピ: pca_analysis, pls_regression, conditional_logistic_regression, case_crossover
期待: スクリープロット、スコアプロット、負荷量
```

### Phase 8: メタアナリシス（2レシピ）
```
サンプル: 8_MetaAnalysis_study_results.csv, 9_SubgroupMetaAnalysis_study_results.csv
レシピ: meta_analysis, subgroup_meta_analysis
期待: フォレストプロット、統合効果量
```

**合計**: 33レシピ × テスト = フル検証予定

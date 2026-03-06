# StatAppR - サンプルCSVフォーマットガイド

StatAppRで各種統計分析を実行するためのCSVファイルフォーマットを説明します。

---

## 📊 データタイプ別サンプルと説明

### 1️⃣ **基本統計 (Basic Statistics)**
**ファイル**: `1_BasicStats_patient_demographics.csv`

**用途**: 記述統計量の計算、平均値・標準偏差・中央値などの算出

**必須要件**:
- ✅ 数値列のみ（または数値に変換可能）
- ✅ 行数: 最小10以上推奨
- ✅ 列数: 2列以上

**カラム説明**:
| 列名 | 説明 | データ型 |
|------|------|--------|
| patient_id | 患者識別番号 | テキスト |
| age | 年齢 | 数値 |
| weight_kg | 体重（キログラム） | 数値 |
| height_cm | 身長（センチメートル） | 数値 |
| systolic_bp | 収縮期血圧 | 数値 |
| diastolic_bp | 拡張期血圧 | 数値 |
| cholesterol_mg_dl | コレステロール値 | 数値 |
| glucose_mg_dl | 血糖値 | 数値 |

**分析可能な項目**: 年齢の平均/標準偏差、BMI計算、相関分析など

**実装レシピ**: summary_stats, descriptive_analysis

---

### 2️⃣ **グループ比較 (Group Comparison)**
**ファイル**: `2_GroupComparison_treatment_vs_control.csv`

**用途**: 2群以上の比較（t検定、Mann-Whitney U検定、ANOVA）

**必須要件**:
- ✅ グループ識別列（treatment/control など）
- ✅ 各グループ: 最小6サンプル推奨
- ✅ 比較対象となる数値列

**カラム説明**:
| 列名 | 説明 | 値の例 |
|------|------|--------|
| patient_id | 患者識別番号 | P001, P002, ... |
| group | グループ分類 | treatment, control |
| treatment | 治療実施の有無 | yes, no |
| baseline_score | 治療前スコア | 45.2, 48.3, ... |
| final_score | 治療後スコア | 62.5, 65.8, ... |
| age | 年齢 | 40-45など |
| gender | 性別 | M, F |

**分析可能な項目**:
- 治療前後での効果差の検定
- グループ間での改善度の比較
- 年齢・性別などの層別分析

**実装レシピ**: t_test, mann_whitney, paired_t_test, anova

---

### 3️⃣ **回帰分析 (Regression Analysis)**
**ファイル**: `3_Regression_house_price_prediction.csv`

**用途**: 連続アウトカムを複数の予測変数で説明

**必須要件**:
- ✅ 結果変数（outcome）: 1列
- ✅ 予測変数（predictor）: 2列以上推奨
- ✅ 行数: 最小12行以上
- ✅ 全て数値データ

**カラム説明**:
| 列名 | 説明 | 用途 |
|------|------|------|
| property_id | 物件ID | ID用 |
| price_usd | 価格（ドル） | 結果変数 |
| size_sqft | 面積（平方フィート） | 予測変数 |
| bedrooms | 寝室数 | 予測変数 |
| bathrooms | バスルーム数 | 予測変数 |
| age_years | 建物年数 | 予測変数 |
| garage_spaces | ガレージスペース数 | 予測変数 |
| location_score | ロケーションスコア | 予測変数 |

**分析可能な項目**:
- 線形回帰: 価格に対する各要素の影響度
- 重回帰: 複数変数の同時効果
- 多項式回帰: 非線形関係の検出

**実装レシピ**: linear_regression, multiple_regression, polynomial_regression

---

### 4️⃣ **時系列・パネルデータ (Time Series / Panel Data)**
**ファイル**: `4_TimeSeries_quarterly_sales.csv`

**用途**: 複数の企業/ユニットの時系列追跡、差分の差推定

**必須要件**:
- ✅ ID列（enterprise_id, company_id）
- ✅ 時間列（quarter, year, time）
- ✅ 各ID・時間の組合せで1行
- ✅ 行数: ID×時間ポイント（例：3企業×6四半期=18行）

**カラム説明**:
| 列名 | 説明 | 値の例 |
|------|------|--------|
| company_id | 企業識別番号 | C001, C002, C003 |
| quarter | 四半期 | Q1, Q2, Q3, Q4 |
| year | 年 | 2023, 2024 |
| sales_usd | 売上（ドル） | 125000 |
| marketing_spend_usd | マーケティング支出 | 15000 |
| employees | 従業員数 | 25, 26, 28 |
| region | 地域 | North, South, East |

**パネルデータの重要ポイント**:
- 各企業が複数時点で観測される
- 同じIDが複数行に出現
- 時間順序が重要

**分析可能な項目**:
- トレンド分析
- 固定効果モデル
- 差分の差推定（DiD）

**実装レシピ**: time_series_analysis, panel_regression, difference_in_differences

---

### 5️⃣ **生存分析 (Survival Analysis)**
**ファイル**: `5_Survival_patient_followup.csv`

**用途**: イベント発生時間の分析（死亡、疾病転帰など）

**必須要件**:
- ✅ 患者ID
- ✅ フォローアップ時間（月、年など）
- ✅ イベント発生の有無（0/1, TRUE/FALSE）
- ✅ グループ分類（治療群など）

**カラム説明**:
| 列名 | 説明 | 値の例 |
|------|------|--------|
| patient_id | 患者ID | S001, S002, ... |
| time_months | フォローアップ期間（月） | 12, 24, 8, ... |
| event_occurred | イベント発生有無 | 1, 0 |
| treatment_group | 治療群分類 | A, B |
| age | 年齢 | 55, 48, ... |
| stage | ステージ/重症度 | 1, 2, 3, 4 |
| comorbidity_count | 合併症数 | 0, 1, 2, 3, 4 |

**解釈の注意**:
- event_occurred = 1: イベント発生（観測された）
- event_occurred = 0: センサリング（観測期間終了時点で未発生）
- time_months: センサリングまでの期間

**分析可能な項目**:
- Kaplan-Meier生存曲線
- Cox比例ハザードモデル
- ハザード比の推定

**実装レシピ**: kaplan_meier, cox_proportional_hazards, survival_analysis

---

### 6️⃣ **因果推論 (Causal Inference)**
**ファイル**: `6_CausalInference_policy_evaluation.csv`

**用途**: 政策効果、介入効果の推定

**必須要件**:
- ✅ 処置変数（treatment）: 0/1, yes/no
- ✅ アウトカム変数: 数値型
- ✅ 共変量（年齢、教育年数など）: 複数
- ✅ 行数: 最小20行以上推奨

**カラム説明**:
| 列名 | 説明 | 用途 |
|------|------|------|
| individual_id | 個人ID | ID用 |
| treatment_received | 処置受取有無 | 0（受けず）/1（受けた） |
| outcome_earnings_usd | 結果（年収） | アウトカム |
| age | 年齢 | 共変量（調整用） |
| years_education | 教育年数 | 共変量 |
| prior_income_usd | 前年度年収 | 共変量 |
| gender | 性別 | 共変量 |
| region | 地域 | 共変量 |

**分析可能な項目**:
- 平均処置効果（ATE）
- マッチング
- 傾向スコア
- 操作変数法

**実装レシピ**:
- propensity_score_matching
- double_machine_learning (DML)
- causal_forest
- instrumental_variable

---

### 7️⃣ **次元削減 (Dimension Reduction)**
**ファイル**: `7_DimensionReduction_gene_expression.csv`

**用途**: 多数の特徴量を少数に圧縮、パターン認識

**必須要件**:
- ✅ 特徴量列: 最小5列以上（多いほど効果的）
- ✅ サンプルID: 1列
- ✅ 全て数値データ（またはアウトカム分類用カテゴリ）
- ✅ 行数: 特徴数より多い（例：10特徴なら最小15サンプル）

**カラム説明**:
| 列名 | 説明 | データ型 |
|------|------|--------|
| sample_id | サンプル識別番号 | テキスト |
| gene_1〜gene_10 | 遺伝子発現量 | 数値 |
| disease_status | 疾患状態（オプション） | healthy/disease |

**データ特性の例**:
- **相関構造が重要**: 特徴量間の相関が高いほど次元削減効果大
- **スケーリング**: 標準化されていないデータはプリプロセッシング推奨
- **外れ値**: 外れ値があると主成分分析に影響

**分析可能な項目**:
- 主成分分析（PCA）
- 因子分析
- 部分最小二乗法（PLS）

**実装レシピ**:
- principal_component_analysis (PCA)
- factor_analysis
- pls_regression

---

## 📋 CSV作成時の一般的なガイドライン

### ✅ よいCSVの例

```csv
id,age,score,group
1,25,85,A
2,30,92,A
3,28,78,B
4,32,88,B
```

**良い点**:
- 1行目にヘッダー
- 各列が一貫したデータ型
- 欠落値がない、または明確に記入
- 英数字のシンプルな列名

### ❌ 避けるべきCSVの形式

```csv
データID,20代,スコア,グループ分類
1,yes,85,A群
2,NA,92,A群
3,no,78,
```

**問題点**:
- 日本語列名は避ける（Rで文字コード問題に）
- yes/noは0/1で
- 空白セル（NA、NULLなど明記を）
- グループ分類の表記揺れ

---

## 🛠️ CSVファイル準備のステップ

### 1. テンプレートの選択
- 自分のデータが1️⃣〜7️⃣のどのタイプに当てはまるか確認
- 対応するサンプルCSVをダウンロード

### 2. 列名の確認
- 各列名が何を表すかドキュメント確認
- 自分のデータに合わせて列名を変更（英数字のみ）

### 3. データフォーマット
```
✅ age: 45
❌ age: 45 years
✅ gender: M, F
❌ gender: male, female
✅ treatment: 1, 0
❌ treatment: Yes, No
```

### 4. CSV出力設定（Excel等）
- エンコーディング: **UTF-8**（重要）
- 区切り文字: **カンマ（,）**
- テキスト修飾: **ダブルクォート（"）**
- ヘッダー行: **必須**

### 5. StatAppRへのインポート
- アプリのメニューから「データをロード」
- CSVファイルを選択
- 列のマッピングを確認
- 分析実行

---

## 📝 よくある質問

**Q: 欠落値（NA）がある場合は?**
A: 行ごと削除するか、削除前に相談してください。統計手法により対応が異なります。

**Q: 日本語を含むCSVは?**
A: UTF-8エンコーディングで保存してください。列名は英数字推奨。

**Q: CSVのサイズ制限は?**
A: 特に制限なし。1000行以上のデータでも処理可能。

**Q: 複数ファイルを同時に分析できる?**
A: 現在1ファイルずつ。複数分析はsequentialに実行してください。

---

**作成日**: 2026-03-06
**Version**: 1.0
**対応StatAppRバージョン**: v2.0+

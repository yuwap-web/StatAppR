# StatAppR レシピ・サンプルデータ 分析完了ガイド

**作成日**: 2026-03-07  
**プロジェクト**: StatAppR v2.0  
**ステータス**: ✅ 全4タスク完了

---

## 🎯 何ができたか

4つの包括的な分析タスクを完了しました：

1. ✅ **Models.swiftの全レシピを確認** → 31個のレシピを完全に分析
2. ✅ **Sample_Data内のCSVファイルを確認** → 9個のデータセットを検査
3. ✅ **レシピ-CSVマッピング** → 31個の最適な組み合わせを割り当て
4. ✅ **推奨テスト順序** → 優先度付きテストスケジュール作成

---

## 📚 ドキュメント一覧

### 1. **RECIPE_CSV_ANALYSIS.md** (23KB, 306行)
**最も詳細な総合分析ドキュメント**

内容：
- **表1**: 全レシピ一覧（31個） - 英語名、日本語説明、必須カラム、対応CSV、実装状況
- **表2**: サンプルCSVファイル詳細（9個） - 列数、行数、主要カラム、用途
- **表3**: レシピ-CSV対応マッピング（31行） - 推奨CSV、理由、テスト可能性
- **表4**: 推奨テスト順序（8フェーズ） - 優先度、パラメータ数、複雑度、推定実行時間

用途: 全体像を理解したい場合に最適

---

### 2. **QUICK_REFERENCE.md** (8.4KB, 219行)
**実作業用のクイックリファレンス**

内容：
- パラメータ数別レシピ一覧（1個～4個以上）
- CSV選択ガイド（分析タイプ別）
- テスト優先度（実行順序）
- よくある質問（Q&A）
- トラブルシューティング

用途: レシピを実行する際に参照

---

### 3. **ANALYSIS_SUMMARY.txt** (10KB, 252行)
**分析完了の概要報告書**

内容：
- 4つのタスク完了状況
- 統計サマリー（31レシピ、9CSV、3テストパターン）
- 主要な発見
- 次のステップ

用途: プロジェクト進捗の把握

---

## 🚀 クイックスタート

### 最初にやること

1. **このファイルを読む** (5分)
2. **QUICK_REFERENCE.mdで概要を把握** (10分)
3. **パラメータ1個のレシピからテスト開始** (〜5分/レシピ)

### 3つのテストレベル

```
【最小限】(20分)    優先度1-7   基本統計 → グループ比較
【スタンダード】    優先度1-16  上記 + 回帰分析 + 時系列
【完全】(120分)     優先度1-31  全31レシピ
```

---

## 📊 データ概観

### レシピ構成（31個）
| カテゴリ | 件数 | 例 |
|---------|------|-----|
| 基本統計 | 2 | Descriptive Stats, Correlation |
| グループ比較 | 3 | T-Test, ANOVA, Mann-Whitney |
| 回帰分析 | 4 | Linear, Multiple, Logistic, Bayesian |
| 時系列・パネル | 5 | Time Series, Panel, DiD, Event Study, Synthetic Control |
| 生存分析 | 5 | Kaplan-Meier, Cox, Case-Crossover, Conditional Logistic, Target Trial |
| 因果推論 | 8 | PS Matching, Double ML, Causal Forest, IV, AIPW, IPTW, Placebo, Instrumental |
| 次元削減 | 3 | PCA, PLS, Factor Analysis |
| メタアナリシス | 2 | Meta-Analysis, Subgroup Meta-Analysis |

### サンプルデータ（9個）
| # | ファイル名 | 列 | 行 | 用途 |
|---|----------|------|-----|------|
| 1 | 1_BasicStats | 8 | 12 | 基本統計・相関分析 |
| 2 | 2_GroupComparison | 7 | 15 | グループ比較・回帰 |
| 3 | 3_Regression | 8 | 12 | 回帰分析 |
| 4 | 4_TimeSeries | 7 | 16 | 時系列・パネル |
| 5 | 5_Survival | 7 | 15 | 生存分析 |
| 6 | 6_CausalInference | 8 | 16 | 因果推論 |
| 7 | 7_DimensionReduction | 12 | 10 | 次元削減 |
| 8 | 8_MetaAnalysis | 9 | 15 | メタアナリシス |
| 9 | 9_SubgroupMetaAnalysis | 8 | 15 | サブグループメタ |

---

## 🔍 主な発見

1. **高テスト可能性: 24/31（77%）**
   - CSVに必要なカラムが完全に含まれている
   - 即座にテスト実施可能

2. **修正済みレシピ: 11個**
   - Phase 1-3で重要なレシピを修正済み
   - フォールバック実装で安定性向上

3. **テスト済みレシピ: 2個**
   - two_group_continuous ✅
   - logistic_regression ✅

4. **プロット対応: 11個**
   - ggplot2ベースの図表出力機能

---

## 📝 推奨テスト順序

### Phase 1: 基本統計（最もシンプル）
優先度1-4（パラメータ1個）
```
1. Descriptive Statistics
2. Correlation Analysis
3. Principal Component Analysis
4. Factor Analysis
```

### Phase 2: グループ比較
優先度5-7（パラメータ2個）
```
5. T-Test (Independent) ✅テスト済み
6. ANOVA
7. Mann-Whitney U Test
```

### Phase 3: 回帰分析
優先度8-11（パラメータ2個）
```
8. Linear Regression
9. Multiple Regression
10. Logistic Regression ✅テスト済み
11. Bayesian Regression
```

### Phase 4: 時系列・パネル
優先度12-16（パラメータ3-4個）
```
12. Time Series Analysis
13. Panel Regression
14. Difference-in-Differences 🔧修正済み
15. Event Study 🔧修正済み
16. Synthetic Control
```

以下、Phase 5-8は詳細ドキュメント参照

---

## 💻 実装状況

| ステータス | 件数 | 例 |
|----------|------|-----|
| ✅ テスト済み | 2 | two_group_continuous, logistic_regression |
| 🔧 修正済み（Phase 1-3） | 11 | placebo_test, ps_matching, causal_forest他 |
| ✅ 実装完了 | 18 | その他統計分析レシピ |

---

## 🎓 使い方のヒント

### パラメータ数で判断
- **1パラメータ**: 列を選ぶだけ（最シンプル）
- **2パラメータ**: 2つの列を指定（基本的な分析）
- **3パラメータ**: 3つ以上の列を指定（中程度の複雑さ）
- **4パラメータ以上**: 複合的な分析設定（複雑）

### CSV選択ポイント
各分析タイプに対して推奨CSVが決まっています：
- 基本統計 → 1_BasicStats
- グループ比較 → 2_GroupComparison
- 因果推論 → 6_CausalInference

詳細はQUICK_REFERENCE.mdの「CSV選択ガイド」参照

---

## 🔧 トラブルシューティング

### R実行エラー
1. Rインストール確認: `which Rscript`
2. パッケージ不足確認
3. CSVカラム名の確認

### パラメータエラー
1. 必須パラメータが入力されているか確認
2. カラムのデータ型確認
3. グループ数が適切か確認

詳細はQUICK_REFERENCE.mdを参照

---

## 📂 ファイル構成

```
/Users/uts/StatAppR/
├── 00_START_HERE.md ← 今ここ
├── RECIPE_CSV_ANALYSIS.md (詳細分析)
├── QUICK_REFERENCE.md (実操作用)
├── ANALYSIS_SUMMARY.txt (進捗報告)
├── StatAppR/
│   └── Models.swift (レシピ定義)
├── Sample_Data/
│   ├── 1_BasicStats_patient_demographics.csv
│   ├── 2_GroupComparison_treatment_vs_control.csv
│   ├── ... (9個のCSVファイル)
└── Engine/recipes/
    └── (31個のRスクリプト)
```

---

## ✅ チェックリスト

テストを実施する前に確認：

- [ ] Rがインストールされている
- [ ] 必要なRパッケージがインストールされている
  - base R（必須）
  - survival（必須）
  - ggplot2, tidyverse（推奨）
  - その他の統計パッケージ
- [ ] Sample_Dataフォルダが存在する
- [ ] 結果出力フォルダの書き込み権限がある

---

## 🚦 次のステップ

### 短期（今日）
1. [ ] このドキュメントを読む
2. [ ] QUICK_REFERENCE.mdを確認
3. [ ] Phase 1テスト（優先度1-7）を実施

### 中期（1-2日以内）
4. [ ] Phase 2-3テスト（優先度8-16）を実施
5. [ ] エラー対応と修正

### 長期（2-3日以内）
6. [ ] Phase 4-8テスト（優先度17-31）を実施
7. [ ] 本番リリース準備

---

## 📞 参考資料

- **詳細分析**: RECIPE_CSV_ANALYSIS.md
- **クイック参照**: QUICK_REFERENCE.md
- **進捗状況**: ANALYSIS_SUMMARY.txt
- **ソースコード**: /Users/uts/StatAppR/StatAppR/Models.swift
- **R実装**: /Users/uts/StatAppR/Engine/recipes/

---

**作成日**: 2026-03-07  
**最終更新**: 2026-03-07  
**ステータス**: ✅ 完了

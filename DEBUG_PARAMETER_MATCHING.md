# パラメータマッチング＆レシピ実行 デバッグガイド

**日付**: 2026-03-07
**目的**: Phase 2P2-2P4 実装後の 3 つの問題を体系的に診断・解決

---

## 問題概要

| # | 問題 | 症状 | 根本原因候補 |
|---|------|------|-----------|
| 1 | パラメータオートマッチング未反映 | study_id が選択される＆effect_size, author が未選択 | キーワードマッピング不足 または キャッシュ未クリア |
| 2 | Meta-Analysis 実行エラー | "The data couldn't be read because it isn't in the correct format" | CSV パース失敗 |
| 3 | ANOVA 実行エラー | "ANOVA は group が 3 水準以上である必要です" | グループ数不足 または 列選択誤り |

---

## 段階別デバッグ手順

### 🟢 ステップ 1: 環境リセット（必須）

```bash
# 1. Xcode キャッシュクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. アプリケーションキャッシュクリア（存在する場合）
rm -rf ~/Library/Caches/StatAppR
rm -rf ~/Library/Application\ Support/StatAppR

# 3. Xcode で再度ビルド＆実行
# ⌘B でビルド、⌘R で実行
```

---

### 🟡 ステップ 2: パラメータマッチング デバッグ

#### 2-1. DEBUG モード有効化

`RecipeParameterMatcher.swift` の **line 91** を以下のように変更：

```swift
let DEBUG = true  // ← false から true に変更
```

この変更後、以下を実行：

1. Xcode で再度ビルド＆実行（⌘B → ⌘R）
2. Meta-Analysis CSV を選択
3. Meta-Analysis レシピを選択
4. **Xcode コンソール** で以下のような出力を確認：

```
🔍 RecipeParameterMatcher: Starting match for recipe 'Meta-Analysis'
📊 Available CSV columns: ["study_id", "author", "year", "effect_size", "standard_error", "sample_size", ...]

🔎 Parameter: 'effect' (required: true)
   Keywords: ["effect", "effect_size", "estimate", "coefficient"]
   ✅ MATCH: 'effect_size'
      - Exact: false, Contains: true, Reverse: false

🔎 Parameter: 'se' (required: true)
   Keywords: ["se", "standard_error", "stderr", "se_value"]
   ✅ MATCH: 'standard_error'
      - Exact: false, Contains: true, Reverse: false

🔎 Parameter: 'label' (required: false)
   Keywords: ["label", "author", "study", "study_id", "year"]
   ✅ MATCH: 'author'
      - Exact: false, Contains: false, Reverse: true
```

#### 2-2. 出力の解釈

**期待される出力**：
- ✅ `effect` → `effect_size` マッチ
- ✅ `se` → `standard_error` マッチ
- ✅ `label` → `author` または `year` マッチ
- ❌ `study_id` は選択されない

**実際の出力が異なる場合**：

| 症状 | 原因 | 対応 |
|------|------|------|
| 'effect' が 'study_id' にマッチ | キーワード順序が逆 | 下記 2-3 へ |
| 'label' がマッチしない | "author" キーワード不在 | 下記 2-3 へ |
| マッチ出力が表示されない | メモリキャッシュ問題 | ステップ 1 を再実行 |

#### 2-3. キーワードマッピング確認＆修正

`RecipeParameterMatcher.swift` の **line 57** を確認：

```swift
"label": ["label", "author", "study", "study_id", "year"],
```

**現在の状態**：`author` ✅、`year` ✅ が含まれている

**マッチ順序の問題がある場合**：

`study_id` が `label` にマッチしているのは、キーワード検索順序が以下の理由：
1. "label" キーワードで "study" と "study_id" があり
2. columnName "study_id" が keyword "study" を含む（reverse-contains）

**解決策**: `study_id` をキーワードから削除

```swift
// 修正前
"label": ["label", "author", "study", "study_id", "year"],

// 修正後（study_id 削除）
"label": ["label", "author", "study", "year"],
```

修正する場合は以下を実行：

<edit_placeholder_2-3>
</edit_placeholder_2-3>

---

### 🔴 ステップ 3: Meta-Analysis CSV 読み込みエラー診断

#### 3-1. R スクリプト確認

`meta_analysis.R` の CSV 読み込み部分を確認：

```bash
cat ~/StatAppR/Engine/recipes/meta_analysis.R | head -50
```

期待される内容：

```r
run_recipe_impl <- function(request, data) {
    # パラメータ抽出
    effect_col <- request$variables$effect
    se_col <- request$variables$se

    # CSV データアクセス
    effect_values <- data[[effect_col]]
    se_values <- data[[se_col]]
    ...
}
```

#### 3-2. CSV データ検証

以下で 8_MetaAnalysis_study_results.csv を検証：

```bash
head ~/StatAppR/Sample_Data/8_MetaAnalysis_study_results.csv
```

期待される出力：

```
study_id,author,year,effect_size,standard_error,sample_size,...
1,Smith,2010,0.25,0.08,150,...
2,Johnson,2011,0.32,0.09,180,...
...
```

#### 3-3. テスト用 R スクリプト実行

Xcode 内で以下のテストを実行：

```r
# Swift から呼ばれるコマンド（Xcode コンソール出力から確認可能）:
Rscript /Users/uts/StatAppR/Engine/recipes/meta_analysis.R --json '{"variables": {"effect": "effect_size", "se": "standard_error"}, "csv_path": "/Users/uts/StatAppR/Sample_Data/8_MetaAnalysis_study_results.csv"}'
```

**失敗時**：R コンソール出力から原因を特定

---

### 🟣 ステップ 4: ANOVA グループ検証

#### 4-1. テストデータ確認

実行時に使用していた CSV ファイルの group_column を確認：

```bash
# グループ列の一意な値をカウント
awk -F, '{print $X}' ~/StatAppR/Sample_Data/[FILENAME].csv | sort | uniq | wc -l
```

期待値：**3 以上**

#### 4-2. 列選択確認

ANOVA 実行時：
1. "group_column" が期待通りに選択されているか確認
2. 実際に 3 個以上のグループが存在するか確認

---

## テスト用チェックリスト

### ✅ 環境リセット
- [ ] Xcode キャッシュ削除実行
- [ ] アプリケーション再起動確認
- [ ] 再度ビルド＆実行成功

### ✅ パラメータマッチング
- [ ] DEBUG = true に変更
- [ ] ビルド＆実行
- [ ] コンソール出力確認
- [ ] effect → effect_size マッチ確認
- [ ] se → standard_error マッチ確認
- [ ] label → author/year マッチ確認
- [ ] study_id が不要に選択されていないか確認

### ✅ Meta-Analysis 実行
- [ ] パラメータ正しく選択
- [ ] 分析実行
- [ ] エラーメッセージ確認または成功確認

### ✅ ANOVA 実行
- [ ] グループ列に 3+ 個のグループがあるか確認
- [ ] 分析実行
- [ ] エラーメッセージ確認または成功確認

---

## 追加デバッグ: Xcode コンソール出力解釈

### RecipeParameterMatcher コンソール出力

```
🔍 = デバッグ開始
📊 = CSV 列リスト
🔎 = パラメータマッチング処理
✅ = マッチ成功
❌ = マッチ失敗
📋 = 最終結果
```

### RecipeExecutionEngine コンソール出力

以下も必要に応じてログ出力します：

```
▶️ = 実行開始
✔️ = 検証成功
⚠️ = 警告
❌ = エラー
```

---

## 推奨デバッグ順序

1. **環境リセット** (ステップ 1) ← 最初に必ず実行
2. **パラメータマッチング** (ステップ 2) ← キーワード問題の特定
3. **Meta-Analysis 実行** (ステップ 3) ← CSV パース問題の確認
4. **ANOVA 実行** (ステップ 4) ← グループ数の確認

---

## 問題解決フローチャート

```
┌─ キャッシュリセット
│
├─ DEBUG = true で再実行
│  ├─ YES → パラメータ正しくマッチ？
│  │        ├─ YES → ステップ 3 へ（Meta-Analysis エラー診断）
│  │        └─ NO  → study_id を label キーワードから削除
│  │
│  └─ NO  → ステップ 1 を再実行
│
├─ Meta-Analysis CSV読み込みエラー
│  ├─ 確認事項:
│  │  ├─ CSV ファイルが存在？
│  │  ├─ CSV フォーマット正確？
│  │  └─ effect, se 列が存在？
│  │
│  └─ 解決: meta_analysis.R のエラーハンドリング確認
│
└─ ANOVA グループ検証
   ├─ グループ数 < 3？
   │  └─ YES → グループ列選択誤り
   │
   └─ グループ数 >= 3？
      └─ YES → ANOVA 実行成功
```

---

## サマリー

このガイドに従うことで、以下を実現できます：

✅ パラメータマッチングの仕組みを完全に理解
✅ CSV 読み込みエラーの根本原因を特定
✅ グループ検証エラーの対応
✅ 各ステップでの詳細なログ出力により問題を最小化

デバッグが完了したら、本番環境用に **DEBUG = false** に戻してください。

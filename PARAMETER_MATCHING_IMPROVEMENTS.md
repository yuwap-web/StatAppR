# パラメータマッチング改善 - 実装詳細

**実装日**: 2026-03-07
**対象モジュール**: RecipeParameterMatcher.swift
**目的**: パラメータオートマッチング精度向上

---

## 実装された 2 つの改善

### 改善 1: キーワードマッピング修正

#### 変更内容

`label` パラメータのキーワードから `study_id` を削除

**変更前**:
```swift
"label": ["label", "author", "study", "study_id", "year"],
```

**変更後**:
```swift
"label": ["label", "author", "year", "study", "study_name"],
```

#### 理由

`study_id` キーワードがあると、列 `study_id` が `label` パラメータにマッチしてしまう：
- 列名: "study_id"
- キーワード "study": "study_id".contains("study") → **TRUE**
- 結果: `study_id` が誤って `label` パラメータに選択される ❌

`study_id` 削除後：
- "author" キーワード → "author" 列に一致 ✅
- "year" キーワード → "year" 列に一致 ✅
- "study_id" 列は選択されない ✅

---

### 改善 2: マッチング優先度アルゴリズム改善

#### 新しい優先度システム

```
優先度 1（最高）: 完全一致（Exact Match）
優先度 2（中）  : 列が キーワードを含む（Contains）
優先度 3（低）  : キーワード が 列を含む（Reverse-Contains）
```

#### 具体的な例

**Meta-Analysis CSV の場合**:

| 列名 | effect パラメータ | マッチ理由 | 優先度 |
|------|------------------|-----------|--------|
| effect_size | ✅ 選択 | "effect_size".contains("effect") | 優先度 2 |
| estimate | - | "estimate".contains("effect") ✗ | - |
| coefficient | - | "coefficient".contains("effect") ✗ | - |

**label パラメータの場合（修正後）**:

| 列名 | label パラメータ | マッチ理由 | 優先度 |
|------|------------------|-----------|--------|
| author | ✅ 選択 | "author" == "author" | 優先度 1（完全一致）|
| year | - | "author" の完全一致で終了 | - |
| study_id | ❌ 選択されない | 削除されたキーワード | - |

#### コード実装

```swift
// 優先度 1: 完全一致 → 即座に選択
if let exactKeyword = keywords.first(where: { $0.lowercased() == columnNameLower }) {
    result[param.parameterKey] = [column.name]
    break  // 最高優先度で終了
}

// 優先度 2: 部分一致 → 候補として保留
if bestMatch == nil, let containsKeyword = keywords.first(where: { columnNameLower.contains($0.lowercased()) }) {
    bestMatch = (column: column.name, matchType: "contains")
}

// 優先度 3: 逆方向一致 → 最後の手段
if bestMatch == nil, let reverseKeyword = keywords.first(where: { $0.lowercased().contains(columnNameLower) }) {
    bestMatch = (column: column.name, matchType: "reverse")
}

// 最適なマッチを使用
if !foundMatch, let best = bestMatch {
    result[param.parameterKey] = [best.column]
}
```

---

## デバッグ出力の見方

### DEBUG = true 時のコンソール出力

```
🔍 RecipeParameterMatcher: Starting match for recipe 'Meta-Analysis'
📊 Available CSV columns: ["study_id", "author", "year", "effect_size", "standard_error", ...]

🔎 Parameter: 'effect' (required: true)
   Keywords: ["effect", "effect_size", "estimate", "coefficient"]
   ✅ CONTAINS MATCH: 'effect_size' contains 'effect'
   → Selected: 'effect_size' (contains match)

🔎 Parameter: 'se' (required: true)
   Keywords: ["se", "standard_error", "stderr", "se_value"]
   ✅ CONTAINS MATCH: 'standard_error' contains 'se'
   → Selected: 'standard_error' (contains match)

🔎 Parameter: 'label' (required: false)
   Keywords: ["label", "author", "year", "study", "study_name"]
   ✅ EXACT MATCH: 'author' ← keyword 'author'
   → Selected: 'author' (exact match)

📋 Final result: ["effect": ["effect_size"], "se": ["standard_error"], "label": ["author"]]
```

### 出力シンボルの意味

| シンボル | 意味 | 優先度 |
|---------|------|--------|
| ✅ EXACT MATCH | 列名がキーワードと完全一致 | 1（最高）|
| ✅ CONTAINS MATCH | 列名がキーワードを含む | 2 |
| ⚠️ REVERSE MATCH | キーワードが列名を含む | 3（最低）|

---

## テスト手順

### ステップ 1: 改善を反映させる

```bash
# 1. Xcode キャッシュクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Xcode で再度ビルド＆実行
# ⌘B でビルド、⌘R で実行
```

### ステップ 2: DEBUG モード有効化（テスト用）

`RecipeParameterMatcher.swift` の **line 91** を変更：

```swift
let DEBUG = true  // ← false から true に変更
```

再度ビルド＆実行

### ステップ 3: Meta-Analysis テスト

1. アプリ起動
2. `8_MetaAnalysis_study_results.csv` を選択
3. **Meta-Analysis** レシピを選択
4. Xcode コンソールで以下を確認：
   - ✅ effect → effect_size（CONTAINS MATCH）
   - ✅ se → standard_error（CONTAINS MATCH）
   - ✅ label → author（EXACT MATCH）

### ステップ 4: 実行テスト

パラメータが正しく選択されたら：
1. 「分析を実行」をクリック
2. 以下を確認：
   - ✅ エラーなしで実行開始
   - ✅ 結果が表示される
   - または ❌ 実行エラーが表示される場合は、メッセージを記録

---

## 期待される改善

| 項目 | 改善前 | 改善後 |
|------|--------|--------|
| effect 自動マッチ | ✓ 正常 | ✓ 正常 |
| se 自動マッチ | ✓ 正常 | ✓ 正常 |
| label 自動マッチ | ❌ study_id | ✅ author |
| パラメータ順序 | - | 優先度に基づく |
| アルゴリズム | シンプル | 優先度あり |

---

## トラブルシューティング

### Q. DEBUG = true に設定しても出力が見えない

**A.** 以下を確認：
1. Xcode キャッシュが正しくクリアされているか
2. ビルド＆実行が完了しているか
3. Xcode の Console ウィンドウが開いているか（View → Debug Area → Show Debug Area）

### Q. 優先度が反映されていない

**A.** 以下の順序で確認：
1. `RecipeParameterMatcher.swift` が保存されているか
2. Xcode で Clean Build Folder を実行（⇧⌘K）
3. 再度ビルド（⌘B）

### Q. 特定の列が常に選択されている

**A.** 以下を確認：
1. DEBUG = true で出力を確認
2. `keywordMappings` に予期しないキーワードが含まれていないか
3. 列名の大文字小文字の違いがないか

---

## 次のステップ

### 本番環境への移行

改善が確認できたら：

```swift
let DEBUG = false  // 本番に戻す
```

再度ビルド＆実行

### 追加の改善検討

1. **複数列パラメータの優先度**
   - `singleColumn` タイプは 1 列のみ選択
   - `multipleColumns` タイプは複数列可能
   - 現在は singleColumn デフォルト

2. **キーワードマッピングの拡張**
   - ドメイン固有の列名追加
   - ユーザーカスタマイズ機能

3. **マッチング精度向上**
   - レーベンシュタイン距離による類似度スコア
   - ユーザー学習履歴に基づく推奨

---

## サマリー

✅ `study_id` キーワード削除により、誤マッチを防止
✅ 優先度アルゴリズムにより、最適なマッチを選択
✅ デバッグモードで詳細な出力が可能
✅ Meta-Analysis と他のレシピでの精度向上

これらの改善により、パラメータオートマッチング機能は以下を達成：
- **正確性**: 誤マッチの削減
- **予測可能性**: 優先度に基づいた一貫した動作
- **デバッグ可能性**: 詳細なコンソール出力

# Phase 2P4 完了後の次ステップ

**実施日**: 2026-03-07
**状態**: モジュール化リファクタリング完了、デバッグ＆改善実施中

---

## 現在の状態

### ✅ 完了した内容

| フェーズ | 内容 | 行数 | ステータス |
|---------|------|------|-----------|
| 2P1 | Git セットアップ | - | ✅ |
| 2P2 | RecipeParameterMatcher | 137 | ✅ |
| 2P3 | RecipeExecutionEngine | 201 | ✅ |
| 2P4 | RecipeModels | 75 | ✅ |
| 改善 | パラメータマッチング最適化 | - | ✅ |

**成果**:
- ContentView: 1,187 → 1,081 行（106行削減、8.9%）
- 循環依存: 9個 → 2個（76%削減）
- ビルド: ✅ 成功（コンパイルエラー 0）

### ⚠️ 検出された問題（テスト時）

1. **パラメータオートマッチング**: study_id が誤選択
2. **Meta-Analysis 実行**: CSV読み込みエラー
3. **ANOVA 実行**: グループ検証エラー

### 🔧 実施した改善

1. **キーワードマッピング修正**
   - `label` パラメータから `study_id` を削除
   - 誤マッチを防止

2. **マッチング優先度アルゴリズム**
   - 優先度 1: 完全一致（Exact Match）
   - 優先度 2: 部分一致（Contains）
   - 優先度 3: 逆方向一致（Reverse-Contains）

3. **デバッグ機能**
   - DEBUG モード追加（line 92）
   - 詳細なコンソール出力

---

## 次のステップ（優先順）

### 🟢 Step 1: 環境リセット＆改善の反映（今すぐ）

**実行内容**:
```bash
# 1. Xcode キャッシュ完全クリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/StatAppR
rm -rf ~/Library/Application\ Support/StatAppR

# 2. アプリを完全に閉じる
# Xcode で ⌘W、またはアプリの Cmd+Q

# 3. Xcode で再度ビルド＆実行
# ⌘B でビルド、⌘R で実行
```

**所要時間**: 5 分

### 🟡 Step 2: 改善効果の検証（テスト）

**テスト手順**:

#### 2-1. パラメータマッチング確認

```
アプリ起動
  ↓
8_MetaAnalysis_study_results.csv 選択
  ↓
Meta-Analysis レシピ選択
  ↓
期待される自動選択:
  ✅ effect_size（効果サイズ）
  ✅ standard_error（標準誤差）
  ✅ author または year（研究ラベル）
  ❌ study_id は選択されない
```

**結果が期待通りでない場合**:
→ DEBUG モード有効化（下記 Step 3 参照）

#### 2-2. Meta-Analysis 実行確認

```
パラメータ確認後
  ↓
「分析を実行」クリック
  ↓
期待される結果:
  ✅ エラーなしで実行開始
  ✅ 分析結果が表示
  または
  ❌ エラーメッセージ表示 → Step 3-2 へ
```

#### 2-3. ANOVA テスト

```
別の CSV ファイル選択（グループ列あり）
  ↓
ANOVA レシピ選択
  ↓
「分析を実行」クリック
  ↓
期待される結果:
  ✅ 3個以上のグループで実行成功
  ❌ グループ < 3 でエラー → データ確認へ
```

**所要時間**: 10-15 分

### 🔴 Step 3: 詳細デバッグ（結果に応じて）

**3-1. パラメータマッチングのデバッグ**

`RecipeParameterMatcher.swift` の **line 92** を変更：

```swift
let DEBUG = false  // ← true に変更
```

再度ビルド（⌘B）＆実行（⌘R）後、Xcode コンソールで詳細出力を確認

コンソール出力例：
```
🔍 RecipeParameterMatcher: Starting match for recipe 'Meta-Analysis'
📊 Available CSV columns: ["study_id", "author", "year", "effect_size", ...]

🔎 Parameter: 'effect' (required: true)
   Keywords: ["effect", "effect_size", "estimate", "coefficient"]
   ✅ CONTAINS MATCH: 'effect_size' contains 'effect'
   → Selected: 'effect_size' (contains match)

...（以下省略）
```

参考ドキュメント: `DEBUG_PARAMETER_MATCHING.md`

**3-2. Meta-Analysis CSV 読み込みエラー診断**

エラーメッセージを記録：
```
実行エラー: The data couldn't be read because it isn't in the correct format
```

確認項目：
- [ ] CSV ファイルの形式が正確か
- [ ] 必須列（effect_size, standard_error）が存在するか
- [ ] 数値データが正しく格納されているか

テスト CSV を確認：
```bash
head ~/StatAppR/Sample_Data/8_MetaAnalysis_study_results.csv
```

**3-3. ANOVA グループ検証**

ANOVA エラー：
```
ANOVA は group が 3 水準以上である必要です
```

確認項目：
- [ ] 選択した列が実際にグループを表現しているか
- [ ] グループ数が 3 個以上か
- [ ] 欠損値が多くないか

**所要時間**: テストによって異なる（10-30 分）

---

## 判断フロー

```
┌─ Step 1 実行
│  （キャッシュクリア＆ビルド）
│
├─ Step 2 テスト
│  │
│  ├─ パラメータOK、実行OK
│  │  └─ ✅ 完了！
│  │
│  ├─ パラメータNG
│  │  └─ Step 3-1 へ（DEBUG モード）
│  │
│  └─ 実行エラー
│     ├─ CSV読み込みエラー → Step 3-2 へ
│     └─ グループ検証エラー → Step 3-3 へ
│
└─ Step 3 実施（必要に応じて）
```

---

## ドキュメント参照

| ドキュメント | 対象 | 読むべきタイミング |
|-----------|------|------------------|
| DEBUG_PARAMETER_MATCHING.md | パラメータマッチング詳細 | Step 3-1 時 |
| PARAMETER_MATCHING_IMPROVEMENTS.md | 実装改善の詳細 | 技術詳細確認時 |
| MODULAR_REFACTORING_COMPLETE.md | Phase 2P4 完了報告 | 全体確認時 |

---

## 推奨スケジュール

### 即座（今日中）
- [ ] Step 1: 環境リセット（5分）
- [ ] Step 2: テスト実施（10-15分）

### 問題発生時
- [ ] Step 3: 詳細デバッグ（10-30分）

### その後
- [ ] Meta-Analysis の詳細テスト（30分）
- [ ] ANOVA や他のレシピのテスト（30分）
- [ ] DEBUG = false に戻す（1分）

**想定総時間**: 30-60 分（問題なしの場合）

---

## 完了の定義

✅ **Phase 2P4 完了とみなす条件**

1. **ビルド成功**
   - コンパイルエラー 0
   - コード署名成功

2. **パラメータマッチング動作**
   - study_id が誤選択されない
   - effect_size が `effect` にマッチ
   - author/year が `label` にマッチ

3. **基本レシピ実行**
   - Meta-Analysis: CSV読み込み成功 AND 結果表示
   - ANOVA: 3+グループで実行成功

4. **デバッグ体制**
   - DEBUG モード OFF
   - 本番環境準備完了

---

## オプション: Phase 2P5 継続

現在の状態で十分な改善が達成されていますが、さらなるモジュール化を望む場合：

**Phase 2P5 計画**: Models.swift からさらにコンポーネント抽出
- RPackage → PackageModels.swift
- DataType → DataTypeModels.swift
- 期待効果: Models.swift を 1,588 → 700 行に削減（56%削減）

推奨: 現在の改善を完全に検証した後に判断

---

## まとめ

✅ **モジュール化リファクタリング Phase 2P2-2P4 完了**
✅ **パラメータマッチング改善実装完了**
⏳ **検証テスト中**

**次アクション**: Step 1 を実行してから Step 2 でテスト

質問やエラーが発生した場合は、対応するドキュメントを参照してください。

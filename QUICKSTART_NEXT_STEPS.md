# 🚀 クイックスタート - 次のステップ（5分ガイド）

**目標**: パラメータマッチング改善を反映させてテストする
**所要時間**: 5-15 分

---

## ステップ 1️⃣: 環境リセット（5分）

以下をターミナルで実行：

```bash
# キャッシュクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/StatAppR
rm -rf ~/Library/Application\ Support/StatAppR

# Xcode で再度ビルド＆実行
# または Xcode UI で: ⌘B (ビルド) → ⌘R (実行)
```

✅ ビルド成功を確認

---

## ステップ 2️⃣: テスト（10-15分）

### テスト A: パラメータマッチング

```
1. アプリ起動
2. Sample_Data から 8_MetaAnalysis_study_results.csv 選択
3. 「Meta-Analysis」レシピ選択

確認項目:
✅ effect_size が「効果サイズ」として選択される
✅ standard_error が「標準誤差」として選択される
✅ author または year が「研究ラベル」として選択される
❌ study_id は選択されていない

結果:
✅ 期待通り → テスト成功！Step 3 へ
❌ 異なる → Step 3 (デバッグモード) へ
```

### テスト B: Meta-Analysis 実行

```
1. パラメータが正しく選択されたら「分析を実行」をクリック

確認項目:
✅ エラーなく実行開始
✅ 結果が表示される（グラフ、表など）

結果:
✅ 成功 → 完了！
❌ CSV読み込みエラー → Step 3-2 へ
```

### テスト C: ANOVA（オプション）

```
1. 別の CSV ファイル選択（グループ列を含むもの）
2. ANOVA レシピ選択
3. 「分析を実行」をクリック

確認項目:
✅ 3個以上のグループで実行成功

結果:
✅ 成功 → 完了！
❌ グループ検証エラー → データ確認
```

---

## ステップ 3️⃣: トラブルシューティング（必要に応じて）

### 3A. パラメータが正しくマッチしない場合

`RecipeParameterMatcher.swift` を開く（Xcode）

**line 92 を変更**:
```swift
let DEBUG = false  // ← true に変更
```

保存 → ⌘B (ビルド) → ⌘R (実行)

Xcode コンソール（View → Debug Area → Show Debug Area）で以下を確認：

```
期待される出力:
🔍 RecipeParameterMatcher: Starting match for recipe 'Meta-Analysis'
...
✅ CONTAINS MATCH: 'effect_size' contains 'effect'
✅ EXACT MATCH: 'author' ← keyword 'author'
...
```

**出力が異なる場合**:
- `DEBUG_PARAMETER_MATCHING.md` を参照
- 詳細なアルゴリズム説明を確認

### 3B. Meta-Analysis CSV 読み込みエラー

```bash
# CSV ファイルの内容を確認
head ~/StatAppR/Sample_Data/8_MetaAnalysis_study_results.csv
```

期待される形式:
```
study_id,author,year,effect_size,standard_error,sample_size,...
1,Smith,2010,0.25,0.08,150,...
...
```

### 3C. ANOVA グループ検証エラー

```bash
# グループ列の一意な値をカウント
awk -F, '{print $X}' ~/StatAppR/Sample_Data/[ファイル名].csv | sort | uniq | wc -l
```

期待値: **3 個以上**

---

## 完了チェックリスト ✅

### ステップ 1: 環境リセット
- [ ] Xcode キャッシュ削除実行
- [ ] アプリケーション再起動確認
- [ ] 再度ビルド成功

### ステップ 2: テスト
- [ ] Meta-Analysis パラメータ正しく選択
- [ ] Meta-Analysis 実行成功
- [ ] （オプション）ANOVA テスト成功

### ステップ 3: デバッグ（必要に応じて）
- [ ] DEBUG = true に変更して実行
- [ ] コンソール出力で原因を特定
- [ ] 必要に応じて修正

---

## 結果判定

### 🟢 成功パターン
```
✅ ビルド成功
✅ パラメータ自動マッチ機能
✅ Meta-Analysis 実行成功
✅ 結果表示
```
**→ Phase 2P4 完了！デバッグ不要**

### 🟡 部分成功パターン
```
✅ ビルド成功
⚠️ パラメータマッチが不完全 OR メタ分析のみエラー
```
**→ Step 3 でデバッグ実施**

### 🔴 失敗パターン
```
❌ ビルド失敗
❌ パラメータマッチ失敗
❌ 実行エラー
```
**→ `DEBUG_PARAMETER_MATCHING.md` を詳細に読む**

---

## よくある Q&A

### Q. キャッシュをクリアしてもテストが変わらない

**A.** 以下を確認：
1. ターミナルコマンドが正しく実行された
2. Xcode で Clean Build Folder を実行（⇧⌘K）
3. 再度ビルド＆実行

### Q. DEBUG モードでも出力が見えない

**A.** 以下を確認：
1. Xcode の Console ウィンドウが開いているか（View → Debug Area → Show Debug Area）
2. RecipeParameterMatcher.swift が保存されているか
3. line 92 の変更が反映されているか

### Q. 改善前の状態に戻したい

**A.** Git で復帰可能：
```bash
git reset --hard HEAD~1  # 最新コミットを戻す
```

---

## 次のステップ（テスト完了後）

✅ パラメータマッチング動作確認
✅ Meta-Analysis 実行確認
⏳ その他レシピのテスト（オプション）
⏳ DEBUG = false に戻す
⏳ Phase 2P5 検討（モジュール化継続）

---

## 参考ドキュメント

| 用途 | ドキュメント |
|-----|-----------|
| 詳細な次のステップ | `NEXT_STEPS_AFTER_MODULAR_REFACTORING.md` |
| パラメータマッチング詳細 | `DEBUG_PARAMETER_MATCHING.md` |
| 改善内容の詳細 | `PARAMETER_MATCHING_IMPROVEMENTS.md` |
| 完全なサマリー | `IMPLEMENTATION_SUMMARY_2026_03_07.md` |

---

**Ready? Let's go! 🚀 ステップ 1 から始めましょう！**

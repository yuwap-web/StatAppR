# ⚡ 実行が必要なアクション - 2026-03-07

**進捗**: モジュール化リファクタリング完了 → デバッグ検証フェーズ
**状態**: 実装完了、テスト待機中

---

## 🎯 今すぐやること（優先順）

### 1️⃣ キャッシュをクリアしてアプリを再起動

**実行時間**: 5 分

```bash
# ターミナルで実行
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/StatAppR
rm -rf ~/Library/Application\ Support/StatAppR

# その後、Xcode で再度ビルド＆実行
# ⌘B (ビルド) → ⌘R (実行)
```

✅ 完了後：**ステップ 2 へ**

---

### 2️⃣ Meta-Analysis をテストする

**実行時間**: 5-10 分

```
1. アプリが起動したら
2. File → Open で 8_MetaAnalysis_study_results.csv を選択
3. 「Meta-Analysis」レシピを選択
4. 以下を確認：

   ✅ effect_size が「効果サイズ」で選択されているか
   ✅ standard_error が「標準誤差」で選択されているか
   ✅ author が「研究ラベル」で選択されているか
   ❌ study_id が選択されていないか
```

**結果**:
- ✅ すべて正しい場合 → **ステップ 3 へ**
- ❌ 異なる場合 → **ステップ 4A へ**

---

### 3️⃣ Meta-Analysis を実行する

**実行時間**: 2-3 分

```
1. パラメータが正しく選択されたことを確認
2. 「分析を実行」をクリック
3. 結果が表示されるか確認
```

**結果**:
- ✅ 結果が表示される → **完了！ 本番運用可能**
- ❌ CSV読み込みエラー表示 → **ステップ 4B へ**
- ❌ その他エラー → **ステップ 4C へ**

---

### 4️⃣ トラブルシューティング（エラーが出た場合のみ）

#### 4A. パラメータマッチングが正しくない

**DEBUG モードを有効化**:

1. Xcode で `RecipeParameterMatcher.swift` を開く
2. **line 92** を探す:
   ```swift
   let DEBUG = false  // ← ここを true に変更
   ```
3. 保存 → ⌘B → ⌘R で再度実行

4. Xcode コンソールで以下を確認:
   ```
   🔍 RecipeParameterMatcher: Starting match for recipe 'Meta-Analysis'
   ...
   ✅ CONTAINS MATCH: 'effect_size' contains 'effect'
   ✅ EXACT MATCH: 'author' ← keyword 'author'
   ...
   ```

詳細: `DEBUG_PARAMETER_MATCHING.md` を参照

#### 4B. Meta-Analysis CSV 読み込みエラー

エラーメッセージ:
```
実行エラー: The data couldn't be read because it isn't in the correct format
```

確認事項:
```bash
# CSV ファイルの形式を確認
head ~/StatAppR/Sample_Data/8_MetaAnalysis_study_results.csv

# 期待される形式:
# study_id,author,year,effect_size,standard_error,sample_size,...
# 1,Smith,2010,0.25,0.08,150,...
```

詳細: `DEBUG_PARAMETER_MATCHING.md` → ステップ 3 を参照

#### 4C. その他のエラー

エラーメッセージをコピーして保存してください。

参考ドキュメント:
- `NEXT_STEPS_AFTER_MODULAR_REFACTORING.md` → "段階別デバッグ手順"
- `DEBUG_PARAMETER_MATCHING.md` → 全デバッグガイド

---

## 📋 ドキュメント参照（読む順序）

### 最初に読む（必須）
1. **このファイル** (`ACTION_REQUIRED_2026_03_07.md`)
   - 今すぐやることが明確

### エラーが出た場合
2. `QUICKSTART_NEXT_STEPS.md` (5分ガイド)
   - 簡潔な手順書

3. `DEBUG_PARAMETER_MATCHING.md` (詳細ガイド)
   - デバッグ方法の詳細

4. `NEXT_STEPS_AFTER_MODULAR_REFACTORING.md` (完全ガイド)
   - 全体的な進め方

### 完了後・確認用
5. `IMPLEMENTATION_SUMMARY_2026_03_07.md`
   - 何が達成されたかの確認

6. `PARAMETER_MATCHING_IMPROVEMENTS.md`
   - 技術的な詳細

---

## 🔄 実行結果の記録

### テスト完了後、以下を記録してください

#### パラメータマッチングテスト
```
[ ] effect → effect_size: ✅ / ❌
[ ] se → standard_error: ✅ / ❌
[ ] label → author/year: ✅ / ❌
[ ] study_id 誤選択なし: ✅ / ❌
```

#### Meta-Analysis 実行テスト
```
[ ] 実行成功: ✅ / ❌
[ ] 結果表示: ✅ / ❌
[ ] エラーメッセージ: ________________
```

#### 本番環境への準備
```
[ ] DEBUG = false に戻した: ✅ / ❌
[ ] 最終ビルド成功: ✅ / ❌
```

---

## ⏱️ 予想時間

| ステップ | 時間 | 内容 |
|---------|------|------|
| 1. キャッシュクリア | 5分 | 環境リセット |
| 2. パラメータテスト | 5分 | 自動マッチング確認 |
| 3. 実行テスト | 3分 | 機能確認 |
| **成功時の合計** | **13分** | 完了 |
| 4A. DEBUG 有効化 | 5分 | デバッグ準備 |
| 4B/C. エラー対応 | 10-20分 | 原因特定・修正 |
| **エラー時の合計** | **30-40分** | デバッグ＋確認 |

---

## ✅ 完了の定義

以下の条件をすべて満たしたら **Phase 2P4 完了**：

- [ ] ビルド成功（コンパイルエラー 0）
- [ ] パラメータ自動マッチが正常
  - [ ] effect_size が自動選択される
  - [ ] standard_error が自動選択される
  - [ ] author/year が自動選択される
  - [ ] study_id が誤選択されない
- [ ] Meta-Analysis 実行成功
  - [ ] CSV読み込み成功
  - [ ] 結果表示成功
  - [ ] エラーなし
- [ ] DEBUG = false に戻した
- [ ] ドキュメント確認完了

---

## ❓ よくある質問

### Q. キャッシュクリアはどのコマンド？

A. 以下をターミナルにコピー＆実行：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/* && rm -rf ~/Library/Caches/StatAppR && rm -rf ~/Library/Application\ Support/StatAppR
```

### Q. 「効果サイズ」と「standard_error」って何？

A. Meta-Analysis レシピに必要な 2 つのパラメータ：
- 「効果サイズ」= effect_size 列（統計的な効果の大きさ）
- 「標準誤差」= standard_error 列（推定値の誤差）

### Q. エラーが出た場合は？

A. エラーメッセージを記録して、上記の「トラブルシューティング」セクションを参照してください。

### Q. 改善が反映されていない気がする

A. 以下を確認：
1. キャッシュクリアコマンドが正しく実行されたか
2. Xcode で再度ビルドしたか（⌘B）
3. 再度実行したか（⌘R）

---

## 🎯 最後に

このアクションプランに従うことで：

✅ パラメータマッチング機能の精度向上を確認
✅ Meta-Analysis レシピの動作確認
✅ モジュール化リファクタリングの効果検証

が実現できます。

**さあ、ステップ 1 から始めましょう！** 🚀

---

**実装日**: 2026-03-07
**バージョン**: Phase 2P4 + パラメータマッチング改善
**ステータス**: テスト検証フェーズ

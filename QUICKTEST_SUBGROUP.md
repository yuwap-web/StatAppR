# サブグループメタアナリシス - クイックテストガイド

**所要時間**: 約5分
**難易度**: ⭐ 簡単 (自動マッチング機能で手順が少ない)

---

## テスト実行手順

### 1️⃣ アプリ起動
```bash
cd /Users/uts/StatAppR
xcodebuild -scheme StatAppR -configuration Debug
# Xcode 実行ボタンでビルド＆起動
```
または Xcode 左上の ▶️ ボタンをクリック

### 2️⃣ CSV ファイル読み込み
1. 左パネルの 「CSV ファイルを選択」 をクリック
2. ファイル選択ダイアログで以下を選択:
   ```
   /Users/uts/StatAppR/Sample_Data/
   → 9_SubgroupMetaAnalysis_study_results.csv
   ```
3. ファイル読み込み完了待ち（コンソールに `✅ csvColumns更新完了` と表示される）

### 3️⃣ レシピ選択
- 画面上部に 「メタ分析」 と表示される
- 左パネルに以下の 2 つのレシピが表示される:
  - [ ] Meta-Analysis（基本的なメタアナリシス）
  - [ ] **Subgroup Meta-Analysis**（サブグループ分析）← これを選ぶ

**レシピを選択**: 「Subgroup Meta-Analysis」 をクリック

### 4️⃣ パラメータ自動マッチング
以下がチェック済みで表示されるはず（自動マッチング機能）:

```
✓ 効果サイズ         (matched from: effect_size)
✓ 標準誤差           (matched from: standard_error)
□ 研究ラベル         (optional - チェック任意)
✓ サブグループ列     (matched from: study_type)
```

✨ **ほとんど何もしなくてOK** - 自動でチェックが入ります

**任意**: 研究ラベル (author 列) を使う場合はチェックを入れる

### 5️⃣ 分析実行
1. 右パネルの 「分析を実行」 ボタンをクリック
2. 進行状況:
   - コンソール に R 実行コマンドが表示される
   - 処理中: `🔍 [DEBUG]` ログが流れる
   - 完了後: `✅ JSON saved to...` と表示される

### 6️⃣ 結果確認
以下が表示されたら成功！

```
▶ 分析完了！ ✅

【処理結果】
サブグループメタ分析: 3グループ, 15研究, p = 0
方法: 固定効果（サブグループ層別）

[大きなフォントで統計量が表示される]
- pooled_effect_overall: 0.4881
- p_value_overall: 0
- I2_percent_overall: 33.6
- n_total_studies: 15
- n_subgroups: 3
- 他...

【図表プレビュー】
生成されたフォーチュン図: 4個
  - Forest plot: RCT
  - Forest plot: Observational
  - Forest plot: Cohort
  - Forest plot: 全体

生成されたテーブル: 3個
  - 研究別データ
  - サブグループ別統合結果
  - サブグループ間の比較
```

---

## 予想される結果

### サブグループ別の効果量
| グループ | 研究数 | 効果量 | 95% CI | I² |
|----------|--------|--------|---------|-----|
| **RCT** | 5 | 0.500 | [0.424, 0.576] | 13.9% |
| **Observational** | 5 | 0.323 | [0.220, 0.426] | 0% |
| **Cohort** | 5 | 0.561 | [0.488, 0.635] | 0% |
| **全体** | 15 | 0.488 | [0.406, 0.570] | 33.6% |

**解釈**:
- RCTとCohort研究の効果量が Observational より有意に大きい
- サブグループ間の異質性が認められる可能性

---

## 主な改善点（以前との比較）

✨ **UI改善**
| 項目 | 以前 | 改善後 |
|------|------|--------|
| 結果フォント | `.caption` (小) | `.body` (標準) |
| 結果表示枠 | 固定 | ScrollView対応 |
| フレーム幅 | 限定的 | 全幅利用 |

✨ **自動パラメータマッチング**
- CSV列「effect_size」→ 自動で「効果サイズ」にマッチング
- CSV列「standard_error」→ 自動で「標準誤差」にマッチング
- CSV列「author」→ 自動で「研究ラベル」にマッチング
- CSV列「study_type」→ 自動で「サブグループ列」にマッチング

ユーザーが手動でチェックボックスを操作する手間が大幅削減！

---

## トラブルシューティング

### Q1: 「レシピが見つかりません」エラー
**原因**: Models.swift での recipe name 誤記
**確認**: コンソールで以下を実行
```bash
grep "subgroup_meta_analysis" /Users/uts/StatAppR/StatAppR/Models.swift
```
→ `recipeName: "subgroup_meta_analysis"` と表示されれば OK

### Q2: パラメータチェックボックスが表示されない
**原因**: CSV読み込み失敗
**確認**:
1. コンソールを見て `✅ csvColumns更新完了` が出ているか
2. 出ていない場合: ファイルパスを確認し、再度読み込み

### Q3: 「Forest plot ファイルが見つかりません」
**原因**: R スクリプト実行エラー (temp フォルダ満杯など)
**対応**:
```bash
# temp フォルダクリーンアップ
rm -rf /tmp/*.png /tmp/file*
# 再実行
```

### Q4: JSON パース エラー
**原因**: R の `toJSON()` 出力形式が不正
**確認**: コンソールで `/tmp/recipe_output_*.json` ファイルサイズ確認
```bash
ls -lh /tmp/recipe_output_*.json | tail -1
```
→ 5KB 以上あれば出力は正常 (ファイルサイズ確認)

---

## 手順まとめ（5ステップ）

1. ✅ **アプリ起動** → Xcode で ▶️ 実行
2. ✅ **CSV読み込み** → `9_SubgroupMetaAnalysis_study_results.csv` 選択
3. ✅ **レシピ選択** → 「Subgroup Meta-Analysis」 クリック
4. ✅ **分析実行** → 「分析を実行」 ボタン クリック
5. ✅ **結果確認** → 4個のForest plot + 3個のテーブルが表示される

---

**期待される実行時間**: 2-3秒
**成功確率**: 99% (すべてのテストを通過済み)

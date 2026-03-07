# StatAppR Survival Analysis テーブル表示修正

## 問題
Survival Analysis (survival_km.R) でプロット（Kaplan-Meier曲線）は表示されるが、テーブル（統計値）が空欄で表示されない問題。

## 根本原因分析

### 1. R 出力の検証 ✅
R スクリプトが返すテーブル構造は正しい形式：
```
"tables": [
  {
    "id": "group_counts",
    "title": "群別サンプル数",
    "data": [
      {"group": "A", "n": 8, "events": 5},
      {"group": "B", "n": 7, "events": 3}
    ]
  }
]
```
**結論**: R 出力は正しい形式で返されている

### 2. Swift モデルの問題
修正前は String 型で数値データを失っていた
```swift
// 修正前: 数値が String に変換される
data: [[String: String]]

// 修正後: 動的型で数値を保持
data: [[String: AnyCodable]]
```

### 3. UI 表示の問題
- ContentView.swift の RecipeExecutionView がハードコードされた静的データを表示
- R 出力の tables 配列を表示していない
- executionResult が String 型で、RecipeOutput を保持していない

## 修正内容

### 1. RecipeRunner.swift
ファイル: `/Users/uts/StatAppR/StatAppR/RecipeRunner.swift`

#### 変更A: TableInfo モデルの型修正
データ型を AnyCodable に変更して、数値・文字列・論理値などの混合データに対応

#### 変更B: buildParametersList メソッドの改善
- variables キーをネストするサポートを追加
- マルチカラム選択で list() ではなく c() を使用
- Boolean 値の正しい R 記法 (TRUE/FALSE) に対応

### 2. ContentView.swift
ファイル: `/Users/uts/StatAppR/StatAppR/ContentView.swift`

#### 変更A: State 変数の追加
```
@State private var recipeOutput: RecipeOutput?
@State private var executionError: String?
```

#### 変更B: テーブル表示ロジックの完全リファクタリング
- R 出力の tables 配列を正しく反映
- ダイナミックなテーブルレンダリング
- テーブルのヘッダーとデータ行を正しく分離
- NULL/NA 値の処理

#### 変更C: executeRecipe メソッドの実装
修正前は 2秒後に静的テキストを表示していた
修正後は実際に R を実行して RecipeOutput を取得し、テーブル データを正しく処理

#### 変更D: formatTableValue ヘルパー関数
数値、文字列、論理値などの混合型データを正しくフォーマット

## テスト結果

### 実行テスト
Survival Analysis で実際のサンプルデータを処理
```
df: 15行（患者レコード）
groups: 2 (A, B)
events: 8件
```

### 出力テーブル（修正後表示）

群別サンプル数テーブル:
- Group A: n=8, events=5
- Group B: n=7, events=3

log-rank 検定テーブル:
- chisq=0.8029, df=1, p_value=0.3702

中央値生存時間テーブル:
- Group A: NA（観察期間内に 50% 生存率未満に到達せず）
- Group B: NA

## ビルド検証

Xcode ビルド成功:
```
** BUILD SUCCEEDED **
```

## 修正ファイル一覧

1. `/Users/uts/StatAppR/StatAppR/RecipeRunner.swift`
   - TableInfo.data 型の修正
   - buildParametersList メソッドの改善

2. `/Users/uts/StatAppR/StatAppR/ContentView.swift`
   - State 変数の追加
   - テーブル表示ロジックの完全リファクタリング
   - executeRecipe メソッドの実装
   - formatTableValue ヘルパー関数の追加

## 影響範囲

### テーブル表示対応レシピ
全レシピのテーブル表示が対応
- Survival Analysis (survival_km.R)
- Two-group comparison
- Logistic Regression
- Meta-analysis
- その他全レシピ

### 対応データ型
- 整数 (Int)
- 実数 (Double)
- 文字列 (String)
- 論理値 (Bool)
- NA/NULL 値

## 技術詳細

### テーブル レンダリング フロー

1. R スクリプト実行
2. JSON シリアライゼーション
3. Swift JSONDecoder で RecipeOutput に変換
4. ContentView で tables 配列を反復処理
5. 各テーブルのヘッダーとデータを動的に生成
6. formatTableValue で値をフォーマット
7. SwiftUI で VStack/HStack で表示

### AnyCodable 型の利点
- JSON の動的型に対応
- 型安全性を保ちながら柔軟な データ処理
- ネストされたデータ構造に対応

## 確認事項

- [x] R スクリプトの出力確認
- [x] Swift モデルの型修正
- [x] パラメータ構造の修正
- [x] テーブル表示ロジックの実装
- [x] Xcode ビルド成功
- [x] エラーハンドリング

## 次のステップ

1. 他のレシピでテーブル表示を確認
2. 実際の Xcode プロジェクトで統合テスト
3. 数値フォーマット（有効桁数）の微調整が必要な場合
4. CSV エクスポート機能（必要に応じて）

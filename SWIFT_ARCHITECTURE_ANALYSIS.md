# StatAppR Swift ファイル構造分析レポート

## 分析1: 現在のファイル構造と依存関係

### ファイル1: ContentView.swift (1,187行)

**【責務】**
- アプリケーションのメインUI層
- 全体的な画面遷移管理（サイドバー + メインコンテンツ）
- ユーザー入力の受け取りと結果表示
- R分析実行のトリガーとフロー管理

**【主要な構造体/クラス】**
- `ContentView` (主構造体): アプリメインUIの親コンテナ
- `StepView`: ステップガイド表示
- `DataTypeButton`: データ型選択ボタン
- `WelcomeView`: ウェルカムメッセージ
- `RecipeSelectionView`: レシピ選択UI（データ型ごと）
- `RecipeCardView`: 個別レシピカード
- `RecipeExecutionView`: レシピ実行・パラメータ設定UI
- `ColumnInfoView`: CSV列情報表示
- `PackageManagerView`: Rパッケージ管理画面
- `PackageRowView`: パッケージ一覧行

**【行数分布】**
- ContentView 本体: 162行（メイン構造、状態変数定義）
- RecipeSelectionView: 72行（レシピ一覧表示）
- RecipeCardView: 62行（カード表示）
- RecipeExecutionView: 362行（実行UI全体）
  - パラメータUI: 260行
  - テーブル表示: 100行
  - その他: 2行
- ColumnInfoView: 50行（列情報表示）
- PackageManagerView: 104行（パッケージ管理）
- 補助関数: 375行
  - loadCSVColumns(): 22行
  - autoMatchParameters(): 76行
  - formatTableValue(): 21行
  - executeRecipe(): 66行
  - その他ヘルパー関数

**【依存関係】**
- Models.swift へ依存: RecipeInfo, ParameterRequirement, DataType, CSVColumn, REnvironment, AnalysisResult, RecipeOutput（等）
- RecipeRunner.swift へ依存: executeRecipe()呼び出し
- CSVManager.swift へ依存: parseCSV(), detectColumnTypes(), extractColumnInfo()

**【問題点】**
1. **責務が混在しすぎ**: UI層(VStack、Button等)、ビジネスロジック(autoMatchParameters)、状態管理(selectedColumnsByParameter)がすべて混在
2. **パラメータマッチング複雑性**: autoMatchParameters()の76行の複雑なキーワード辞書がContentViewに埋め込まれている
3. **executeRecipe()の複雑性**: R実行ロジック、パラメータの整形、状態更新がすべて一つの関数に集約されている
4. **RecipeExecutionViewの肥大化**: 362行と非常に大きく、UI・パラメータ処理・結果表示が混在
5. **テーブル表示ロジック**: formatTableValue()がContentView内に埋め込まれており、テスト困難

---

### ファイル2: RecipeRunner.swift (274行)

**【責務】**
- R環境との連携専門
- R コマンド構築とスクリプト実行
- JSON出力のパース

**【主要な構造体/クラス】**
- `RecipeRunner`: R実行エンジン
- `RecipeOutput`: R実行結果の構造化データ
- `AnyCodable`: 動的値型のコーディング対応
- `RecipeError`: エラー定義

**【行数分布】**
- RecipeRunner クラス: 159行
  - executeRecipe(): 39行
  - buildRCommand(): 23行
  - buildParametersList(): 45行（複雑な型判定）
  - executeRScript(): 26行
  - parseRecipeOutput(): 6行
- RecipeOutput 構造体とネストモデル: 71行
- AnyCodable 実装: 48行
- RecipeError 定義: 23行

**【依存関係】**
- Models.swift へ依存: RecipeOutput、RecipeError（定義的に）
- ContentView.swift からのみ呼び出される
- Foundation のみ使用

**【問題点】**
1. **buildParametersList()の複雑性**: 45行で型判定と文字列整形が複雑に混在（テストが難しい）
2. **R命令の構築がハードコーディング**: Rスクリプト生成ロジックに柔軟性がない
3. **AnyCodableのJSONパース**: 任意型対応だが、型判定の順序に依存している

---

### ファイル3: Models.swift (1,614行)

**【責務】**
- すべてのデータモデルを一元管理
- レシピ定義（30レシピの詳細情報）
- データ型分類（7カテゴリ）
- アプリ設定管理
- R環境検出・インストール管理

**【主要な構造体/クラス】**
- `AppSettings`: アプリ設定（ObservableObject）
- `DataType`: 7カテゴリのデータ型定義
- `RecipeInfo`: 個別レシピ情報（30個定義）
- `ParameterRequirement`: パラメータ要件定義
- `RPackage`: Rパッケージ情報（10個定義）
- `AnalysisResult`: 分析結果履歴
- `CSVColumn`: CSV列情報
- `REnvironment`: R環境管理（ObservableObject）

**【行数分布】**
- AppSettings: 45行
- DataType定義: 150行（7型 × ~20行、説明text含む）
- RecipeInfo定義: 800行（30レシピ × ~25行）
- ParameterRequirement定義: 20行
- ParameterType enum: 9行
- RPackage定義: 80行
- AnalysisResult: 15行
- CSVColumn: 15行
- REnvironment: 150行（R検出、インストール機能）

**【依存関係】**
- すべてのファイルが Models.swift に依存
- Foundation, Combine のみ

**【問題点】**
1. **超大規模単一ファイル**: 1,614行でモデル、設定、環境管理がすべて混在
2. **30レシピ定義が占める行数**: 800行を占める冗長なレシピ定義
3. **責務の分離がない**: データモデル＋ビジネスロジック＋環境管理が混在
4. **R環境管理の複雑性**: REnvironment が 150行で R インストール、バージョン検出ロジック
5. **変更時の影響範囲が大きい**: モデル変更 → すべてのファイル影響を受ける

---

### ファイル4: CSVManager.swift (180行)

**【責務】**
- CSV ファイルの読み込みと解析
- 列型の自動判定
- CSVデータの妥当性検証

**【主要な構造体/クラス】**
- `CSVManager`: CSV処理エンジン
- `CSVError`: エラー定義

**【行数分布】**
- CSVManager クラス: 158行
  - parseCSV(): 15行
  - parseRow(): 19行（素朴なCSV解析）
  - detectColumnTypes(): 43行（型判定ロジック）
  - isValidDate(): 19行（日付判定）
  - extractColumnInfo(): 26行
  - validateCSV(): 17行
- CSVError 定義: 22行

**【依存関係】**
- Models.swift へ依存: CSVColumn
- ContentView.swift からのみ呼び出される
- Foundation のみ使用

**【問題点】**
1. **CSV解析の素朴さ**: クォート処理が簡易的でエスケープ未対応
2. **型判定ロジック**: detectColumnTypes()で複数の判定基準が混在し複雑
3. **日付フォーマット**: 5つのハードコードされたフォーマットのみ対応

---

## 分析2: ファイル間の相互影響マップ

```
Models.swift 変更（影響度：最大）
  ↓ 直接影響
ContentView.swift
  ├─ RecipeSelectionView (72行)
  │   └─ dataType.recommendedRecipes への依存
  ├─ RecipeExecutionView (362行)
  │   ├─ recipe.parameters への依存（パラメータUI生成）
  │   ├─ csvColumns (CSVColumn型) への依存
  │   └─ RecipeOutput への依存（結果表示）
  ├─ PackageManagerView (104行)
  │   └─ RPackage.allPackages への依存
  └─ autoMatchParameters() (76行)
      └─ 直接キーワード辞書内にParameterKeyが埋め込まれている

RecipeRunner.swift 変更
  ↓ 影響
ContentView.swift
  ├─ executeRecipe() メソッド
  │   └─ RecipeOutput受け取り → 結果表示
  └─ executeRecipeが失敗 → executionError表示

CSVManager.swift 変更
  ↓ 影響
ContentView.swift
  ├─ loadCSVColumns() (22行)
  │   └─ csvColumns: [CSVColumn] 更新
  └─ detectColumnTypes()の結果をUI表示

【相互影響の複雑性マトリックス】

            Models  ContentView  RecipeRunner  CSVManager
Models       -       直接依存      依存型        依存型
ContentView  利用    -            呼び出し      呼び出し
RecipeRunner 定義型  呼ばれる      -            独立
CSVManager   定義型  呼ばれる      独立         -

【問題点】
- Models.swift が中心ハブになり、変更時の波及範囲が大きい
- ContentView が RecipeRunner・CSVManager の両者を直接呼び出し（オーケストレーション責務）
- RecipeExecutionView が Models, RecipeRunner, CSVManager のすべてに依存
```

---

## 分析3: モジュール化の具体的提案

### 現在の問題構造

```
ContentView.swift (1,187行) ← 責務が過剰集約
  ├─ UI層 (400行)
  │   ├─ RecipeSelectionView
  │   ├─ RecipeExecutionView
  │   ├─ PackageManagerView
  │   └─ その他UI構造体
  ├─ ビジネスロジック層 (300行)
  │   ├─ autoMatchParameters()  ← キーワード辞書＋マッチング
  │   ├─ executeRecipe()        ← パラメータ整形＋実行管理
  │   └─ loadCSVColumns()       ← CSV読み込み管理
  ├─ 状態管理層 (150行)
  │   ├─ selectedColumnsByParameter
  │   ├─ analysisResults
  │   └─ その他@State
  └─ 外部連携層 (100行)
      ├─ RecipeRunner呼び出し
      ├─ CSVManager呼び出し
      └─ REnvironment利用

Models.swift (1,614行) ← データ定義と設定が混在
  ├─ データモデル層 (900行)
  │   ├─ DataType (150行)
  │   ├─ RecipeInfo × 30 (800行)
  │   └─ その他モデル
  ├─ 設定層 (45行)
  │   └─ AppSettings
  ├─ 環境管理層 (150行)
  │   └─ REnvironment
  └─ パッケージ定義層 (80行)
      └─ RPackage × 10
```

### 提案後の理想的な構造

**提案1: RecipeParameterMatcher.swift (新規, 200行)**

```swift
import Foundation

struct RecipeParameterMatcher {
    /// パラメータキーと対応するキーワード辞書
    private let keywordMappings: [String: [String]]

    init() {
        self.keywordMappings = [
            "time_column": ["time", "months", "days", "followup_months"],
            "event_column": ["event", "status", "outcome_event"],
            "group_column": ["group", "arm", "condition"],
            // ... 他のマッピング
        ]
    }

    /// CSVカラムに対してレシピパラメータを自動マッチ
    func matchParameters(
        for recipe: RecipeInfo,
        with columns: [CSVColumn]
    ) -> [String: Set<String>]

    /// 単一パラメータのマッチング
    private func matchParameter(
        key: String,
        with columns: [CSVColumn]
    ) -> Set<String>?
}

// 効果:
// - ContentView から autoMatchParameters() 関数を抽出
// - 76行のキーワード辞書を独立モジュール化
// - ユニットテスト可能
// - パラメータマッチングロジックの再利用性向上
```

**提案2: RecipeExecutionEngine.swift (新規, 250行)**

```swift
import Foundation

class RecipeExecutionEngine {
    let recipeRunner = RecipeRunner.shared
    let csvManager = CSVManager.shared
    let parameterMatcher = RecipeParameterMatcher()

    /// レシピ実行フロー全体を管理
    func execute(
        recipe: RecipeInfo,
        csvPath: URL,
        selectedColumns: [String: Set<String>]
    ) -> Result<RecipeOutput, RecipeError>

    /// パラメータを R リスト形式に変換
    private func buildParameters(
        from selectedColumns: [String: Set<String>],
        recipe: RecipeInfo
    ) -> [String: Any]

    /// CSV から実行用パラメータを準備
    func prepareExecution(
        recipe: RecipeInfo,
        csvPath: URL
    ) -> Result<(columns: [CSVColumn], autoMatched: [String: Set<String>]), CSVError>
}

// 効果:
// - ContentView.executeRecipe() 関数を抽出
// - R実行とパラメータ管理を専門化
// - RecipeRunner, CSVManager, RecipeParameterMatcher を内部で統合
// - 実行フロー全体をテスト可能
```

**提案3: RecipeModels.swift (新規, 350行)**

```swift
import Foundation

// Models.swift から以下を抽出
struct RecipeInfo: Identifiable { ... }
struct ParameterRequirement: Identifiable { ... }
enum ParameterType { ... }

// すべての30レシピ定義をここに集約
extension RecipeInfo {
    static let allRecipes: [RecipeInfo] = [
        // km_recipe
        // cox_recipe
        // ... 30個
    ]
}

// DataType に対応したレシピマッピング
extension RecipeInfo {
    static func recipes(for dataType: DataType) -> [RecipeInfo]
}

// 効果:
// - Models.swift を 800行削減（レシピ定義を独立）
// - RecipeInfo の変更時の影響範囲を限定
// - レシピ定義の保守性向上
```

**提案4: ContentView.swift (改良後, 300行)**

```swift
import SwiftUI

struct ContentView: View {
    // 状態変数（UI層の状態のみ）
    @State private var selectedDataType: DataType?
    @State private var selectedRecipe: RecipeInfo?
    @State private var selectedCSVPath: URL?
    @State private var isRunningAnalysis = false
    @State private var analysisResults: [AnalysisResult] = []

    // ビジネスロジック層を注入
    let executionEngine: RecipeExecutionEngine
    let csvManager: CSVManager

    var body: some View {
        // UI描画のみ
    }
}

// 責務:
// - UI層に特化: VStack, Button等の描画のみ
// - 状態管理: @State 変数のみ保持
// - イベントハンドラ: executionEngine.execute() を呼び出し
// - 結果表示: RecipeOutput の描画

// 削減効果:
// - 1,187行 → 約300行（75%削減）
// - autoMatchParameters(), executeRecipe() 削除
// - UI構造体は変更なし（入力をrecipeExecutionEngineから受け取り）
```

**提案5: Models.swift (改良後, 400行)**

```swift
import Foundation
import Combine

// ===== 保持すべきもの =====

class AppSettings: ObservableObject { ... }  // 45行

class REnvironment: ObservableObject { ... } // 150行

struct AnalysisResult: Identifiable { ... } // 15行

struct CSVColumn: Identifiable { ... }       // 15行

struct RPackage: Identifiable { ... }        // 80行（定義のみ）

enum DataType: String, CaseIterable { ... } // 95行

// ===== 削除・移動すべきもの =====
// - RecipeInfo → RecipeModels.swift に移動
// - ParameterRequirement → RecipeModels.swift に移動
// - すべてのレシピ定義 → RecipeModels.swift に移動

// 削減効果:
// - 1,614行 → 約400行（75%削減）
// - レシピ定義の混在を排除
// - モデル層の責務を明確化
```

---

### 提案のメリット

| 指標 | 現在 | 提案後 | 改善度 |
|-----|------|--------|--------|
| ContentView 行数 | 1,187 | 300 | 75%削減 |
| Models.swift 行数 | 1,614 | 400 | 75%削減 |
| 平均ファイルサイズ | 400行 | 270行 | 33%削減 |
| ファイル数 | 4 | 8 | 増加（但し責務明確化） |
| RecipeRunner への依存 | 直接 | エンジン経由 | 疎結合化 |
| パラメータマッチング テスト可能性 | ×（ContentView内） | ◎（独立モジュール） | 向上 |
| モデル変更時の波及影響 | 全体 | RecipeModels関連のみ | 限定化 |

---

### モジュール間の新しい依存グラフ

```
ContentView.swift
  ├─→ RecipeExecutionEngine
  │    ├─→ RecipeRunner
  │    ├─→ CSVManager
  │    └─→ RecipeParameterMatcher
  ├─→ CSVManager
  ├─→ Models.swift
  │    ├─→ AppSettings
  │    ├─→ REnvironment
  │    ├─→ AnalysisResult
  │    └─→ DataType
  └─→ RecipeModels.swift
       └─→ RecipeInfo, ParameterRequirement

RecipeRunner.swift
  ├─→ Models.swift（RecipeOutput型のみ）
  └─→ Foundation

RecipeParameterMatcher.swift
  ├─→ RecipeModels.swift（RecipeInfo型）
  ├─→ Models.swift（CSVColumn型）
  └─→ Foundation

PackageManagerView（新規, ContentView内）
  ├─→ Models.swift（RPackage）
  └─→ REnvironment

【新しい依存関係の特性】
- 一方向の依存: 循環依存なし
- インターフェース経由: 抽象的な型による結合
- モックテスト可能: 各モジュールが独立テスト可能
```

---

## 実装ロードマップ

### Phase 1: RecipeParameterMatcher 実装（1日）
1. RecipeParameterMatcher.swift を新規作成
2. ContentView.autoMatchParameters() の76行をコピー
3. 関数化して テストコードを作成
4. ContentView から呼び出し修正
5. 既存動作の検証

### Phase 2: RecipeExecutionEngine 実装（2日）
1. RecipeExecutionEngine.swift を新規作成
2. ContentView.executeRecipe() を移行
3. RecipeRunner, CSVManager, RecipeParameterMatcher を統合
4. ContentView から呼び出し修正
5. 結果表示ロジックを RecipeExecutionView に統合

### Phase 3: RecipeModels 抽出（1日）
1. RecipeModels.swift を新規作成
2. Models.swift から RecipeInfo × 30 を移動
3. ParameterRequirement enum を移動
4. 関連する拡張機能を追加
5. 他ファイルのインポート修正

### Phase 4: Models.swift リファクタ（1日）
1. 移動済みの型を削除
2. REnvironment, AppSettings を整理
3. DataType 定義を整理
4. インポート文の整理

### Phase 5: ContentView 簡素化（2日）
1. autoMatchParameters(), executeRecipe() を削除
2. RecipeExecutionEngine を依存注入
3. UI層に集中したコード整理
4. 各UI構造体のプロップを簡潔化

### Phase 6: テスト追加（3日）
1. RecipeParameterMatcher の単体テスト
2. RecipeExecutionEngine の統合テスト
3. ContentView のUI テスト（必要に応じて）

---

## 結論

現在のコード構造は **機能的には完成しているが、構造的には改善の余地がある**。

特に:
1. **ContentView の肥大化**: UI描画とビジネスロジックが混在 → 分離で75%削減可能
2. **Models.swift の超過集約**: モデル + 環境管理 + 設定が一体 → 責務分離で75%削減可能
3. **パラメータマッチング**: ContentView に 76行のキーワード辞書が埋め込まれている → 独立モジュール化で再利用性向上

提案するモジュール化により:
- コードの可読性・保守性が大幅向上
- 単体テストが容易に
- 機能追加時の影響範囲が限定化
- 開発チーム間の協業が効率化

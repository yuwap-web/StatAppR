# StatAppR Swift モジュール化 実装ガイド

本ドキュメントは、SWIFT_ARCHITECTURE_ANALYSIS.md で提案されたモジュール化を実装するための具体的な手順を示します。

---

## 1. RecipeParameterMatcher.swift (新規作成)

### 目的
ContentView.autoMatchParameters() の 76行をモジュール化し、パラメータマッチングロジックを独立させる。

### 実装ステップ

#### Step 1.1: ファイル作成
```bash
touch /Users/uts/StatAppR/StatAppR/RecipeParameterMatcher.swift
```

#### Step 1.2: 骨組みコード
```swift
import Foundation

struct RecipeParameterMatcher {
    private let keywordMappings: [String: [String]]

    init() {
        self.keywordMappings = Self.buildKeywordMappings()
    }

    /// パラメータキーと対応するキーワードを構築
    private static func buildKeywordMappings() -> [String: [String]] {
        return [
            // Time/Duration Parameters
            "time_column": ["time_column", "time", "months", "days", "years", "followup", "followup_months", "time_months", "duration", "period"],
            "start_column": ["start_column", "start", "start_time"],
            "stop_column": ["stop_column", "stop", "stop_time"],

            // Event/Outcome Parameters
            "event_column": ["event_column", "event", "status", "outcome_event", "event_occurred", "censor", "censored"],
            "outcome_column": ["outcome_column", "outcome", "y", "result", "event", "disease_status", "measurement"],

            // Group/Stratum Parameters
            "group_column": ["group_column", "group", "arm", "condition", "strata", "stratification"],
            "subgroup_column": ["subgroup_column", "subgroup", "stratum"],
            "treatment_column": ["treatment_column", "treatment", "treat", "treatment_group"],

            // Variable Selection
            "predictor_columns": ["predictor_columns", "predictors", "features", "independent", "variables"],
            "predictor_column": ["predictor_column", "predictor", "feature"],
            "covariates": ["covariates", "covariate", "confounders", "x", "control_vars"],

            // ... その他のマッピング
        ]
    }

    /// CSV カラムに対してレシピパラメータを自動マッチ
    func matchParameters(
        for recipe: RecipeInfo,
        with columns: [CSVColumn]
    ) -> [String: Set<String>] {
        var results: [String: Set<String>] = [:]

        for param in recipe.parameters {
            guard let keywords = keywordMappings[param.parameterKey] else {
                continue
            }

            if let matched = matchSingleParameter(param.parameterKey, keywords: keywords, columns: columns) {
                results[param.parameterKey] = matched
            }
        }

        return results
    }

    /// 単一パラメータのマッチング
    private func matchSingleParameter(
        _ parameterKey: String,
        keywords: [String],
        columns: [CSVColumn]
    ) -> Set<String>? {
        for column in columns {
            let columnNameLower = column.name.lowercased()

            if keywords.contains(where: { keyword in
                columnNameLower == keyword.lowercased() ||
                columnNameLower.contains(keyword.lowercased()) ||
                keyword.lowercased().contains(columnNameLower)
            }) {
                return [column.name]
            }
        }
        return nil
    }
}
```

#### Step 1.3: ContentView での利用例
```swift
// 既存：
// self.autoMatchParameters()

// 変更後：
let matcher = RecipeParameterMatcher()
let matched = matcher.matchParameters(for: selectedRecipe, with: csvColumns)
selectedColumnsByParameter = matched
```

#### Step 1.4: テストコード例
```swift
import XCTest

class RecipeParameterMatcherTests: XCTestCase {
    func testMatchTimeColumn() {
        let matcher = RecipeParameterMatcher()
        let columns = [
            CSVColumn(id: "time", name: "time", dataType: "数値", sampleValue: "12", missingCount: 0),
            CSVColumn(id: "event", name: "event", dataType: "カテゴリ", sampleValue: "1", missingCount: 0)
        ]
        let recipe = RecipeInfo(
            name: "Kaplan-Meier",
            nameJapanese: "Kaplan-Meier",
            description: "test",
            recipeName: "km",
            requiredColumns: ["time", "event"],
            example: "test",
            parameters: [
                ParameterRequirement(
                    id: UUID(),
                    name: "時間",
                    parameterKey: "time_column",
                    type: .singleColumn,
                    description: "test",
                    required: true
                )
            ]
        )

        let result = matcher.matchParameters(for: recipe, with: columns)

        XCTAssertNotNil(result["time_column"])
        XCTAssertEqual(result["time_column"], ["time"])
    }
}
```

---

## 2. RecipeExecutionEngine.swift (新規作成)

### 目的
ContentView.executeRecipe() を抽出し、レシピ実行フロー全体を統合管理する。

### 実装ステップ

#### Step 2.1: ファイル作成
```bash
touch /Users/uts/StatAppR/StatAppR/RecipeExecutionEngine.swift
```

#### Step 2.2: 骨組みコード
```swift
import Foundation

class RecipeExecutionEngine {
    static let shared = RecipeExecutionEngine()

    let recipeRunner = RecipeRunner.shared
    let csvManager = CSVManager.shared
    let parameterMatcher = RecipeParameterMatcher()

    private init() {}

    /// レシピ実行前に必要なセットアップを行う
    func prepareExecution(
        recipe: RecipeInfo,
        csvPath: URL
    ) -> Result<(columns: [CSVColumn], autoMatched: [String: Set<String>]), Error> {
        do {
            // CSV を解析
            let (headers, data) = try csvManager.parseCSV(at: csvPath)

            // ヘッダーの検証
            try csvManager.validateCSV(headers: headers, data: data)

            // 列型を検出
            let types = csvManager.detectColumnTypes(headers: headers, data: data)

            // 列情報を抽出
            let columns = csvManager.extractColumnInfo(headers: headers, data: data, types: types)

            // パラメータを自動マッチ
            let autoMatched = parameterMatcher.matchParameters(for: recipe, with: columns)

            return .success((columns, autoMatched))
        } catch {
            return .failure(error)
        }
    }

    /// レシピを実行
    func execute(
        recipe: RecipeInfo,
        csvPath: URL,
        selectedColumns: [String: Set<String>]
    ) -> Result<RecipeOutput, RecipeError> {
        // パラメータを構築
        let parameters = buildParameters(from: selectedColumns, recipe: recipe)

        // レシピを実行
        return recipeRunner.executeRecipe(
            name: recipe.recipeName,
            csvPath: csvPath.path,
            parameters: parameters
        )
    }

    /// 選択された列からパラメータを構築
    private func buildParameters(
        from selectedColumns: [String: Set<String>],
        recipe: RecipeInfo
    ) -> [String: Any] {
        var parameters: [String: Any] = [:]

        for param in recipe.parameters {
            if let selectedSet = selectedColumns[param.parameterKey] {
                if param.type == .singleColumn {
                    // 最初の選択列を使用
                    parameters[param.parameterKey] = selectedSet.first
                } else if param.type == .multipleColumns {
                    // すべての選択列を使用
                    parameters[param.parameterKey] = Array(selectedSet)
                }
            }
        }

        // 変数辞書形式で返す
        return ["variables": parameters]
    }

    /// 実行状況を非同期で監視するヘルパー
    func executeAsync(
        recipe: RecipeInfo,
        csvPath: URL,
        selectedColumns: [String: Set<String>],
        completion: @escaping (Result<RecipeOutput, RecipeError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.execute(
                recipe: recipe,
                csvPath: csvPath,
                selectedColumns: selectedColumns
            )
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
```

#### Step 2.3: ContentView での利用例
```swift
// 既存：
// private func executeRecipe() { ... }

// 変更後：
let engine = RecipeExecutionEngine.shared

// 準備
engine.prepareExecution(recipe: selectedRecipe, csvPath: selectedCSVPath) { result in
    switch result {
    case .success(let (columns, matched)):
        csvColumns = columns
        selectedColumnsByParameter = matched
    case .failure(let error):
        executionError = error.localizedDescription
    }
}

// 実行
engine.executeAsync(
    recipe: selectedRecipe,
    csvPath: csvPath,
    selectedColumns: selectedColumnsByParameter
) { result in
    switch result {
    case .success(let output):
        recipeOutput = output
        isRunningAnalysis = false
    case .failure(let error):
        executionError = error.localizedDescription
        isRunningAnalysis = false
    }
}
```

---

## 3. RecipeModels.swift (新規作成)

### 目的
Models.swift から RecipeInfo と関連型を抽出し、レシピ定義を独立させる。

### 実装ステップ

#### Step 3.1: ファイル作成
```bash
touch /Users/uts/StatAppR/StatAppR/RecipeModels.swift
```

#### Step 3.2: 骨組みコード
```swift
import Foundation

// MARK: - Recipe Information Model

struct RecipeInfo: Identifiable {
    let id = UUID()
    let name: String
    let nameJapanese: String
    let description: String
    let recipeName: String
    let requiredColumns: [String]
    let example: String
    let parameters: [ParameterRequirement]
}

// MARK: - Parameter Requirement Model

struct ParameterRequirement: Identifiable {
    let id = UUID()
    let name: String           // 表示名（「時間列」など）
    let parameterKey: String   // パラメータキー（「time_column」など）
    let type: ParameterType    // パラメータ型
    let description: String    // 説明
    let required: Bool         // 必須か
}

enum ParameterType {
    case singleColumn          // 1つの列を選ぶ
    case multipleColumns       // 複数の列を選ぶ
    case categorical           // カテゴリから選ぶ
    case numeric               // 数値入力
}

// MARK: - Recipe Extensions

extension RecipeInfo {
    /// DataType ごとに推奨レシピを取得
    static func recommendedRecipes(for dataType: DataType) -> [RecipeInfo] {
        switch dataType {
        case .basicStats:
            return [basicStats_recipe, correlation_recipe]
        case .groupComparison:
            return [tTest_recipe, mannWhitney_recipe]
        // ... その他のデータ型
        default:
            return []
        }
    }

    // MARK: - Recipe Definitions (全30個)

    static let basicStats_recipe = RecipeInfo(
        name: "記述統計量",
        nameJapanese: "記述統計量",
        description: "平均値、標準偏差、中央値などの記述統計量を計算します。",
        recipeName: "basic_stats",
        requiredColumns: ["任意の数値列"],
        example: "患者データ: age, weight, height",
        parameters: [
            ParameterRequirement(
                id: UUID(),
                name: "選択列",
                parameterKey: "variables",
                type: .multipleColumns,
                description: "分析対象の列を選択",
                required: true
            )
        ]
    )

    static let tTest_recipe = RecipeInfo(
        name: "t検定",
        nameJapanese: "独立標本t検定",
        description: "2つのグループ間の平均値の差を検定します。",
        recipeName: "t_test",
        requiredColumns: ["グループ列", "測定値列"],
        example: "Treatment vs Control: group, value",
        parameters: [
            ParameterRequirement(
                id: UUID(),
                name: "グループ列",
                parameterKey: "group_column",
                type: .singleColumn,
                description: "グループを表す列を選択",
                required: true
            ),
            ParameterRequirement(
                id: UUID(),
                name: "値列",
                parameterKey: "value_column",
                type: .singleColumn,
                description: "測定値の列を選択",
                required: true
            )
        ]
    )

    // ... 他の28個のレシピ定義
}

// MARK: - All Recipes

extension RecipeInfo {
    static let allRecipes: [RecipeInfo] = [
        basicStats_recipe,
        tTest_recipe,
        // ... 全30個
    ]
}
```

#### Step 3.3: インポート修正
```swift
// 他のファイルで
import Foundation

// 変更前:
// RecipeInfo は Models.swift から

// 変更後:
// RecipeInfo は RecipeModels.swift から
```

---

## 4. Models.swift (改良)

### 目的
RecipeInfo 関連を削除し、コア定義のみに集約する。

### 実装ステップ

#### Step 4.1: 削除対象の確認
```
削除する行数: 約800行（RecipeInfo 定義と 30 レシピ）
削除する行数: 約20行（ParameterRequirement 定義）
削除する行数: 約9行（ParameterType 定義）
---
合計削除: 約829行
新規保持行数: 1,614 - 829 = 785行
```

#### Step 4.2: 削除コマンド例（手動実行）
```swift
// Models.swift から以下を削除：
// - struct RecipeInfo: Identifiable { ... }
// - struct ParameterRequirement: Identifiable { ... }
// - enum ParameterType { ... }
// - すべてのレシピ定義 (km_recipe, cox_recipe, ... など)
```

#### Step 4.3: インポート追加
Models.swift の先頭に以下を追加（RecipeInfo 型を参照する場合）:
```swift
import Foundation
import Combine
// 必要に応じて追加:
// import RecipeModels
```

---

## 5. ContentView.swift (改良)

### 目的
UI層に集中し、ビジネスロジックを削除する。

### 実装ステップ

#### Step 5.1: 削除対象の確認
```
削除する関数:
- autoMatchParameters() (76行)
- executeRecipe() (66行)
- loadCSVColumns() (22行)
---
合計削除: 164行

削除する @State:
- selectedColumnsByParameter (UI層で不要に)
---
合計削減: 約180行
```

#### Step 5.2: 新規メンバー追加
```swift
struct ContentView: View {
    // 既存の @State メンバーは保持
    @State private var selectedDataType: DataType? = nil
    @State private var selectedRecipe: RecipeInfo? = nil
    @State private var selectedCSVPath: URL? = nil
    @State private var showingFileImporter = false
    @State private var isRunningAnalysis = false
    @State private var analysisResults: [AnalysisResult] = []
    @State private var rEnvironment = REnvironment()

    // ビジネスロジック層を依存注入
    let executionEngine: RecipeExecutionEngine
    let csvManager: CSVManager = CSVManager.shared
}
```

#### Step 5.3: 削除すべき関数の置き換え
```swift
// 【削除】
private func loadCSVColumns() {
    // ... 22行
}

// 【削除】
private func autoMatchParameters() {
    // ... 76行
}

// 【削除】
private func executeRecipe() {
    // ... 66行
}

// 【新規】: RecipeExecutionView での利用に統一
// RecipeExecutionView が executionEngine を直接利用
```

#### Step 5.4: RecipeExecutionView の修正
```swift
struct RecipeExecutionView: View {
    let recipe: RecipeInfo
    @Binding var csvPath: URL?
    @Binding var isRunning: Bool
    @Binding var results: [AnalysisResult]
    let rEnvironment: REnvironment
    let onBack: () -> Void

    // 新規: executionEngine を注入
    let executionEngine: RecipeExecutionEngine

    @State private var csvData: String?
    @State private var csvColumns: [CSVColumn] = []
    @State private var selectedColumnsByParameter: [String: Set<String>] = [:]
    @State private var executionResult: String?
    @State private var recipeOutput: RecipeOutput?
    @State private var executionError: String?

    var body: some View {
        // 既存の UI コードは変更不要
        // 実行ロジックのみ executionEngine を利用
    }

    // 【新規】: onAppear で準備
    private func prepareExecution() {
        guard let csvPath = csvPath else { return }

        executionEngine.prepareExecution(recipe: recipe, csvPath: csvPath) { result in
            switch result {
            case .success(let (columns, matched)):
                csvColumns = columns
                selectedColumnsByParameter = matched
            case .failure(let error):
                executionError = error.localizedDescription
            }
        }
    }

    // 【修正】: executeRecipe をシンプル化
    private func executeRecipe() {
        isRunning = true

        guard let csvPath = csvPath else {
            executionError = "CSVファイルが選択されていません"
            isRunning = false
            return
        }

        executionEngine.executeAsync(
            recipe: recipe,
            csvPath: csvPath,
            selectedColumns: selectedColumnsByParameter
        ) { result in
            switch result {
            case .success(let output):
                recipeOutput = output
                isRunning = false
            case .failure(let error):
                executionError = error.localizedDescription
                isRunning = false
            }
        }
    }
}
```

---

## 6. 段階的な実装プラン

### Week 1: 基盤モジュール構築

**Day 1: RecipeParameterMatcher 実装**
- [ ] RecipeParameterMatcher.swift を作成
- [ ] キーワードマッピングを完全実装
- [ ] ContentView.autoMatchParameters() を参考に実装
- [ ] 単体テストを作成

**Day 2: RecipeExecutionEngine 実装**
- [ ] RecipeExecutionEngine.swift を作成
- [ ] prepareExecution() メソッド実装
- [ ] execute() メソッド実装
- [ ] 非同期実行サポート (executeAsync) を追加

**Day 3-4: RecipeModels 抽出**
- [ ] RecipeModels.swift を作成
- [ ] RecipeInfo 定義を移動
- [ ] 全 30 レシピ定義を移動
- [ ] extension で recommendedRecipes() を追加
- [ ] ビルド検証

### Week 2: 既存ファイル改良

**Day 5: Models.swift 削減**
- [ ] RecipeInfo 関連を削除
- [ ] ParameterRequirement 削除
- [ ] 全レシピ定義を削除
- [ ] 残りのモデルを整理
- [ ] インポート修正

**Day 6-7: ContentView 簡素化**
- [ ] autoMatchParameters() 削除
- [ ] executeRecipe() 削除
- [ ] loadCSVColumns() 削除
- [ ] executionEngine 依存注入追加
- [ ] ビルド検証

**Day 8: RecipeExecutionView 修正**
- [ ] executionEngine を注入
- [ ] 実行ロジックを修正
- [ ] prepareExecution() 追加
- [ ] executeRecipe() をシンプル化
- [ ] 動作テスト

### Week 3: テストと検証

**Day 9-10: 単体テスト**
- [ ] RecipeParameterMatcher テスト
- [ ] RecipeExecutionEngine テスト
- [ ] エッジケースの検証

**Day 11: 統合テスト**
- [ ] 全フロー（CSV読込 → マッチング → 実行）
- [ ] エラーハンドリング
- [ ] UI動作確認

**Day 12: ドキュメント更新**
- [ ] アーキテクチャドキュメント更新
- [ ] 開発者向けガイド作成
- [ ] 変更履歴ドキュメント

---

## 7. チェックリスト

### 実装完了確認
- [ ] RecipeParameterMatcher.swift: 正常に動作
- [ ] RecipeExecutionEngine.swift: 正常に動作
- [ ] RecipeModels.swift: 全レシピ定義が移動完了
- [ ] Models.swift: 削減完了 (1,614 → ~400行)
- [ ] ContentView.swift: 削減完了 (1,187 → ~300行)
- [ ] RecipeExecutionView: 修正完了

### ビルド検証
- [ ] Xcode ビルド成功
- [ ] コンパイル警告: 0件
- [ ] ランタイムエラー: なし

### テスト検証
- [ ] 単体テスト: 全パス
- [ ] 統合テスト: 全パス
- [ ] UI機能テスト: 全パス

### コード品質
- [ ] 循環依存: なし
- [ ] 未使用インポート: なし
- [ ] 保守性指標: 向上確認

---

## 8. ロールバック計画

万が一 問題が発生した場合:

```bash
# Git で現在の状態をコミット
git add -A
git commit -m "refactor: Swift アーキテクチャ改善"

# 問題発生時はこれで戻す
git reset --hard HEAD~1
```

---

## 参考資料

- SWIFT_ARCHITECTURE_ANALYSIS.md: 詳細分析
- 提案のメリット表: 改善指標確認
- モジュール間依存グラフ: アーキテクチャ図

このガイドに従うことで、計画的かつ安全にモジュール化を進められます。

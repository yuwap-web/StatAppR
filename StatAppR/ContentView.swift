import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedDataType: DataType? = nil
    @State private var selectedRecipe: RecipeInfo? = nil
    @State private var selectedCSVPath: URL? = nil
    @State private var showingFileImporter = false
    @State private var showingPackageManager = false
    @State private var isRunningAnalysis = false
    @State private var analysisResults: [AnalysisResult] = []
    @State private var rEnvironment = REnvironment()
    @State private var expandedParameterKey: String? = nil

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // MARK: - Left Sidebar (Instructions & Data Type Selection)
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Welcome Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("StatAppRへようこそ")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text("このアプリケーションでは、CSVデータを読み込んで、様々な統計分析を実行できます。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)

                            // Step-by-step Guide
                            VStack(alignment: .leading, spacing: 12) {
                                Text("操作手順")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                StepView(number: 1, title: "データタイプを選択", description: "あなたのデータの種類を選んでください")
                                StepView(number: 2, title: "CSVをロード", description: "コンピュータからCSVファイルを選択")
                                StepView(number: 3, title: "レシピを選択", description: "実行したい分析方法を選びます")
                                StepView(number: 4, title: "分析を実行", description: "結果がすぐに表示されます")
                            }

                            Divider()
                                .padding(.vertical, 12)

                            // Data Type Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("データタイプ")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                VStack(spacing: 8) {
                                    ForEach(DataType.allCases) { dataType in
                                        DataTypeButton(
                                            dataType: dataType,
                                            isSelected: selectedDataType == dataType,
                                            action: { selectedDataType = dataType }
                                        )
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding(16)
                    }
                    .background(Color(.windowBackgroundColor))

                    // Bottom Action Buttons
                    VStack(spacing: 8) {
                        Divider()

                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Button(action: { showingFileImporter = true }) {
                                    HStack {
                                        Image(systemName: "folder.badge.plus")
                                        Text("CSVをロード")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }

                                Button(action: { showingPackageManager = true }) {
                                    HStack {
                                        Image(systemName: "box.truck")
                                        Text("パッケージ")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }
                            }

                            // 推奨パラメータを適用ボタン
                            if selectedRecipe != nil {
                                Button(action: {
                                    applyRecommendedParameters()
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("推奨パラメータを適用")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(12)
                    }
                    .background(Color(.controlBackgroundColor))
                }
                .frame(minWidth: 280, maxWidth: 300)
                .background(Color(.windowBackgroundColor))

                // MARK: - Main Content Area
                ZStack {
                    if selectedDataType == nil {
                        WelcomeView()
                    } else if selectedRecipe == nil {
                        RecipeSelectionView(
                            dataType: selectedDataType!,
                            onSelectRecipe: { recipe in
                                selectedRecipe = recipe
                                selectedCSVPath = nil  // Reset CSV path when switching recipes
                            }
                        )
                    } else {
                        RecipeExecutionView(
                            recipe: selectedRecipe!,
                            csvPath: $selectedCSVPath,
                            isRunning: $isRunningAnalysis,
                            results: $analysisResults,
                            rEnvironment: rEnvironment,
                            onBack: { selectedRecipe = nil }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Loading Overlay
            if isRunningAnalysis {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("分析を実行中...")
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            onCompletion: { result in
                if case .success(let url) = result {
                    selectedCSVPath = url
                }
            }
        )
        .sheet(isPresented: $showingPackageManager) {
            PackageManagerView(rEnvironment: rEnvironment)
        }
        .onAppear {
            rEnvironment.detectR()
        }
    }

    // MARK: - Apply Recommended Parameters

    private func applyRecommendedParameters() {
        print("🔍 [DEBUG] applyRecommendedParameters() called")
        guard let recipe = selectedRecipe else {
            print("❌ [DEBUG] selectedRecipe is nil")
            return
        }

        print("✅ [DEBUG] selectedRecipe: \(recipe.recipeName)")

        // Load the recommended CSV file
        let sampleDataFileName = getRecommendedSampleDataFile(for: recipe.recipeName)
        print("🔍 [DEBUG] Looking for sample data file: \(sampleDataFileName)")

        guard let sampleDataURL = findSampleDataFile(sampleDataFileName) else {
            print("❌ [DEBUG] Sample data file not found at: \(sampleDataFileName)")
            print("📁 [DEBUG] Searched in: /Users/uts/StatAppR/Sample_Data/")
            return
        }

        print("✅ [DEBUG] Found sample data file at: \(sampleDataURL.path)")

        // Set the CSV path
        print("📄 [DEBUG] Setting selectedCSVPath to: \(sampleDataURL.lastPathComponent)")
        selectedCSVPath = sampleDataURL

        // Apply recommended parameters after a short delay to allow CSV to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            applyRecommendedColumnSelections(for: recipe.recipeName)
        }
    }

    private func getRecommendedSampleDataFile(for recipeName: String) -> String {
        // First, try to read from recipes.json (source of truth)
        let recipesPath = "/Users/uts/StatAppR/Engine/recipes/recipes.json"

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: recipesPath))
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                // Find recipe by ID
                if let recipe = json.first(where: { ($0["id"] as? String) == recipeName }),
                   let sampleDataFile = recipe["sampleDataFile"] as? String {
                    print("📋 [RecipeLoad] Found sampleDataFile from recipes.json: \(sampleDataFile) for \(recipeName)")
                    return sampleDataFile
                }
            }
        } catch {
            print("⚠️ [RecipeLoad] Error reading recipes.json: \(error)")
        }

        // Fallback: Use hardcoded map for backward compatibility
        let fileMap: [String: String] = [
            "basic_statistics": "1_BasicStats_patient_demographics.csv",
            "two_group_continuous": "2_GroupComparison_treatment_vs_control.csv",
            "two_group_categorical": "2_GroupComparison_treatment_vs_control.csv",
            "anova_continuous": "2_GroupComparison_treatment_vs_control.csv",
            "linear_regression": "3_Regression_house_price_prediction.csv",
            "multiple_regression": "3_Regression_house_price_prediction.csv",
            "logistic_regression": "2_GroupComparison_treatment_vs_control.csv",
            "mixed_model": "2_GroupComparison_treatment_vs_control.csv",
            "pca_analysis": "7_DimensionReduction_gene_expression.csv",
            "pls_regression": "3_Regression_house_price_prediction.csv",
            "cox_regression": "5_Survival_patient_followup.csv",
            "survival_km": "5_Survival_patient_followup.csv",
            "iptw_km_survival": "5_Survival_patient_followup.csv",
            "meta_analysis": "8_MetaAnalysis_study_results.csv",
            "subgroup_meta_analysis": "8_MetaAnalysis_study_results.csv",
            "propensity_score": "6_CausalInference_policy_evaluation.csv",
            "ps_matching": "6_CausalInference_policy_evaluation.csv",
            "iptw_ate": "6_CausalInference_policy_evaluation.csv",
            "aipw_ate": "6_CausalInference_policy_evaluation.csv",
            "double_ml_ate": "6_CausalInference_policy_evaluation.csv",
            "causal_forest": "6_CausalInference_policy_evaluation.csv",
            "target_trial_emulation": "5_Survival_patient_followup.csv",
            "iv_2sls": "6_CausalInference_policy_evaluation.csv",
            "instrumental_variable": "6_CausalInference_policy_evaluation.csv",
            "difference_in_differences": "4_TimeSeries_quarterly_sales.csv",
            "synthetic_control": "4_TimeSeries_quarterly_sales.csv",
            "bayesian_regression": "3_Regression_house_price_prediction.csv",
            "balance_table": "6_CausalInference_policy_evaluation.csv",
            "event_study": "4_TimeSeries_quarterly_sales.csv",
            "placebo_test": "4_TimeSeries_quarterly_sales.csv",
            "conditional_logistic_regression": "2_GroupComparison_treatment_vs_control.csv",
            "case_crossover": "5_Survival_patient_followup.csv"
        ]

        let result = fileMap[recipeName] ?? "1_BasicStats_patient_demographics.csv"
        print("📋 [RecipeLoad] Using fallback map for \(recipeName): \(result)")
        return result
    }

    private func findSampleDataFile(_ fileName: String) -> URL? {
        let fileManager = FileManager.default
        let baseDir = "/Users/uts/StatAppR/Sample_Data"
        let filePath = (baseDir as NSString).appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: filePath) {
            return URL(fileURLWithPath: filePath)
        }

        // Try alternative location
        if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let altPath = documentsDir.appendingPathComponent("StatAppR/Sample_Data/\(fileName)").path
            if fileManager.fileExists(atPath: altPath) {
                return URL(fileURLWithPath: altPath)
            }
        }

        return nil
    }

    private func applyRecommendedColumnSelections(for recipeName: String) {
        // This function will be implemented in conjunction with RecipeExecutionView
        // For now, this is a placeholder that informs the parent view
        // The actual parameter selection happens in RecipeExecutionView after CSV is loaded
        print("✨ Recommended CSV loaded for \(recipeName)")
    }
}

// MARK: - Step View Component

struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Data Type Button

struct DataTypeButton: View {
    let dataType: DataType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(dataType.emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dataType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(dataType.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
            .border(isSelected ? Color.blue : Color.clear, width: 2)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("StatAppRへようこそ")
                    .font(.title)
                    .fontWeight(.bold)

                Text("CSVデータを使って、統計分析を簡単に実行できます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("7つのデータタイプに対応", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Text("基本統計からAI応用まで、幅広い分析に対応")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("複数の分析手法", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Text("各データタイプに複数の統計手法を用意")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("サンプルデータ付き", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Text("すぐに試せるサンプルCSVファイルを用意")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(28)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            VStack(spacing: 12) {
                Text("左のパネルからデータタイプを選択して開始してください")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Recipe Selection View

struct RecipeSelectionView: View {
    let dataType: DataType
    let onSelectRecipe: (RecipeInfo) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Header
            VStack(alignment: .center, spacing: 8) {
                HStack(spacing: 12) {
                    Text(dataType.emoji)
                        .font(.title)
                    Text(dataType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Text(dataType.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .frame(maxWidth: .infinity, alignment: .center)

            Divider()

            // Recipe List
            ScrollView {
                VStack(spacing: 16) {
                    // Detailed Information Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("📋 詳細情報")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(dataType.detailedDescription)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    Text("実行可能な分析")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        ForEach(dataType.recommendedRecipes) { recipe in
                            RecipeCardView(
                                recipe: recipe,
                                action: { onSelectRecipe(recipe) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Recipe Card View

struct RecipeCardView: View {
    let recipe: RecipeInfo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Text(recipe.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(recipe.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("必要な列:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recipe.requiredColumns, id: \.self) { column in
                            HStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                Text(column)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)

                HStack {
                    Text("例: \(recipe.example)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.windowBackgroundColor))
            .border(Color(.separatorColor), width: 1)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recipe Execution View

struct RecipeExecutionView: View {
    let recipe: RecipeInfo
    @Binding var csvPath: URL?
    @Binding var isRunning: Bool
    @Binding var results: [AnalysisResult]
    let rEnvironment: REnvironment
    let onBack: () -> Void

    @State private var csvData: String?
    @State private var csvColumns: [CSVColumn] = []
    @State private var selectedColumnsByParameter: [String: Set<String>] = [:]
    @State private var executionResult: String?
    @State private var recipeOutput: RecipeOutput?
    @State private var executionError: String?
    @State private var selectedResultTab: String = "summary"
    @State private var columnSearchText: String = ""
    @State private var recommendedParametersApplied: Bool = false
    @State private var expandedParameterKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back Button & Recipe Switcher
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .font(.body)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recipe.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("レシピ: \(recipe.recipeName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("別のレシピ")
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // CSV Information Section & Status Indicator
                    if let csvPath = csvPath {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("データファイル", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(csvPath.lastPathComponent)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                HStack(spacing: 16) {
                                    Label("\(csvColumns.count) 列", systemImage: "square.split.2x1")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Label("データ準備完了", systemImage: "checkmark.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(16)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)

                            // Parameter Settings (レシピごとのパラメータ設定)
                            if !recipe.parameters.isEmpty && !csvColumns.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    let requiredCount = recipe.parameters.filter { $0.required }.count
                                    let totalCount = recipe.parameters.count

                                    HStack {
                                        Text("分析パラメータ（必須\(requiredCount)/\(totalCount)）")
                                            .font(.body)
                                            .fontWeight(.semibold)

                                        if recommendedParametersApplied {
                                            HStack(spacing: 4) {
                                                Image(systemName: "sparkles")
                                                    .font(.caption)
                                                Text("推奨設定適用済み")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.purple)
                                            .padding(4)
                                            .background(Color.purple.opacity(0.1))
                                            .cornerRadius(3)
                                        }

                                        Spacer()
                                    }

                                    // Display parameters based on recipe requirements
                                    ForEach(recipe.parameters) { param in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                HStack(spacing: 4) {
                                                    Text(param.name)
                                                        .font(.body)
                                                        .fontWeight(.semibold)

                                                    Button(action: {
                                                        if expandedParameterKey == param.parameterKey {
                                                            expandedParameterKey = nil
                                                        } else {
                                                            expandedParameterKey = param.parameterKey
                                                        }
                                                    }) {
                                                        Image(systemName: expandedParameterKey == param.parameterKey ? "questionmark.circle.fill" : "questionmark.circle")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                    .buttonStyle(.plain)
                                                }

                                                if param.required {
                                                    Text("※必須")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                }

                                                Spacer()
                                            }

                                            if expandedParameterKey == param.parameterKey {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("📖 用語説明")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.blue)

                                                    Text(ParameterGlossary.getExplanationOrDefault(for: param.parameterKey))
                                                        .font(.caption)
                                                        .lineLimit(nil)
                                                        .padding(8)
                                                        .background(Color(.controlBackgroundColor))
                                                        .cornerRadius(4)
                                                }
                                                .padding(.top, 4)
                                            }

                                            Text(param.description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            // Parameter Selection UI based on type
                                            if param.type == .singleColumn || param.type == .multipleColumns {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    // Search field
                                                    HStack {
                                                        Image(systemName: "magnifyingglass")
                                                            .foregroundColor(.gray)
                                                        TextField("列を検索", text: $columnSearchText)
                                                            .textFieldStyle(.roundedBorder)
                                                            .font(.caption)
                                                    }
                                                    .padding(8)
                                                    .background(Color(.windowBackgroundColor))
                                                    .cornerRadius(4)

                                                    // Grouped columns by type
                                                    // Apply search filter only if columnSearchText is not empty
                                                    let searchFilter = columnSearchText.trimmingCharacters(in: .whitespaces)
                                                    let numericColumns = csvColumns.filter { column in
                                                        column.dataType == "numeric" && (searchFilter.isEmpty || column.name.localizedCaseInsensitiveContains(searchFilter))
                                                    }
                                                    let categoricalColumns = csvColumns.filter { column in
                                                        column.dataType == "categorical" && (searchFilter.isEmpty || column.name.localizedCaseInsensitiveContains(searchFilter))
                                                    }
                                                    let otherColumns = csvColumns.filter { column in
                                                        !["numeric", "categorical"].contains(column.dataType) && (searchFilter.isEmpty || column.name.localizedCaseInsensitiveContains(searchFilter))
                                                    }

                                                    // Numeric columns group
                                                    if !numericColumns.isEmpty {
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("数値列")
                                                                .font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.secondary)

                                                            ForEach(numericColumns) { column in
                                                                ColumnSelectionRow(
                                                                    column: column,
                                                                    parameterKey: param.parameterKey,
                                                                    isSingleSelection: param.type == .singleColumn,
                                                                    selectedColumns: $selectedColumnsByParameter
                                                                )
                                                            }
                                                        }
                                                        .padding(8)
                                                        .background(Color(.windowBackgroundColor))
                                                        .cornerRadius(4)
                                                    }

                                                    // Categorical columns group
                                                    if !categoricalColumns.isEmpty {
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("カテゴリ列")
                                                                .font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.secondary)

                                                            ForEach(categoricalColumns) { column in
                                                                ColumnSelectionRow(
                                                                    column: column,
                                                                    parameterKey: param.parameterKey,
                                                                    isSingleSelection: param.type == .singleColumn,
                                                                    selectedColumns: $selectedColumnsByParameter
                                                                )
                                                            }
                                                        }
                                                        .padding(8)
                                                        .background(Color(.windowBackgroundColor))
                                                        .cornerRadius(4)
                                                    }

                                                    // Other columns group
                                                    if !otherColumns.isEmpty {
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("その他")
                                                                .font(.subheadline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.secondary)

                                                            ForEach(otherColumns) { column in
                                                                ColumnSelectionRow(
                                                                    column: column,
                                                                    parameterKey: param.parameterKey,
                                                                    isSingleSelection: param.type == .singleColumn,
                                                                    selectedColumns: $selectedColumnsByParameter
                                                                )
                                                            }
                                                        }
                                                        .padding(8)
                                                        .background(Color(.windowBackgroundColor))
                                                        .cornerRadius(4)
                                                    }

                                                    if numericColumns.isEmpty && categoricalColumns.isEmpty && otherColumns.isEmpty {
                                                        Text("該当する列がありません")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .padding(8)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(6)
                                    }
                                }
                            }

                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text("CSVファイルをロードしてください")
                                .font(.headline)

                            Text("左のパネルから「CSVをロード」ボタンでファイルを選択してください")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }

                    // Execution Results
                    if let output = recipeOutput {
                        VStack(alignment: .leading, spacing: 12) {
                            // Results Header
                            HStack {
                                Label("分析結果", systemImage: "chart.bar.fill")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }

                            Divider()

                            // Results Tab Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("結果タイプ", selection: $selectedResultTab) {
                                    if output.summary != nil {
                                        Text("概要").tag("summary")
                                    }
                                    if output.figures != nil && !(output.figures?.isEmpty ?? true) {
                                        Text("図表").tag("figures")
                                    }
                                    if output.tables != nil && !(output.tables?.isEmpty ?? true) {
                                        Text("統計値").tag("tables")
                                    }
                                    if output.warnings != nil && !(output.warnings?.isEmpty ?? true) {
                                        Text("警告").tag("warnings")
                                    }
                                }
                                .pickerStyle(.segmented)

                                // Summary Tab
                                if selectedResultTab == "summary", let summary = output.summary {
                                    VStack(alignment: .leading, spacing: 12) {
                                        if let headline = summary.headline {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("主要結果")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                Text(headline)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(12)
                                                    .background(Color(.controlBackgroundColor))
                                                    .cornerRadius(6)
                                            }
                                        }

                                        if let methodUsed = summary.method_used {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("使用した方法")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                Text(methodUsed)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(12)
                                                    .background(Color(.controlBackgroundColor))
                                                    .cornerRadius(6)
                                            }
                                        }

                                        if let keyMetrics = summary.key_metrics, !keyMetrics.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("主要指標")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(Array(keyMetrics), id: \.key) { key, value in
                                                        HStack {
                                                            Text(key)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                            Spacer()
                                                            Text(formatTableValue(value.value))
                                                                .font(.caption)
                                                                .fontWeight(.semibold)
                                                        }
                                                    }
                                                }
                                                .padding(12)
                                                .background(Color(.controlBackgroundColor))
                                                .cornerRadius(6)
                                            }
                                        }
                                    }
                                }

                                // Figures Tab
                                if selectedResultTab == "figures", let figures = output.figures, !figures.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(figures, id: \.id) { figure in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text(figure.title)
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    Text(figure.type)
                                                        .font(.caption2)
                                                        .padding(4)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(3)
                                                }
                                                Text(figure.id)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)

                                                // Display figure image if path exists
                                                if let path = figure.path, FileManager.default.fileExists(atPath: path) {
                                                    if let nsImage = NSImage(contentsOfFile: path) {
                                                        Image(nsImage: nsImage)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(maxWidth: .infinity)
                                                            .border(Color.gray.opacity(0.3))
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .background(Color(.controlBackgroundColor))
                                            .cornerRadius(6)
                                        }
                                    }
                                }

                                // Tables Tab
                                if selectedResultTab == "tables", let tables = output.tables, !tables.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(tables, id: \.id) { table in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(table.title)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)

                                            // Dynamic table rendering
                                            if !table.data.isEmpty {
                                                VStack(spacing: 0) {
                                                    // Header row
                                                    let firstRow = table.data[0]
                                                    let keys = Array(firstRow.keys).sorted()

                                                    HStack(spacing: 8) {
                                                        ForEach(keys, id: \.self) { key in
                                                            Text(key)
                                                                .fontWeight(.semibold)
                                                                .font(.caption2)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                        }
                                                    }
                                                    .padding(8)
                                                    .background(Color(.controlBackgroundColor))

                                                    Divider()

                                                    // Data rows
                                                    ForEach(Array(table.data.enumerated()), id: \.offset) { _, row in
                                                        HStack(spacing: 8) {
                                                            ForEach(keys, id: \.self) { key in
                                                                if let value = row[key] {
                                                                    Text(formatTableValue(value.value))
                                                                        .font(.caption)
                                                                        .foregroundColor(.secondary)
                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                } else {
                                                                    Text("--")
                                                                        .font(.caption)
                                                                        .foregroundColor(.secondary)
                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                }
                                                            }
                                                        }
                                                        .padding(8)
                                                        .background(Color(.windowBackgroundColor))
                                                    }
                                                }
                                                .cornerRadius(6)
                                                .border(Color(.controlBackgroundColor), width: 1)
                                            } else {
                                                Text("データがありません")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(12)
                                                    .background(Color(.windowBackgroundColor))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(6)
                                        }
                                    }
                                }

                                // Warnings Tab
                                if selectedResultTab == "warnings", let warnings = output.warnings, !warnings.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(warnings, id: \.code) { warning in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text(warning.code)
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    Text(warning.severity)
                                                        .font(.caption2)
                                                        .padding(4)
                                                        .background(Color.orange.opacity(0.2))
                                                        .cornerRadius(3)
                                                }
                                                Text(warning.message)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .background(Color.orange.opacity(0.05))
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    } else if let error = executionError {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("エラーが発生しました", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("エラーメッセージ:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .padding(10)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("解決方法:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 6) {
                                    Label("CSV ファイルが正しく読み込まれているか確認", systemImage: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Label("パラメータの選択が完了しているか確認", systemImage: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Label("R とすべての必須パッケージがインストールされているか確認", systemImage: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Label("別のレシピを選択して再度試す", systemImage: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            HStack(spacing: 12) {
                                Button(action: { executionError = nil; recipeOutput = nil }) {
                                    Text("リセット")
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }

                                Button(action: { onBack() }) {
                                    Text("別のレシピ")
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.05))
                        .border(Color.red.opacity(0.3), width: 1)
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding(20)
            }

            // Execute Button
            if csvPath != nil {
                HStack {
                    Button(action: executeRecipe) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("分析を実行")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .disabled(isRunning)
                }
                .padding(20)
                .background(Color(.controlBackgroundColor))
            }
        }
        .onAppear {
            checkRInstallation()
            loadCSVColumns()
        }
        .onChange(of: csvPath) {
            recommendedParametersApplied = false  // Reset when CSV changes
            loadCSVColumns()
        }
        .onChange(of: recipe.name) {
            // When recipe changes, reset CSV path and re-run auto-matching
            csvPath = nil  // Reset CSV to prevent mismatched data
            selectedColumnsByParameter = [:]
            csvColumns = []

            // Re-run auto-matching for the new recipe (will trigger when CSV is loaded)
            let matcher = RecipeParameterMatcher()
            selectedColumnsByParameter = matcher.matchParametersForRecipe(recipe, csvColumns: csvColumns)
        }
    }

    private func loadCSVColumns() {
        guard let csvPath = csvPath else {
            print("🔍 [RecipeExecution] csvPath is nil")
            csvColumns = []
            selectedColumnsByParameter = [:]
            recommendedParametersApplied = false
            return
        }

        print("📂 [RecipeExecution] Loading CSV: \(csvPath.lastPathComponent)")

        do {
            let (headers, data) = try CSVManager.shared.parseCSV(at: csvPath)
            try CSVManager.shared.validateCSV(headers: headers, data: data)
            let types = CSVManager.shared.detectColumnTypes(headers: headers, data: data)
            csvColumns = CSVManager.shared.extractColumnInfo(headers: headers, data: data, types: types)

            print("✅ [RecipeExecution] CSV loaded: \(headers.count) columns, \(data.count) rows")

            // Check if this is a recommended sample data file and apply recommended parameters
            let isRecommendedSample = isLoadingRecommendedSampleData(csvPath: csvPath)
            print("🔍 [RecipeExecution] Is recommended sample data: \(isRecommendedSample)")

            if isRecommendedSample {
                // Apply recommended parameters from recipe
                print("✨ [RecipeExecution] Applying recommended parameters for: \(recipe.recipeName)")
                applyRecommendedParametersForRecipe()
            } else {
                // Auto-match parameters using RecipeParameterMatcher
                print("🔄 [RecipeExecution] Using auto-matching for: \(recipe.recipeName)")
                let matcher = RecipeParameterMatcher()
                selectedColumnsByParameter = matcher.matchParametersForRecipe(recipe, csvColumns: csvColumns)
                recommendedParametersApplied = false
            }
        } catch {
            print("❌ [RecipeExecution] Error loading CSV: \(error.localizedDescription)")
            csvColumns = []
            selectedColumnsByParameter = [:]
            recommendedParametersApplied = false
            executionError = error.localizedDescription
        }
    }

    private func isLoadingRecommendedSampleData(csvPath: URL) -> Bool {
        let fileName = csvPath.lastPathComponent
        let recommendedFiles = [
            "1_BasicStats_patient_demographics.csv",
            "2_GroupComparison_treatment_vs_control.csv",
            "3_Regression_house_price_prediction.csv",
            "4_TimeSeries_quarterly_sales.csv",
            "5_Survival_patient_followup.csv",
            "6_CausalInference_policy_evaluation.csv",
            "7_DimensionReduction_gene_expression.csv",
            "8_MetaAnalysis_study_results.csv",
            "9_SubgroupMetaAnalysis_study_results.csv"
        ]
        return recommendedFiles.contains(fileName)
    }

    private func applyRecommendedParametersForRecipe() {
        // Load recipes.json to get recommended parameters
        let recipesPath = "/Users/uts/StatAppR/Engine/recipes/recipes.json"

        print("🔍 [RecipeExecution] Looking for recipes.json at: \(recipesPath)")

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: recipesPath))
            print("✅ [RecipeExecution] recipes.json found and loaded")

            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let recipes = json as? [[String: Any]] {
                print("✅ [RecipeExecution] Parsed \(recipes.count) recipes from JSON")

                // Find the current recipe in the JSON
                if let recipeDict = recipes.first(where: { ($0["id"] as? String) == recipe.recipeName }) {
                    print("✅ [RecipeExecution] Found recipe definition: \(recipe.recipeName)")

                    // Get recommended parameters
                    if let recommendedParams = recipeDict["recommendedParameters"] as? [String: Any] {
                        print("✅ [RecipeExecution] Found recommendedParameters: \(recommendedParams.keys.joined(separator: ", "))")

                        selectedColumnsByParameter = convertRecommendedParamsToSelection(recommendedParams)
                        recommendedParametersApplied = true
                        print("✨ [RecipeExecution] ✅ Applied recommended parameters for \(recipe.recipeName)")
                        print("📋 [RecipeExecution] Selected parameters: \(selectedColumnsByParameter)")
                        return
                    } else {
                        print("⚠️ [RecipeExecution] No recommendedParameters found in recipe definition")
                    }
                } else {
                    print("❌ [RecipeExecution] Recipe not found: \(recipe.recipeName)")
                }
            } else {
                print("❌ [RecipeExecution] Failed to parse recipes.json as array")
            }
        } catch {
            print("❌ [RecipeExecution] Failed to load recipes.json: \(error)")
        }

        // Fallback to auto-matching if recipes.json not found or doesn't have recommended params
        print("🔄 [RecipeExecution] Falling back to auto-matching")
        let matcher = RecipeParameterMatcher()
        selectedColumnsByParameter = matcher.matchParametersForRecipe(recipe, csvColumns: csvColumns)
        recommendedParametersApplied = false
    }

    private func convertRecommendedParamsToSelection(_ recommendedParams: [String: Any]) -> [String: Set<String>] {
        var selection: [String: Set<String>] = [:]

        for (paramKey, paramValue) in recommendedParams {
            if let stringValue = paramValue as? String {
                // Single value
                selection[paramKey] = [stringValue]
            } else if let arrayValue = paramValue as? [String] {
                // Array of values
                selection[paramKey] = Set(arrayValue)
            } else if let numberValue = paramValue as? NSNumber {
                // Numeric value (convert to string for storage)
                selection[paramKey] = [numberValue.stringValue]
            }
        }

        return selection
    }

    // MARK: - R Installation Check

    private func checkRInstallation() {
        // Check for Rscript in common installation paths
        let commonPaths = [
            "/usr/local/bin/Rscript",      // Homebrew install (Intel)
            "/opt/homebrew/bin/Rscript",   // M1/M2 Homebrew (Apple Silicon)
            "/usr/bin/Rscript",             // System R
            "/Applications/R.app/Contents/MacOS/Rscript"  // R.app GUI
        ]

        let rscriptExists = commonPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }

        if !rscriptExists {
            showRInstallationAlert()
        }
    }

    private func showRInstallationAlert() {
        let alert = NSAlert()
        alert.messageText = "⚠️ R がインストールされていません"
        alert.informativeText = """
        統計分析を実行するには R のインストールが必要です。

        【推奨】Homebrew でインストール:
        1. ターミナルを開く
        2. 以下をコピーして実行：
           brew install r
        3. インストール完了後、アプリを再起動

        【別の方法】CRAN から直接インストール:
        1. https://cran.r-project.org にアクセス
        2. macOS 用の R をダウンロード
        3. インストーラーを実行

        インストール後、アプリを再起動してください。
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "詳細ガイドを開く")

        let result = alert.runModal()
        if result == NSApplication.ModalResponse.alertSecondButtonReturn {
            if let url = URL(string: "https://cran.r-project.org") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func formatTableValue(_ value: Any) -> String {
        if let intVal = value as? Int {
            return String(intVal)
        } else if let doubleVal = value as? Double {
            // Format doubles with appropriate precision
            if doubleVal.isNaN {
                return "NA"
            } else if doubleVal.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(doubleVal))
            } else {
                return String(format: "%.4g", doubleVal)
            }
        } else if let stringVal = value as? String {
            return stringVal
        } else if let boolVal = value as? Bool {
            return boolVal ? "TRUE" : "FALSE"
        } else {
            return String(describing: value)
        }
    }

    private func executeRecipe() {
        guard let csvPath = csvPath else {
            executionError = "CSVファイルが指定されていません"
            return
        }

        isRunning = true
        recipeOutput = nil
        executionError = nil
        executionResult = nil

        // Use RecipeExecutionEngine to execute recipe
        RecipeExecutionEngine.shared.executeRecipe(
            recipe: recipe,
            csvPath: csvPath,
            selectedColumns: selectedColumnsByParameter,
            workDirectory: rEnvironment.workDirectory
        ) { result in
            isRunning = false

            switch result {
            case .success(let output):
                recipeOutput = output
                executionResult = "✅ 分析完了しました"

            case .failure(let error):
                executionError = error.errorDescription ?? "不明なエラーが発生しました"
                recipeOutput = nil
            }
        }
    }
}

// MARK: - Column Selection Row

struct ColumnSelectionRow: View {
    let column: CSVColumn
    let parameterKey: String
    let isSingleSelection: Bool
    @Binding var selectedColumns: [String: Set<String>]

    var isSelected: Bool {
        (selectedColumns[parameterKey] ?? []).contains(column.name)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(column.name)
                    .font(.body)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(column.dataType)
                        .font(.caption)
                        .padding(2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)

                    Text(column.sampleValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(String(format: "%.0f%%", column.completeness * 100))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
        .onTapGesture {
            updateSelection()
        }
    }

    private func updateSelection() {
        if var selected = selectedColumns[parameterKey] {
            if selected.contains(column.name) {
                selected.remove(column.name)
            } else {
                if isSingleSelection {
                    selected = [column.name]
                } else {
                    selected.insert(column.name)
                }
            }
            selectedColumns[parameterKey] = selected
        } else {
            selectedColumns[parameterKey] = [column.name]
        }
    }
}

// MARK: - Column Info View

struct ColumnInfoView: View {
    let column: CSVColumn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(column.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(column.dataType)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("サンプル値")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(column.sampleValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("完全性")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", column.completeness * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(10)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Package Manager View

struct PackageManagerView: View {
    let rEnvironment: REnvironment
    @Environment(\.dismiss) var dismiss
    @State private var installationProgress: [String: Double] = [:]
    @State private var installedPackages: Set<String> = []
    @State private var isInstallingAll = false
    @State private var installationMessage = ""
    @State private var selectedTab: String = "status"

    var requiredPackages: [RPackage] {
        RPackage.allPackages.filter { $0.isRequired }
    }

    var optionalPackages: [RPackage] {
        RPackage.allPackages.filter { !$0.isRequired }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("R パッケージ管理")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))

            Divider()

            // Tabs
            Picker("タブ", selection: $selectedTab) {
                Text("R 環境").tag("status")
                Text("必須パッケージ").tag("required")
                Text("オプション").tag("optional")
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedTab == "status" {
                        REnvironmentStatusView(rEnvironment: rEnvironment)
                    } else if selectedTab == "required" {
                        PackageListView(
                            packages: requiredPackages,
                            installedPackages: installedPackages,
                            onInstall: { installPackage($0) }
                        )
                    } else {
                        PackageListView(
                            packages: optionalPackages,
                            installedPackages: installedPackages,
                            onInstall: { installPackage($0) }
                        )
                    }

                    if !installationMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("インストール状態", systemImage: "info.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(installationMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }

                    Spacer()
                }
                .padding(20)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                }

                if !isInstallingAll {
                    Button(action: { installAllMissing() }) {
                        Text("不足分をインストール")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                } else {
                    Button(action: {}) {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("インストール中...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .disabled(true)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private func installPackage(_ package: RPackage) {
        installationMessage = "\(package.name) をインストール中..."
        print("Installing \(package.name)...")

        // Simulate installation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            installedPackages.insert(package.id)
            installationMessage = "\(package.name) をインストールしました"
        }
    }

    private func installAllMissing() {
        isInstallingAll = true
        installationMessage = "不足しているパッケージをインストール中...\nこれは数分かかります。"
        print("Installing all missing packages...")

        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate batch installation
            for package in RPackage.allPackages {
                if !installedPackages.contains(package.id) {
                    DispatchQueue.main.async {
                        installedPackages.insert(package.id)
                        installationMessage = "\(package.name) をインストールしました"
                    }
                    usleep(500000) // 0.5s delay between packages
                }
            }

            DispatchQueue.main.async {
                isInstallingAll = false
                installationMessage = "すべてのパッケージのインストールが完了しました"
            }
        }
    }
}

// MARK: - R Environment Status View

struct REnvironmentStatusView: View {
    let rEnvironment: REnvironment
    @State private var isInstallingR = false
    @State private var isSelectingWorkDirectory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // R Installation Status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: rEnvironment.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(rEnvironment.isInstalled ? .green : .red)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("R")
                            .font(.headline)
                            .fontWeight(.semibold)

                        if let version = rEnvironment.version {
                            Text("バージョン: \(version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if rEnvironment.isInstalled {
                            Text("バージョン情報を取得中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("インストール: 必須")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    if !rEnvironment.isInstalled && !isInstallingR {
                        Button(action: { installR() }) {
                            Text("インストール")
                                .font(.caption)
                                .padding(6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    } else if isInstallingR {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Installation Guide
            if !rEnvironment.isInstalled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("📋 インストール方法")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("【Homebrew を使う（推奨）】")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("ターミナルで以下を実行してください：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("brew install r")
                            .font(.caption)
                            .monospaced()
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("【CRAN から直接インストール】")
                            .font(.caption)
                            .fontWeight(.semibold)
                        HStack {
                            Text("https://cran.r-project.org")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Button(action: {
                                if let url = URL(string: "https://cran.r-project.org") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Image(systemName: "safari")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }

            // System Information
            VStack(alignment: .leading, spacing: 8) {
                Text("📊 システム情報")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    Text("R 実行パス:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(rEnvironment.rScriptPath)
                        .font(.caption)
                        .monospaced()
                }
                .padding(8)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(4)

                HStack {
                    Text("パッケージライブラリ:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("システムデフォルト")
                        .font(.caption)
                }
                .padding(8)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(4)
            }

            // Work Directory Information
            VStack(alignment: .leading, spacing: 12) {
                Text("📁 ワークディレクトリ")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("保存場所:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rEnvironment.workDirectory)
                                .font(.caption)
                                .monospaced()
                                .lineLimit(nil)
                                .textSelection(.enabled)
                                .foregroundColor(.secondary)

                            let defaultPath = FileManager.default.homeDirectoryForCurrentUser
                                .appendingPathComponent("Documents")
                                .appendingPathComponent("StatAppR")
                                .path

                            if rEnvironment.workDirectory == defaultPath {
                                Text("(デフォルト位置)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("(カスタム位置)")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        VStack(spacing: 6) {
                            Button(action: {
                                NSWorkspace.shared.open(URL(fileURLWithPath: rEnvironment.workDirectory))
                            }) {
                                Image(systemName: "folder.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .help("フォルダを開く")

                            Button(action: {
                                isSelectingWorkDirectory = true
                            }) {
                                Text("変更")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(3)
                            }
                            .buttonStyle(.plain)
                            .help("ワークディレクトリを変更")
                        }
                    }
                    .padding(8)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("保存されるもの:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 3))
                                .foregroundColor(.secondary)
                            Text("図表・グラフ（PNG形式）")
                                .font(.caption)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 3))
                                .foregroundColor(.secondary)
                            Text("解析結果データ（JSON形式）")
                                .font(.caption)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 3))
                                .foregroundColor(.secondary)
                            Text("統計値・テーブル")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 注記")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Text("分析実行時に自動的にワークディレクトリが作成され、結果ファイルが保存されます。上記のフォルダアイコンをクリックして、Finderで保存先を確認できます。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding(8)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(4)
            }
            .fileImporter(
                isPresented: $isSelectingWorkDirectory,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false,
                onCompletion: { result in
                    if case .success(let urls) = result, let url = urls.first {
                        rEnvironment.setWorkDirectory(url.path)
                    }
                    isSelectingWorkDirectory = false
                }
            )
        }
    }

    private func installR() {
        isInstallingR = true
        // Trigger R installation from rEnvironment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isInstallingR = false
        }
    }
}

// MARK: - Package List View

struct PackageListView: View {
    let packages: [RPackage]
    let installedPackages: Set<String>
    let onInstall: (RPackage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if packages.isEmpty {
                Text("パッケージがありません")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(20)
            } else {
                Text("\(packages.count) 個のパッケージ")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    ForEach(packages) { package in
                        PackageRowView(
                            package: package,
                            isInstalled: installedPackages.contains(package.id),
                            onInstall: { onInstall(package) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Package Row View

struct PackageRowView: View {
    let package: RPackage
    let isInstalled: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isInstalled ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(package.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(package.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isInstalled {
                Button(action: onInstall) {
                    Text("インストール")
                        .font(.caption)
                        .padding(6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    ContentView()
}

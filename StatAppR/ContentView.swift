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

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("7つのデータタイプに対応", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("基本統計からAI応用まで、幅広い分析に対応")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("複数の分析手法", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("各データタイプに複数の統計手法を用意")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("サンプルデータ付き", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("すぐに試せるサンプルCSVファイルを用意")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            VStack(spacing: 12) {
                Text("左のパネルからデータタイプを選択して開始してください")
                    .font(.subheadline)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(dataType.emoji)
                        .font(.title)
                    Text(dataType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text(dataType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Recipe List
            ScrollView {
                VStack(spacing: 12) {
                    // Detailed Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 詳細情報")
                            .font(.headline)

                        Text(dataType.detailedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
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
            VStack(alignment: .leading, spacing: 12) {
                Text(recipe.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("必要な列:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recipe.requiredColumns, id: \.self) { column in
                            HStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                Text(column)
                                    .font(.caption2)
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back Button & Recipe Switcher
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("レシピ: \(recipe.recipeName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("別のレシピ")
                    }
                    .font(.subheadline)
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
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                HStack(spacing: 16) {
                                    Label("\(csvColumns.count) 列", systemImage: "square.split.2x1")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Label("データ準備完了", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)

                            // Parameter Settings (レシピごとのパラメータ設定)
                            if !recipe.parameters.isEmpty && !csvColumns.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    let requiredCount = recipe.parameters.filter { $0.required }.count
                                    let totalCount = recipe.parameters.count
                                    Text("分析パラメータ（必須\(requiredCount)/\(totalCount)）")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    // Display parameters based on recipe requirements
                                    ForEach(recipe.parameters) { param in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(param.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)

                                                if param.required {
                                                    Text("※必須")
                                                        .font(.caption2)
                                                        .foregroundColor(.red)
                                                }

                                                Spacer()
                                            }

                                            Text(param.description)
                                                .font(.caption)
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
                                                    let numericColumns = csvColumns.filter { $0.dataType == "numeric" && $0.name.localizedCaseInsensitiveContains(columnSearchText) }
                                                    let categoricalColumns = csvColumns.filter { $0.dataType == "categorical" && $0.name.localizedCaseInsensitiveContains(columnSearchText) }
                                                    let otherColumns = csvColumns.filter { !["numeric", "categorical"].contains($0.dataType) && $0.name.localizedCaseInsensitiveContains(columnSearchText) }

                                                    // Numeric columns group
                                                    if !numericColumns.isEmpty {
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            Text("数値列")
                                                                .font(.caption2)
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
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            Text("カテゴリ列")
                                                                .font(.caption2)
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
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            Text("その他")
                                                                .font(.caption2)
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
                                        .padding(12)
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
            loadCSVColumns()
        }
        .onChange(of: recipe.name) {
            // When recipe changes, re-run auto-matching for the new recipe
            let matcher = RecipeParameterMatcher()
            selectedColumnsByParameter = matcher.matchParametersForRecipe(recipe, csvColumns: csvColumns)
        }
    }

    private func loadCSVColumns() {
        guard let csvPath = csvPath else {
            csvColumns = []
            selectedColumnsByParameter = [:]
            return
        }

        do {
            let (headers, data) = try CSVManager.shared.parseCSV(at: csvPath)
            try CSVManager.shared.validateCSV(headers: headers, data: data)
            let types = CSVManager.shared.detectColumnTypes(headers: headers, data: data)
            csvColumns = CSVManager.shared.extractColumnInfo(headers: headers, data: data, types: types)

            // Auto-match parameters using RecipeParameterMatcher
            let matcher = RecipeParameterMatcher()
            selectedColumnsByParameter = matcher.matchParametersForRecipe(recipe, csvColumns: csvColumns)
        } catch {
            csvColumns = []
            selectedColumnsByParameter = [:]
            executionError = error.localizedDescription
        }
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
            selectedColumns: selectedColumnsByParameter
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
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(column.dataType)
                        .font(.caption2)
                        .padding(2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)

                    Text(column.sampleValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(String(format: "%.0f%%", column.completeness * 100))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
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
                    Text(rEnvironment.isInstalled ? "/usr/local/bin/Rscript" : "未検出")
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

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
                                    .fontWeight(.bold)

                                Text("このアプリケーションでは、CSVデータを読み込んで、様々な統計分析を実行できます。")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                            .onChange(of: selectedDataType) { _ in
                                // Reset recipe selection when data type changes
                                selectedRecipe = nil
                            }

                            // Step-by-step Guide
                            VStack(alignment: .leading, spacing: 12) {
                                Text("手順")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                StepView(number: 1, title: "データタイプを選択", description: "あなたのデータの種類を選んでください")
                                StepView(number: 2, title: "CSVをロード", description: "コンピュータからCSVファイルを選択")
                                StepView(number: 3, title: "レシピを選択", description: "実行したい分析方法を選びます")
                                StepView(number: 4, title: "分析を実行", description: "結果がすぐに表示されます")
                            }

                            Divider()
                                .padding(.vertical, 8)

                            // Data Type Selection
                            VStack(alignment: .center, spacing: 12) {
                                Text("データタイプを選択")
                                    .font(.title3)
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
                            .frame(maxWidth: .infinity, alignment: .center)

                            Spacer()
                        }
                        .padding(12)
                    }
                    .background(Color(.windowBackgroundColor))

                    // Bottom Action Buttons
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.vertical, 4)

                        HStack(spacing: 12) {
                            Button(action: { showingFileImporter = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.title3)
                                    Text("CSVをロード")
                                        .fontWeight(.semibold)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }

                            Button(action: { showingPackageManager = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "box.truck")
                                        .font(.title3)
                                    Text("パッケージ")
                                        .fontWeight(.semibold)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                        }
                        .padding(10)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .frame(minWidth: 280, maxWidth: 380)
                .background(Color(.windowBackgroundColor))

                // MARK: - Main Content Area
                VStack {
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor))
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
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.headline)
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(dataType.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(dataType.description)
                        .font(.subheadline)
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
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("7つのデータタイプに対応", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("基本統計からAI応用まで、幅広い分析に対応")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("複数の分析手法", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("各データタイプに複数の統計手法を用意")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("サンプルデータ付き", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("すぐに試せるサンプルCSVファイルを用意")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(28)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)

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
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(dataType.detailedDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 12)
                    .padding(.top, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    Text("実行可能な分析")
                        .font(.title2)
                        .fontWeight(.semibold)
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
                Text("\(recipe.name)　\(recipe.nameJapanese)")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(recipe.description)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("必要な列:")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recipe.requiredColumns, id: \.self) { column in
                            HStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                Text(column)
                                    .font(.subheadline)
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
                        .font(.headline)
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
    @State private var selectedColumns: Set<String> = []
    @State private var executionResult: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recipe.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("レシピ: \(recipe.recipeName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // CSV Information Section
                    if let csvPath = csvPath {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("ロード済みファイル", systemImage: "checkmark.circle.fill")
                                .font(.title3)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(csvPath.lastPathComponent)
                                    .font(.headline)
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
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)

                            // Parameter Settings (レシピごとのパラメータ設定)
                            if !recipe.parameters.isEmpty && !csvColumns.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("分析パラメータ")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    // Display parameters based on recipe requirements
                                    ForEach(recipe.parameters) { param in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(param.name)
                                                    .font(.headline)
                                                    .fontWeight(.semibold)

                                                if param.required {
                                                    Text("※必須")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                }

                                                Spacer()
                                            }

                                            Text(param.description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            // Parameter Selection UI based on type
                                            if param.type == .singleColumn || param.type == .multipleColumns {
                                                VStack(spacing: 6) {
                                                    ForEach(csvColumns) { column in
                                                        HStack {
                                                            Text(column.name)
                                                                .font(.subheadline)
                                                            Spacer()
                                                            Image(systemName: selectedColumns.contains(column.name) ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(selectedColumns.contains(column.name) ? .blue : .gray)
                                                                .onTapGesture {
                                                                    if selectedColumns.contains(column.name) {
                                                                        selectedColumns.remove(column.name)
                                                                    } else {
                                                                        selectedColumns.insert(column.name)
                                                                    }
                                                                }
                                                        }
                                                        .padding(8)
                                                        .background(Color(.windowBackgroundColor))
                                                        .cornerRadius(4)
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

                            // Column Information & Selection (従来の列情報表示)
                            if !csvColumns.isEmpty && recipe.parameters.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("列情報と選択")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    VStack(spacing: 8) {
                                        ForEach(csvColumns) { column in
                                            HStack {
                                                ColumnInfoView(column: column)

                                                Spacer()

                                                // Column Selection Checkbox
                                                Image(systemName: selectedColumns.contains(column.name) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(selectedColumns.contains(column.name) ? .blue : .gray)
                                                    .onTapGesture {
                                                        if selectedColumns.contains(column.name) {
                                                            selectedColumns.remove(column.name)
                                                        } else {
                                                            selectedColumns.insert(column.name)
                                                        }
                                                    }
                                            }
                                        }
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
                    if let result = executionResult {
                        VStack(alignment: .leading, spacing: 16) {
                            // Results Header
                            HStack {
                                Label("分析結果", systemImage: "chart.bar.fill")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }

                            // Results Summary
                            VStack(alignment: .leading, spacing: 8) {
                                Text("処理結果")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .padding(12)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(6)
                            }

                            // Chart Preview (Placeholder)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("図表プレビュー")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                // Chart Placeholder
                                HStack(spacing: 12) {
                                    VStack(alignment: .center, spacing: 8) {
                                        ForEach(0..<5, id: \.self) { index in
                                            HStack(spacing: 4) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.blue.opacity(Double(5-index) / 5))
                                                    .frame(width: CGFloat(20 + index * 15), height: 20)

                                                Spacer()
                                            }
                                        }
                                    }
                                    .frame(height: 120)

                                    Text("データ可視化\n（R結果）")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .padding(12)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(6)
                            }

                            // Statistics Table
                            VStack(alignment: .leading, spacing: 8) {
                                Text("統計値")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                VStack(spacing: 6) {
                                    HStack {
                                        Text("項目").fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                                        Text("値").fontWeight(.semibold).frame(width: 80, alignment: .trailing)
                                    }
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color(.controlBackgroundColor))

                                    ForEach(["サンプル数", "平均値", "標準偏差", "最小値", "最大値"], id: \.self) { stat in
                                        HStack {
                                            Text(stat).frame(maxWidth: .infinity, alignment: .leading)
                                            Text("--").frame(width: 80, alignment: .trailing).foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                        .padding(8)
                                        Divider().padding(.horizontal, -8)
                                    }
                                }
                                .background(Color(.windowBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                        .padding(20)
                        .background(Color(.controlBackgroundColor).opacity(0.5))
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
    }

    private func executeRecipe() {
        isRunning = true

        // Simulate recipe execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            executionResult = """
            ✅ 分析完了！

            サンプル結果:
            - 処理行数: \(csvColumns.count)
            - ステータス: 成功
            - 処理時間: 1.2秒

            詳細な結果がR環境で生成されました。
            """

            isRunning = false
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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Rパッケージ管理")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))

            Divider()

            // Package List
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("R環境")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 12) {
                            Image(systemName: rEnvironment.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(rEnvironment.isInstalled ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("R")
                                    .font(.headline)
                                if let version = rEnvironment.version {
                                    Text("バージョン: \(version)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .padding(20)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("オプショナルパッケージ")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        VStack(spacing: 8) {
                            ForEach(RPackage.allPackages.filter { !$0.isRequired }) { package in
                                PackageRowView(
                                    package: package,
                                    isInstalled: installedPackages.contains(package.id),
                                    onInstall: { installPackage(package) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
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

                Button(action: { installAllMissing() }) {
                    Text("すべてインストール")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
        }
    }

    private func installPackage(_ package: RPackage) {
        // Simulate package installation
        print("Installing \(package.name)...")
    }

    private func installAllMissing() {
        // Simulate batch installation
        print("Installing all missing packages...")
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

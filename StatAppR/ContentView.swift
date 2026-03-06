import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedDataType: DataType? = nil
    @State private var selectedRecipe: RecipeInfo? = nil
    @State private var selectedCSVPath: URL? = nil
    @State private var showingFileImporter = false
    @State private var showingPackageManager = false
    @State private var showingSettings = false
    @State private var isRunningAnalysis = false
    @State private var analysisResults: [AnalysisResult] = []
    @StateObject private var rEnvironment = REnvironment()
    @StateObject private var appSettings = AppSettings()

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

                            // Network Connection Notice
                            HStack(spacing: 8) {
                                Image(systemName: "wifi")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Text("ネットワーク接続が必須です（Rインストール・パッケージダウンロード時）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)

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

                            HStack(spacing: 12) {
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

                                Button(action: { showingSettings = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gear")
                                            .font(.title3)
                                        Text("設定")
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 12)
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
                                appSettings: appSettings,
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(appSettings: appSettings)
        }
        .sheet(isPresented: $rEnvironment.showRInstallationNeeded) {
            RInstallationView(rEnvironment: rEnvironment)
        }
        .onAppear {
            rEnvironment.detectR()
            appSettings.ensureResultsFolderExists()
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
            VStack(alignment: .center, spacing: 8) {
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
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(16)
            .background(Color(.controlBackgroundColor))
            .padding(.horizontal, 20)
            .padding(.top, 20)

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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
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
    let appSettings: AppSettings
    let onBack: () -> Void

    @State private var csvData: String?
    @State private var csvColumns: [CSVColumn] = []
    @State private var selectedColumnsByParameter: [String: Set<String>] = [:]
    @State private var executionResult: String?
    @State private var recipeOutput: RecipeOutput?

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
            .onAppear {
                // Load CSV columns if csvPath is already set (when CSV loaded before recipe selection)
                if let csvPath = csvPath {
                    loadCSVColumns(csvPath)
                }
            }
            .onChange(of: csvPath) { newPath in
                if let newPath = newPath {
                    loadCSVColumns(newPath)
                }
            }

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

                                                            let paramKey = param.parameterKey
                                                            let selectedForParam = selectedColumnsByParameter[paramKey] ?? []
                                                            let isSelected = selectedForParam.contains(column.name)

                                                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(isSelected ? .blue : .gray)
                                                                .onTapGesture {
                                                                    if selectedColumnsByParameter[paramKey] == nil {
                                                                        selectedColumnsByParameter[paramKey] = []
                                                                    }

                                                                    if selectedColumnsByParameter[paramKey]?.contains(column.name) ?? false {
                                                                        selectedColumnsByParameter[paramKey]?.remove(column.name)
                                                                    } else {
                                                                        selectedColumnsByParameter[paramKey]?.insert(column.name)
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

                                                // Column info only - selection in parameters above
                                                Text("")
                                                    .font(.caption)
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
                                    .font(.headline)
                                    .fontWeight(.bold)

                                ScrollView {
                                    Text(result)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(8)
                                }
                                .frame(maxHeight: 400)
                            }
                            .frame(maxWidth: .infinity)

                            // Results Folder Information
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text("作業フォルダ")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button(action: {
                                        NSWorkspace.shared.open(URL(fileURLWithPath: appSettings.resultsFolder))
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.right.square")
                                            Text("Finder で開く")
                                                .font(.caption)
                                        }
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(appSettings.resultsFolder)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .textSelection(.enabled)
                                        Spacer()
                                        Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(appSettings.resultsFolder, forType: .string)
                                        }) {
                                            Image(systemName: "doc.on.doc.fill")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                        .help("パスをコピー")
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("PNG 画像ファイルが保存されています。論文作成時に使用できます。")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let figures = recipeOutput?.figures, !figures.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "photo.stack.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                            Text("生成ファイル: \(figures.count) 個")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }

                                        // List generated files
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(figures.prefix(5), id: \.id) { figure in
                                                HStack(spacing: 4) {
                                                    Image(systemName: "square.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                    Text(figure.title)
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Text(figure.path.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                .padding(4)
                                            }
                                            if figures.count > 5 {
                                                Text("他 \(figures.count - 5) 個")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 16)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color(.controlBackgroundColor))
                                        .cornerRadius(4)
                                    }
                                }
                                .padding(12)
                                .background(Color(.controlBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                            }

                            // Chart Preview (Actual Figures)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("図表プレビュー")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                if let figures = recipeOutput?.figures, !figures.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(figures, id: \.id) { figure in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 8) {
                                                    Text(figure.title)
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    // File type indicator
                                                    if let filePath = figure.path, filePath.lowercased().hasSuffix(".pdf") {
                                                        Label("PDF", systemImage: "doc.pdf.fill")
                                                            .font(.caption2)
                                                            .foregroundColor(.red)
                                                    } else {
                                                        Label("PNG", systemImage: "photo.fill")
                                                            .font(.caption2)
                                                            .foregroundColor(.blue)
                                                    }
                                                }

                                                if let filePath = figure.path, FileManager.default.fileExists(atPath: filePath) {
                                                    if filePath.lowercased().hasSuffix(".pdf") {
                                                        // PDF file - show open button
                                                        HStack(spacing: 12) {
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text("PDF レポート")
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                                Text(URL(fileURLWithPath: filePath).lastPathComponent)
                                                                    .font(.caption2)
                                                                    .foregroundColor(.secondary)
                                                                    .lineLimit(2)
                                                            }
                                                            Spacer()
                                                            Button(action: {
                                                                NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
                                                            }) {
                                                                HStack(spacing: 4) {
                                                                    Image(systemName: "arrow.up.right")
                                                                    Text("開く")
                                                                }
                                                                .font(.caption)
                                                                .padding(8)
                                                                .background(Color.red.opacity(0.1))
                                                                .foregroundColor(.red)
                                                                .cornerRadius(4)
                                                            }
                                                        }
                                                        .padding(12)
                                                        .background(Color.red.opacity(0.03))
                                                        .cornerRadius(6)
                                                    } else {
                                                        // PNG image - show preview
                                                        if let image = NSImage(contentsOfFile: filePath) {
                                                            Image(nsImage: image)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(maxHeight: 300)
                                                                .cornerRadius(6)
                                                        } else {
                                                            Text("画像の読み込みに失敗しました")
                                                                .font(.caption)
                                                                .foregroundColor(.red)
                                                        }
                                                    }
                                                } else {
                                                    Text("ファイルが見つかりません: \(figure.path ?? "N/A")")
                                                        .font(.caption)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            .padding(12)
                                            .background(Color(.controlBackgroundColor))
                                            .cornerRadius(6)
                                        }
                                    }
                                } else {
                                    // Placeholder when no figures available
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

                                        Text("データ可視化\n（R結果を待機中）")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    .padding(12)
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }

                            // Statistics Table (from actual results)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("統計値")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                VStack(spacing: 6) {
                                    HStack {
                                        Text("項目").fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                                        Text("値").fontWeight(.semibold).frame(width: 100, alignment: .trailing)
                                    }
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color(.controlBackgroundColor))

                                    if let keyMetrics = recipeOutput?.summary?.key_metrics {
                                        // Build statistics from key_metrics
                                        let statsItems = [
                                            ("総研究数", keyMetrics["n_total_studies"]),
                                            ("サブグループ数", keyMetrics["n_subgroups"]),
                                            ("統合効果量", keyMetrics["pooled_effect_overall"]),
                                            ("p値", keyMetrics["p_value_overall"]),
                                            ("異質性 I²", keyMetrics["I2_percent_overall"]),
                                            ("Q統計量", keyMetrics["Q_overall"])
                                        ]

                                        ForEach(statsItems.indices, id: \.self) { index in
                                            let (label, value) = statsItems[index]
                                            HStack {
                                                Text(label).frame(maxWidth: .infinity, alignment: .leading)
                                                if let val = value?.value {
                                                    // Format numeric values
                                                    if let numVal = val as? NSNumber {
                                                        Text(String(format: "%.4g", numVal.doubleValue))
                                                            .frame(width: 100, alignment: .trailing)
                                                            .font(.caption)
                                                            .fontWeight(.semibold)
                                                    } else {
                                                        Text("\(val)").frame(width: 100, alignment: .trailing)
                                                    }
                                                } else {
                                                    Text("--").frame(width: 100, alignment: .trailing).foregroundColor(.secondary)
                                                }
                                            }
                                            .font(.caption)
                                            .padding(8)
                                            if index < statsItems.count - 1 {
                                                Divider().padding(.horizontal, -8)
                                            }
                                        }
                                    } else {
                                        // Fallback when no results yet
                                        ForEach(["総研究数", "サブグループ数", "統合効果量", "p値", "異質性 I²", "Q統計量"], id: \.self) { stat in
                                            HStack {
                                                Text(stat).frame(maxWidth: .infinity, alignment: .leading)
                                                Text("--").frame(width: 100, alignment: .trailing).foregroundColor(.secondary)
                                            }
                                            .font(.caption)
                                            .padding(8)
                                            Divider().padding(.horizontal, -8)
                                        }
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

    private func loadCSVColumns(_ url: URL) {
        do {
            print("🔍 [DEBUG] CSV読み込み開始: \(url.lastPathComponent)")

            let (headers, data) = try CSVManager.shared.parseCSV(at: url)
            print("🔍 [DEBUG] 解析完了 - ヘッダー: \(headers.count)列, データ: \(data.count)行")

            // Validate CSV
            try CSVManager.shared.validateCSV(headers: headers, data: data)
            print("🔍 [DEBUG] 検証完了")

            // Detect column types
            let types = CSVManager.shared.detectColumnTypes(headers: headers, data: data)
            print("🔍 [DEBUG] 型検出完了: \(types)")

            // Extract column information
            let columnInfo = CSVManager.shared.extractColumnInfo(headers: headers, data: data, types: types)
            print("🔍 [DEBUG] 列情報抽出完了: \(columnInfo.count)列")

            // Update state
            csvColumns = columnInfo
            print("🔍 [DEBUG] csvColumns更新完了: \(csvColumns.count)列")

            // 🎯 Auto-match parameters to CSV columns
            autoMatchParameters(headers: headers)
            print("🔍 [DEBUG] パラメータマッチング完了")
        } catch {
            // Handle error silently - CSV is already loaded
            print("❌ [ERROR] CSV読み込みエラー: \(error)")
        }
    }

    private func autoMatchParameters(headers: [String]) {
        // キーワード マッピング辞書
        let keywordMappings: [String: [String]] = [
            // 効果量・結果変数
            "effect": ["effect_size", "effect", "estimate", "coef"],
            "y": ["y", "outcome", "result", "value", "response"],
            "outcome": ["outcome", "y", "result", "event"],
            "outcome_column": ["outcome_column", "outcome", "y", "result", "event", "disease_status"],

            // 標準誤差・分散
            "se": ["se", "standard_error", "std_error", "stderr"],
            "standard_error": ["standard_error", "se", "stderr"],

            // グループ・処理
            "group": ["group", "treatment", "arm", "condition"],
            "group_column": ["group_column", "group", "treatment", "arm", "condition", "treatment_group", "strata"],
            "treatment": ["treatment", "group", "arm", "intervention"],
            "treatment_group": ["treatment_group", "treatment", "arm", "group"],

            // 時間変数
            "time": ["time", "months", "days", "years", "followup", "followup_months", "time_months"],
            "time_column": ["time_column", "time", "months", "days", "years", "followup", "followup_months", "time_months"],
            "event": ["event", "status", "outcome_event", "event_occurred"],
            "event_column": ["event_column", "event", "status", "outcome_event", "event_occurred"],

            // サンプルサイズ
            "n": ["n", "sample_size", "count"],
            "sample_size": ["sample_size", "n", "count"],

            // ID・識別子
            "study_id": ["study_id", "id", "study"],
            "id": ["id", "study_id", "patient_id"],

            // ラベル・名前
            "label": ["label", "name", "author", "study_name"],
            "study_label": ["study_label", "author", "study_name"],

            // サブグループ・層別化
            "subgroup_column": ["subgroup_column", "subgroup", "group_var", "stratify", "stratum", "type", "category", "class", "year", "region", "study_type"],
            "subgroup": ["subgroup", "subgroup_column", "group", "strata"],

            // 予測変数・共変量
            "predictor_columns": ["predictor_columns", "predictors", "covariates", "independent", "variables", "features"],
            "predictors": ["predictors", "predictor_columns", "covariates", "independent", "variables"],
            "covariates": ["covariates", "predictors", "predictor_columns", "independent", "variables"],
        ]

        // 各パラメータに対して自動マッチング
        for param in recipe.parameters {
            let paramKey = param.parameterKey.lowercased()
            var matchedColumn: String?

            // 1. 完全一致をチェック
            if let exactMatch = headers.first(where: { $0.lowercased() == paramKey }) {
                matchedColumn = exactMatch
            }
            // 2. キーワードベースのマッチング
            else if let keywords = keywordMappings[paramKey] {
                for keyword in keywords {
                    if let match = headers.first(where: { $0.lowercased().contains(keyword.lowercased()) }) {
                        matchedColumn = match
                        break
                    }
                }
            }
            // 3. 部分一致（パラメータがヘッダーに含まれるか）
            else if let partialMatch = headers.first(where: { $0.lowercased().contains(paramKey) }) {
                matchedColumn = partialMatch
            }
            // 4. 逆方向（ヘッダーがパラメータに含まれるか）
            else if let reverseMatch = headers.first(where: { paramKey.contains($0.lowercased()) }) {
                matchedColumn = reverseMatch
            }

            // マッチした列をセット
            if let matched = matchedColumn {
                selectedColumnsByParameter[paramKey] = [matched]
            }
        }
    }

    private func executeRecipe() {
        guard let csvPath = csvPath else { return }

        isRunning = true

        // Build parameters from selected columns
        var parameters: [String: Any] = [:]

        // Map selectedColumnsByParameter to recipe parameters
        for param in recipe.parameters {
            let selectedForParam = selectedColumnsByParameter[param.parameterKey] ?? []

            if param.type == .singleColumn {
                // For single column parameters, get first selected column
                if let selectedColumn = selectedForParam.first {
                    parameters[param.parameterKey] = selectedColumn
                }
            } else if param.type == .multipleColumns {
                // For multiple column parameters, convert set to array
                parameters[param.parameterKey] = Array(selectedForParam)
            }
        }

        // Execute recipe on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let result = RecipeRunner.shared.executeRecipe(
                name: recipe.recipeName,
                csvPath: csvPath.path,
                parameters: parameters,
                resultsFolder: appSettings.resultsFolder
            )

            DispatchQueue.main.async {
                switch result {
                case .success(let output):
                    // Format output for display
                    var summaryText = "処理成功"

                    // Extract information from SummaryInfo if available
                    if let summary = output.summary {
                        var summaryLines: [String] = []

                        if let headline = summary.headline {
                            summaryLines.append("📌 \(headline)")
                        }
                        if let method = summary.method_used {
                            summaryLines.append("📊 使用方法: \(method)")
                        }
                        if let metrics = summary.key_metrics, !metrics.isEmpty {
                            summaryLines.append("📈 主要指標:")
                            for (key, value) in metrics {
                                summaryLines.append("  • \(key): \(value.value)")
                            }
                        }
                        if let notes = summary.interpretation_notes, !notes.isEmpty {
                            summaryLines.append("📝 解釈:")
                            for note in notes {
                                summaryLines.append("  • \(note)")
                            }
                        }

                        summaryText = summaryLines.isEmpty ? "処理成功" : summaryLines.joined(separator: "\n")
                    }

                    // Build figures information
                    var figuresText = ""
                    if let figures = output.figures, !figures.isEmpty {
                        figuresText = "\n\n📊 生成されたグラフ: \(figures.count)個"
                        for (i, fig) in figures.enumerated() {
                            figuresText += "\n  [\(i + 1)] \(fig.title) (\(fig.type))"
                        }
                    }

                    // Build tables information
                    var tablesText = ""
                    if let tables = output.tables, !tables.isEmpty {
                        tablesText = "\n\n📋 生成されたテーブル: \(tables.count)個"
                        for (i, table) in tables.enumerated() {
                            tablesText += "\n  [\(i + 1)] \(table.title)"
                        }
                    }

                    let resultText = """
                    ✅ 分析完了！

                    レシピ: \(recipe.name)
                    処理対象列: \(selectedColumnsByParameter.values.flatMap { Array($0) }.joined(separator: ", "))
                    処理行数: \(csvColumns.count)

                    結果:
                    \(summaryText)\(figuresText)\(tablesText)
                    """
                    executionResult = resultText
                    recipeOutput = output  // 💾 Store the full RecipeOutput for figure display

                case .failure(let error):
                    executionResult = """
                    ❌ エラーが発生しました

                    詳細: \(error.localizedDescription)
                    """
                }

                isRunning = false
            }
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
        guard !rEnvironment.isInstalled else {
            print("R is not installed")
            return
        }

        print("Installing \(package.name)...")
        installationProgress[package.id] = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/Rscript")
            process.arguments = ["-e", "install.packages('\(package.id)', quiet=TRUE); cat('Done')"]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    DispatchQueue.main.async {
                        installedPackages.insert(package.id)
                        installationProgress[package.id] = 1.0
                        print("\(package.name) installed successfully")
                    }
                } else {
                    DispatchQueue.main.async {
                        installationProgress[package.id] = nil
                        print("Failed to install \(package.name)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    installationProgress[package.id] = nil
                    print("Error installing \(package.name): \(error)")
                }
            }
        }
    }

    private func installAllMissing() {
        guard rEnvironment.isInstalled else {
            print("R is not installed")
            return
        }

        print("Installing all missing packages...")
        let missingPackages = RPackage.allPackages.filter { !installedPackages.contains($0.id) && !$0.isRequired }

        for package in missingPackages {
            installPackage(package)
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

// MARK: - R Installation View

struct RInstallationView: View {
    let rEnvironment: REnvironment
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Rが見つかりません")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("このアプリケーションを使用するには、Rの統計処理環境をインストールする必要があります。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)

            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("インストール方法")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    Label("推奨: Homebrewを使用（自動）", systemImage: "1.circle.fill")
                        .font(.body)
                        .fontWeight(.semibold)

                    Text("アプリから自動でインストールできます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("手動: 公式サイトからダウンロード", systemImage: "2.circle.fill")
                        .font(.body)
                        .fontWeight(.semibold)

                    Text("https://www.r-project.org")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.leading, 32)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("注記: ネットワーク接続が必須", systemImage: "wifi")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Status Message (with scrolling support)
            if !rEnvironment.rInstallationMessage.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ステータス / インストール手順:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(rEnvironment.rInstallationMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .textSelection(.enabled)  // Allow copy-paste
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Helper Buttons
            VStack(spacing: 8) {
                Button(action: {
                    if let url = URL(string: "https://brew.sh") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("Homebrewサイトを開く")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(.controlBackgroundColor))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                .disabled(rEnvironment.isInstallingR)

                if rEnvironment.rInstallationMessage.contains("失敗") ||
                   rEnvironment.rInstallationMessage.contains("エラー") ||
                   rEnvironment.rInstallationMessage.contains("パスワード") {
                    Button(action: {
                        rEnvironment.rInstallationMessage = ""
                        rEnvironment.isInstallingR = false
                        rEnvironment.installRUsingHomebrew()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("リトライ")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(.controlBackgroundColor))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                    }
                    .disabled(rEnvironment.isInstallingR)
                }
            }
            .padding(20)

            // Main Buttons
            HStack(spacing: 12) {
                Button(action: {
                    rEnvironment.showRInstallationNeeded = false
                }) {
                    Text("後で")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                }
                .disabled(rEnvironment.isInstallingR)

                Button(action: { rEnvironment.installRUsingHomebrew() }) {
                    HStack(spacing: 8) {
                        if rEnvironment.isInstallingR {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(rEnvironment.isInstallingR ? "インストール中..." : "今すぐインストール")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .disabled(rEnvironment.isInstallingR)
            }
            .padding(20)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var showingFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("設定")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))

            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Results Folder Setting
                    VStack(alignment: .leading, spacing: 12) {
                        Label("結果の保存先", systemImage: "folder.fill")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("分析結果（PNG画像、PDFレポート）を保存するフォルダ")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("現在のパス:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(appSettings.resultsFolder)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                panel.allowsMultipleSelection = false
                                panel.message = "結果フォルダを選択"

                                if panel.runModal() == .OK, let url = panel.url {
                                    appSettings.updateResultsFolder(url.path)
                                }
                            }) {
                                Text("変更")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)

                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: appSettings.resultsFolder))
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square")
                                Text("フォルダを開く")
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                        }
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)

                    // PDF Generation Setting
                    VStack(alignment: .leading, spacing: 12) {
                        Label("PDF レポート生成", systemImage: "doc.fill")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("分析完了時に統計結果を PDF として自動生成")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle(isOn: $appSettings.generatePDF) {
                            Text("PDF を自動生成")
                                .font(.body)
                        }
                        .onChange(of: appSettings.generatePDF) { newValue in
                            appSettings.setGeneratePDF(newValue)
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)

                        if appSettings.generatePDF {
                            Text("✅ 有効: 分析完了後に PDF レポートが生成されます")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(8)
                        } else {
                            Text("⚠️ 無効: PNG 画像のみが生成されます")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(8)
                        }
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)

                    // Auto Open Setting
                    VStack(alignment: .leading, spacing: 12) {
                        Label("自動で結果を開く", systemImage: "arrow.up.right")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("分析完了時に自動で結果フォルダを開く")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle(isOn: $appSettings.autoOpenResults) {
                            Text("結果フォルダを自動で開く")
                                .font(.body)
                        }
                        .onChange(of: appSettings.autoOpenResults) { newValue in
                            appSettings.setAutoOpenResults(newValue)
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("💡 ヒント")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        Text("結果フォルダを Google Drive や Dropbox と同期させることで、クラウド自動バックアップできます。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(6)
                }
                .padding(20)
            }
        }
    }
}

#Preview {
    ContentView()
}

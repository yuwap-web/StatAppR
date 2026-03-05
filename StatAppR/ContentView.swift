import SwiftUI

struct ContentView: View {
    @State private var csvPath: String = "/Users/uts/Desktop/pharm_demo2.csv"
    @State private var workdir: String = DatasetInspector.defaultWorkdir()

    @State private var columns: [String] = []
    @State private var columnsError: String?

    // ✅ recipes.json 由来のメニュー
    @State private var availableRecipes: [RecipeDescriptor] = []
    @State private var recipeId: String = "two_group_continuous"

    // いったん共通UIとして残す（two_group系のデフォルト）
    @State private var yColumn: String = "hba1c_baseline"
    @State private var groupColumn: String = "treatment"

    @State private var isRunning = false
    @State private var lastResult: AnalysisResult?
    @State private var lastError: String?

    private var selectedRecipe: RecipeDescriptor? {
        availableRecipes.first(where: { $0.id == recipeId })
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("StatAppR")
                    .font(.title2)
                    .bold()

                GroupBox("入力") {
                    VStack(alignment: .leading, spacing: 10) {

                        HStack {
                            TextField("CSV path", text: $csvPath)
                                .textFieldStyle(.roundedBorder)
                            OpenCSVButton(csvPath: $csvPath)
                        }

                        HStack {
                            TextField("workdir", text: $workdir)
                                .textFieldStyle(.roundedBorder)
                            Button("自動生成") {
                                workdir = DatasetInspector.defaultWorkdir()
                            }
                        }

                        // ✅ 解析メニュー（recipes.json）
                        HStack(spacing: 12) {
                            Picker("解析", selection: $recipeId) {
                                ForEach(availableRecipes, id: \.id) { r in
                                    Text(r.title).tag(r.id)
                                }
                            }
                            .pickerStyle(.menu)

                            Text(selectedRecipe?.description ?? "（説明なし）")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack(spacing: 12) {
                            Picker("目的変数 (y)", selection: $yColumn) {
                                ForEach(columns, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .frame(minWidth: 260)
                            .pickerStyle(.menu)

                            Picker("群 (group)", selection: $groupColumn) {
                                ForEach(columns, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .frame(minWidth: 260)
                            .pickerStyle(.menu)

                            Button("列を再読み込み") { loadColumns() }
                        }

                        if let e = columnsError {
                            Text(e).foregroundStyle(.red)
                        }

                        HStack(spacing: 12) {
                            Button(isRunning ? "解析中…" : "実行") {
                                run()
                            }
                            .disabled(isRunning || columns.isEmpty || availableRecipes.isEmpty)

                            if let e = lastError {
                                Text(e).foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let r = lastResult {
                    Divider()
                    ResultView(
                        workdir: URL(fileURLWithPath: workdir, isDirectory: true),
                        result: r
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
            .padding()

            // ✅ ここが「onAppearで recipes を読み込む」場所（既存を置換）
            .onAppear {
                let list = RecipesCatalog.availableInBundle()
                availableRecipes = list

                if !list.contains(where: { $0.id == recipeId }), let first = list.first {
                    recipeId = first.id
                }

                loadColumns()
            }

            .onChange(of: csvPath) { _ in
                loadColumns()
            }
        }
    }

    private func loadColumns() {
        columnsError = nil
        do {
            columns = try DatasetInspector.readHeader(csvPath: csvPath)
            if !columns.contains(yColumn), let first = columns.first { yColumn = first }
            if !columns.contains(groupColumn), columns.count >= 2 { groupColumn = columns[1] }
        } catch {
            columns = []
            columnsError = error.localizedDescription
        }
    }

    private func run() {
        lastError = nil
        isRunning = true
        lastResult = nil

        let req = AnalysisRequest(
            schema_version: "1.0",
            analysis_run_id: "run_" + String(Int(Date().timeIntervalSince1970)),
            recipe_id: recipeId, // ✅ enumではなく recipes.json の id
            dataset: .init(path: csvPath, format: "csv"),
            variables: ["y": yColumn, "group": groupColumn],
            output: .init(workdir: workdir)
        )

        Task.detached {
            do {
                let res = try StatAppEngine.runAnalysis(request: req)
                await MainActor.run {
                    self.lastResult = res
                    self.isRunning = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.isRunning = false
                }
            }
        }
    }
}

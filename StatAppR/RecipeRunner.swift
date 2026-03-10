import Foundation

class RecipeRunner {
    static let shared = RecipeRunner()

    // Determine Rscript path - support both Intel and Apple Silicon Macs
    let rScriptPath: String = {
        let possiblePaths = [
            "/opt/homebrew/bin/Rscript",      // Apple Silicon homebrew (default)
            "/usr/local/bin/Rscript",          // Intel homebrew or direct installation
            "/usr/bin/Rscript"                 // System installation
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ Found Rscript at: \(path)")
                return path
            }
        }

        // Fallback to homebrew Apple Silicon location
        print("⚠️ Rscript not found in standard locations. Using fallback: /opt/homebrew/bin/Rscript")
        return "/opt/homebrew/bin/Rscript"
    }()

    let recipesDirectory = "/Users/uts/StatAppR/Engine/recipes"

    // MARK: - Recipe Execution

    func executeRecipe(
        name: String,
        csvPath: String,
        parameters: [String: Any],
        workDirectory: String = NSTemporaryDirectory()
    ) -> Result<RecipeOutput, RecipeError> {
        let recipePath = "\(recipesDirectory)/\(name).R"

        // Verify recipe exists
        if !FileManager.default.fileExists(atPath: recipePath) {
            return .failure(.recipeNotFound(name))
        }

        // Create results directory within work directory
        let resultsFolder = "\(workDirectory)/results"
        do {
            try FileManager.default.createDirectory(atPath: resultsFolder, withIntermediateDirectories: true)
        } catch {
            return .failure(.executionError("Failed to create results directory: \(error.localizedDescription)"))
        }

        // Use provided work directory
        let outputFile = "\(workDirectory)/recipe_output_\(UUID().uuidString).json"

        // Build R command
        let rCommand = buildRCommand(
            recipePath: recipePath,
            csvPath: csvPath,
            parameters: parameters,
            outputFile: outputFile
        )

        // DEBUG: ログ出力
        print("🔴 DEBUG RecipeRunner - R Command:")
        print("=====================================")
        print(rCommand)
        print("=====================================")

        // Execute R command
        do {
            _ = try executeRScript(rCommand, resultsFolder: resultsFolder)

            // Parse output
            if let result = try parseRecipeOutput(at: outputFile) {
                return .success(result)
            } else {
                return .failure(.invalidOutput)
            }
        } catch {
            return .failure(.executionError(error.localizedDescription))
        }
    }

    // MARK: - R Command Building

    private func buildRCommand(
        recipePath: String,
        csvPath: String,
        parameters: [String: Any],
        outputFile: String
    ) -> String {
        // Load recipe source
        let runnerDir = "/Users/uts/StatAppR/Engine"

        // Escape paths for R (handle quotes in paths)
        let escapedRecipePath = recipePath.replacingOccurrences(of: "'", with: "\\'")
        let escapedCsvPath = csvPath.replacingOccurrences(of: "'", with: "\\'")
        let escapedOutputFile = outputFile.replacingOccurrences(of: "'", with: "\\'")

        let commandLines = [
            "runner_dir <- '\(runnerDir)'",
            // Auto-install jsonlite if not available
            "if (!requireNamespace('jsonlite', quietly = TRUE)) { install.packages('jsonlite', repos = 'https://cran.r-project.org'); library(jsonlite) } else { library(jsonlite) }",
            "source('\(escapedRecipePath)')",
            "df <- read.csv('\(escapedCsvPath)', stringsAsFactors = FALSE)",
            buildParametersList(parameters),
            "result <- run(request, df)",
            "result_json <- toJSON(result, pretty = TRUE, auto_unbox = TRUE)",
            "write(result_json, '\(escapedOutputFile)')",
            "cat('SUCCESS')"
        ]

        return commandLines.joined(separator: "; ")
    }

    private func buildParametersList(_ parameters: [String: Any]) -> String {
        var lines: [String] = []

        lines.append("request <- list(")

        if !parameters.isEmpty {
            // Check if parameters already has a "variables" key
            if let variables = parameters["variables"] as? [String: Any], !variables.isEmpty {
                lines.append("  variables = list(")

                let varLines = variables.map { key, value in
                    if let value = value as? String {
                        return "    \(key) = '\(value)'"
                    } else if let value = value as? [String] {
                        let csvList = value.map { "'\($0)'" }.joined(separator: ", ")
                        return "    \(key) = c(\(csvList))"
                    } else if let value = value as? Bool {
                        return "    \(key) = \(value ? "TRUE" : "FALSE")"
                    } else {
                        return "    \(key) = \(value)"
                    }
                }

                lines.append(varLines.joined(separator: ",\n"))
                lines.append("  )")
            } else {
                // Fallback for flat parameters
                let parameterLines = parameters.map { key, value in
                    if let value = value as? String {
                        return "  \(key) = '\(value)'"
                    } else if let value = value as? [String] {
                        let csvList = value.map { "'\($0)'" }.joined(separator: ", ")
                        return "  \(key) = list(\(csvList))"
                    } else {
                        return "  \(key) = \(value)"
                    }
                }

                lines.append(parameterLines.joined(separator: ",\n"))
            }
        }

        lines.append(")")

        return lines.joined(separator: "\n")
    }

    // MARK: - R Script Execution

    private func executeRScript(_ command: String, resultsFolder: String = "") throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rScriptPath)
        process.arguments = ["-e", command]

        // Set environment variable for R to save plots in the results folder
        var environment = ProcessInfo.processInfo.environment
        if !resultsFolder.isEmpty {
            environment["STATAPPR_RESULTS_FOLDER"] = resultsFolder
        }
        process.environment = environment

        let pipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            if let errorMessage = String(data: errorData, encoding: .utf8) {
                throw RecipeError.executionError(errorMessage)
            }
            throw RecipeError.executionError("Unknown error")
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Output Parsing

    private func parseRecipeOutput(at path: String) throws -> RecipeOutput? {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()

        return try decoder.decode(RecipeOutput.self, from: data)
    }
}

// MARK: - Recipe Output Model

struct RecipeOutput: Codable {
    let summary: SummaryInfo?
    let tables: [TableInfo]?
    let figures: [FigureInfo]?
    let warnings: [WarningInfo]?
    let errors: [ErrorInfo]?

    struct SummaryInfo: Codable {
        let headline: String?
        let method_used: String?
        let key_metrics: [String: AnyCodable]?
        let interpretation_notes: [String]?
    }

    struct TableInfo: Codable {
        let id: String
        let title: String
        let data: [[String: AnyCodable]]
    }

    struct FigureInfo: Codable {
        let id: String
        let title: String
        let type: String
        let path: String?  // Path to the figure file
    }

    struct WarningInfo: Codable {
        let code: String
        let severity: String
        let message: String
    }

    struct ErrorInfo: Codable {
        let code: String
        let message: String
    }
}

// MARK: - AnyCodable for Dynamic Values

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}

// MARK: - Recipe Errors

enum RecipeError: LocalizedError {
    case recipeNotFound(String)
    case executionError(String)
    case invalidOutput
    case parseError(String)
    case csvNotFound(String)
    case parameterError(String)
    case rNotInstalled
    case packageMissing(String)

    var errorDescription: String? {
        switch self {
        case .recipeNotFound(let recipe):
            return "分析レシピが見つかりません: \(recipe)"
        case .executionError(let message):
            return "分析の実行に失敗しました：\(message)"
        case .invalidOutput:
            return "R の出力形式が無効です"
        case .parseError(let message):
            return "結果の解析に失敗しました：\(message)"
        case .csvNotFound(let path):
            return "CSV ファイルが見つかりません：\(path)"
        case .parameterError(let message):
            return "パラメータが無効です：\(message)"
        case .rNotInstalled:
            return "R がインストールされていません"
        case .packageMissing(let package):
            return "必要なパッケージ '\(package)' がインストールされていません"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .recipeNotFound(let recipe):
            return "別のレシピを選択してください。または、パッケージマネージャーでパッケージを確認してください。"
        case .executionError(let message):
            if message.contains("package") {
                return "パッケージマネージャーから必要なパッケージをインストールしてください。"
            } else if message.contains("csv") || message.contains("file") {
                return "CSV ファイルが正しく読み込まれているか確認してください。"
            }
            return "R スクリプトに問題がある可能性があります。ログを確認してください。"
        case .invalidOutput:
            return "分析を再度実行してください。それでも失敗する場合は、別のレシピを試してください。"
        case .parseError(_):
            return "R の出力形式が予期した形式ではありません。パッケージを最新版に更新してください。"
        case .csvNotFound(let path):
            return "「CSV をロード」ボタンから再度ファイルを選択してください。ファイルが削除されていないか確認してください。"
        case .parameterError(_):
            return "分析パラメータを確認して再度設定してください。必須パラメータが選択されているか確認しましたか？"
        case .rNotInstalled:
            return "R をインストールしてください。https://cran.r-project.org から最新版をダウンロードできます。"
        case .packageMissing(let package):
            return "パッケージマネージャーで '\(package)' をインストールしてください。"
        }
    }
}

import Foundation

class RecipeRunner {
    static let shared = RecipeRunner()

    let rScriptPath = "/usr/bin/Rscript"
    let recipesDirectory = "/Users/uts/StatAppR/Engine/recipes"

    // MARK: - Recipe Execution

    func executeRecipe(
        name: String,
        csvPath: String,
        parameters: [String: Any]
    ) -> Result<RecipeOutput, RecipeError> {
        let recipePath = "\(recipesDirectory)/\(name).R"

        // Verify recipe exists
        if !FileManager.default.fileExists(atPath: recipePath) {
            return .failure(.recipeNotFound(name))
        }

        // Create temporary working directory
        let tempDir = NSTemporaryDirectory()
        let outputFile = "\(tempDir)/recipe_output_\(UUID().uuidString).json"

        // Build R command
        let rCommand = buildRCommand(
            recipePath: recipePath,
            csvPath: csvPath,
            parameters: parameters,
            outputFile: outputFile
        )

        // Execute R command
        do {
            let output = try executeRScript(rCommand)

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
        let commandLines = [
            "source('\(recipePath)')",
            "df <- read.csv('\(csvPath)', stringsAsFactors = FALSE)",
            buildParametersList(parameters),
            "result <- run(request, df)",
            "library(jsonlite)",
            "result_json <- toJSON(result, pretty = TRUE)",
            "write(result_json, '\(outputFile)')",
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

    private func executeRScript(_ command: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rScriptPath)
        process.arguments = ["-e", command]

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

    var errorDescription: String? {
        switch self {
        case .recipeNotFound(let recipe):
            return "レシピが見つかりません: \(recipe)"
        case .executionError(let message):
            return "実行エラー: \(message)"
        case .invalidOutput:
            return "無効な出力形式"
        case .parseError(let message):
            return "解析エラー: \(message)"
        case .csvNotFound(let path):
            return "CSVファイルが見つかりません: \(path)"
        }
    }
}

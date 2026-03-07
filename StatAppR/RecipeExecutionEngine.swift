import Foundation

/// RecipeExecutionEngine
/// Responsible for orchestrating the complete recipe execution flow.
/// This module encapsulates parameter validation, R command building, and result parsing.
///
/// Single Responsibility: Execute recipes and manage the execution lifecycle
/// Dependencies: RecipeRunner, CSVManager
///
/// Usage:
/// ```swift
/// let engine = RecipeExecutionEngine()
/// engine.executeRecipe(
///     recipe: myRecipe,
///     csvPath: fileURL,
///     selectedColumns: parameterDict,
///     completion: { result in ... }
/// )
/// ```

class RecipeExecutionEngine {

    /// Shared singleton instance
    static let shared = RecipeExecutionEngine()

    /// Reference to the recipe runner for R execution
    private let recipeRunner = RecipeRunner.shared

    /// MARK: - Public Interface

    /// Execute a recipe with given parameters
    ///
    /// - Parameters:
    ///   - recipe: The recipe to execute
    ///   - csvPath: Path to the CSV data file
    ///   - selectedColumns: Dictionary mapping parameter keys to selected column names
    ///   - completion: Callback with result (success or failure)
    func executeRecipe(
        recipe: RecipeInfo,
        csvPath: URL,
        selectedColumns: [String: Set<String>],
        completion: @escaping (Result<RecipeOutput, RecipeExecutionError>) -> Void
    ) {
        // Validate inputs
        guard validateInputs(recipe: recipe, csvPath: csvPath, selectedColumns: selectedColumns) else {
            completion(.failure(.invalidInputs("入力値の検証に失敗しました")))
            return
        }

        // Build parameters dictionary from selected columns
        do {
            let parameters = try buildParameters(
                recipe: recipe,
                selectedColumns: selectedColumns
            )

            // Execute recipe asynchronously
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.recipeRunner.executeRecipe(
                    name: recipe.recipeName,
                    csvPath: csvPath.path,
                    parameters: parameters
                )

                // Return result on main thread
                DispatchQueue.main.async {
                    completion(result.mapError { error in
                        RecipeExecutionError.executionFailed(error.errorDescription ?? "実行エラー")
                    })
                }
            }
        } catch {
            completion(.failure(.parameterBuildingFailed(error.localizedDescription)))
        }
    }

    /// MARK: - Input Validation

    /// Validate recipe, CSV path, and selected columns
    ///
    /// - Returns: true if all inputs are valid, false otherwise
    private func validateInputs(
        recipe: RecipeInfo,
        csvPath: URL,
        selectedColumns: [String: Set<String>]
    ) -> Bool {
        // Check CSV path exists
        guard FileManager.default.fileExists(atPath: csvPath.path) else {
            return false
        }

        // Check recipe has required parameters
        for param in recipe.parameters where param.required {
            let selected = selectedColumns[param.parameterKey] ?? []
            if selected.isEmpty {
                return false
            }
        }

        return true
    }

    /// MARK: - Parameter Building

    /// Build parameters dictionary from recipe definition and selected columns
    ///
    /// - Parameters:
    ///   - recipe: The recipe definition
    ///   - selectedColumns: Mapping of parameter keys to selected column names
    /// - Returns: Dictionary in format expected by R
    /// - Throws: RecipeExecutionError if parameter building fails
    private func buildParameters(
        recipe: RecipeInfo,
        selectedColumns: [String: Set<String>]
    ) throws -> [String: Any] {
        var params: [String: Any] = [:]

        for param in recipe.parameters {
            let selectedForParam = selectedColumns[param.parameterKey] ?? []

            switch param.type {
            case .singleColumn:
                // Single column parameter - take first match
                if let firstSelected = selectedForParam.first {
                    params[param.parameterKey] = firstSelected
                } else if param.required {
                    throw RecipeExecutionError.missingRequiredParameter(param.name)
                }

            case .multipleColumns:
                // Multiple columns parameter - pass as array
                if !selectedForParam.isEmpty {
                    params[param.parameterKey] = Array(selectedForParam)
                } else if param.required {
                    throw RecipeExecutionError.missingRequiredParameter(param.name)
                }

            case .categorical:
                // Categorical parameter - not yet implemented
                // This would be for select lists, radio buttons, etc.
                // For now, skip categorical parameters
                break

            case .numeric:
                // Numeric parameter - not yet implemented
                // This would be for numeric input fields
                // For now, skip numeric parameters
                break
            }
        }

        // Wrap in request structure expected by R
        return ["variables": params]
    }

    /// Get error message for a missing parameter
    ///
    /// - Parameter parameterName: Name of the missing parameter
    /// - Returns: User-friendly error message in Japanese
    func getMissingParameterError(_ parameterName: String) -> String {
        return "\(parameterName) は必須です"
    }
}

/// MARK: - Error Types

/// Errors that can occur during recipe execution
enum RecipeExecutionError: LocalizedError {
    case invalidInputs(String)
    case missingRequiredParameter(String)
    case parameterBuildingFailed(String)
    case executionFailed(String)
    case invalidOutput(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidInputs(let message):
            return "入力値エラー: \(message)"

        case .missingRequiredParameter(let paramName):
            return "\(paramName) は必須です"

        case .parameterBuildingFailed(let message):
            return "パラメータ構築エラー: \(message)"

        case .executionFailed(let message):
            return "実行エラー: \(message)"

        case .invalidOutput(let message):
            return "出力解析エラー: \(message)"

        case .unknownError:
            return "不明なエラーが発生しました"
        }
    }

    var recipeErrorDescription: String {
        return errorDescription ?? "不明なエラー"
    }
}

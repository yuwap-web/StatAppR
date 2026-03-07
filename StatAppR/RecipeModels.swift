import Foundation

/// RecipeModels.swift
/// Contains all data models related to recipe definitions and parameters.
/// This module isolates recipe model definitions, improving code organization
/// and allowing these models to be used independently in testing or other contexts.
///
/// Models:
/// - RecipeInfo: Represents a single statistical recipe/analysis
/// - ParameterRequirement: Describes a parameter needed by a recipe
/// - ParameterType: Enumerates the types of parameters available

// MARK: - Recipe Information Model

/// RecipeInfo
/// Represents a single statistical recipe/analysis that can be executed.
/// Contains all metadata needed to display the recipe in the UI and execute it in R.
///
/// Properties:
/// - name: English name of the recipe
/// - nameJapanese: Japanese name for UI display
/// - description: Short description of what the recipe does
/// - recipeName: Identifier used to locate the R script (e.g., "meta_analysis")
/// - requiredColumns: List of column types required
/// - example: Example of how to use this recipe
/// - parameters: Array of parameter requirements
struct RecipeInfo: Identifiable {
    let id = UUID()
    let name: String                                    // English name
    let nameJapanese: String                           // 日本語名
    let description: String                            // Short description
    let recipeName: String                             // R script identifier (e.g., "meta_analysis")
    let requiredColumns: [String]                      // List of required column types
    let example: String                                // Usage example
    let parameters: [ParameterRequirement]             // Parameters this recipe needs
}

// MARK: - Parameter Requirement Model

/// ParameterRequirement
/// Describes a single parameter that a recipe needs.
/// Used to generate the parameter selection UI and validate user input.
///
/// Properties:
/// - name: Display name for the parameter (e.g., "時間列")
/// - parameterKey: Key used in R request (e.g., "time_column")
/// - type: Type of parameter (single column, multiple columns, etc.)
/// - description: Explanation of what this parameter is for
/// - required: Whether this parameter must be provided
struct ParameterRequirement: Identifiable {
    let id = UUID()
    let name: String               // 表示名（「時間列」など）
    let parameterKey: String       // パラメータキー（「time_column」など）
    let type: ParameterType        // パラメータ型
    let description: String        // 説明
    let required: Bool             // 必須か
}

// MARK: - Parameter Type Enumeration

/// ParameterType
/// Enumerates all possible types of parameters that recipes can have.
/// Each type affects how the parameter is displayed and handled in the UI.
///
/// Cases:
/// - singleColumn: User selects one CSV column
/// - multipleColumns: User selects multiple CSV columns
/// - categorical: User selects from a predefined list (future: select lists, radio buttons)
/// - numeric: User enters a numeric value (future: text input with validation)
enum ParameterType {
    case singleColumn              // 1つの列を選ぶ
    case multipleColumns           // 複数の列を選ぶ
    case categorical               // カテゴリから選ぶ（将来実装）
    case numeric                   // 数値入力（将来実装）
}

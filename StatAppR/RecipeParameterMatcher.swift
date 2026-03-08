import Foundation

/// RecipeParameterMatcher
/// Responsible for automatically matching CSV column names to recipe parameter requirements.
/// This module encapsulates all keyword-based parameter matching logic, reducing ContentView complexity.
///
/// Key Features:
/// - Comprehensive keyword mappings for 25+ parameter types
/// - Flexible matching algorithm (exact, contains, reverse-contains)
/// - Single responsibility: parameter auto-matching only
/// - Reusable across all recipes
///
/// Usage:
/// ```swift
/// let matcher = RecipeParameterMatcher()
/// let matched = matcher.matchParametersForRecipe(recipe, csvColumns: columns)
/// // matched: [String: Set<String>] where key=parameterKey, value=matchedColumnNames
/// ```

struct RecipeParameterMatcher {

    /// Comprehensive keyword mappings for all parameter types
    /// Maps parameter keys to arrays of matching keywords (aliases)
    /// Organized by parameter category for maintainability
    private let keywordMappings: [String: [String]] = [
        // ===== Time/Duration Parameters =====
        "time_column": ["time_column", "time", "months", "days", "years", "followup", "followup_months", "time_months", "duration", "period"],
        "start_column": ["start_column", "start", "start_time"],
        "stop_column": ["stop_column", "stop", "stop_time"],

        // ===== Event/Outcome Parameters =====
        "event_column": ["event_column", "event", "status", "outcome_event", "event_occurred", "censor", "censored"],
        "outcome_column": ["outcome_column", "outcome", "y", "result", "event", "disease_status", "measurement", "treatment"],

        // ===== Group/Stratum Parameters =====
        "group_column": ["group_column", "group", "arm", "condition", "strata", "stratification"],
        "subgroup_column": ["subgroup_column", "subgroup", "stratum", "author", "year", "category"],
        "treatment_column": ["treatment_column", "treatment", "treat", "treatment_group"],

        // ===== Variable Selection =====
        "variables": ["variables", "vars", "variable", "numeric_vars", "columns"],
        "predictor_columns": ["predictor_columns", "predictors", "features", "independent", "age", "gender", "bmi", "score", "baseline", "height", "weight"],
        "predictor_column": ["predictor_column", "predictor", "feature"],
        "covariates": ["covariates", "covariate", "confounders", "x", "control_vars"],

        // ===== ID Parameters =====
        "id": ["id", "patient_id", "subject_id", "individual_id"],
        "unit_id": ["unit_id", "unit", "entity_id", "firm_id", "country_id"],

        // ===== Exposure/Intervention =====
        "exposure_column": ["exposure_column", "exposure", "exposed"],

        // ===== Instrumental Variables =====
        "instrument": ["instrument", "instrument_var", "z", "iv"],

        // ===== Study/Research Parameters =====
        "author_column": ["author_column", "author", "study", "study_name"],
        "label": ["label", "author", "year", "study", "study_name"],  // Removed "study_id" to avoid false matches
        "effect_size_column": ["effect_size_column", "effect_size"],
        "standard_error_column": ["standard_error_column", "standard_error", "stderr"],

        // ===== Effect Size & SE (Meta-analysis) =====
        "effect": ["effect", "effect_size", "estimate", "coefficient"],
        "se": ["se", "standard_error", "stderr", "se_value"],

        // ===== Event/Policy Parameters =====
        "event_date_column": ["event_date_column", "event_date", "policy_time", "treat_time", "intervention_date"],

        // ===== Match/Case Parameters =====
        "matchset_column": ["matchset_column", "matchset", "matched_set"],

        // ===== Weight Parameters =====
        "weight_column": ["weight_column", "weight", "weights", "sample_weight"],
    ]

    /// Match recipe parameters to CSV columns using keyword-based matching
    ///
    /// Algorithm:
    /// 1. For each recipe parameter, look up its keywords in the mapping
    /// 2. For each CSV column, check for matches using three criteria:
    ///    - Exact match (columnName == keyword)
    ///    - Column contains keyword (columnName.contains(keyword))
    ///    - Keyword contains column (keyword.contains(columnName))
    /// 3. Add matched column to selectedColumnsByParameter[parameterKey]
    /// 4. Stop after first match per parameter (singleColumn behavior)
    ///
    /// - Parameters:
    ///   - recipe: The recipe whose parameters need matching
    ///   - csvColumns: Available CSV columns to match against
    /// - Returns: Dictionary mapping parameter keys to matched column names
    func matchParametersForRecipe(_ recipe: RecipeInfo?, csvColumns: [CSVColumn]) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]
        let DEBUG = true  // Set to true to enable detailed logging

        guard let recipe = recipe else {
            return result
        }

        if DEBUG {
            print("🔍 RecipeParameterMatcher: Starting match for recipe '\(recipe.name)'")
            print("📊 Available CSV columns: \(csvColumns.map { $0.name })")
        }

        for param in recipe.parameters {
            // Special handling for "variables" parameter: auto-select all numeric columns
            if param.parameterKey == "variables" && param.type == .multipleColumns {
                let numericColumns = csvColumns.filter { $0.dataType == "数値" }  // CSVManager returns "数値" in Japanese
                if !numericColumns.isEmpty {
                    result[param.parameterKey] = Set(numericColumns.map { $0.name })
                    if DEBUG {
                        print("🔍 Parameter 'variables': Auto-selected numeric columns: \(numericColumns.map { $0.name })")
                    }
                    continue
                }
            }

            // Special handling for "outcome_column" in logistic_regression: prefer binary categorical
            if param.parameterKey == "outcome_column" && param.type == .singleColumn && recipe.recipeName == "logistic_regression" {
                // Look for columns that could be binary outcome
                // Priority: "treatment" column name, then any categorical column
                if let treatmentCol = csvColumns.first(where: { $0.name.lowercased() == "treatment" }) {
                    result[param.parameterKey] = [treatmentCol.name]
                    if DEBUG {
                        print("🔍 Parameter 'outcome_column' (logistic_regression): Auto-selected 'treatment' column")
                    }
                    continue
                }
            }

            // Special handling for "predictor_columns" in logistic_regression: auto-select numeric columns except outcome
            if param.parameterKey == "predictor_columns" && param.type == .multipleColumns && recipe.recipeName == "logistic_regression" {
                // Get the already-matched outcome_column
                let outcomeColumns = result["outcome_column"] ?? Set()
                let numericColumns = csvColumns.filter { $0.dataType == "数値" && !outcomeColumns.contains($0.name) }
                if !numericColumns.isEmpty {
                    result[param.parameterKey] = Set(numericColumns.map { $0.name })
                    if DEBUG {
                        print("🔍 Parameter 'predictor_columns' (logistic_regression): Auto-selected numeric columns: \(numericColumns.map { $0.name })")
                    }
                    continue
                }
            }

            guard let keywords = keywordMappings[param.parameterKey] else {
                if DEBUG {
                    print("⚠️ No keywords found for parameter '\(param.parameterKey)'")
                }
                continue
            }

            if DEBUG {
                print("\n🔎 Parameter: '\(param.parameterKey)' (required: \(param.required))")
                print("   Keywords: \(keywords)")
            }

            // Try to find matching columns with priority:
            // 1. Exact match
            // 2. Column contains keyword (columnName.contains(keyword))
            // 3. Keyword contains column (keyword.contains(columnName)) - least preferred

            var foundMatch = false
            var bestMatch: (column: String, matchType: String)? = nil

            for column in csvColumns {
                let columnNameLower = column.name.lowercased()

                // Check for exact matches (highest priority)
                if let exactKeyword = keywords.first(where: { $0.lowercased() == columnNameLower }) {
                    if DEBUG {
                        print("   ✅ EXACT MATCH: '\(column.name)' ← keyword '\(exactKeyword)'")
                    }
                    result[param.parameterKey] = [column.name]
                    foundMatch = true
                    break  // Highest priority - stop immediately
                }

                // Check for column contains keyword (medium priority)
                if bestMatch == nil, let containsKeyword = keywords.first(where: { columnNameLower.contains($0.lowercased()) }) {
                    if DEBUG {
                        print("   ✅ CONTAINS MATCH: '\(column.name)' contains '\(containsKeyword)'")
                    }
                    bestMatch = (column: column.name, matchType: "contains")
                }

                // Check for keyword contains column (lowest priority)
                if bestMatch == nil, let reverseKeyword = keywords.first(where: { $0.lowercased().contains(columnNameLower) }) {
                    if DEBUG {
                        print("   ⚠️ REVERSE MATCH: '\(reverseKeyword)' contains '\(column.name)' (lower priority)")
                    }
                    bestMatch = (column: column.name, matchType: "reverse")
                }
            }

            // Use the best match found (if no exact match was already applied)
            if !foundMatch, let best = bestMatch {
                if DEBUG {
                    print("   → Selected: '\(best.column)' (\(best.matchType) match)")
                }
                result[param.parameterKey] = [best.column]
                foundMatch = true
            }

            if DEBUG && !foundMatch {
                print("   ❌ No match found")
            }
        }

        if DEBUG {
            print("\n📋 Final result: \(result)")
        }

        return result
    }

    /// Get keywords for a specific parameter key
    /// Useful for debugging or UI display purposes
    ///
    /// - Parameter parameterKey: The parameter key to look up
    /// - Returns: Array of keywords if found, nil otherwise
    func getKeywordsForParameter(_ parameterKey: String) -> [String]? {
        return keywordMappings[parameterKey]
    }

    /// Check if a parameter key has keyword mappings
    ///
    /// - Parameter parameterKey: The parameter key to check
    /// - Returns: true if the parameter has keyword mappings, false otherwise
    func hasKeywordsForParameter(_ parameterKey: String) -> Bool {
        return keywordMappings[parameterKey] != nil
    }
}

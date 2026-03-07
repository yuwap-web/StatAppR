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
        "outcome_column": ["outcome_column", "outcome", "y", "result", "event", "disease_status", "measurement"],

        // ===== Group/Stratum Parameters =====
        "group_column": ["group_column", "group", "arm", "condition", "strata", "stratification"],
        "subgroup_column": ["subgroup_column", "subgroup", "stratum"],
        "treatment_column": ["treatment_column", "treatment", "treat", "treatment_group"],

        // ===== Variable Selection =====
        "predictor_columns": ["predictor_columns", "predictors", "features", "independent", "variables"],
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
        "label": ["label", "author", "study", "study_id"],
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

        guard let recipe = recipe else {
            return result
        }

        for param in recipe.parameters {
            guard let keywords = keywordMappings[param.parameterKey] else {
                continue
            }

            // Try to find matching columns
            for column in csvColumns {
                let columnNameLower = column.name.lowercased()

                // Check for exact matches or keyword matches (case-insensitive)
                if keywords.contains(where: { keyword in
                    columnNameLower == keyword.lowercased() ||
                    columnNameLower.contains(keyword.lowercased()) ||
                    keyword.lowercased().contains(columnNameLower)
                }) {
                    result[param.parameterKey] = [column.name]
                    break  // One match per parameter for singleColumn behavior
                }
            }
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

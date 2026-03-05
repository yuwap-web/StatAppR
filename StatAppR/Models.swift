import Foundation

struct AnalysisRequest: Codable {
    var schema_version: String
    var analysis_run_id: String
    var recipe_id: String
    var dataset: DatasetSpec
    var variables: [String: String]
    var output: OutputSpec

    struct DatasetSpec: Codable {
        var path: String
        var format: String = "csv"
    }

    struct OutputSpec: Codable {
        var workdir: String
    }
}

import Foundation

struct AnalysisResult: Codable {
    var schema_version: String
    var analysis_run_id: String
    var recipe_id: String
    var status: String
    var started_at: String?
    var ended_at: String?

    var summary: Summary
    var artifacts: Artifacts
    var errors: [RunMessage]?
    var warnings: [RunMessage]?

    struct Summary: Codable {
        var headline: String
        var method_used: String?
        var key_metrics: [KeyMetric]?
        var interpretation_notes: [String]?

        struct KeyMetric: Codable {
            var name: String
            var value: Double?
        }
    }

    struct Artifacts: Codable {
        var tables: [TableArtifact]
        var figures: [FigureArtifact]?
        var report: [String]?
        var repro: ReproArtifact?
    }

    struct TableArtifact: Codable, Identifiable {
        var id: String
        var title: String
        var path: String
    }

    struct FigureArtifact: Codable, Identifiable {
        var id: String
        var title: String
        var path: String
    }

    struct ReproArtifact: Codable {
        var r_script: String?
        var session_info: String?
        var lockfile: String?
        var request_copy: String?
        var data_hash: String?
    }

    struct RunMessage: Codable, Identifiable {
        var id: String { code + ":" + (message ?? "") }
        var code: String
        var severity: String?
        var message: String?
        var hint: String?
    }
}

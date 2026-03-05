import Foundation

enum StatAppEngineError: LocalizedError {
    case runnerNotFound(String)
    case rscriptNotFound
    case processFailed(Int32, String)
    case invalidResultJSON(String)

    var errorDescription: String? {
        switch self {
        case .runnerNotFound(let p): return "runner.R が見つかりません: \(p)"
        case .rscriptNotFound: return "Rscript が見つかりません（/usr/local/bin/Rscript を確認）"
        case .processFailed(let code, let msg): return "解析に失敗しました (exit=\(code)): \(msg)"
        case .invalidResultJSON(let p): return "analysis_result.json の読み込みに失敗: \(p)"
        }
    }
}

final class StatAppEngine {
    /// あなたの環境ではここ（固定）
    static let defaultRunnerPath = "/Users/uts/StatAppR/Engine/runner.R"
    static let defaultRscriptPath = "/usr/local/bin/Rscript"

    static func runAnalysis(request: AnalysisRequest,
                            runnerPath: String = defaultRunnerPath,
                            rscriptPath: String = defaultRscriptPath) throws -> AnalysisResult {

        let workdir = URL(fileURLWithPath: request.output.workdir, isDirectory: true)
        try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)

        let reqURL = workdir.appendingPathComponent("analysis_request.json")
        try writeJSON(request, to: reqURL)

        // Validate runner exists
        if !FileManager.default.fileExists(atPath: runnerPath) {
            throw StatAppEngineError.runnerNotFound(runnerPath)
        }
        if !FileManager.default.fileExists(atPath: rscriptPath) {
            throw StatAppEngineError.rscriptNotFound
        }

        // Run process
        let p = Process()
        p.executableURL = URL(fileURLWithPath: rscriptPath)
        p.arguments = ["--vanilla", runnerPath, reqURL.path]

        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe

        try p.run()
        p.waitUntilExit()

        let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        if p.terminationStatus != 0 {
            throw StatAppEngineError.processFailed(p.terminationStatus, (stderr + "\n" + stdout).trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let resultURL = workdir.appendingPathComponent("analysis_result.json")
        guard FileManager.default.fileExists(atPath: resultURL.path) else {
            throw StatAppEngineError.invalidResultJSON(resultURL.path)
        }
        return try readJSON(AnalysisResult.self, from: resultURL)
    }

    // MARK: - JSON helpers
    private static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try enc.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    private static func readJSON<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        let dec = JSONDecoder()
        return try dec.decode(T.self, from: data)
    }
}

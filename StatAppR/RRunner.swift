import Foundation

enum EngineLocator {
    static func engineDir() throws -> URL {
        // まずは確実に：開発フォルダ直下 Engine を直指定
        let dev = URL(fileURLWithPath: "/Users/uts/StatAppR/Engine")
        if FileManager.default.fileExists(atPath: dev.appendingPathComponent("runner.R").path) {
            return dev
        }
        throw NSError(domain: "EngineLocator", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Engine not found at /Users/uts/StatAppR/Engine (runner.R missing)"])
    }
}

final class RRunner {
    func runTwoGroup(datasetPath: String, workdir: String) throws {
        let engine = try EngineLocator.engineDir()
        let runnerPath = engine.appendingPathComponent("runner.R").path

        // Models.swift の AnalysisRequest を使う（ここに定義しない）
        let req = AnalysisRequest(
            schema_version: "1.0",
            analysis_run_id: "run_\(Int(Date().timeIntervalSince1970))",
            recipe_id: "two_group_continuous",
            dataset: .init(path: datasetPath, format: "csv"),
            variables: [
                "group": "treatment",
                "y": "hba1c_baseline"
            ],
            output: .init(workdir: workdir)
        )
        try FileManager.default.createDirectory(atPath: workdir, withIntermediateDirectories: true)

        let reqURL = URL(fileURLWithPath: workdir).appendingPathComponent("analysis_request.json")
        let data = try JSONEncoder().encode(req)
        try data.write(to: reqURL, options: .atomic)

        let candidates = ["/usr/local/bin/Rscript", "/opt/homebrew/bin/Rscript", "/usr/bin/Rscript"]
        let rscript = candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let rscript else {
            throw NSError(domain: "RRunner", code: 2, userInfo: [NSLocalizedDescriptionKey: "Rscript not found"])
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: rscript)
        p.arguments = ["--vanilla", runnerPath, reqURL.path]

        let logsDir = URL(fileURLWithPath: workdir).appendingPathComponent("logs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        let outURL = logsDir.appendingPathComponent("stdout.txt")
        let errURL = logsDir.appendingPathComponent("stderr.txt")
        FileManager.default.createFile(atPath: outURL.path, contents: nil)
        FileManager.default.createFile(atPath: errURL.path, contents: nil)
        let outFH = try FileHandle(forWritingTo: outURL)
        let errFH = try FileHandle(forWritingTo: errURL)

        p.standardOutput = outFH
        p.standardError  = errFH

        try p.run()
        p.waitUntilExit()

        try? outFH.close()
        try? errFH.close()

        if p.terminationStatus != 0 {
            throw NSError(domain: "RRunner", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "R failed (\(p.terminationStatus)). Check \(logsDir.path)."])
        }
    }
}

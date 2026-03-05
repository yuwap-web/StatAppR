import Foundation

enum DatasetInspectorError: LocalizedError {
    case fileNotFound(String)
    case empty
    case unreadable

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let p): return "CSVが見つかりません: \(p)"
        case .empty: return "CSVが空です"
        case .unreadable: return "CSVを読み取れません"
        }
    }
}

final class DatasetInspector {
    static func readHeader(csvPath: String) throws -> [String] {
        let url = URL(fileURLWithPath: csvPath)
        guard FileManager.default.fileExists(atPath: url.path) else { throw DatasetInspectorError.fileNotFound(csvPath) }

        // Read first non-empty line
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard let first = lines.first else { throw DatasetInspectorError.empty }

        // Simple CSV split (Phase0)
        let cols = first.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
        return cols.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    static func defaultWorkdir() -> String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let stamp = Int(Date().timeIntervalSince1970)
        return desktop.appendingPathComponent("statapp_run_\(stamp)", isDirectory: true).path
    }
}

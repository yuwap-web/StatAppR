import Foundation

struct CSVPreview: Sendable {
    let headers: [String]
    let rows: [[String]]
}

/// Simple CSV preview loader (Phase0):
/// - Reads UTF-8 CSV
/// - Splits by commas (does NOT fully support quoted commas yet)
func loadCSVPreview(fileURL: URL, maxRows: Int = 30) throws -> CSVPreview {
    let text = try String(contentsOf: fileURL, encoding: .utf8)
    var lines = text.split(whereSeparator: \.isNewline).map(String.init)

    guard !lines.isEmpty else {
        return CSVPreview(headers: [], rows: [])
    }

    func splitCSVLine(_ line: String) -> [String] {
        line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
    }

    let headers = splitCSVLine(lines.removeFirst())
    var rows: [[String]] = []

    for line in lines.prefix(maxRows) {
        rows.append(splitCSVLine(line))
    }
    return CSVPreview(headers: headers, rows: rows)
}

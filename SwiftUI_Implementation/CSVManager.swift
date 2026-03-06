import Foundation

class CSVManager {
    static let shared = CSVManager()

    // MARK: - CSV Parsing

    func parseCSV(at url: URL) throws -> (headers: [String], data: [[String]]) {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerRow = rows.first else {
            throw CSVError.emptyFile
        }

        let headers = parseRow(headerRow)
        let data = rows.dropFirst().map { parseRow($0) }

        return (headers, Array(data))
    }

    private func parseRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        values.append(currentValue.trimmingCharacters(in: .whitespaces))
        return values
    }

    // MARK: - Data Type Detection

    func detectColumnTypes(headers: [String], data: [[String]]) -> [String: String] {
        var types: [String: String] = [:]

        for (index, header) in headers.enumerated() {
            var isNumeric = true
            var isBoolean = true
            var isDate = true

            for row in data {
                guard index < row.count else { continue }
                let value = row[index].lowercased().trimmingCharacters(in: .whitespaces)

                if value.isEmpty { continue }

                // Check numeric
                if isNumeric && Double(value) == nil {
                    isNumeric = false
                }

                // Check boolean
                if isBoolean && !["true", "false", "yes", "no", "1", "0"].contains(value) {
                    isBoolean = false
                }

                // Check date
                if isDate && !isValidDate(value) {
                    isDate = false
                }
            }

            if isNumeric {
                types[header] = "数値"
            } else if isBoolean {
                types[header] = "カテゴリ"
            } else if isDate {
                types[header] = "日時"
            } else {
                types[header] = "テキスト"
            }
        }

        return types
    }

    private func isValidDate(_ value: String) -> Bool {
        let dateFormats = [
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy-MM-dd HH:mm:ss"
        ]

        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if formatter.date(from: value) != nil {
                return true
            }
        }

        return false
    }

    // MARK: - CSV to Column Info

    func extractColumnInfo(headers: [String], data: [[String]], types: [String: String]) -> [CSVColumn] {
        var columns: [CSVColumn] = []

        for (index, header) in headers.enumerated() {
            let values = data.compactMap { row in
                guard index < row.count else { return nil }
                return row[index]
            }

            let sampleValue = values.first ?? "N/A"
            let missingCount = values.filter { $0.isEmpty }.count
            let dataType = types[header] ?? "テキスト"

            let column = CSVColumn(
                id: header,
                name: header,
                dataType: dataType,
                sampleValue: sampleValue,
                missingCount: missingCount
            )

            columns.append(column)
        }

        return columns
    }

    // MARK: - Validation

    func validateCSV(headers: [String], data: [[String]]) throws {
        if headers.isEmpty {
            throw CSVError.emptyHeaders
        }

        if data.isEmpty {
            throw CSVError.noData
        }

        let columnCount = headers.count
        for (rowIndex, row) in data.enumerated() {
            if row.count != columnCount {
                throw CSVError.inconsistentColumns(row: rowIndex, expected: columnCount, found: row.count)
            }
        }
    }
}

// MARK: - CSV Error Types

enum CSVError: LocalizedError {
    case emptyFile
    case emptyHeaders
    case noData
    case inconsistentColumns(row: Int, expected: Int, found: Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSVファイルが空です"
        case .emptyHeaders:
            return "ヘッダー行がありません"
        case .noData:
            return "データ行がありません"
        case .inconsistentColumns(let row, let expected, let found):
            return "行\(row + 1): 列数が一致しません（期待: \(expected), 実際: \(found)）"
        }
    }
}

import Foundation

class CSVManager {
    static let shared = CSVManager()

    // MARK: - Encoding Detection

    func detectEncoding(at url: URL) -> String {
        // Try to detect file encoding
        // Returns "UTF-8" or "shift-jis"
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return "UTF-8"  // Default
        }

        // Try UTF-8 first
        if String(data: data, encoding: .utf8) != nil {
            print("🔍 [CSVManager] Detected encoding: UTF-8")
            return "UTF-8"
        }

        // Try Shift-JIS
        if String(data: data, encoding: .shiftJIS) != nil {
            print("🔍 [CSVManager] Detected encoding: shift-jis")
            return "shift-jis"
        }

        // Default
        print("🔍 [CSVManager] Encoding detection failed, using UTF-8 as default")
        return "UTF-8"
    }

    // MARK: - CSV Parsing

    func parseCSV(at url: URL, maxRows: Int? = nil) throws -> (headers: [String], data: [[String]]) {
        // ファイル読み込み（大きなファイルはメモリ効率的に）
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int ?? 0
        let fileSizeMB = Double(fileSize) / (1024 * 1024)

        // 大きなファイル（>100MB）の場合、段階的に読み込む
        let content: String
        if fileSizeMB > 100 {
            // メモリ効率的な読み込み：必要な行数分だけ読む
            content = try readFileInChunks(at: url, maxRows: maxRows ?? 500)
            print("📊 [CSVManager] Large file mode (> 100MB): Reading in chunks")
        } else {
            // 小さいファイル：全行を読み込む（エンコーディング自動検出）
            if let contentUTF8 = try? String(contentsOf: url, encoding: .utf8) {
                content = contentUTF8
                print("📊 [CSVManager] Normal file mode (< 100MB): Reading entire file (UTF-8)")
            } else if let contentShiftJIS = try? String(contentsOf: url, encoding: .shiftJIS) {
                content = contentShiftJIS
                print("📊 [CSVManager] Normal file mode (< 100MB): Reading entire file (Shift-JIS)")
            } else {
                throw CSVError.emptyFile
            }
        }

        var rows = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerRow = rows.first else {
            throw CSVError.emptyFile
        }

        // 大きなファイルの場合、先頭maxRows行のみ処理
        if let maxRows = maxRows, rows.count > maxRows + 1 {
            rows = Array(rows.prefix(maxRows + 1))  // ヘッダー + maxRows
            print("📊 [CSVManager] Processing first \(maxRows) rows for column type detection (total rows available: \(rows.count))")
        }

        let headers = parseRow(headerRow)
        let data = rows.dropFirst().map { parseRow($0) }

        return (headers, Array(data))
    }

    // MARK: - Chunked File Reading for Large Files

    private func readFileInChunks(at url: URL, maxRows: Int) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        var lines: [String] = []
        var buffer = ""
        let chunkSize = 1024 * 1024  // 1MB chunks

        while lines.count <= maxRows {
            let chunk = try fileHandle.readData(ofLength: chunkSize)
            guard !chunk.isEmpty else { break }

            // Try UTF-8 first, then fall back to Shift-JIS
            var chunkString = String(data: chunk, encoding: .utf8)

            if chunkString == nil {
                // Try Shift-JIS (common for Japanese CSV files)
                chunkString = String(data: chunk, encoding: .shiftJIS)
                if chunkString != nil {
                    print("ℹ️  [CSVManager] Decoded chunk as Shift-JIS (UTF-8 failed)")
                }
            }

            guard let chunkString = chunkString else {
                print("❌ [CSVManager] Failed to decode chunk as UTF-8 or Shift-JIS")
                break
            }

            buffer += chunkString

            // Split and process complete lines
            let parts = buffer.split(separator: "\n", omittingEmptySubsequences: false)

            // Add all complete lines (keep last incomplete line in buffer)
            for i in 0..<(parts.count - 1) {
                lines.append(String(parts[i]))
                if lines.count > maxRows {
                    return lines.prefix(maxRows + 1).joined(separator: "\n")
                }
            }

            // Keep incomplete last line in buffer
            buffer = String(parts.last ?? "")
        }

        // Add remaining buffer content
        if !buffer.isEmpty {
            lines.append(buffer)
        }

        print("📊 [CSVManager] Successfully read \(lines.count) lines")
        return lines.joined(separator: "\n")
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
            let values = data.compactMap { row -> String? in
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

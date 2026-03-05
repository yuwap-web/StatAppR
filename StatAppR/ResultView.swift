import SwiftUI

struct ResultView: View {
    let workdir: URL
    let result: AnalysisResult

    @State private var tablePreviews: [String: CSVPreview] = [:]
    @State private var previewError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(result.summary.headline)
                .font(.title3)
                .bold()

            if result.status != "ok" {
                Text("status: \(result.status)")
                    .foregroundStyle(.red)

                if let errors = result.errors, !errors.isEmpty {
                    ForEach(errors) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.code).bold()
                            if let msg = e.message { Text(msg) }
                            if let hint = e.hint { Text(hint).foregroundStyle(.secondary) }
                        }
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            ForEach(result.artifacts.tables) { t in
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(t.title.isEmpty ? t.id : t.title)
                                .font(.headline)

                            Spacer()

                            Button("Finderで開く") {
                                let url = workdir.appendingPathComponent(t.path)
                                NSWorkspace.shared.open(url)
                            }
                        }

                        if let pv = tablePreviews[t.id] {
                            CSVTablePreview(preview: pv)
                        } else if let err = previewError {
                            Text(err).foregroundStyle(.red)
                        } else {
                            Text("読み込み中…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear { loadAllPreviews() }
    }

    private func loadAllPreviews() {
        previewError = nil
        tablePreviews = [:]

        for t in result.artifacts.tables {
            let url = workdir.appendingPathComponent(t.path)
            do {
                let pv = try loadCSVPreview(fileURL: url, maxRows: 30)
                tablePreviews[t.id] = pv
            } catch {
                previewError = "CSV読み込み失敗: \(error.localizedDescription)"
            }
        }
    }
}

private struct CSVTablePreview: View {
    let preview: CSVPreview

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 4) {
                if !preview.headers.isEmpty {
                    HStack {
                        ForEach(preview.headers.indices, id: \.self) { i in
                            Text(preview.headers[i])
                                .font(.caption)
                                .bold()
                                .frame(minWidth: 100, alignment: .leading)
                        }
                    }
                    Divider()
                }

                ForEach(preview.rows.indices, id: \.self) { r in
                    HStack {
                        let row = preview.rows[r]
                        ForEach(row.indices, id: \.self) { c in
                            Text(row[c])
                                .font(.caption)
                                .frame(minWidth: 100, alignment: .leading)
                        }
                    }
                }
            }
            .padding(6)
        }
        .frame(maxHeight: 240)
    }
}
